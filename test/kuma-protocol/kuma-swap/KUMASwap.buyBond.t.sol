// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "./KUMASwapSetUp.t.sol";

contract KUMASwapBuyBond is KUMASwapSetUp {
    using WadRayMath for uint256;

    /**
     * @notice Tests buyBond function by buying a bond not resulting in a yield update nor a CloneBond issuance.
     */
    function test_buyBond_WithCouponEqYield() public {
        _KUMASwap.sellBond(1);
        vm.expectEmit(false, false, false, true);
        emit BondBought(1, 10 ether, address(this));
        _KUMASwap.buyBond(1);
        assertEq(_KUMASwap.getCoupons().length, 0);
        assertEq(_KIBToken.balanceOf(address(this)), 0);
        assertEq(_KIBToken.getYield(), WadRayMath.RAY);
        assertEq(_KUMABondToken.ownerOf(1), address(this));
    }

    /**
     * @notice Tests buyBond function by buying a bond not resulting in a yield update.
     */
    function test_buyBond_WithCouponGtYield() public {
        IKUMABondToken.Bond memory bond_ = _bond;
        uint256 newYield = 1000000001847694957439350563; // 6%
        bond_.coupon = newYield;
        _KUMABondToken.issueBond(_alice, bond_);

        _KUMASwap.sellBond(1);

        vm.startPrank(_alice, _alice);
        _KUMASwap.sellBond(2);

        skip(365 days);

        vm.expectEmit(false, false, true, true);
        emit BondBought(2, 10.5 ether, _alice);
        _KUMASwap.buyBond(2);

        // Bough bond has a coupon of 6%, remaining bond in the reserve has a 5% coupon.
        // Thus _KIBToken yield should not be updated.
        assertEq(_KUMASwap.getCoupons().length, 1);
        assertEq(_KIBToken.balanceOf(_alice), 0);
        assertEq(_KIBToken.getYield(), _YIELD);
        assertEq(_KBCToken.getBond(1).coupon, _YIELD);
        assertEq(_KBCToken.getBond(1).parentId, 2);
        assertEq(_KBCToken.ownerOf(1), _alice);
        assertEq(_KBCToken.balanceOf(_alice), 1);
        assertEq(_KUMABondToken.ownerOf(1), address(_KUMASwap));
        assertEq(_KUMASwap.getCloneBond(2), 1);
    }

    /**
     * @notice Tests buyBond function by buying the lowest coupon in the pool while the central bank
     * rate is still higher than the new lowest coupon.
     */
    function test_buyBond_WithLowestCouponAndReferenceRateGtRemaingCoupon() public {
        IKUMABondToken.Bond memory bond_ = _bond;
        uint256 newYield = 1000000000937303470807876290; // 3%
        bond_.coupon = newYield;
        _mcagAggregator.transmit(int256(newYield));

        _KUMABondToken.issueBond(_alice, bond_);

        vm.startPrank(_alice, _alice);
        _KUMASwap.sellBond(2);
        vm.stopPrank();

        _KUMASwap.sellBond(1);

        _mcagAggregator.transmit(int256(1000000001847694957439350563));

        // Bond 1 has a 5% coupon, bond 2 has a 3% coupon and oracle returns a 6% rate.
        // Thus _KIBToken yield should be 3%.
        assertEq(_KIBToken.getYield(), newYield);

        skip(365 days);

        vm.expectEmit(false, false, false, true);
        emit MinCouponUpdated(newYield, _YIELD);
        vm.expectEmit(false, false, true, true);
        emit BondBought(2, 10.3 ether, address(this));
        _KUMASwap.buyBond(2);

        // Bough bond has a 3% rate, remaining bond in reserve has a 5% coupon and oracle returns a 6% rate.
        // Thus _KIBToken yield should increase from 3% to 5%.
        assertEq(_KUMASwap.getCoupons().length, 1);
        assertEq(_KUMASwap.getCoupons()[0], _YIELD);
        assertEq(_KIBToken.getYield(), _YIELD);
    }

    /**
     * @notice Tests buyBond function by buying the last remaining bond of the _bondReserve.
     * This is done to test a specific branch of the _updateMinCoupon() function.
     */
    function test_buyBond_LastBondInReserve() public {
        _KUMASwap.sellBond(1);
        _KUMASwap.buyBond(1);
        // Buying the last bond in reserve should result in a yield update of _KIBToken to RAY.
        assertEq(_KUMASwap.getCoupons().length, 0);
        assertEq(_KIBToken.getYield(), WadRayMath.RAY);
    }

    /**
     * @notice Tests a specific branch of _updateMinCoupon() function.
     */
    function test_buyBond_With6BondsInReserve() public {
        IKUMABondToken.Bond memory bond2 = _bond;
        IKUMABondToken.Bond memory bond3 = _bond;
        IKUMABondToken.Bond memory bond4 = _bond;
        IKUMABondToken.Bond memory bond5 = _bond;
        IKUMABondToken.Bond memory bond6 = _bond;
        uint256 bond2Yield = 1000000000937303470807876290; // 3%
        uint256 bond3Yield = 1000000001847694957439350563; // 6%
        uint256 bond4Yield = 1000000001243680656318820313; // 4%
        uint256 bond5Yield = 1000000000627937192491029811; // 2%
        uint256 bond6Yield = 1000000000315522921573372069; // 1%
        bond2.coupon = bond2Yield;
        bond3.coupon = bond3Yield;
        bond4.coupon = bond4Yield;
        bond5.coupon = bond5Yield;
        bond6.coupon = bond6Yield;

        _mcagAggregator.transmit(int256(1000000000315522921573372069)); // 1%

        _KUMABondToken.issueBond(address(this), bond2);
        _KUMABondToken.issueBond(address(this), bond3);
        _KUMABondToken.issueBond(address(this), bond4);
        _KUMABondToken.issueBond(address(this), bond5);
        _KUMABondToken.issueBond(address(this), bond6);

        _KUMASwap.sellBond(1);
        _KUMASwap.sellBond(2);
        _KUMASwap.sellBond(3);
        _KUMASwap.sellBond(4);
        _KUMASwap.sellBond(5);
        _KUMASwap.sellBond(6);

        _mcagAggregator.transmit(int256(1000000001847694957439350563)); // 6%

        // Bond coupons in reserve are as follow : [3%, 6%, 4%, 2%, 1%].
        // Buying bond id 2 result in the follwing reserve [3%, 6%, 4%, 2%].
        // Array being of length 4 _updateMinCoupon loop should initiate.
        // Oracle rate being 6% _KIBToken yield should be updated to 1%.
        _KUMASwap.buyBond(6);

        assertEq(_KUMASwap.getCoupons().length, 5);
        assertEq(_KIBToken.getYield(), bond5Yield);
    }

    /**
     * @notice Tests buyBond function with a CloneBond issuance.
     */
    function test_buyBond_WithCloneBondIssuance() public {
        uint256 newYield = 1000000001847694957439350563; // 6%
        IKUMABondToken.Bond memory bond_ = _bond;
        bond_.coupon = newYield;
        _KUMABondToken.issueBond(address(this), bond_);
        _KUMASwap.sellBond(1);
        skip(365 days);
        _KUMASwap.sellBond(2);
        skip(365 days);

        _KUMASwap.buyBond(2);

        IKBCToken.CloneBond memory cBond = _KBCToken.getBond(1);

        assertEq(_KUMASwap.getCloneBond(2), 1);
        assertEq(_KBCToken.getTokenIdCounter(), 1);

        // bond 1 : 10 ether at 5% for 1 year = 10.5 ether
        // bond 2 is sold : 21.1 ether at 5% for 1 year = 22.155 ether
        // bond 2 base value is 10.6 / 1.05 = 10.0952...
        // bond 2 is bought and valued at : 10.6 / 1.05 * 1.05^2 = 11.13
        // 22.155 - 11.13 = 11.025 ether
        assertEq(_KIBToken.balanceOf(address(this)), 11.025 ether);
        assertEq(cBond.principal, 11.13 ether);
        assertEq(cBond.coupon, _YIELD);
        assertEq(cBond.issuance, block.timestamp);
        assertEq(cBond.parentId, 2);
    }

    /**
     * @notice Tests buyBond function data validation logic by trying to buy a bond not in the reserve.
     */
    function test_buyBond_RevertWhen_BondNotInReserve() public {
        vm.expectRevert(Errors.INVALID_TOKEN_ID.selector);
        _KUMASwap.buyBond(1);
    }

    /**
     * @notice Tests buyBond function by buying an expired bond.
     */
    function test_buyBond_ExpiredBond() public {
        _KUMASwap.sellBond(1);
        IKUMABondToken.Bond memory bond_ = _bond;
        bond_.maturity = bond_.maturity + 365 days;
        _KUMABondToken.issueBond(address(this), bond_);
        _KUMASwap.sellBond(2);
        skip(_TERM);
        _KUMASwap.expireBond(1);
        assertTrue(_KUMASwap.isExpired());
        _KUMASwap.buyBond(1);

        assertFalse(_KUMASwap.isExpired());
        assertEq(_KUMASwap.getMinCoupon(), _YIELD);
    }

    /**
     * @notice Tests buying an expired bonds while there are 2 expired bonds. Here KIBT Yield
     * should remain RAY.
     */
    function test_buyBond_BuyExpiredBondWhileMultipleBondsExpired() public {
        IKUMABondToken.Bond memory bond_ = _bond;
        _KUMABondToken.issueBond(address(this), bond_);
        _KUMASwap.sellBond(1);
        _KUMASwap.sellBond(2);

        vm.warp(_bond.maturity);

        _KUMASwap.expireBond(1);
        _KUMASwap.expireBond(2);

        _KUMASwap.buyBond(1);

        assertTrue(_KUMASwap.isExpired());
        assertEq(_KIBToken.getYield(), WadRayMath.RAY);
    }

    /**
     * @notice Tests buyBond function when a bond has been expired and the bought bond isn't the expired one.
     */
    function test_buyBond_RevertWhen_IsExpiredAndBuyNonExpiredBond() public {
        _KUMASwap.sellBond(1);
        IKUMABondToken.Bond memory bond_ = _bond;
        bond_.maturity = bond_.maturity + 365 days;
        _KUMABondToken.issueBond(address(this), bond_);
        _KUMASwap.sellBond(2);
        skip(_TERM);
        _KUMASwap.expireBond(1);
        vm.expectRevert(Errors.EXPIRED_BONDS_MUST_BE_BOUGHT_FIRST.selector);
        _KUMASwap.buyBond(2);
    }

    /**
     * @notice Tests that if a bond is purchased after maturity but not expired it's valuation isn't capped to its maturity.
     */
    function test_buyBond_AfterMaturity() public {
        _KUMASwap.sellBond(1);
        skip(_TERM + 365 days);

        uint256 realizedBondValue = _KIBToken.balanceOf(address(this));
        uint256 bondFaceValue = _bond.coupon.rayPow(_TERM).rayMul(_bond.principal);

        console2.log("realizedBondValue", realizedBondValue);
        console2.log("bondFaceValue", bondFaceValue);
        console2.log("loss", realizedBondValue - bondFaceValue);

        _KUMASwap.buyBond(1);

        assertEq(_KIBToken.balanceOf(address(this)), 0);
    }

    /**
     * @notice Tests the effect of a bond bought after maturity on other bonds in the pool.
     */
    function test_buyBond_AfterMaturityImpactOnOtherBonds() public {
        _KUMASwap.sellBond(1);
        skip(_TERM / 2);
        _KUMABondToken.issueBond(address(this), _bond);
        _KUMASwap.sellBond(2);
        skip(_TERM / 2 + 365 days);
        _KUMASwap.buyBond(1);

        uint256 realizedBondValue = _KIBToken.balanceOf(address(this));
        uint256 bondFaceValue = _bond.coupon.rayPow(_TERM / 2 + 365 days).rayMul(_bond.principal);

        console2.log("realizedBondValue", realizedBondValue);
        console2.log("bondFaceValue", bondFaceValue);
        console2.log("loss", realizedBondValue - bondFaceValue);
    }

    /**
     * @notice Tests the effect of expiring a bond with an issuance equals to an epoch on the timestamp of on epoch.
     */
    function test_buyBond_WhenBondWasExpiredOnEpochTimestamp() public {
        uint256 previousEpoch = _KIBToken.getPreviousEpochTimestamp();
        vm.warp(previousEpoch);
        IKUMABondToken.Bond memory bond_ = _bond;
        bond_.issuance = uint64(previousEpoch);
        bond_.maturity = uint64(previousEpoch + 365 days);
        _KUMABondToken.issueBond(address(this), bond_);
        _KUMASwap.sellBond(2);

        skip(365 days);

        _KUMASwap.expireBond(2);

        uint256 realizedBondValue = _KIBToken.balanceOf(address(this));
        uint256 bondFaceValue = bond_.coupon.rayPow(365 days).rayMul(bond_.principal);

        console2.log("realizedBondValue", realizedBondValue);
        console2.log("bondFaceValue", bondFaceValue);
        console2.log("loss", realizedBondValue - bondFaceValue);

        assertEq(realizedBondValue, bondFaceValue);
    }

    /**
     * @notice Tests that when a bond is bought and the central bank rate becomes lower than the
     * current yield the bond is valued at face value.
     */
    function test_buyBond_WhenBondCouponGtReferenceRateAndReferenceRateLtCurrentYield() public {
        _KUMASwap.sellBond(1);
        skip(365 days);
        _mcagAggregator.transmit(int256(1000000000937303470807876290)); // 3%
        vm.expectEmit(false, false, false, true);
        emit BondBought(1, 10.5 ether, address(this));
        _KUMASwap.buyBond(1);
    }

    /**
     * @notice Tests that buyBond reverts when contract is paused.
     */
    function test_buyBond_RevertWhen_Paused() public {
        _KUMASwap.sellBond(1);
        _KUMASwap.pause();
        vm.expectRevert("Pausable: paused");
        _KUMASwap.buyBond(1);
    }

    /**
     * @notice Tests that bonds cannot be bought when deprecation mode is enabled.
     */
    function test_buyBond_RevertWhen_DeprecationModeEnabled() public {
        _KUMASwap.sellBond(1);
        _KUMASwap.initializeDeprecationMode();
        skip(2 days);
        _KUMASwap.enableDeprecationMode();
        vm.expectRevert(Errors.DEPRECATION_MODE_ENABLED.selector);
        _KUMASwap.buyBond(1);
    }
}
