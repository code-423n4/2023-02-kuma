// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "./KUMASwapSetUp.t.sol";

contract KUMASwapSellBond is KUMASwapSetUp {
    using WadRayMath for uint256;

    /**
     * @notice Tests sellBond function by selling a bond not resulting in a yield update.
     */
    function test_sellBond_WithCouponEqYieldAndNoAccruedInterests() public {
        vm.expectEmit(false, false, true, true);
        emit BondSold(1, 10 ether, address(this));
        _KUMASwap.sellBond(1);
        assertTrue(_KUMASwap.isInReserve(1));
        assertEq(_KUMASwap.getCoupons().length, 1);
        assertEq(_KUMASwap.getCoupons()[0], _YIELD);
        assertEq(_KIBToken.balanceOf(address(this)), 10 ether);
        assertEq(_KIBToken.getYield(), _YIELD);
        assertEq(_KUMABondToken.ownerOf(1), address(_KUMASwap));
        assertEq(_KUMASwap.getMinCoupon(), _YIELD);
        assertEq(_KUMASwap.getBondBaseValue(1), uint256(10 ether).wadToRay());
    }

    /**
     * @notice Tests sellBond function by selling a bond not resulting in a yield update with
     * accrued interests on soldBond to check correct bond valuation.
     */
    function test_sellBond_WithCouponEqYieldAndAccruedInterests() public {
        skip(365 days);
        vm.expectEmit(false, false, true, true);
        emit BondSold(1, 10.5 ether, address(this));
        _KUMASwap.sellBond(1);
        assertEq(_KIBToken.balanceOf(address(this)), 10.5 ether);
    }

    /**
     * @notice Tests sellBond function by selling a bond with a KIBTYield greater than RAY in order
     * to test baseBondValue calulation.
     */
    function test_sellBond_WithKIBTCumulativeYieldGtRay() public {
        _KUMASwap.sellBond(1);
        skip(365 days);
        IKUMABondToken.Bond memory bond_ = _bond;
        bond_.issuance = uint64(block.timestamp);
        _KUMABondToken.issueBond(address(this), bond_);
        _KUMASwap.sellBond(2);
        assertEq(_KUMASwap.getBondBaseValue(2), uint256(10 ether).wadToRay().rayDiv(_YIELD.rayPow(365 days)));
    }

    /**
     * @notice Tests sellBond function by selling a bond resulting in a yield update with
     * accrued interests on sold bond to check correct bond valuation.
     */
    function test_sellBond_WithCouponLtMinCouponAndAccruedInterests() public {
        _KUMASwap.sellBond(1);
        uint256 newYield = 1000000000937303470807876290;
        _mcagAggregator.transmit(int256(newYield)); // 3%
        _KIBToken.refreshYield();
        IKUMABondToken.Bond memory bond_ = _bond;
        bond_.coupon = newYield;
        _KUMABondToken.issueBond(address(this), bond_);
        vm.expectEmit(false, false, true, true);
        emit BondSold(2, 10.3 ether, address(this));
        skip(365 days);
        _KUMASwap.sellBond(2);

        assertEq(_KIBToken.balanceOf(address(this)), 20.6 ether);
        assertEq(_KIBToken.getYield(), newYield);
    }

    /**
     * @notice Tests sellBond function by selling a bond resulting while bond reserve > 1 to check that sold
     * bond is valued at clone bond coupon.
     */
    function test_sellBond_WithYieldUpdate() public {
        _KUMASwap.sellBond(1);
        _KUMABondToken.issueBond(_alice, _bond);
        skip(365 days);
        uint256 newYield = 1000000000937303470807876290;
        _mcagAggregator.transmit(int256(newYield)); // 3%
        vm.prank(_alice);
        _KUMASwap.sellBond(2);

        assertEq(_KIBToken.getYield(), newYield);
        assertEq(_KIBToken.balanceOf(_alice), 10.5 ether);
    }

    /**
     * @notice Tests sellBond function by selling a bond not resulting in a yield update but resulting in a
     * clone coupon create. Checks that the sold bond is value at clone coupon.
     */
    function test_sellBond_WithNoYieldUpdateWithGhostCouponCreation() public {
        skip(365 days);
        _mcagAggregator.transmit(int256(1000000000937303470807876290)); // 3%
        _KUMASwap.sellBond(1);

        assertEq(_KIBToken.balanceOf(address(this)), 10.5 ether);
    }

    /**
     * @notice Tests that only unique coupons are pushed to the _coupons array.
     */
    function test_sellBond_MultipleBondsWithSameCoupons() public {
        _KUMABondToken.issueBond(address(this), _bond);
        _KUMASwap.sellBond(1);
        _KUMASwap.sellBond(2);

        assertEq(_KUMASwap.getCoupons().length, 1);
        assertEq(_KUMASwap.getCouponInventory(_YIELD), 2);
        assertEq(_KUMASwap.getBondReserve().length, 2);
    }

    /**
     * @notice Tests sellBond function data validation by trying to sell a bond with
     * the wrond risk category.
     */
    function test_sellBond_RevertWhen_WrongRiskCategory() public {
        IKUMABondToken.Bond memory bond_ = _bond;
        bond_.riskCategory = keccak256(abi.encode(bytes4("USD"), bytes4("US"), 365 days));
        _KUMABondToken.issueBond(address(this), bond_);
        vm.expectRevert(Errors.WRONG_RISK_CATEGORY.selector);
        _KUMASwap.sellBond(2);
    }

    /**
     * @notice Tests sellBond function data validation by trying to sell a matured bond.
     */
    function test_sellBond_RevertWhen_MaturedBond() public {
        skip(365 days * 30);
        vm.expectRevert(Errors.CANNOT_SELL_MATURED_BOND.selector);
        _KUMASwap.sellBond(1);
    }

    /**
     * @notice Tests sellBond function data validation by trying to sell a matured bond with
     * a coupon lower than the oracle rate.
     */
    function test_sellBond_RevertWhen_CouponLtOracleRate() public {
        _mcagAggregator.transmit(int256(_YIELD + 1));
        vm.expectRevert(Errors.COUPON_TOO_LOW.selector);
        _KUMASwap.sellBond(1);
    }

    /**
     * @notice Tests sellBond function data validation by trying to sell a matured bond with
     * a coupon lower than the currentYield.
     */
    function test_sellBond_RevertWhen_CouponLtCurrentYield() public {
        IKUMABondToken.Bond memory bond_ = _bond;
        bond_.coupon = _bond.coupon - 1;
        _KUMABondToken.issueBond(address(this), bond_);
        _KUMASwap.sellBond(1);
        _mcagAggregator.transmit(int256(_YIELD + 1));
        vm.expectRevert(Errors.COUPON_TOO_LOW.selector);
        _KUMASwap.sellBond(2);
    }

    /**
     * @notice Tests sellBond with maxCoupons reached.
     */
    function test_sellBond_RevertWhen_MaxCouponsReached() public {
        _KUMASwap.sellBond(1);
        IKUMABondToken.Bond memory bond_ = _bond;

        for (uint256 i; i < 364; i++) {
            bond_.coupon = bond_.coupon + 1;
            _KUMABondToken.issueBond(address(this), bond_);
            _KUMASwap.sellBond(i + 2);
        }

        vm.expectRevert(Errors.MAX_COUPONS_REACHED.selector);
        _KUMASwap.sellBond(365);
    }

    /**
     * @notice Tests that variable fee is correctly charged in sellBond.
     */
    function test_sellBond_WithVariableFee() public {
        _KUMASwap.setFees(1e3, 0); // 10%
        vm.expectEmit(false, false, false, true);
        emit FeeCharged(1 ether);
        vm.expectEmit(false, false, false, true);
        emit BondSold(1, 9 ether, address(this));
        _KUMASwap.sellBond(1);
        assertEq(_KIBToken.balanceOf(address(_KUMAFeeCollector)), 1 ether);
        assertEq(_KIBToken.balanceOf(address(this)), 9 ether);
    }

    /**
     * @notice Tests that fixed fee is correctly charged in sellBond.
     */
    function test_sellBond_WithFixedFee() public {
        _KUMASwap.setFees(0, 1 ether);
        vm.expectEmit(false, false, false, true);
        emit FeeCharged(1 ether);
        vm.expectEmit(false, false, false, true);
        emit BondSold(1, 9 ether, address(this));
        _KUMASwap.sellBond(1);
        assertEq(_KIBToken.balanceOf(address(_KUMAFeeCollector)), 1 ether);
        assertEq(_KIBToken.balanceOf(address(this)), 9 ether);
    }

    /**
     * @notice Tests that both variable and fixed fee are correctly charged in sellBond.
     */
    function test_sellBond_WithVariableFeeAndFixedFee() public {
        _KUMASwap.setFees(5e2, 0.5 ether); // 5%
        vm.expectEmit(false, false, false, true);
        emit FeeCharged(1 ether);
        vm.expectEmit(false, false, false, true);
        emit BondSold(1, 9 ether, address(this));
        _KUMASwap.sellBond(1);
        assertEq(_KIBToken.balanceOf(address(_KUMAFeeCollector)), 1 ether);
        assertEq(_KIBToken.balanceOf(address(this)), 9 ether);
    }

    /**
     * @notice Tests that sellBond reverts when contract is paused.
     */
    function test_sellBond_RevertWhen_Paused() public {
        _KUMASwap.pause();
        vm.expectRevert("Pausable: paused");
        _KUMASwap.sellBond(1);
    }

    /**
     * @notice Tests that bonds cannot be sold when deprecation mode is enabled.
     */
    function test_sellBond_RevertWhen_DeprecationModeEnabled() public {
        _KUMASwap.initializeDeprecationMode();
        skip(2 days);
        _KUMASwap.enableDeprecationMode();
        vm.expectRevert(Errors.DEPRECATION_MODE_ENABLED.selector);
        _KUMASwap.sellBond(1);
    }
}
