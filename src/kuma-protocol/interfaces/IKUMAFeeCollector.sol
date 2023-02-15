// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {IKUMAAddressProvider} from "./IKUMAAddressProvider.sol";

interface IKUMAFeeCollector {
    event PayeeAdded(address indexed payee, uint256 share);
    event PayeeRemoved(address indexed payee);
    event FeeReleased(uint256 income);
    event KUMAAddressProviderSet(address KUMAAddressProvider);
    event ShareUpdated(address indexed payee, uint256 newShare);
    event RiskCategorySet(bytes32 riskCategory);

    function initialize(IKUMAAddressProvider KUMAAddressProvider, bytes4 currency, bytes4 country, uint64 term)
        external;

    function release() external;

    function addPayee(address payee, uint256 share) external;

    function removePayee(address payee) external;

    function updatePayeeShare(address payee, uint256 share) external;

    function changePayees(address[] calldata newPayees, uint256[] calldata newShares) external;

    function getKUMAAddressProvider() external view returns (IKUMAAddressProvider);

    function getRiskCategory() external view returns (bytes32);

    function getPayees() external view returns (address[] memory);

    function getTotalShares() external view returns (uint256);

    function getShare(address payee) external view returns (uint256);
}
