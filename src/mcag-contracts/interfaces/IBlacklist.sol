// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

interface IBlacklist {
    event AccessControllerSet(address accesController);
    event Blacklisted(address indexed account);
    event UnBlacklisted(address indexed account);

    function blacklist(address account) external;

    function unBlacklist(address account) external;

    function accessController() external view returns (IAccessControl);

    function isBlacklisted(address account) external view returns (bool);
}
