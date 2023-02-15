// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {IKIBToken} from "@kuma/interfaces/IKIBToken.sol";
import {IMCAGRateFeed} from "@kuma/interfaces/IMCAGRateFeed.sol";
import {WadRayMath} from "@kuma/libraries/WadRayMath.sol";

contract InvariantKIBTokenBase {
    using WadRayMath for uint256;

    IKIBToken internal _KIBToken;
    IMCAGRateFeed internal _rateFeed;

    uint256 internal _maxTimestamp = type(uint32).max;
    uint256 internal _maxYield = 1000000008319516284844715116; // 30%
    uint256 internal _maxCumulativeYield = _maxYield.rayPow(_maxTimestamp);
    uint256 internal _maxTotalBaseSupply = (type(uint256).max - WadRayMath.HALF_RAY) / _maxCumulativeYield;

    constructor(IKIBToken KIBToken, IMCAGRateFeed rateFeed) {
        _KIBToken = KIBToken;
        _rateFeed = rateFeed;
    }

    /**
     * @notice This is a helper function used mainly for the KIBToken mint function
     * during invariant test to avoid overflow during fuzzing.
     * The logic here is to determine maxmium values with sensible parameters such as :
     * - Maximum elapsed time (maxTimestamp) : 136 years
     * - Maximum yield : 30%
     */
    function _getMaxAmount() internal view returns (uint256) {
        uint256 availableBaseSupply = _maxTotalBaseSupply - _KIBToken.getTotalBaseSupply();

        return WadRayMath.rayToWad(availableBaseSupply.rayMul(_KIBToken.getUpdatedCumulativeYield()));
    }
}
