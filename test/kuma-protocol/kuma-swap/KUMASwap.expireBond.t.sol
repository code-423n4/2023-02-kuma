// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "./KUMASwapSetUp.t.sol";

contract KUMASwapExpireBond is KUMASwapSetUp {
    function test_expireBond() public {
        _KUMASwap.sellBond(1);
        skip(365 days * 30);
        vm.expectEmit(false, false, false, true);
        emit BondExpired(1);
        _KUMASwap.expireBond(1);

        assertTrue(_KUMASwap.isExpired());
        assertEq(_KUMASwap.getMinCoupon(), _YIELD);
        assertEq(_KIBToken.getYield(), WadRayMath.RAY);
        assertEq(_KUMASwap.getExpiredBonds().length, 1);
        assertEq(_KUMASwap.getExpiredBonds()[0], 1);
    }

    function test_expireBond_RevertWhen_BondNotMatured() public {
        _KUMASwap.sellBond(1);
        vm.expectRevert(Errors.BOND_NOT_MATURED.selector);
        _KUMASwap.expireBond(1);
    }

    function test_expireBond_RevertWhen_ExpireInvalidBond() public {
        vm.expectRevert(Errors.INVALID_TOKEN_ID.selector);
        _KUMASwap.expireBond(1);
    }

    function test_expireBond_RevertWhen_DeprecationModeEnabled() public {
        _KUMASwap.sellBond(1);
        _KUMASwap.initializeDeprecationMode();
        skip(2 days);
        _KUMASwap.enableDeprecationMode();
        vm.expectRevert(Errors.DEPRECATION_MODE_ENABLED.selector);
        _KUMASwap.expireBond(1);
    }
}
