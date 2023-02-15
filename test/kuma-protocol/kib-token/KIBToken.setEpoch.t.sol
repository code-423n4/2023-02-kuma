// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "./KIBTokenSetUp.t.sol";

contract KIBTokenSetEpoch is KIBTokenSetUp {
    using Roles for bytes32;
    using WadRayMath for uint256;

    function test_setEpochLength_Set_Epoch() public {
        vm.expectEmit(false, false, false, true);
        emit EpochLengthSet(4 hours, 1 days);
        _KIBToken.setEpochLength(1 days);
        assertEq(_KIBToken.getEpochLength(), 1 days);
    }

    function test_setEpochLength_HigherEpochLengthEffectOfCumulativeYield() public {
        _KIBToken.mint(_alice, 10 ether);
        // Initial timestamp is 30 years + 4 hours per the BaseSetUp
        // warp to 1 second before the first rebase and set epoch length to a higher value
        // alice balance should still be 10 ether
        skip(4 hours - 1);
        _KIBToken.setEpochLength(365 days);
        assertEq(_KIBToken.balanceOf(_alice), 10 ether);

        // warp to the end of the old epoch
        // bringing timestamp to 30 years + 8 hours
        skip(1);
        // alice balance should still be 10 ether because the new epoch is higher
        assertEq(_KIBToken.balanceOf(_alice), 10 ether);

        // warp to the end of the 1st epoch ie to 31 years
        skip(365 days - 4 hours);

        // alice balance should now account for 1 year - 4 hours of interests
        assertEq(_KIBToken.balanceOf(_alice), _YIELD.rayPow(365 days - 4 hours).rayMul(10 ether));
    }

    function test_setEpochLength_LowerEpochLengthEffectOfCumulative_Yield() public {
        _KIBToken.mint(_alice, 10 ether);
        // skip to 1 second before the epoch update and update epoch to lower value
        skip(4 hours - 1);
        _KIBToken.setEpochLength(1 hours);
        // alice balance should now account for 3 hours of interests
        assertEq(_KIBToken.balanceOf(_alice), _YIELD.rayPow(3 hours).rayMul(10 ether));

        // skip to next epoch
        skip(1);
        // alice balance should now account for 4 hours of interests
        assertEq(_KIBToken.balanceOf(_alice), _YIELD.rayPow(4 hours).rayMul(10 ether));
    }

    function test_setEpochLength_RevertWhen_SetToZero() public {
        vm.expectRevert(Errors.EPOCH_LENGTH_CANNOT_BE_ZERO.selector);
        _KIBToken.setEpochLength(0);
    }

    function test_setEpochLength_RevertWhen_SetEpochLengthGtMaxEpochLength() public {
        vm.expectRevert(Errors.NEW_EPOCH_LENGTH_TOO_HIGH.selector);
        _KIBToken.setEpochLength(365 days + 1);
    }

    function test_setEpochLength_RevertWhen_NotSetEpochLengthRole() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.ACCESS_CONTROL_ACCOUNT_IS_MISSING_ROLE.selector, _alice, Roles.KUMA_SET_EPOCH_LENGTH_ROLE
            )
        );
        vm.prank(_alice);
        _KIBToken.setEpochLength(1 days);
    }
}
