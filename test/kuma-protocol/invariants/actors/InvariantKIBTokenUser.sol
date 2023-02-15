// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {IMCAGRateFeed} from "@kuma/interfaces/IMCAGRateFeed.sol";
import {IKIBToken} from "@kuma/interfaces/IKIBToken.sol";
import {InvariantKIBTokenBase} from "./InvariantKIBTokenBase.sol";
import {Test} from "forge-std/Test.sol";

contract InvariantKIBTokenUser is Test, InvariantKIBTokenBase {
    address private _admin;
    address private _alice;

    constructor(IKIBToken KIBToken, IMCAGRateFeed rateFeed, address alice, address admin)
        InvariantKIBTokenBase(KIBToken, rateFeed)
    {
        _alice = alice;
        _admin = admin;
    }

    function KIBTokenTransfer(uint256 amount) external {
        amount = bound(amount, 0, _getMaxAmount());
        uint256 currentBalance = _KIBToken.balanceOf(address(this));
        if (currentBalance < amount) {
            vm.prank(_admin);
            _KIBToken.mint(address(this), amount - currentBalance);
        }
        (bool success) = _KIBToken.transfer(_alice, amount);
        assertEq(success, true);
    }

    function KIBTokenTransferFrom(uint256 amount) external {
        amount = bound(amount, 0, _getMaxAmount());
        uint256 currentBalance = _KIBToken.balanceOf(_alice);
        if (currentBalance < amount) {
            vm.prank(_admin);
            _KIBToken.mint(_alice, amount - currentBalance);
        }
        vm.startPrank(_alice, _alice);
        _KIBToken.approve(address(this), amount);
        vm.stopPrank();
        (bool success) = _KIBToken.transferFrom(_alice, address(this), amount);
        assertEq(success, true);
    }
}
