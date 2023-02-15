// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "./KIBTokenSetUp.t.sol";

contract KIBTokenMint is KIBTokenSetUp {
    using Roles for bytes32;
    using WadRayMath for uint256;

    function test_mint_WithPriceRateEqualsYield() public {
        _KIBToken.mint(address(this), 10 ether);
        uint256 ownerBalance0 = _KIBToken.balanceOf(address(this));
        uint256 ownerBaseBalance0 = _KIBToken.getBaseBalance(address(this));
        uint256 totalSupply0 = _KIBToken.totalSupply();

        vm.warp(block.timestamp + 365 days + 30 minutes);
        vm.expectEmit(false, false, false, true);
        emit PreviousEpochCumulativeYieldUpdated(WadRayMath.RAY, _YIELD.rayPow(365 days));
        vm.expectEmit(false, false, false, true);
        emit CumulativeYieldUpdated(WadRayMath.RAY, _YIELD.rayPow(365 days + 30 minutes));
        _KIBToken.mint(_alice, 10 ether);
        uint256 _aliceBalance0 = _KIBToken.balanceOf(_alice);
        uint256 _aliceBaseBalance0 = _KIBToken.getBaseBalance(_alice);
        uint256 ownerBalance1 = _KIBToken.balanceOf(address(this));
        uint256 ownerBaseBalance1 = _KIBToken.getBaseBalance(address(this));
        uint256 totalSupply1 = _KIBToken.totalSupply();

        vm.warp(block.timestamp + 365 days);
        uint256 _aliceBalance1 = _KIBToken.balanceOf(_alice);
        uint256 _aliceBaseBalance1 = _KIBToken.getBaseBalance(_alice);
        uint256 ownerBalance2 = _KIBToken.balanceOf(address(this));
        uint256 ownerBaseBalance2 = _KIBToken.getBaseBalance(address(this));
        uint256 totalSupply2 = _KIBToken.totalSupply();
        uint256 totalBaseSupply2 = _KIBToken.getTotalBaseSupply();

        assertEq(ownerBalance0, 10 ether);
        assertEq(ownerBaseBalance0, WadRayMath.wadToRay(10 ether));
        assertEq(_aliceBalance0, 10 ether);
        assertEq(_aliceBaseBalance0, 9523809523809523809576561433);
        assertEq(totalSupply0, 10 ether);
        assertEq(ownerBalance1, 10.5 ether);
        assertEq(ownerBaseBalance1, WadRayMath.wadToRay(10 ether));
        assertEq(_aliceBalance1, 10.5 ether);
        assertEq(_aliceBaseBalance1, 9523809523809523809576561433);
        assertEq(totalSupply1, 20.5 ether);
        assertEq(ownerBalance2, 11.025 ether);
        assertEq(ownerBaseBalance2, WadRayMath.wadToRay(10 ether));
        assertEq(totalSupply2, 21.525 ether);
        assertEq(totalBaseSupply2, 19523809523809523809576561433);
    }

    function test_mint_WithReferenceRateGtYield() public {
        _KIBToken.mint(address(this), 10 ether);
        uint256 ownerBalance0 = _KIBToken.balanceOf(address(this));
        uint256 ownerBaseBalance0 = _KIBToken.getBaseBalance(address(this));
        uint256 totalSupply0 = _KIBToken.totalSupply();

        vm.warp(block.timestamp + 365 days + 30 minutes);

        _mcagAggregator.transmit(int256(1000000003022265980097387650));

        _KIBToken.mint(_alice, 10 ether);
        uint256 _aliceBalance0 = _KIBToken.balanceOf(_alice);
        uint256 _aliceBaseBalance0 = _KIBToken.getBaseBalance(_alice);
        uint256 ownerBalance1 = _KIBToken.balanceOf(address(this));
        uint256 ownerBaseBalance1 = _KIBToken.getBaseBalance(address(this));
        uint256 totalSupply1 = _KIBToken.totalSupply();

        vm.warp(block.timestamp + 365 days);
        uint256 _aliceBalance1 = _KIBToken.balanceOf(_alice);
        uint256 _aliceBaseBalance1 = _KIBToken.getBaseBalance(_alice);
        uint256 ownerBalance2 = _KIBToken.balanceOf(address(this));
        uint256 ownerBaseBalance2 = _KIBToken.getBaseBalance(address(this));
        uint256 totalSupply2 = _KIBToken.totalSupply();
        uint256 totalBaseSupply2 = _KIBToken.getTotalBaseSupply();

        assertEq(ownerBalance0, 10 ether);
        assertEq(ownerBaseBalance0, WadRayMath.wadToRay(10 ether));
        assertEq(_aliceBalance0, 10 ether);
        assertEq(_aliceBaseBalance0, 9523809523809523809576561433);
        assertEq(totalSupply0, 10 ether);
        assertEq(ownerBalance1, 10.5 ether);
        assertEq(ownerBaseBalance1, WadRayMath.wadToRay(10 ether));
        assertEq(_aliceBalance1, 10.5 ether);
        assertEq(_aliceBaseBalance1, 9523809523809523809576561433);
        assertEq(totalSupply1, 20.5 ether);
        assertEq(ownerBalance2, 11.025 ether);
        assertEq(ownerBaseBalance2, WadRayMath.wadToRay(10 ether));
        assertEq(totalSupply2, 21.525 ether);
        assertEq(totalBaseSupply2, 19523809523809523809576561433);
    }

    function test_mint_WithPriceRateLtYield() public {
        _KIBToken.mint(address(this), 10 ether);
        uint256 ownerBalance0 = _KIBToken.balanceOf(address(this));
        uint256 ownerBaseBalance0 = _KIBToken.getBaseBalance(address(this));
        uint256 totalSupply0 = _KIBToken.totalSupply();

        vm.warp(block.timestamp + 365 days);
        _mcagAggregator.transmit(int256(1000000000937303470807876290));

        _KIBToken.mint(_alice, 10 ether);
        uint256 _aliceBalance0 = _KIBToken.balanceOf(_alice);
        uint256 _aliceBaseBalance0 = _KIBToken.getBaseBalance(_alice);
        uint256 ownerBalance1 = _KIBToken.balanceOf(address(this));
        uint256 ownerBaseBalance1 = _KIBToken.getBaseBalance(address(this));
        uint256 totalSupply1 = _KIBToken.totalSupply();

        vm.warp(block.timestamp + 365 days);
        uint256 _aliceBalance1 = _KIBToken.balanceOf(_alice);
        uint256 _aliceBaseBalance1 = _KIBToken.getBaseBalance(_alice);
        uint256 ownerBalance2 = _KIBToken.balanceOf(address(this));
        uint256 ownerBaseBalance2 = _KIBToken.getBaseBalance(address(this));
        uint256 totalSupply2 = _KIBToken.totalSupply();
        uint256 totalBaseSupply2 = _KIBToken.getTotalBaseSupply();

        assertEq(ownerBalance0, 10 ether);
        assertEq(ownerBaseBalance0, WadRayMath.wadToRay(10 ether));
        assertEq(_aliceBalance0, 10 ether);
        assertEq(_aliceBaseBalance0, 9523809523809523809576561433);
        assertEq(totalSupply0, 10 ether);
        assertEq(ownerBalance1, 10.5 ether);
        assertEq(ownerBaseBalance1, WadRayMath.wadToRay(10 ether));
        assertEq(totalSupply1, 20.5 ether);
        assertEq(_aliceBalance1, 10.3 ether);
        assertEq(_aliceBaseBalance1, 9523809523809523809576561433);
        assertEq(ownerBalance2, 10.815 ether);
        assertEq(ownerBaseBalance2, WadRayMath.wadToRay(10 ether));
        assertEq(totalSupply2, 21.115 ether);
        assertEq(totalBaseSupply2, 19523809523809523809576561433);
    }

    function test_mint_WithTransfer() public {
        _KIBToken.mint(address(this), 5 ether);
        _KIBToken.transfer(_bob, 5 ether);
        assertEq(_KIBToken.balanceOf(address(this)), 0);
        assertEq(_KIBToken.balanceOf(_bob), 5 ether);
        assertEq(_KIBToken.totalSupply(), 5 ether);
        skip(365 days);
        assertEq(_KIBToken.balanceOf(_bob), 5.25 ether);
        assertEq(_KIBToken.totalSupply(), 5.25 ether);
        _KIBToken.mint(_alice, 10 ether);
        vm.prank(_alice);
        _KIBToken.transfer(_bob, 10 ether);
        assertEq(_KIBToken.balanceOf(_alice), 0);
        assertEq(_KIBToken.balanceOf(_bob), 15.25 ether);
        assertEq(_KIBToken.totalSupply(), 15.25 ether);
        skip(365 days);
        assertEq(_KIBToken.balanceOf(_bob), 16.0125 ether);
        assertEq(_KIBToken.totalSupply(), 16.0125 ether);
    }

    function test_mint_Rounding() public {
        _KIBToken.mint(address(this), 5 ether);
        skip(365 days);
        assertEq(_KIBToken.balanceOf(address(this)), 5.25 ether);
        _KIBToken.mint(_bob, 4745698303631878590);
        vm.warp(block.timestamp + 365 days);
        assertEq(_KIBToken.balanceOf(address(this)), 5.5125 ether);
        assertEq(_KIBToken.balanceOf(_bob), 4982983218813472519); // Note: would be 4982983218813472520 if cumYield was exactly 1.05 but it is very very slightly less since our per second yield is also slightly less
    }

    function test_mint_WithYieldUpdate() public {
        _KIBToken.mint(address(this), 10 ether);
        assertEq(_KIBToken.getCumulativeYield(), WadRayMath.RAY); // Still not greater than epoch so yield won't be greater than 1
        vm.warp(block.timestamp + 365 days / 2);
        assertEq(_KIBToken.getUpdatedCumulativeYield(), _YIELD.rayPow(365 days / 2)); // Still not greater than epoch so yield won't be greater than 1
        uint256 _YIELD_10_PERCENT = 1000000003022265980097387651;
        _mcagAggregator.transmit(int256(1000000004431822129783699001));

        vm.mockCall(
            address(_KUMASwap), abi.encodeWithSelector(_KUMASwap.getMinCoupon.selector), abi.encode(_YIELD_10_PERCENT)
        );

        _KIBToken.refreshYield();
        vm.warp(block.timestamp + 365 days / 2);
        assertEq(
            _KIBToken.getUpdatedCumulativeYield(),
            _YIELD.rayPow(365 days / 2).rayMul(_YIELD_10_PERCENT.rayPow(365 days / 2))
        );

        /**
         * Cannot use assertEq here because rate is non linear so after 6 months
         * rewards will be slightly less then half of the rewards that would have
         * been earned over a year.
         */
        assertApproxEqRel(_KIBToken.balanceOf(address(this)), 10.75 ether, 5e16);
    }

    function test_mint_RevertWhen_BeforeStartTime() public {
        vm.warp(block.timestamp - 365 days);
        vm.expectRevert(Errors.START_TIME_NOT_REACHED.selector);
        _KIBToken.mint(address(this), 10 ether);
    }

    function test_mint_RevertWhen_ToAddressZero() public {
        vm.expectRevert(Errors.ERC20_MINT_TO_THE_ZERO_ADDRESS.selector);
        _KIBToken.mint(address(0), 10 ether);
    }

    function test_mint_Access_Control() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.ACCESS_CONTROL_ACCOUNT_IS_MISSING_ROLE.selector,
                _alice,
                Roles.KUMA_MINT_ROLE.toGranularRole(_RISK_CATEGORY)
            )
        );
        vm.prank(_alice);
        _KIBToken.mint(_alice, 10 ether);
    }

    // Test that yield earned within an Epoch is still kept by a user even if a token was minted to them during the epoch
    function test_mint_YieldEarnedInEpoch() public {
        _KIBToken.mint(_alice, 1 ether);
        skip(4 hours - 1);
        assertEq(_KIBToken.balanceOf(_alice), 1 ether); // Didn't complete epoch yet so alice should have her starting balance
        _KIBToken.mint(_alice, 1); // Mint miniscule amount to alice to trigger update of baseBalances within epoch
        skip(0.5 hours);
        assertGt(_KIBToken.balanceOf(_alice), 1 ether + 1e12); // Alice should earn at least 1e12 wei within this time
    }
}
