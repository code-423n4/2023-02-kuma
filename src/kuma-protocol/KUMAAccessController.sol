// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Roles} from "./libraries/Roles.sol";

contract KUMAAccessController is AccessControl {
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(Roles.KUMA_MANAGER_ROLE, msg.sender);
    }
}
