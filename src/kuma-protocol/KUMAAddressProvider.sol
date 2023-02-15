// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {Errors} from "./libraries/Errors.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IKUMAAddressProvider} from "./interfaces/IKUMAAddressProvider.sol";
import {IKIBToken} from "./interfaces/IKIBToken.sol";
import {IKUMAFeeCollector} from "./interfaces/IKUMAFeeCollector.sol";
import {IKUMASwap} from "./interfaces/IKUMASwap.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {Roles} from "./libraries/Roles.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

contract KUMAAddressProvider is IKUMAAddressProvider, UUPSUpgradeable, Initializable {
    IAccessControl private _accessController;

    address private _KBCToken;
    address private _rateFeed;
    address private _KUMABondToken;

    mapping(bytes32 => address) private _KIBToken;
    mapping(bytes32 => address) private _KUMASwap;
    mapping(bytes32 => address) private _KUMAFeeCollector;

    modifier onlyValidAddress(address _address) {
        if (_address == address(0)) {
            revert Errors.CANNOT_SET_TO_ADDRESS_ZERO();
        }
        _;
    }

    modifier onlyManager() {
        if (!_accessController.hasRole(Roles.KUMA_MANAGER_ROLE, msg.sender)) {
            revert Errors.ACCESS_CONTROL_ACCOUNT_IS_MISSING_ROLE(msg.sender, Roles.KUMA_MANAGER_ROLE);
        }
        _;
    }

    constructor() initializer {}

    function initialize(IAccessControl accessController) external override initializer {
        if (address(accessController) == address(0)) {
            revert Errors.CANNOT_SET_TO_ADDRESS_ZERO();
        }
        _accessController = accessController;

        emit AccessControllerSet(address(accessController));
    }

    function setKBCToken(address KBCToken) external override onlyManager onlyValidAddress(KBCToken) {
        _KBCToken = KBCToken;
        emit KBCTokenSet(KBCToken);
    }

    function setRateFeed(address rateFeed) external override onlyManager onlyValidAddress(rateFeed) {
        _rateFeed = rateFeed;
        emit RateFeedSet(rateFeed);
    }

    function setKUMABondToken(address KUMABondToken) external override onlyManager onlyValidAddress(KUMABondToken) {
        _KUMABondToken = KUMABondToken;
        emit KUMABondTokenSet(KUMABondToken);
    }

    function setKIBToken(bytes4 currency, bytes4 country, uint64 term, address KIBToken)
        external
        override
        onlyManager
        onlyValidAddress(KIBToken)
    {
        bytes32 riskCategory = _checkRiskCategory(currency, country, term);
        if (IKIBToken(KIBToken).getRiskCategory() != riskCategory) {
            revert Errors.RISK_CATEGORY_MISMATCH();
        }
        _KIBToken[riskCategory] = KIBToken;
        emit KIBTokenSet(KIBToken, currency, country, term);
    }

    function setKUMASwap(bytes4 currency, bytes4 country, uint64 term, address KUMASwap)
        external
        override
        onlyManager
        onlyValidAddress(KUMASwap)
    {
        bytes32 riskCategory = _checkRiskCategory(currency, country, term);
        if (IKUMASwap(KUMASwap).getRiskCategory() != riskCategory) {
            revert Errors.RISK_CATEGORY_MISMATCH();
        }
        _KUMASwap[riskCategory] = KUMASwap;
        emit KUMASwapSet(KUMASwap, currency, country, term);
    }

    function setKUMAFeeCollector(bytes4 currency, bytes4 country, uint64 term, address KUMAFeeCollector)
        external
        override
        onlyManager
        onlyValidAddress(KUMAFeeCollector)
    {
        bytes32 riskCategory = _checkRiskCategory(currency, country, term);
        if (IKUMAFeeCollector(KUMAFeeCollector).getRiskCategory() != riskCategory) {
            revert Errors.RISK_CATEGORY_MISMATCH();
        }
        _KUMAFeeCollector[riskCategory] = KUMAFeeCollector;
        emit KUMAFeeCollectorSet(KUMAFeeCollector, currency, country, term);
    }

    function getAccessController() external view override returns (IAccessControl) {
        return _accessController;
    }

    function getKBCToken() external view override returns (address) {
        return _KBCToken;
    }

    function getRateFeed() external view override returns (address) {
        return _rateFeed;
    }

    function getKUMABondToken() external view override returns (address) {
        return _KUMABondToken;
    }

    function getKIBToken(bytes32 riskCategory) external view override returns (address) {
        return _KIBToken[riskCategory];
    }

    function getKUMASwap(bytes32 riskCategory) external view override returns (address) {
        return _KUMASwap[riskCategory];
    }

    function getKUMAFeeCollector(bytes32 riskCategory) external view override returns (address) {
        return _KUMAFeeCollector[riskCategory];
    }

    function _checkRiskCategory(bytes4 currency, bytes4 country, uint64 term) internal pure returns (bytes32) {
        if (currency == bytes4(0) || country == bytes4(0) || term == 0) {
            revert Errors.INVALID_RISK_CATEGORY();
        }
        return keccak256(abi.encode(currency, country, term));
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyManager {}
}
