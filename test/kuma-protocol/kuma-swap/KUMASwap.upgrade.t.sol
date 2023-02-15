// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "./KUMASwapSetUp.t.sol";
import {MockKUMASwapV2} from "@kuma/mocks/MockKUMASwapV2.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

contract KUMASwapUpgrade is KUMASwapSetUp {
    MockKUMASwapV2 private _KUMASwapV2Impl;
    MockKUMASwapV2 private _KUMASwapV2;

    function setUp() public {
        _KUMASwap.sellBond(1);
        _KUMASwapV2Impl = new MockKUMASwapV2();
        _KUMASwapV2 = MockKUMASwapV2(address(_KUMASwap));
    }

    function test_upgrade() public {
        UUPSUpgradeable(address(_KUMASwap)).upgradeToAndCall(
            address(_KUMASwapV2Impl), abi.encodeWithSelector(_KUMASwapV2Impl.reinitialize.selector)
        );
        assertEq(_KUMASwapV2.getDummyVar0(), 123);
        assertEq(_KUMABondToken.balanceOf(address(_KUMASwapV2)), 1);

        _KUMABondToken.issueBond(address(this), _bond);
        _KUMASwapV2.sellAsset(2);
        assertEq(_KUMABondToken.ownerOf(2), address(_KUMASwapV2));
    }

    function test_upgrade_RevertWhen_CallerIsNotManager() public {
        vm.prank(_alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.ACCESS_CONTROL_ACCOUNT_IS_MISSING_ROLE.selector, _alice, Roles.KUMA_MANAGER_ROLE
            )
        );
        UUPSUpgradeable(address(_KUMASwap)).upgradeToAndCall(
            address(_KUMASwapV2Impl), abi.encodeWithSelector(_KUMASwapV2Impl.reinitialize.selector)
        );
    }

    function test_upgrade_RevertWhen_UpgradingToNonUUPSContract() public {
        vm.expectRevert("ERC1967Upgrade: new implementation is not UUPS");
        UUPSUpgradeable(address(_KUMASwap)).upgradeTo(address(_deprecationStableCoin));
    }
}
