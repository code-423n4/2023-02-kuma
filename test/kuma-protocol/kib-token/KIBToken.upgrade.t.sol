// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "./KIBTokenSetUp.t.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

contract KIBTokenUpgrade is KIBTokenSetUp {
    function test_upgrade_RevertWhen_CallerIsNotManager() public {
        KIBToken newKIBToken = new KIBToken();
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.ACCESS_CONTROL_ACCOUNT_IS_MISSING_ROLE.selector, _alice, Roles.KUMA_MANAGER_ROLE
            )
        );
        vm.prank(_alice);
        UUPSUpgradeable(address(_KIBToken)).upgradeTo(address(newKIBToken));
    }
}
