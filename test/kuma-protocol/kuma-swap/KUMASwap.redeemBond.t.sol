// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "./KUMASwapSetUp.t.sol";

contract KUMASwapRedeemBond is KUMASwapSetUp {
    /**
     * @notice Tests that a user can redeem its KIBToken agains the deprecation mode stable coin during deprecation mode.
     */
    function test_redeemKIBT() public {
        IKUMABondToken.Bond memory bond_ = _bond;
        bond_.principal = 30 ether;

        _KUMABondToken.issueBond(_bob, bond_);

        _KUMASwap.sellBond(1);

        vm.prank(_bob);
        _KUMASwap.sellBond(2);

        skip(363 days);

        _KUMASwap.initializeDeprecationMode();
        skip(2 days);
        _KUMASwap.enableDeprecationMode();

        vm.prank(_alice);
        _deprecationStableCoin.approve(address(_KUMASwap), 10 ether);
        _KUMASwap.buyBondForStableCoin(1, _alice, 5 ether);
        _KUMASwap.buyBondForStableCoin(2, _alice, 5 ether);

        // At this point Bob should have an KIBT balance of 31.5 and address(this) 10.5
        // Thus Bob share should be 75% and address(this) 25%
        // Stable coin balance of KUMASwap shoud be 10
        // So address(this) should get 2.5 ether stable coin and Bob should get 7.5 ether

        vm.expectEmit(true, false, false, true);
        emit KIBTRedeemed(address(this), 2.5 ether);
        _KUMASwap.redeemKIBT(_KIBToken.balanceOf(address(this)));
        vm.expectEmit(true, false, false, true);
        emit KIBTRedeemed(_bob, 7.5 ether);
        vm.startPrank(_bob);
        _KUMASwap.redeemKIBT(_KIBToken.balanceOf(_bob));

        assertEq(_deprecationStableCoin.balanceOf(address(this)), 2.5 ether);
        assertEq(_deprecationStableCoin.balanceOf(_bob), 7.5 ether);
    }

    /**
     * @notice Tests that a user cannot redeem an amount of 0.
     */
    function test_redeemKIBT_RevertWhen_AmountEqZero() public {
        _KUMASwap.initializeDeprecationMode();
        skip(2 days);
        _KUMASwap.enableDeprecationMode();
        vm.expectRevert(Errors.AMOUNT_CANNOT_BE_ZERO.selector);
        _KUMASwap.redeemKIBT(0);
    }

    /**
     * @notice Tests that a user cannot redeem a KIBToken while bond reserve is not empty.
     */
    function test_redeemKIBT_RevertWhen_NonEmptyReserve() public {
        _KUMASwap.sellBond(1);
        _KUMASwap.initializeDeprecationMode();
        skip(2 days);
        _KUMASwap.enableDeprecationMode();
        vm.expectRevert(Errors.BOND_RESERVE_NOT_EMPTY.selector);
        _KUMASwap.redeemKIBT(10 ether);
    }

    /**
     * Tests that a user cannot redeem its KIBT for stable coins outside of deprecation mode.
     */
    function test_redeemKIBT_RevertWhen_DeprecationModeNotEnabled() public {
        vm.expectRevert(Errors.DEPRECATION_MODE_NOT_ENABLED.selector);
        _KUMASwap.redeemKIBT(10 ether);
    }
}
