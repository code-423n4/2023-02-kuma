// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "./KIBTokenSetUp.t.sol";

contract KIBTokenBurn is KIBTokenSetUp {
    using Roles for bytes32;

    function test_burn() public {
        _KIBToken.mint(address(this), 10 ether);
        vm.warp(block.timestamp + 365 days);
        _KIBToken.mint(_alice, 10 ether);
        vm.warp(block.timestamp + 365 days);
        _KIBToken.burn(address(this), 1.025 ether);
        _KIBToken.burn(_alice, 0.5 ether);

        assertEq(_KIBToken.balanceOf(_alice), 10 ether);
        assertEq(_KIBToken.balanceOf(address(this)), 10 ether);
        assertEq(_KIBToken.totalSupply(), 20 ether);
    }

    function test_burn_RevertWhen_FromAddressZero() public {
        vm.expectRevert(Errors.ERC20_BURN_FROM_THE_ZERO_ADDRESS.selector);
        _KIBToken.burn(address(0), 10 ether);
    }

    function test_burn_RevertWhen_AmountExceedsBalance() public {
        vm.expectRevert(Errors.ERC20_BURN_AMOUNT_EXCEEDS_BALANCE.selector);
        _KIBToken.burn(_alice, 10 ether);
    }

    function test_burn_RevertWhen_NotManager() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.ACCESS_CONTROL_ACCOUNT_IS_MISSING_ROLE.selector,
                _alice,
                Roles.KUMA_BURN_ROLE.toGranularRole(_RISK_CATEGORY)
            )
        );
        vm.prank(_alice);
        _KIBToken.burn(_alice, 10 ether);
    }

    // Test that yield earned within an Epoch is still kept by a user even if a token was burned to them during the epoch
    function test_burn_YieldEarnedInEpoch() public {
        _KIBToken.mint(_alice, 1 ether);
        skip(4 hours - 1);
        assertEq(_KIBToken.balanceOf(_alice), 1 ether); // Didn't complete epoch yet so alice should have her starting balance
        _KIBToken.burn(_alice, 1); // Burn miniscule amount from alice to trigger update of baseBalances within epoch
        skip(0.5 hours);
        assertGt(_KIBToken.balanceOf(_alice), 1 ether + 1e12); // Alice should earn at least 1e12 wei within this time
    }
}
