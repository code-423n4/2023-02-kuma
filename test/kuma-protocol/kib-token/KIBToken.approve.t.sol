// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "./KIBTokenSetUp.t.sol";

contract KIBTokenApprove is KIBTokenSetUp {
    function test_approve() public {
        vm.expectEmit(true, true, false, true);
        emit Approval(address(this), _alice, 10 ether);
        _KIBToken.approve(_alice, 10 ether);
        assertEq(_KIBToken.allowance(address(this), _alice), 10 ether);
    }

    function test_approve_RevertWhen_FromAddressZero() public {
        vm.expectRevert("ERC20: approve from the zero address");
        vm.prank(address(0));
        _KIBToken.approve(_alice, 10 ether);
    }

    function test_approve_ToAddressZero() public {
        vm.expectRevert("ERC20: approve to the zero address");
        _KIBToken.approve(address(0), 5 ether);
    }

    function test_increaseAllowance() public {
        uint256 allowanceBefore = _KIBToken.allowance(address(this), _alice);
        vm.expectEmit(true, true, false, true);
        emit Approval(address(this), _alice, 10 ether);
        _KIBToken.approve(_alice, 10 ether);
        uint256 allowanceAfter = _KIBToken.allowance(address(this), _alice);
        assertEq(allowanceBefore, 0);
        assertEq(allowanceAfter, 10 ether);
    }
}
