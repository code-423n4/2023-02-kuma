// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "./KUMASwapSetUp.t.sol";

contract KUMASwapBuyBondForStableCoin is KUMASwapSetUp {
    /**
     * @notice Tests that a bond can be bought for a the accepted stable coin during deprecation mode.
     */
    function test_buyBondForStableCoin() public {
        _KUMASwap.sellBond(1);
        _KUMABondToken.issueBond(address(this), _bond);
        _KUMASwap.sellBond(2);
        _KUMASwap.initializeDeprecationMode();
        skip(2 days);
        _KUMASwap.enableDeprecationMode();
        vm.prank(_alice);
        _deprecationStableCoin.approve(address(_KUMASwap), 10 ether);
        vm.expectEmit(false, false, true, true);
        emit BondBought(1, 10 ether, _alice);
        _KUMASwap.buyBondForStableCoin(1, _alice, 10 ether);

        assertFalse(_KUMASwap.isInReserve(1));
        assertEq(_KUMASwap.getBondReserve().length, 1);
        assertEq(_KIBToken.getYield(), WadRayMath.RAY);
        assertEq(_KUMABondToken.ownerOf(1), _alice);
    }

    /**
     * @notice Tests that a bond not in the reserve cannot be bought.
     */
    function test_buyBondForStableCoin_RevertWhen_InvalidTokenId() public {
        _KUMASwap.initializeDeprecationMode();
        skip(2 days);
        _KUMASwap.enableDeprecationMode();
        vm.expectRevert(Errors.INVALID_TOKEN_ID.selector);
        _KUMASwap.buyBondForStableCoin(1, _alice, 10 ether);
    }

    /**
     * @notice Tests that a bond cannot be bought for a the accepted stable coin outside deprecation mode.
     */
    function test_buyBondForStableCoin_RevertWhen_NotDeprecated() public {
        vm.expectRevert(Errors.DEPRECATION_MODE_NOT_ENABLED.selector);
        _KUMASwap.buyBondForStableCoin(1, _alice, 10 ether);
    }

    /**
     * @notice Tests that a bond cannot be bought with a buyer address of address(0).
     */
    function test_buyBondForStableCoin_RevertWhen_BuyerEqAddressZero() public {
        _KUMASwap.sellBond(1);
        _KUMASwap.initializeDeprecationMode();
        skip(2 days);
        _KUMASwap.enableDeprecationMode();
        vm.expectRevert(Errors.BUYER_CANNOT_BE_ADDRESS_ZERO.selector);
        _KUMASwap.buyBondForStableCoin(1, address(0), 10 ether);
    }

    /**
     * @notice Tests that a bond cannot be bought for an amount of 0.
     */
    function test_buyBondForStableCoin_RevertWhen_AmountEqZero() public {
        _KUMASwap.sellBond(1);
        _KUMASwap.initializeDeprecationMode();
        skip(2 days);
        _KUMASwap.enableDeprecationMode();
        vm.expectRevert(Errors.AMOUNT_CANNOT_BE_ZERO.selector);
        _KUMASwap.buyBondForStableCoin(1, _alice, 0);
    }

    /**
     * @notice Tests buyBondForStableCoin access control.
     */
    function test_buyBondForStableCoin_RevertWhen_NotManager() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.ACCESS_CONTROL_ACCOUNT_IS_MISSING_ROLE.selector, _alice, Roles.KUMA_MANAGER_ROLE
            )
        );
        vm.prank(_alice);
        _KUMASwap.buyBondForStableCoin(1, _alice, 10 ether);
    }
}
