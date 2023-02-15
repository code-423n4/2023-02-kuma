// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {AccessController} from "@mcag/AccessController.sol";
import {Blacklist} from "@mcag/Blacklist.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {Errors} from "@mcag/libraries/Errors.sol";
import {Roles} from "@mcag/libraries/Roles.sol";
import {Test, console2} from "forge-std/Test.sol";

contract BlacklistTest is Test {
    event AccessControllerSet(address accesController);
    event Blacklisted(address indexed account);
    event UnBlacklisted(address indexed account);

    address private _alice = vm.addr(1);
    AccessController private _accessController;
    Blacklist private _blacklist;

    function setUp() public {
        _accessController = new AccessController();
        _blacklist = new Blacklist(_accessController);
    }

    function test_constructor() public {
        vm.expectEmit(false, false, false, true);
        emit AccessControllerSet(address(_accessController));

        Blacklist newBlacklist = new Blacklist(_accessController);

        assertEq(address(newBlacklist.accessController()), address(_accessController));
    }

    function test_constructor_RevertWhen_InitializedWithInvalidParameters() public {
        vm.expectRevert(Errors.CANNOT_SET_TO_ADDRESS_ZERO.selector);
        new Blacklist(IAccessControl(address(0)));
    }

    function test_blacklist() public {
        vm.expectEmit(true, false, false, true);
        emit Blacklisted(_alice);
        _blacklist.blacklist(_alice);

        assertTrue(_blacklist.isBlacklisted(_alice));
    }

    function test_blacklist_RevertWhen_CallerIsNotBlacklister() public {
        vm.expectRevert(Errors.BLACKLIST_CALLER_IS_NOT_BLACKLISTER.selector);
        vm.prank(_alice);
        _blacklist.blacklist(address(this));
    }

    function test_unBlacklist() public {
        _blacklist.blacklist(_alice);
        vm.expectEmit(true, false, false, true);
        emit UnBlacklisted(_alice);
        _blacklist.unBlacklist(_alice);

        assertFalse(_blacklist.isBlacklisted(_alice));
    }

    function test_unBlacklist_RevertWhen_CallerIsNotBlacklister() public {
        vm.expectRevert(Errors.BLACKLIST_CALLER_IS_NOT_BLACKLISTER.selector);
        vm.prank(_alice);
        _blacklist.unBlacklist(address(this));
    }
}
