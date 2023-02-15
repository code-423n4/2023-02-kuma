// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "../BaseSetUp.t.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {Errors} from "@kuma/libraries/Errors.sol";
import {WadRayMath} from "@kuma/libraries/WadRayMath.sol";

abstract contract KUMASwapSetUp is BaseSetUp {
    event BondBought(uint256 tokenId, uint256 KIBTokenBurned, address indexed buyer);
    event BondClaimed(uint256 tokenId, uint256 cloneTokenId);
    event BondExpired(uint256 tokenId);
    event BondSold(uint256 tokenId, uint256 KIBTokenMinted, address indexed seller);
    event DeprecationModeInitialized();
    event DeprecationModeEnabled();
    event DeprecationModeUninitialized();
    event DeprecationStableCoinSet(address oldDeprecationStableCoin, address newDeprecationStableCoin);
    event FeeCharged(uint256 fee);
    event FeeSet(uint16 variableFee, uint256 fixedFee);
    event KIBTRedeemed(address indexed redeemer, uint256 redeemedStableCoinAmount);
    event KUMAAddressProviderSet(address KUMAAddressProvider);
    event MaxCouponsSet(uint256 maxCoupons);
    event MinCouponUpdated(uint256 oldMinCoupon, uint256 newMinCoupon);
    event RiskCategorySet(bytes32 riskCategory);

    IKUMABondToken.Bond internal _bond;

    constructor() {
        _bond = IKUMABondToken.Bond({
            cusip: _CUSIP,
            isin: _ISIN,
            currency: _CURRENCY,
            country: _COUNTRY,
            term: _TERM,
            issuance: uint64(block.timestamp),
            maturity: uint64(block.timestamp + _TERM),
            coupon: _YIELD,
            principal: 10 ether,
            riskCategory: _RISK_CATEGORY
        });

        _KUMABondToken.issueBond(address(this), _bond);
        _KUMABondToken.setApprovalForAll(address(_KUMASwap), true);
        vm.prank(_alice);
        _KUMABondToken.setApprovalForAll(address(_KUMASwap), true);
        vm.prank(_bob);
        _KUMABondToken.setApprovalForAll(address(_KUMASwap), true);
        _deprecationStableCoin.mint(_alice, 10 ether);
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
        external
        pure
        returns (bytes4)
    {
        return IERC721Receiver.onERC721Received.selector;
    }
}
