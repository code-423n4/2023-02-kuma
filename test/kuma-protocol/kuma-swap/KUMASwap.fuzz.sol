// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "../BaseSetUp.t.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {WadRayMath} from "@kuma/libraries/WadRayMath.sol";

contract KUMASwapFuzzTest is BaseSetUp {
    using WadRayMath for uint256;

    uint256 private constant _MAX_COUPON = 1000000008319516284844715116; // 30%
    uint256 private constant _MAX_PRINCIPAL = 1e32;
    uint256 private constant _MAX_WARP = 365 days * 30;

    IKUMABondToken.Bond private _bond;

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
        external
        pure
        returns (bytes4)
    {
        return IERC721Receiver.onERC721Received.selector;
    }

    function setUp() public {
        _bond = IKUMABondToken.Bond({
            cusip: _CUSIP,
            isin: _ISIN,
            currency: _CURRENCY,
            country: _COUNTRY,
            term: _TERM,
            issuance: uint64(block.timestamp),
            maturity: uint64(block.timestamp + 365 days * 3),
            coupon: _YIELD,
            principal: 10 ether,
            riskCategory: _RISK_CATEGORY
        });
        _KUMABondToken.issueBond(address(this), _bond);
        _KUMABondToken.setApprovalForAll(address(_KUMASwap), true);
        vm.prank(_alice);
        _KUMABondToken.setApprovalForAll(address(_KUMASwap), true);
    }

    function testFuzz_ShouldValueSoldBondAndUpdateYieldCorrectly(
        uint256 warp,
        uint256 coupon,
        uint256 oracleRate,
        uint256 principal
    ) public {
        principal = bound(principal, 0, _MAX_PRINCIPAL);
        oracleRate = bound(oracleRate, WadRayMath.RAY, _MAX_COUPON);
        coupon = bound(coupon, oracleRate, _MAX_COUPON);
        warp = bound(warp, 0, 365 days * 3 - 1);
        IKUMABondToken.Bond memory bond_ = _bond;
        bond_.coupon = coupon;
        bond_.principal = principal;

        _KUMABondToken.issueBond(address(this), bond_);

        _mcagAggregator.transmit(int256(oracleRate));

        skip(warp);

        _KUMASwap.sellBond(2);

        uint256 elapsedTime = _KIBToken.getPreviousEpochTimestamp() - bond_.issuance;

        if (elapsedTime > _TERM) {
            elapsedTime = _TERM;
        }

        uint256 expectedKIBTBalance = coupon.rayPow(elapsedTime).rayMul(bond_.principal);
        uint256 expectedYield = coupon < oracleRate ? coupon : oracleRate;

        assertEq(_KIBToken.balanceOf(address(this)), expectedKIBTBalance);
        assertEq(_KIBToken.getYield(), expectedYield);
    }

    function testFuzz_ShouldValueBoughtBondAndUpdateYieldCorrectly(
        uint256 warp,
        uint256 coupon,
        uint256 oracleRate,
        uint256 principal
    ) public {
        _KUMASwap.sellBond(1);
        principal = bound(principal, 0, _MAX_PRINCIPAL);
        oracleRate = bound(oracleRate, WadRayMath.RAY, _MAX_COUPON);
        coupon = bound(coupon, oracleRate > _YIELD ? oracleRate : _YIELD, _MAX_COUPON);
        warp = bound(warp, 0, _MAX_WARP);

        IKUMABondToken.Bond memory bond_ = _bond;
        bond_.coupon = coupon;
        bond_.principal = principal;

        _KUMABondToken.issueBond(_alice, bond_);

        _mcagAggregator.transmit(int256(oracleRate));

        vm.startPrank(_alice, _alice);
        _KUMASwap.sellBond(2);

        uint256 bondSaleValue = _getBondValue(bond_.issuance, bond_.issuance, coupon, principal);
        uint256 baseBondValue = bondSaleValue.rayDiv(_KIBToken.getUpdatedCumulativeYield()).wadToRay();

        skip(warp);

        uint256 balanceBefore = _KIBToken.balanceOf(_alice);

        _KUMASwap.buyBond(2);

        uint256 bondFaceValue = _getBondValue(bond_.issuance, bond_.term, coupon, principal);
        uint256 realizedBondValue = baseBondValue.rayMul(_KIBToken.getUpdatedCumulativeYield()).rayToWad();
        uint256 bondPurchaseValue = bondFaceValue > realizedBondValue ? realizedBondValue : bondFaceValue;

        uint256 expectedYield = _bond.coupon < oracleRate ? _bond.coupon : oracleRate;
        uint256 expectedBalance = balanceBefore - bondPurchaseValue;

        assertEq(_KIBToken.getYield(), expectedYield);
        assertEq(_KIBToken.balanceOf(_alice), expectedBalance);
    }

    function _getBondValue(uint256 issuance, uint256 term, uint256 coupon, uint256 principal)
        internal
        view
        returns (uint256)
    {
        uint256 previousEpochTimestamp = _KIBToken.getPreviousEpochTimestamp();

        if (previousEpochTimestamp <= issuance) {
            return principal;
        }

        uint256 elapsedTime = previousEpochTimestamp - issuance;

        if (elapsedTime > term) {
            elapsedTime = term;
        }

        return coupon.rayPow(elapsedTime).rayMul(principal);
    }
}
