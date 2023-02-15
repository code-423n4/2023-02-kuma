// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {IMCAGRateFeed} from "@kuma/interfaces/IMCAGRateFeed.sol";
import {IKIBToken} from "@kuma/interfaces/IKIBToken.sol";
import {InvariantKIBTokenBase} from "./InvariantKIBTokenBase.sol";
import {Test} from "forge-std/Test.sol";
import {WadRayMath} from "@kuma/libraries/WadRayMath.sol";

contract InvariantKIBTokenAdmin is Test, InvariantKIBTokenBase {
    using WadRayMath for uint256;

    address private _user;

    constructor(IKIBToken KIBToken, IMCAGRateFeed rateFeed, address user) InvariantKIBTokenBase(KIBToken, rateFeed) {
        _user = user;
    }

    function KIBTokenMint(uint256 amount) external {
        amount = bound(amount, 0, _getMaxAmount());
        uint256 userBaseBalanceBefore = _KIBToken.getBaseBalance(_user);
        uint256 updatedCumulativeYield = _KIBToken.getUpdatedCumulativeYield();
        _KIBToken.mint(_user, amount);
        uint256 userBaseBalanceAfter = _KIBToken.getBaseBalance(_user);
        assertEq(userBaseBalanceAfter - userBaseBalanceBefore, amount.rayDiv(updatedCumulativeYield));
    }

    function KIBTokenBurn(uint256 amount) external {
        amount = bound(amount, 0, _KIBToken.balanceOf(_user));
        uint256 userBalanceBefore = _KIBToken.balanceOf(_user);
        _KIBToken.burn(_user, amount);
        uint256 userBalanceAfter = _KIBToken.balanceOf(_user);
        assertEq(userBalanceBefore - userBalanceAfter, amount);
    }

    function KIBTokenSetEpochLength(uint256 epochLength) external {
        epochLength = bound(epochLength, 1, 365 days);
        _KIBToken.setEpochLength(epochLength);
        assertEq(_KIBToken.getEpochLength(), epochLength);
    }

    function KIBTokenSetYield(uint256 yield) external {
        yield = WadRayMath.RAY + bound(yield, 0, 8319516284844715116); // 30% max
        vm.mockCall(address(_rateFeed), abi.encodeWithSelector(IMCAGRateFeed.getRate.selector), abi.encode(yield));
        assertEq(_KIBToken.getYield(), yield);
    }
}
