// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "./KIBTokenSetUp.t.sol";

contract KIBTokenTransfer is KIBTokenSetUp {
    using WadRayMath for uint256;

    function test_transfer() public {
        _KIBToken.mint(address(this), 10 ether);
        vm.expectEmit(true, true, false, true);
        emit Transfer(address(this), _alice, 5 ether);
        _KIBToken.transfer(_alice, 5 ether);
        assertEq(_KIBToken.balanceOf(address(this)), 5 ether);
        assertEq(_KIBToken.balanceOf(_alice), 5 ether);
    }

    function test_transfer_MaxBalanceWithoutRefresh() public {
        _KIBToken.mint(address(this), 10 ether);
        skip(365 days);
        _KIBToken.transfer(_alice, _KIBToken.balanceOf(address(this)));
        assertEq(_KIBToken.getBaseBalance(address(this)), 0);
        assertTrue(
            (_KIBToken.getBaseBalance(_alice) > WadRayMath.wadToRay(10 ether) - 5e8)
                && (_KIBToken.getBaseBalance(_alice) < WadRayMath.wadToRay(10 ether) + 5e8)
        ); // Base balance should be within 1e9 tolerance
        assertEq(_KIBToken.balanceOf(_alice), 10.5 ether);
    }

    function test_transfer_RevertWhen_FromAddressZero() public {
        vm.expectRevert(Errors.ERC20_TRANSFER_FROM_THE_ZERO_ADDRESS.selector);
        vm.prank(address(0));
        _KIBToken.transfer(address(this), 10 ether);
    }

    function test_transfer_RevertWhen_ToAddressZero() public {
        vm.expectRevert(Errors.ERC20_TRANSER_TO_THE_ZERO_ADDRESS.selector);
        _KIBToken.transfer(address(0), 10 ether);
    }

    function test_transfer_RevertWhen_AmountExceedsBalance() public {
        vm.expectRevert(Errors.ERC20_TRANSFER_AMOUNT_EXCEEDS_BALANCE.selector);
        _KIBToken.transfer(_alice, 10 ether);
    }

    function test_transferFrom() public {
        _KIBToken.mint(address(this), 10 ether);
        _KIBToken.approve(_alice, 5 ether);
        vm.expectEmit(true, true, false, true);
        emit Approval(address(this), _alice, 0);
        vm.expectEmit(true, true, false, true);
        emit Transfer(address(this), _alice, 5 ether);
        vm.prank(_alice);
        _KIBToken.transferFrom(address(this), _alice, 5 ether);
    }

    function test_transfer_From_Max_Uint_Approval() public {
        _KIBToken.mint(address(this), 10 ether);
        _KIBToken.approve(_alice, type(uint256).max);
        vm.prank(_alice);
        _KIBToken.transferFrom(address(this), _alice, 5 ether);
    }

    function test_transfer_From_Approve_Before_Rewards() public {
        _KIBToken.mint(address(this), 10 ether);
        _KIBToken.approve(_alice, 10 ether);
        vm.warp(block.timestamp + 365 days);
        vm.startPrank(_alice, _alice);
        _KIBToken.transferFrom(address(this), _alice, 10 ether);
        assertApproxEqAbs(_KIBToken.balanceOf(_alice), 10 ether, 1);
        assertApproxEqAbs(_KIBToken.balanceOf(address(this)), 0.5 ether, 1);
    }

    function test_transferFrom_BalanceOfWithRewards() public {
        _KIBToken.mint(address(this), 10 ether);
        vm.warp(block.timestamp + 365 days);
        _KIBToken.approve(_alice, _KIBToken.balanceOf(address(this)));
        vm.startPrank(_alice, _alice);
        _KIBToken.transferFrom(address(this), _alice, _KIBToken.balanceOf(address(this)));
        assertEq(_KIBToken.balanceOf(_alice), 10.5 ether);
        assertTrue(
            (_KIBToken.getBaseBalance(_alice) > WadRayMath.wadToRay(10 ether) - 5e8)
                && (_KIBToken.getBaseBalance(_alice) < WadRayMath.wadToRay(10 ether) + 5e8)
        ); // Base balances should be within wadRayRatio tolerance
        assertEq(_KIBToken.balanceOf(address(this)), 0);
        assertEq(_KIBToken.getBaseBalance(address(this)), 0);
        assertEq(_KIBToken.allowance(address(this), _alice), 0);
    }

    function test_transferFrom_RevertWhen_InsufficientAllowance() public {
        _KIBToken.mint(address(this), 10 ether);
        vm.prank(_alice);
        vm.expectRevert("ERC20: insufficient allowance");
        _KIBToken.transferFrom(address(this), _alice, 5 ether);
    }

    function test_transfer_RevertWhen_AmountEqZero() public {
        _KIBToken.mint(address(this), 10 ether);
        _KIBToken.transfer(_alice, 5 ether);
        skip(356 days);

        _KIBToken.transfer(_alice, 0);
        skip(356 days);
    }

    // Test Rounding with numbers found from the depths of fuzz testing
    function test_Rounding() public {
        vm.prank(address(this));
        _KIBToken.mint(_alice, 36486023718626623496684752349278144);

        vm.prank(_alice);
        _KIBToken.approve((address(this)), 36486023718626623496684752349278144);

        _KIBToken.transferFrom(_alice, address(this), 36486023718626623496684752349278144);

        skip(365 days);

        // Yield Should be 1049994151880169816447168406 at this point
        _KIBToken.mint(_bob, 1362);
        assertEq(1362, _KIBToken.balanceOf(_bob));
        vm.prank(address(this));
        _KIBToken.mint(_bob, 182612551125860953057715315542701);
        assertEq(182612551125860953057715315542701 + 1362, _KIBToken.balanceOf(_bob));
        vm.startPrank(_bob);
        // Transfer should work for bob
        _KIBToken.transfer(_alice, 182612551125860953057715315542701 + 1362);
        assertEq(_KIBToken.balanceOf(_alice), 182612551125860953057715315542701 + 1362);
    }

    // Test Rounding with numbers found from the depths of fuzz testing
    function test_Rounding2() public {
        vm.prank(address(this));
        _KIBToken.mint(_alice, 3);

        vm.prank(_alice);
        _KIBToken.transfer(_bob, 3);
        assertEq(_KIBToken.balanceOf(_bob), 3);

        vm.prank(address(this));
        _KIBToken.mint(_bob, 21035940036530841404822589);
        assertEq(_KIBToken.balanceOf(_bob), 21035940036530841404822589 + 3);
        vm.startPrank(_bob);
        _KIBToken.transfer(address(this), 21035940036530841404822592);
        assertEq(_KIBToken.balanceOf(address(this)), 21035940036530841404822589 + 3);
    }

    function test_Rounding3() public {
        vm.prank(address(this));
        _KIBToken.mint(_alice, 2830);
        assertEq(_KIBToken.balanceOf(_alice), 2830);
        vm.prank(_alice);
        _KIBToken.transfer(address(this), 2830);
        assertEq(_KIBToken.balanceOf(_alice), 0);
        assertEq(_KIBToken.balanceOf(address(this)), 2830);
        skip(365 days + 1 seconds);
        uint256 adminBal = _KIBToken.balanceOf(address(this));
        vm.prank(address(this));
        _KIBToken.mint(_bob, 8018);
        assertEq(8018, _KIBToken.balanceOf(_bob), "Bob didn't receive full mint amount");
        vm.prank(_bob);
        _KIBToken.transfer(address(this), 8018);
        assertEq(_KIBToken.balanceOf(_bob), 0);
        assertEq(_KIBToken.balanceOf(address(this)), adminBal + 8018, "Bob's transfer did not transfer full amount");
    }

    function test_WadRayRounding(uint256 balanceOf, uint256 yield) public {
        vm.assume(balanceOf < 1e40); // BalanceOf in 18 digits
        vm.assume(yield > 0 && yield < 1e30);
        uint256 baseBalance = balanceOf.rayDiv(yield); // baseBalance in 27 digits
        assertApproxEqAbs(balanceOf, baseBalance.rayMul(yield), yield / 1e27);
    }

    // Test that yield earned within an Epoch is still kept by a user even if they transferred during the epoch
    function test_transfer_YieldEarnedInEpoch() public {
        _KIBToken.mint(_alice, 1 ether);
        skip(4 hours - 1);
        assertEq(_KIBToken.balanceOf(_alice), 1 ether); // Didn't complete epoch yet so alice should have her starting balance
        vm.prank(_alice);
        _KIBToken.transfer(_bob, 1); // Transfer miniscule amount to bob to trigger update of balanceOf within epoch
        skip(0.5 hours);
        assertGt(_KIBToken.balanceOf(_alice), 1 ether + 1e12); // Alice should earn at least 1e12 wei within this time
    }
}
