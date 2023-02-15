// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "../BaseSetUp.t.sol";
import {Errors} from "@kuma/libraries/Errors.sol";
import {WadRayMath} from "@kuma/libraries/WadRayMath.sol";

abstract contract KIBTokenSetUp is BaseSetUp {
    using Roles for bytes32;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event CumulativeYieldUpdated(uint256 oldCumulativeYield, uint256 newCumulativeYield);
    event EpochLengthSet(uint256 previousEpochLength, uint256 newEpochLength);
    event KUMAAddressProviderSet(address KUMAAddressProvider);
    event PreviousEpochCumulativeYieldUpdated(uint256 oldCumulativeYield, uint256 newCumulativeYield);
    event RiskCategorySet(bytes32 riskCategory);
    event YieldUpdated(uint256 oldYield, uint256 newYield);

    constructor() {
        _KUMAAccessController.grantRole(Roles.KUMA_MINT_ROLE.toGranularRole(_RISK_CATEGORY), address(this));
        _KUMAAccessController.grantRole(Roles.KUMA_BURN_ROLE.toGranularRole(_RISK_CATEGORY), address(this));
        _KUMAAccessController.grantRole(Roles.KUMA_SET_EPOCH_LENGTH_ROLE, address(this));

        vm.mockCall(address(_KUMASwap), abi.encodeWithSelector(_KUMASwap.getMinCoupon.selector), abi.encode(_YIELD));
    }
}
