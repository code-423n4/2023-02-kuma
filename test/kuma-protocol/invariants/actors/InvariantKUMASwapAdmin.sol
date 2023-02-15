// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {IKIBToken} from "@kuma/interfaces/IKIBToken.sol";
import {Test} from "forge-std/Test.sol";

contract InvariantKUMASwapAdmin is Test {
    IKIBToken private _KIBToken;

    constructor(IKIBToken KIBToken) {
        _KIBToken = KIBToken;
    }

    function KUMASwapSetEpochLength(uint256 epochLength) external {
        epochLength = bound(epochLength, 1, 6 days);
        _KIBToken.setEpochLength(epochLength);
    }
}
