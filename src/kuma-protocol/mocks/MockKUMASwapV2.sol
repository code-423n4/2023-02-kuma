// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Errors} from "../libraries/Errors.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {IKUMABondToken} from "@mcag/interfaces/IKUMABondToken.sol";
import {IKUMAAddressProvider} from "../interfaces/IKUMAAddressProvider.sol";
import {IKBCToken} from "../interfaces/IKBCToken.sol";
import {IKIBToken} from "../interfaces/IKIBToken.sol";
import {IMockKUMASwapV2} from "./interfaces/IMockKUMASwapV2.sol";
import {IMCAGRateFeed} from "../interfaces/IMCAGRateFeed.sol";
import {PausableUpgradeable} from "@openzeppelin-upgradeable/contracts/security/PausableUpgradeable.sol";
import {PercentageMath} from "../libraries/PercentageMath.sol";
import {Roles} from "../libraries/Roles.sol";
import {WadRayMath} from "../libraries/WadRayMath.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

contract MockKUMASwapV2 is IMockKUMASwapV2, PausableUpgradeable, UUPSUpgradeable {
    using EnumerableSet for EnumerableSet.UintSet;
    using PercentageMath for uint256;
    using Roles for bytes32;
    using SafeERC20 for IERC20;
    using WadRayMath for uint256;

    uint256 public constant MIN_ALLOWED_COUPON = WadRayMath.RAY;
    uint256 public constant DEPRECATION_MODE_TIMELOCK = 2 days;

    uint8 private constant _VERSION = 2;

    bytes32 private _riskCategory;
    uint16 private _maxCoupons;
    IKUMAAddressProvider private _KUMAAddressProvider;
    bool private _isDeprecated;
    uint56 private _deprecationInitializedAt;
    uint16 private _variableFee;
    uint96 private _expirationDelay;
    IERC20 private _deprecationStableCoin;
    uint256 private _fixedFee;
    uint256 private _minCoupon;

    // @notice Set of unique coupons in reserve
    EnumerableSet.UintSet private _coupons;
    // @notice Set of all token ids in reserve
    EnumerableSet.UintSet private _bondReserve;
    // @notice Set of all expired token ids in the reserve;
    EnumerableSet.UintSet private _expiredBonds;

    // @notice KUMABondToken id to KBCToken id
    mapping(uint256 => uint256) private _cloneBonds;
    // @notice Quantity of each coupon in reserve
    mapping(uint256 => uint256) private _couponInventory;
    // @notive Bond id to Bond sale price discounted by KIBToken cumulative yield
    mapping(uint256 => uint256) private _bondBaseValue;

    // New non dynamic state variables should be stored here
    uint256 private _dummyVar0;

    modifier onlyRole(bytes32 role) {
        if (!IAccessControl(_KUMAAddressProvider.getAccessController()).hasRole(role, msg.sender)) {
            revert Errors.ACCESS_CONTROL_ACCOUNT_IS_MISSING_ROLE(msg.sender, role);
        }
        _;
    }

    modifier whenNotDeprecated() {
        if (_isDeprecated) {
            revert Errors.DEPRECATION_MODE_ENABLED();
        }
        _;
    }

    modifier whenDeprecated() {
        if (!_isDeprecated) {
            revert Errors.DEPRECATION_MODE_NOT_ENABLED();
        }
        _;
    }

    function reinitialize() external override reinitializer(_VERSION) {
        _dummyVar0 = 123;
    }

    /**
     * @notice Sells a bond against KIBToken.
     * @param tokenId Sold bond tokenId.
     */
    function sellAsset(uint256 tokenId) external override whenNotPaused whenNotDeprecated {
        if (_coupons.length() == _maxCoupons) {
            revert Errors.MAX_COUPONS_REACHED();
        }
        IKUMAAddressProvider KUMAAddressProvider = _KUMAAddressProvider;
        IKUMABondToken KUMABondToken = IKUMABondToken(KUMAAddressProvider.getKUMABondToken());
        IKUMABondToken.Bond memory bond = KUMABondToken.getBond(tokenId);

        if (bond.riskCategory != _riskCategory) {
            revert Errors.WRONG_RISK_CATEGORY();
        }

        if (bond.maturity <= block.timestamp) {
            revert Errors.CANNOT_SELL_MATURED_BOND();
        }

        IKIBToken KIBToken = IKIBToken(KUMAAddressProvider.getKIBToken(_riskCategory));
        uint256 referenceRate = IMCAGRateFeed(KUMAAddressProvider.getRateFeed()).getRate(_riskCategory);

        if (bond.coupon < referenceRate) {
            revert Errors.COUPON_TOO_LOW();
        }

        if (_coupons.length() == 0) {
            _minCoupon = bond.coupon;
            _coupons.add(bond.coupon);
        } else {
            if (bond.coupon < _minCoupon) {
                _minCoupon = bond.coupon;
            }
            if (!_coupons.contains(bond.coupon)) {
                _coupons.add(bond.coupon);
            }
        }

        _couponInventory[bond.coupon]++;
        _bondReserve.add(tokenId);

        uint256 bondValue = _getBondValue(bond.issuance, bond.term, bond.coupon, bond.principal);

        _bondBaseValue[tokenId] = bondValue.wadToRay().rayDiv(KIBToken.getUpdatedCumulativeYield());

        uint256 fee = _calculateFees(bondValue);

        uint256 mintAmount = bondValue;

        if (fee > 0) {
            mintAmount = bondValue - fee;
            KIBToken.mint(KUMAAddressProvider.getKUMAFeeCollector(_riskCategory), fee);
        }

        KIBToken.mint(msg.sender, mintAmount);
        KUMABondToken.safeTransferFrom(msg.sender, address(this), tokenId);

        emit FeeCharged(fee);
        emit BondSold(tokenId, mintAmount, msg.sender);
    }

    /**
     * @notice Buys a bond against KIBToken.
     * @param tokenId Bought bond tokenId.
     */
    function buyAsset(uint256 tokenId) external override whenNotPaused whenNotDeprecated {
        IKUMAAddressProvider KUMAAddressProvider = _KUMAAddressProvider;
        IKUMABondToken KUMABondToken = IKUMABondToken(KUMAAddressProvider.getKUMABondToken());
        IKUMABondToken.Bond memory bond = KUMABondToken.getBond(tokenId);

        if (!_bondReserve.contains(tokenId)) {
            revert Errors.INVALID_TOKEN_ID();
        }

        bool isBondExpired = _expiredBonds.contains(tokenId);

        if (_expiredBonds.length() > 0 && !isBondExpired) {
            revert Errors.EXPIRED_BONDS_MUST_BE_BOUGHT_FIRST();
        }

        if (_couponInventory[bond.coupon] == 1) {
            _coupons.remove(bond.coupon);
        }

        _couponInventory[bond.coupon]--;
        _bondReserve.remove(tokenId);

        if (isBondExpired) {
            _expiredBonds.remove(tokenId);
        }

        IKIBToken KIBToken = IKIBToken(_KUMAAddressProvider.getKIBToken(_riskCategory));

        uint256 bondFaceValue = _getBondValue(bond.issuance, bond.term, bond.coupon, bond.principal);
        uint256 realizedBondValue = _bondBaseValue[tokenId].rayMul(KIBToken.getUpdatedCumulativeYield()).rayToWad();

        bool requireClone = bondFaceValue > realizedBondValue;

        if (requireClone) {
            _cloneBonds[tokenId] = IKBCToken(_KUMAAddressProvider.getKBCToken()).issueBond(
                msg.sender,
                IKBCToken.CloneBond({
                    parentId: tokenId,
                    issuance: KIBToken.getPreviousEpochTimestamp(),
                    coupon: KIBToken.getYield(),
                    principal: realizedBondValue
                })
            );
        }

        _updateMinCoupon();

        KIBToken.burn(msg.sender, realizedBondValue);

        if (!requireClone) {
            KUMABondToken.safeTransferFrom(address(this), msg.sender, tokenId);
        }

        emit BondBought(tokenId, realizedBondValue, msg.sender);
    }

    /**
     * @notice Buys a bond against _deprecationStableCoin.
     * @dev Requires an approval on amount from buyer. This will also result in some stale state for the contract on _coupons
     * and _minCoupon but this is acceptable as deprecation mode is irreversible. This function also ignores any existing clone bond
     * which is the intended bahaviour as bonds will be valued per their market rate offchain.
     * @param tokenId Bought bond tokenId.
     * @param buyer Bought bond buyer.
     * @param amount Stable coin price paid by the buyer.
     */
    function buyAssetForStableCoin(uint256 tokenId, address buyer, uint256 amount)
        external
        override
        onlyRole(Roles.KUMA_MANAGER_ROLE)
        whenDeprecated
    {
        if (!_bondReserve.contains(tokenId)) {
            revert Errors.INVALID_TOKEN_ID();
        }
        if (buyer == address(0)) {
            revert Errors.BUYER_CANNOT_BE_ADDRESS_ZERO();
        }
        if (amount == 0) {
            revert Errors.AMOUNT_CANNOT_BE_ZERO();
        }

        _bondReserve.remove(tokenId);

        _deprecationStableCoin.safeTransferFrom(buyer, address(this), amount);
        IKUMABondToken(_KUMAAddressProvider.getKUMABondToken()).safeTransferFrom(address(this), buyer, tokenId);

        emit BondBought(tokenId, amount, buyer);
    }

    /**
     * @notice Claims a bond against a CloneBond.
     * @dev Can only by called by a KUMA_SWAP_CLAIM_ROLE address.
     * @param tokenId Claimed bond tokenId.
     */
    function claimAsset(uint256 tokenId)
        external
        override
        onlyRole(Roles.KUMA_SWAP_CLAIM_ROLE.toGranularRole(_riskCategory))
    {
        IKUMAAddressProvider KUMAAddressProvider = _KUMAAddressProvider;

        if (_cloneBonds[tokenId] == 0) {
            revert Errors.BOND_NOT_AVAILABLE_FOR_CLAIM();
        }

        uint256 gBondId = _cloneBonds[tokenId];
        delete _cloneBonds[tokenId];

        IKBCToken(KUMAAddressProvider.getKBCToken()).redeem(gBondId);
        IKUMABondToken(KUMAAddressProvider.getKUMABondToken()).safeTransferFrom(address(this), msg.sender, tokenId);

        emit BondClaimed(tokenId, gBondId);
    }

    /**
     * @notice Redeems KIBToken against deprecation mode stable coin. Redeem stable coin amount is calculated as follow :
     *                          KIBTokenAmount
     *      redeemAmount = ------------------------ * KUMASwapStableCoinBalance
     *                        KIBTokenTotalSupply
     * @dev Can only be called if deprecation mode is enabled.
     * @param amount Amount of KIBToken to redeem.
     */
    function redeemKIBT(uint256 amount) external override whenDeprecated {
        if (amount == 0) {
            revert Errors.AMOUNT_CANNOT_BE_ZERO();
        }
        if (_bondReserve.length() != 0) {
            revert Errors.BOND_RESERVE_NOT_EMPTY();
        }
        IKIBToken KIBToken = IKIBToken(_KUMAAddressProvider.getKIBToken(_riskCategory));
        IERC20 deprecationStableCoin = _deprecationStableCoin;

        uint256 redeemAmount =
            amount.wadMul(_deprecationStableCoin.balanceOf(address(this))).wadDiv(KIBToken.totalSupply());
        KIBToken.burn(msg.sender, amount);
        deprecationStableCoin.safeTransfer(msg.sender, redeemAmount);

        emit KIBTRedeemed(msg.sender, redeemAmount);
    }

    /**
     * @notice Expires a bond if it has reached maturity by setting _minCoupon to MIN_ALLOWED_COUPON.
     * @param tokenId Claimed bond tokenId.
     */
    function expireBond(uint256 tokenId) external override whenNotDeprecated {
        if (!_bondReserve.contains(tokenId)) {
            revert Errors.INVALID_TOKEN_ID();
        }

        IKUMAAddressProvider KUMAAddressProvider = _KUMAAddressProvider;

        if (IKUMABondToken(KUMAAddressProvider.getKUMABondToken()).getBond(tokenId).maturity <= block.timestamp) {
            _expiredBonds.add(tokenId);

            IKIBToken(KUMAAddressProvider.getKIBToken(_riskCategory)).refreshYield();

            emit BondExpired(tokenId);
        }
    }

    /**
     * @dev See {Pausable-_pause}.
     */
    function pause() external override onlyRole(Roles.KUMA_SWAP_PAUSE_ROLE.toGranularRole(_riskCategory)) {
        _pause();
    }

    /**
     * @dev See {Pausable-_unpause}.
     */
    function unpause() external override onlyRole(Roles.KUMA_SWAP_UNPAUSE_ROLE.toGranularRole(_riskCategory)) {
        _unpause();
    }

    /**
     * @notice Set fees that will be charges upon bond sale per the following formula :
     * totalFee = bondValue * variableFee + fixedFee.
     * @param variableFee in basis points.
     * @param fixedFee in KIBToken decimals.
     */
    function setFees(uint16 variableFee, uint256 fixedFee) external override onlyRole(Roles.KUMA_MANAGER_ROLE) {
        _variableFee = variableFee;
        _fixedFee = fixedFee;
        emit FeeSet(variableFee, fixedFee);
    }

    /**
     * @notice Sets a new stable coin to be accepted during deprecation mode.
     * @param newDeprecationStableCoin New stable coin.
     */
    function setDeprecationStableCoin(IERC20 newDeprecationStableCoin)
        external
        override
        onlyRole(Roles.KUMA_MANAGER_ROLE)
        whenNotDeprecated
    {
        if (address(newDeprecationStableCoin) == address(0)) {
            revert Errors.CANNOT_SET_TO_ADDRESS_ZERO();
        }
        emit DeprecationStableCoinSet(address(_deprecationStableCoin), address(newDeprecationStableCoin));
        _deprecationStableCoin = newDeprecationStableCoin;
    }

    /**
     * @notice Initializes deprecation mode.
     */
    function initializeDeprecationMode() external override onlyRole(Roles.KUMA_MANAGER_ROLE) whenNotDeprecated {
        if (_deprecationInitializedAt != 0) {
            revert Errors.DEPRECATION_MODE_ALREADY_INITIALIZED();
        }

        _deprecationInitializedAt = uint56(block.timestamp);

        emit DeprecationModeInitialized();
    }

    /**
     * @notice Cancel the initialization of the deprecation mode.
     */
    function uninitializeDeprecationMode() external onlyRole(Roles.KUMA_MANAGER_ROLE) whenNotDeprecated {
        if (_deprecationInitializedAt == 0) {
            revert Errors.DEPRECATION_MODE_NOT_INITIALIZED();
        }

        _deprecationInitializedAt = 0;

        emit DeprecationModeUninitialized();
    }

    /**
     * @notice Enables deprecation.
     * @dev Deprecation mode must have been initialized at least 2 days before through the initializeDeprecationMode function.
     */
    function enableDeprecationMode() external override onlyRole(Roles.KUMA_MANAGER_ROLE) whenNotDeprecated {
        if (_deprecationInitializedAt == 0) {
            revert Errors.DEPRECATION_MODE_NOT_INITIALIZED();
        }

        uint256 elapsedTime = block.timestamp - _deprecationInitializedAt;

        if (elapsedTime < DEPRECATION_MODE_TIMELOCK) {
            revert Errors.ELAPSED_TIME_SINCE_DEPRECATION_MODE_INITIALIZATION_TOO_SHORT(
                elapsedTime, DEPRECATION_MODE_TIMELOCK
            );
        }

        _isDeprecated = true;

        IKIBToken(_KUMAAddressProvider.getKIBToken(_riskCategory)).refreshYield();

        emit DeprecationModeEnabled();
    }

    function getRiskCategory() external view returns (bytes32) {
        return _riskCategory;
    }

    function getMaxCoupons() external view returns (uint16) {
        return _maxCoupons;
    }

    function getKUMAAddressProvider() external view returns (IKUMAAddressProvider) {
        return _KUMAAddressProvider;
    }

    /**
     * @return True if deprecation mode has been initialized false if not.
     */
    function isDeprecationInitialized() external view override returns (bool) {
        return _deprecationInitializedAt != 0;
    }

    /**
     * @return Timestamp of deprecation mode initialization.
     */
    function getDeprecationInitializedAt() external view override returns (uint56) {
        return _deprecationInitializedAt;
    }

    /**
     * @return True if deprecation mode has been enabled false if not.
     */
    function isDeprecated() external view override returns (bool) {
        return _isDeprecated;
    }

    /**
     * @return _varibaleFee Variable fee in basis points.
     */
    function getVariableFee() external view override returns (uint16) {
        return _variableFee;
    }

    /**
     * @return _deprecationStableCoin Accepted stable coin during deprecation mode.
     */
    function getDeprecationStableCoin() external view override returns (IERC20) {
        return _deprecationStableCoin;
    }

    /**
     * @return _fixedFee Fixed fee in KIBToken decimals.
     */
    function getFixedFee() external view override returns (uint256) {
        return _fixedFee;
    }

    /**
     * @return Lowest coupon of bonds in reserve.
     */
    function getMinCoupon() external view override returns (uint256) {
        return _minCoupon;
    }

    /**
     * @return Array of all coupons in reserve.
     */
    function getCoupons() external view override returns (uint256[] memory) {
        return _coupons.values();
    }

    /**
     * @return Index of coupon in the _coupons Set.
     */
    function getCouponIndex(uint256 coupon) external view override returns (uint256) {
        return _coupons._inner._indexes[bytes32(coupon)];
    }

    /**
     * @return Array of all tokenIds in reserve.
     */
    function getBondReserve() external view override returns (uint256[] memory) {
        return _bondReserve.values();
    }

    /**
     * @return Array of all tokenIds in reserve.
     */
    function getExpiredBonds() external view override returns (uint256[] memory) {
        return _expiredBonds.values();
    }

    /**
     * @return Index of tokenId in the _bondReserve Array.
     */
    function getBondIndex(uint256 tokenId) external view override returns (uint256) {
        return _bondReserve._inner._indexes[bytes32(tokenId)];
    }

    /**
     * @return CloneBond Id of parent tokenId.
     */
    function getCloneBond(uint256 tokenId) external view override returns (uint256) {
        return _cloneBonds[tokenId];
    }

    /**
     * @return Amount of bonds with coupon value in inventory.
     */
    function getCouponInventory(uint256 coupon) external view override returns (uint256) {
        return _couponInventory[coupon];
    }

    /**
     * @return True if bond is in reserve false if not.
     */
    function isInReserve(uint256 tokenId) external view override returns (bool) {
        return _bondReserve.contains(tokenId);
    }

    /**
     * @return True if reserve has an expired bond false if not.
     */
    function isExpired() external view override returns (bool) {
        return _expiredBonds.length() > 0;
    }

    /**
     * @return Bond base value.
     */
    function getBondBaseValue(uint256 tokenId) external view override returns (uint256) {
        return _bondBaseValue[tokenId];
    }

    function getDummyVar0() external view returns (uint256) {
        return _dummyVar0;
    }

    function version() public pure override returns (uint8) {
        return _VERSION;
    }

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
        external
        pure
        override
        returns (bytes4)
    {
        return IERC721Receiver.onERC721Received.selector;
    }

    function _authorizeUpgrade(address newImplementation) internal view override onlyRole(Roles.KUMA_MANAGER_ROLE) {}

    /**
     * @return bondValue Bond principal value + accrued interests.
     */
    function _getBondValue(uint256 issuance, uint256 term, uint256 coupon, uint256 principal)
        private
        view
        returns (uint256)
    {
        uint256 previousEpochTimestamp =
            IKIBToken(_KUMAAddressProvider.getKIBToken(_riskCategory)).getPreviousEpochTimestamp();

        if (previousEpochTimestamp <= issuance) {
            return principal;
        }

        uint256 elapsedTime = previousEpochTimestamp - issuance;

        if (elapsedTime > term) {
            elapsedTime = term;
        }

        return coupon.rayPow(elapsedTime).rayMul(principal);
    }

    /**
     * @return minCoupon Lowest coupon of bonds in reserve.
     */
    function _updateMinCoupon() private returns (uint256) {
        uint256 currentMinCoupon = _minCoupon;

        if (_coupons.length() == 0) {
            _minCoupon = MIN_ALLOWED_COUPON;
            emit MinCouponUpdated(currentMinCoupon, MIN_ALLOWED_COUPON);
            return MIN_ALLOWED_COUPON;
        }

        if (_couponInventory[currentMinCoupon] != 0) {
            return currentMinCoupon;
        }

        uint256 minCoupon = _coupons.at(0);

        for (uint256 i = 1; i < _coupons.length();) {
            uint256 coupon = _coupons.at(i);

            if (coupon < minCoupon) {
                minCoupon = coupon;
            }

            unchecked {
                ++i;
            }
        }

        _minCoupon = minCoupon;

        emit MinCouponUpdated(currentMinCoupon, minCoupon);

        return minCoupon;
    }

    /**
     * @return fee Based on a specific amount.
     */
    function _calculateFees(uint256 amount) private view returns (uint256 fee) {
        if (_variableFee > 0) {
            fee = amount.percentMul(_variableFee);
        }
        if (_fixedFee > 0) {
            fee += _fixedFee;
        }
    }
}
