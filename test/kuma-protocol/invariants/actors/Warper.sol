// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Test} from "forge-std/Test.sol";

contract Warper is Test {
    function warp(uint256 warpTime) external {
        warpTime = bound(warpTime, 0, type(uint32).max - block.timestamp);
        vm.warp(block.timestamp + warpTime);
    }
}
