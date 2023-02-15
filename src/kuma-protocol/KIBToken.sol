// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {
    ERC20Upgradeable, IERC20Upgradeable
} from "@openzeppelin-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol";
import {
    ERC20PermitUpgradeable,
    IERC20PermitUpgradeable
} from "@openzeppelin-upgradeable/contracts/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import {Errors} from "./libraries/Errors.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IKUMAAddressProvider} from "./interfaces/IKUMAAddressProvider.sol";
import {IKIBToken} from "./interfaces/IKIBToken.sol";
import {IKUMASwap} from "./interfaces/IKUMASwap.sol";
import {IMCAGRateFeed} from "./interfaces/IMCAGRateFeed.sol";
import {Roles} from "./libraries/Roles.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import {WadRayMath} from "./libraries/WadRayMath.sol";

contract KIBToken is IKIBToken, ERC20PermitUpgradeable, UUPSUpgradeable {
    using Roles for bytes32;
    using WadRayMath for uint256;

    uint256 public constant MAX_YIELD = 1e29;
    uint256 public constant MAX_EPOCH_LENGTH = 365 days;
    uint256 public constant MIN_YIELD = WadRayMath.RAY;

    IKUMAAddressProvider private _KUMAAddressProvider;
    bytes32 private _riskCategory;
    uint256 private _yield;
    uint256 private _previousEpochCumulativeYield;
    uint256 private _cumulativeYield;
    uint256 private _lastRefresh;
    uint256 private _epochLength;

    uint256 private _totalBaseSupply; // Underlying assets supply (does not include rewards)

    mapping(address => uint256) private _baseBalances; // (does not include rewards)
    mapping(address => mapping(address => uint256)) private _allowances;

    modifier onlyRole(bytes32 role) {
        if (!_KUMAAddressProvider.getAccessController().hasRole(role, msg.sender)) {
            revert Errors.ACCESS_CONTROL_ACCOUNT_IS_MISSING_ROLE(msg.sender, role);
        }
        _;
    }

    constructor() initializer {}

    /**
     * @notice The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     * @param name Token name.
     * @param symbol Tokne symbol.
     * @param epochLength Rebase intervals in seconds.
     * @param KUMAAddressProvider KUMAAddressProvider.
     */
    function initialize(
        string memory name,
        string memory symbol,
        uint256 epochLength,
        IKUMAAddressProvider KUMAAddressProvider,
        bytes4 currency,
        bytes4 country,
        uint64 term
    ) external override initializer {
        if (epochLength == 0) {
            revert Errors.EPOCH_LENGTH_CANNOT_BE_ZERO();
        }
        if (address(KUMAAddressProvider) == address(0)) {
            revert Errors.CANNOT_SET_TO_ADDRESS_ZERO();
        }
        if (currency == bytes4(0) || country == bytes4(0) || term == 0) {
            revert Errors.WRONG_RISK_CATEGORY();
        }
        _yield = MIN_YIELD;
        _epochLength = epochLength;
        _lastRefresh = block.timestamp % epochLength == 0
            ? block.timestamp
            : (block.timestamp / epochLength) * epochLength + epochLength;
        _cumulativeYield = MIN_YIELD;
        _previousEpochCumulativeYield = MIN_YIELD;
        _KUMAAddressProvider = KUMAAddressProvider;
        _riskCategory = keccak256(abi.encode(currency, country, term));
        __ERC20_init(name, symbol);
        __ERC20Permit_init(name);

        emit CumulativeYieldUpdated(0, MIN_YIELD);
        emit EpochLengthSet(0, epochLength);
        emit KUMAAddressProviderSet(address(KUMAAddressProvider));
        emit PreviousEpochCumulativeYieldUpdated(0, MIN_YIELD);
        emit RiskCategorySet(_riskCategory);
        emit YieldUpdated(0, MIN_YIELD);
    }

    /**
     * @param epochLength New rebase interval.
     */
    function setEpochLength(uint256 epochLength) external override onlyRole(Roles.KUMA_SET_EPOCH_LENGTH_ROLE) {
        if (epochLength == 0) {
            revert Errors.EPOCH_LENGTH_CANNOT_BE_ZERO();
        }
        if (epochLength > MAX_EPOCH_LENGTH) {
            revert Errors.NEW_EPOCH_LENGTH_TOO_HIGH();
        }
        if (epochLength > _epochLength) {
            _refreshCumulativeYield();
            _refreshYield();
        }
        emit EpochLengthSet(_epochLength, epochLength);
        _epochLength = epochLength;
    }

    /**
     * @notice Updates yield based on current yield and oracle reference rate.
     */
    function refreshYield() external override {
        _refreshCumulativeYield();
        _refreshYield();
    }

    /**
     * @dev See {ERC20-_mint}.
     * @notice Following logic has been added/updated :
     * - Cumulative yield refresh
     */
    function mint(address account, uint256 amount)
        external
        override
        onlyRole(Roles.KUMA_MINT_ROLE.toGranularRole(_riskCategory))
    {
        if (block.timestamp < _lastRefresh) {
            revert Errors.START_TIME_NOT_REACHED();
        }
        if (account == address(0)) {
            revert Errors.ERC20_MINT_TO_THE_ZERO_ADDRESS();
        }
        _refreshCumulativeYield();
        _refreshYield();

        uint256 newAccountBalance = this.balanceOf(account) + amount;
        uint256 newBaseBalance = WadRayMath.wadToRay(newAccountBalance).rayDiv(_previousEpochCumulativeYield); // Store baseAmount in 27 decimals

        if (amount > 0) {
            _totalBaseSupply += newBaseBalance - _baseBalances[account];
            _baseBalances[account] = newBaseBalance;
        }

        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev See {ERC20-_burn}.
     * @notice Following logic has been added/updated :
     * - Cumulative yield refresh
     * - Destroy baseAmount instead of amount
     */
    function burn(address account, uint256 amount)
        external
        override
        onlyRole(Roles.KUMA_BURN_ROLE.toGranularRole(_riskCategory))
    {
        if (account == address(0)) {
            revert Errors.ERC20_BURN_FROM_THE_ZERO_ADDRESS();
        }
        _refreshCumulativeYield();
        _refreshYield();

        uint256 startingAccountBalance = this.balanceOf(account);
        if (startingAccountBalance < amount) {
            revert Errors.ERC20_BURN_AMOUNT_EXCEEDS_BALANCE();
        }

        uint256 newAccountBalance = startingAccountBalance - amount;
        uint256 newBaseBalance = WadRayMath.wadToRay(newAccountBalance).rayDiv(_previousEpochCumulativeYield);
        if (amount > 0) {
            _totalBaseSupply -= _baseBalances[account] - newBaseBalance;
            _baseBalances[account] = newBaseBalance;
        }

        emit Transfer(account, address(0), amount);
    }

    function getKUMAAddressProvider() external view returns (IKUMAAddressProvider) {
        return _KUMAAddressProvider;
    }

    function getRiskCategory() external view returns (bytes32) {
        return _riskCategory;
    }

    /**
     * @return Current yield
     */
    function getYield() external view override returns (uint256) {
        return _yield;
    }

    /**
     * @return Timestamp of last rebase.
     */
    function getLastRefresh() external view override returns (uint256) {
        return _lastRefresh;
    }

    /**
     * @return Current baseTotalSupply.
     */
    function getTotalBaseSupply() external view override returns (uint256) {
        return _totalBaseSupply;
    }

    /**
     * @return User base balance
     */
    function getBaseBalance(address account) external view override returns (uint256) {
        return _baseBalances[account];
    }

    /**
     * @return Current epoch length.
     */
    function getEpochLength() external view override returns (uint256) {
        return _epochLength;
    }

    /**
     * @return Last updated cumulative yield
     */
    function getCumulativeYield() external view override returns (uint256) {
        return _cumulativeYield;
    }

    /**
     * @return Cumulative yield calculated at last epoch
     */
    function getUpdatedCumulativeYield() external view override returns (uint256) {
        return _calculatePreviousEpochCumulativeYield();
    }

    /**
     * @return Timestamp rounded down to the previous epoch length.
     */
    function getPreviousEpochTimestamp() external view returns (uint256) {
        return _getPreviousEpochTimestamp();
    }

    /**
     * @dev See {ERC20-balanceOf}.
     */
    function balanceOf(address account) public view override(ERC20Upgradeable, IERC20Upgradeable) returns (uint256) {
        return WadRayMath.rayToWad(_baseBalances[account].rayMul(_calculatePreviousEpochCumulativeYield()));
    }

    /**
     * @dev See {ERC20-symbol}.
     */
    function totalSupply() public view override(ERC20Upgradeable, IERC20Upgradeable) returns (uint256) {
        return WadRayMath.rayToWad(_totalBaseSupply.rayMul(_calculatePreviousEpochCumulativeYield()));
    }

    /**
     * @dev See {ERC20-_transfer}.
     */
    function _transfer(address from, address to, uint256 amount) internal override {
        if (from == address(0)) {
            revert Errors.ERC20_TRANSFER_FROM_THE_ZERO_ADDRESS();
        }
        if (to == address(0)) {
            revert Errors.ERC20_TRANSER_TO_THE_ZERO_ADDRESS();
        }
        _refreshCumulativeYield();
        _refreshYield();

        uint256 startingFromBalance = this.balanceOf(from);
        if (startingFromBalance < amount) {
            revert Errors.ERC20_TRANSFER_AMOUNT_EXCEEDS_BALANCE();
        }
        uint256 newFromBalance = startingFromBalance - amount;
        uint256 newToBalance = this.balanceOf(to) + amount;

        uint256 previousEpochCumulativeYield_ = _previousEpochCumulativeYield;
        uint256 newFromBaseBalance = WadRayMath.wadToRay(newFromBalance).rayDiv(previousEpochCumulativeYield_);
        uint256 newToBaseBalance = WadRayMath.wadToRay(newToBalance).rayDiv(previousEpochCumulativeYield_);

        if (amount > 0) {
            _totalBaseSupply -= (_baseBalances[from] - newFromBaseBalance);
            _totalBaseSupply += (newToBaseBalance - _baseBalances[to]);
            _baseBalances[from] = newFromBaseBalance;
            _baseBalances[to] = newToBaseBalance;
        }

        emit Transfer(from, to, amount);
    }

    /**
     * @notice Updates the internal state variables after accounting for newly received tokens.
     */
    function _refreshCumulativeYield() private {
        uint256 newPreviousEpochCumulativeYield = _calculatePreviousEpochCumulativeYield();
        uint256 newCumulativeYield = _calculateCumulativeYield();

        if (newPreviousEpochCumulativeYield != _previousEpochCumulativeYield) {
            emit PreviousEpochCumulativeYieldUpdated(_previousEpochCumulativeYield, newPreviousEpochCumulativeYield);
            _previousEpochCumulativeYield = newPreviousEpochCumulativeYield;
        }
        if (newCumulativeYield != _cumulativeYield) {
            emit CumulativeYieldUpdated(_cumulativeYield, newCumulativeYield);
            _cumulativeYield = newCumulativeYield;
        }

        _lastRefresh = block.timestamp;
    }

    /**
     * @notice Updates yield based on current yield and oracle reference rate.
     */
    function _refreshYield() private {
        IKUMASwap KUMASwap = IKUMASwap(_KUMAAddressProvider.getKUMASwap(_riskCategory));
        uint256 yield_ = _yield;
        if (KUMASwap.isExpired() || KUMASwap.isDeprecated()) {
            _yield = MIN_YIELD;
            emit YieldUpdated(yield_, MIN_YIELD);
            return;
        }
        uint256 referenceRate = IMCAGRateFeed(_KUMAAddressProvider.getRateFeed()).getRate(_riskCategory);
        uint256 minCoupon = KUMASwap.getMinCoupon();
        uint256 lowestYield = referenceRate < minCoupon ? referenceRate : minCoupon;
        if (lowestYield != yield_) {
            _yield = lowestYield;
            emit YieldUpdated(yield_, lowestYield);
        }
    }

    /**
     * @return Timestamp rounded down to the previous epoch length.
     */
    function _getPreviousEpochTimestamp() private view returns (uint256) {
        uint256 epochLength = _epochLength;
        uint256 epochTimestampRemainder = block.timestamp % epochLength;
        if (epochTimestampRemainder == 0) {
            return block.timestamp;
        }
        return (block.timestamp / epochLength) * epochLength;
    }

    /**
     * @notice Helper function to calculate cumulativeYield at call timestamp.
     * @return Updated cumulative yield
     */
    function _calculateCumulativeYield() private view returns (uint256) {
        uint256 timeElapsed = block.timestamp - _lastRefresh;
        if (timeElapsed == 0) return _cumulativeYield;
        return _yield.rayPow(timeElapsed).rayMul(_cumulativeYield);
    }

    /**
     * @notice Helper function to calculate previousEpochCumulativeYield at call timestamp.
     * @return Updated previous epoch cumulative yield.
     */
    function _calculatePreviousEpochCumulativeYield() private view returns (uint256) {
        uint256 previousEpochTimestamp = _getPreviousEpochTimestamp();
        if (previousEpochTimestamp < _lastRefresh) {
            return _previousEpochCumulativeYield;
        }
        uint256 timeElapsedToEpoch = previousEpochTimestamp - _lastRefresh;
        return _yield.rayPow(timeElapsedToEpoch).rayMul(_cumulativeYield);
    }

    function _authorizeUpgrade(address newImplementation) internal view override onlyRole(Roles.KUMA_MANAGER_ROLE) {}
}
