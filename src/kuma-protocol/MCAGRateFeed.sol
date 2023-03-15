// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {Errors} from "./libraries/Errors.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IMCAGRateFeed} from "./interfaces/IMCAGRateFeed.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {MCAGAggregatorInterface} from "@mcag/interfaces/MCAGAggregatorInterface.sol";
import {Roles} from "./libraries/Roles.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import {WadRayMath} from "./libraries/WadRayMath.sol";

contract MCAGRateFeed is IMCAGRateFeed, UUPSUpgradeable, Initializable {
    uint8 private constant _DECIMALS = 27;
    uint256 private constant _MIN_RATE_COUPON = WadRayMath.RAY;

    uint256 private _stalenessThreshold;
    IAccessControl private _accessController;

    mapping(bytes32 => MCAGAggregatorInterface) private _oracles;

    modifier onlyManager() {
        if (!_accessController.hasRole(Roles.KUMA_MANAGER_ROLE, msg.sender)) {
            revert Errors.ACCESS_CONTROL_ACCOUNT_IS_MISSING_ROLE(msg.sender, Roles.KUMA_MANAGER_ROLE);
        }
        _;
    }

    constructor() initializer {}

    /**
     * @param accessController KUMA DAO AccessController.
     */
    function initialize(IAccessControl accessController, uint256 stalenessThreshold) external override initializer {
        if (address(accessController) == address(0)) {
            revert Errors.CANNOT_SET_TO_ADDRESS_ZERO();
        }
        if (stalenessThreshold == 0) {
            revert Errors.CANNOT_SET_TO_ZERO();
        }
        _accessController = accessController;
        _stalenessThreshold = stalenessThreshold;

        emit AccessControllerSet(address(accessController));
        emit StalenessThresholdSet(stalenessThreshold);
    }

    /**
     * @notice Set an MCAGAggregator for a specific risk category.
     * @param currency Currency of the bond - example : USD
     * @param country Treasury issuer - example : US
     * @param term Lifetime of the bond ie maturity in seconds - issuance date - example : 10 years
     */
    function setOracle(bytes4 currency, bytes4 country, uint64 term, MCAGAggregatorInterface oracle)
        external
        override
        onlyManager
    {
        if (currency == bytes4(0) || country == bytes4(0) || term == 0) {
            revert Errors.WRONG_RISK_CATEGORY();
        }
        if (address(oracle) == address(0)) {
            revert Errors.CANNOT_SET_TO_ADDRESS_ZERO();
        }

        bytes32 riskCategory = keccak256(abi.encode(currency, country, term));
        _oracles[riskCategory] = oracle;

        emit OracleSet(address(oracle), currency, country, term);
    }

    /**
     * @notice Sets a new staleness threshold.
     * @param stalenessThreshold New staleness threshold in seconds.
     */
    function setStalenessThreshold(uint256 stalenessThreshold) external override onlyManager {
        if (stalenessThreshold == 0) {
            revert Errors.CANNOT_SET_TO_ZERO();
        }
        _stalenessThreshold = stalenessThreshold;

        emit StalenessThresholdSet(stalenessThreshold);
    }

    /**
     * @return KUMA DAO AccessController.
     */
    function getAccessController() external view override returns (IAccessControl) {
        return _accessController;
    }

    /**
     * @param riskCategory Unique risk category identifier computed with keccack256(abi.encode(currency, country, term))
     * @return rate Oracle rate in 27 decimals.
     */
    function getRate(bytes32 riskCategory) external view override returns (uint256) {
        MCAGAggregatorInterface oracle = _oracles[riskCategory];
        (, int256 answer,, uint256 updatedAt,) = oracle.latestRoundData();

        if (block.timestamp - updatedAt > _stalenessThreshold) {
            revert Errors.ORACLE_ANSWER_IS_STALE();
        }

        if (answer < 0) {
            return _MIN_RATE_COUPON;
        }

        uint256 rate = uint256(answer);
        uint8 oracleDecimal = oracle.decimals();

        if (_DECIMALS < oracleDecimal) {
            rate = uint256(answer) / (10 ** (oracleDecimal - _DECIMALS));
        } else if (_DECIMALS > oracleDecimal) {
            rate = uint256(answer) * 10 ** (_DECIMALS - oracleDecimal);
        }

        if (rate < _MIN_RATE_COUPON) {
            return _MIN_RATE_COUPON;
        }

        return rate;
    }

    /**
     * @param riskCategory Unique risk category identifier computed with keccack256(abi.encode(currency, country, term))
     * @return MCAGAggregator for a specific risk category.
     */
    function getOracle(bytes32 riskCategory) external view override returns (MCAGAggregatorInterface) {
        return _oracles[riskCategory];
    }

    /**
     * @return Current staleness threshold.
     */
    function getStalenessThreshold() external view override returns (uint256) {
        return _stalenessThreshold;
    }

    /**
     * @return Minimum acceptable rate.
     */
    function minRateCoupon() external pure override returns (uint256) {
        return _MIN_RATE_COUPON;
    }

    /**
     * @return Number of decimals used to get its user representation.
     */
    function decimals() external pure override returns (uint8) {
        return _DECIMALS;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyManager {}
}
