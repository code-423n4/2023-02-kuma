// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {MCAGAggregatorInterface} from "@mcag/interfaces/MCAGAggregatorInterface.sol";

interface IMCAGRateFeed {
    event AccessControllerSet(address accessController);
    event OracleSet(address oracle, bytes4 indexed currency, bytes4 indexed country, uint64 indexed term);

    function initialize(IAccessControl accessController) external;

    function setOracle(bytes4 currency, bytes4 country, uint64 term, MCAGAggregatorInterface oracle) external;

    function minRateCoupon() external view returns (uint256);

    function decimals() external view returns (uint8);

    function getAccessController() external view returns (IAccessControl);

    function getRate(bytes32 riskCategory) external view returns (uint256);

    function getOracle(bytes32 riskCategory) external view returns (MCAGAggregatorInterface);
}
