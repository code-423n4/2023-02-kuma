// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Errors} from "./libraries/Errors.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IKUMAAddressProvider} from "./interfaces/IKUMAAddressProvider.sol";
import {IKUMAFeeCollector} from "./interfaces/IKUMAFeeCollector.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {Roles} from "./libraries/Roles.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

contract KUMAFeeCollector is IKUMAFeeCollector, UUPSUpgradeable, Initializable {
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;

    IKUMAAddressProvider private _KUMAAddressProvider;
    bytes32 private _riskCategory;
    EnumerableSet.AddressSet private _payees;
    uint256 private _totalShares;

    mapping(address => uint256) private _shares;

    modifier onlyManager() {
        if (!_KUMAAddressProvider.getAccessController().hasRole(Roles.KUMA_MANAGER_ROLE, msg.sender)) {
            revert Errors.ACCESS_CONTROL_ACCOUNT_IS_MISSING_ROLE(msg.sender, Roles.KUMA_MANAGER_ROLE);
        }
        _;
    }

    constructor() initializer {}

    function initialize(IKUMAAddressProvider KUMAAddressProvider, bytes4 currency, bytes4 country, uint64 term)
        external
        override
        initializer
    {
        if (address(KUMAAddressProvider) == address(0)) {
            revert Errors.CANNOT_SET_TO_ADDRESS_ZERO();
        }
        if (currency == bytes4(0) || country == bytes4(0) || term == 0) {
            revert Errors.WRONG_RISK_CATEGORY();
        }
        _KUMAAddressProvider = KUMAAddressProvider;
        _riskCategory = keccak256(abi.encode(currency, country, term));

        emit KUMAAddressProviderSet(address(KUMAAddressProvider));
        emit RiskCategorySet(_riskCategory);
    }

    /**
     * @notice Releases the accumulated fee income to the payees.
     * @dev Uses _totalShares to calculate correct share.
     */
    function release() external override {
        IERC20 KIBToken = IERC20(_KUMAAddressProvider.getKIBToken(_riskCategory));
        uint256 availableIncome = KIBToken.balanceOf(address(this));

        if (availableIncome == 0) {
            revert Errors.NO_AVAILABLE_INCOME();
        }
        if (_payees.length() == 0) {
            revert Errors.NO_PAYEES();
        }

        _release(KIBToken, availableIncome);
    }

    /**
     * @notice Adds a payee.
     * @dev Will update totalShares and therefore reduce the relative share of all other payees.
     * @dev Will release existing fees before the update.
     * @param payee The address of the payee to add.
     * @param share The number of shares owned by the payee.
     */
    function addPayee(address payee, uint256 share) external override onlyManager {
        if (_payees.contains(payee)) {
            revert Errors.PAYEE_ALREADY_EXISTS();
        }
        if (payee == address(0)) {
            revert Errors.CANNOT_SET_TO_ADDRESS_ZERO();
        }
        if (share == 0) {
            revert Errors.SHARE_CANNOT_BE_ZERO();
        }

        _releaseIfAvailableIncome();

        _payees.add(payee);
        _shares[payee] = share;
        _totalShares += share;

        emit PayeeAdded(payee, share);
    }

    /**
     * @notice Removes a payee.
     * @dev Will update totalShares and therefore increase the relative share of all other payees.
     * @dev Will release existing fees before the update.
     * @param payee The address of the payee to add.
     */
    function removePayee(address payee) external override onlyManager {
        if (!_payees.contains(payee)) {
            revert Errors.PAYEE_DOES_NOT_EXIST();
        }

        _releaseIfAvailableIncome();

        _payees.remove(payee);
        _totalShares -= _shares[payee];
        delete _shares[payee];

        emit PayeeRemoved(payee);
    }

    /**
     * @notice Updates an existing payee's share.
     * @dev Will release existing fees before the update.
     * @param payee Payee's address.
     * @param share New payee's share.
     */
    function updatePayeeShare(address payee, uint256 share) external onlyManager {
        if (!_payees.contains(payee)) {
            revert Errors.PAYEE_DOES_NOT_EXIST();
        }
        if (share == 0) {
            revert Errors.SHARE_CANNOT_BE_ZERO();
        }

        _releaseIfAvailableIncome();

        uint256 currentShare = _shares[payee];

        if (currentShare < share) {
            _totalShares += share - currentShare;
        } else if (currentShare > share) {
            _totalShares -= currentShare - share;
        }

        _shares[payee] = share;

        emit ShareUpdated(payee, share);
    }

    /**
     * @notice Updates the payee configuration to a new one.
     * @dev Will release existing fees before the update.
     * @param newPayees Array of  new payees
     * @param newShares Array of shares for each new payee
     */
    function changePayees(address[] calldata newPayees, uint256[] calldata newShares) external override onlyManager {
        if (newPayees.length != newShares.length) {
            revert Errors.PAYEES_AND_SHARES_MISMATCHED(newPayees.length, newShares.length);
        }
        if (newPayees.length == 0) {
            revert Errors.NO_PAYEES();
        }

        _releaseIfAvailableIncome();

        uint256 payeesLength = _payees.length();

        if (payeesLength > 0) {
            for (uint256 i = payeesLength; i > 0; i--) {
                address payee = _payees.at(i - 1);
                _payees.remove(payee);
                delete _shares[payee];
                emit PayeeRemoved(payee);
            }
            _totalShares = 0;
        }

        for (uint256 i; i < newPayees.length; i++) {
            if (newPayees[i] == address(0)) {
                revert Errors.CANNOT_SET_TO_ADDRESS_ZERO();
            }
            if (newShares[i] == 0) {
                revert Errors.SHARE_CANNOT_BE_ZERO();
            }

            address payee = newPayees[i];
            _payees.add(payee);
            _shares[payee] = newShares[i];
            _totalShares += newShares[i];

            emit PayeeAdded(payee, newShares[i]);
        }
    }

    function getKUMAAddressProvider() external view returns (IKUMAAddressProvider) {
        return _KUMAAddressProvider;
    }

    function getRiskCategory() external view returns (bytes32) {
        return _riskCategory;
    }

    /**
     * @notice Internal helper function to release an available income to a all payees.
     * @dev Uses totalShares to calculate correct share
     * @param KIBToken Cached KIBToken for gas savings.
     * @param availableIncome Available income to release to payees.
     */
    function _release(IERC20 KIBToken, uint256 availableIncome) private {
        uint256 totalShares = _totalShares;

        for (uint256 i; i < _payees.length(); i++) {
            address payee = _payees.at(i);
            KIBToken.safeTransfer(payee, availableIncome * _shares[payee] / totalShares);
        }

        emit FeeReleased(availableIncome);
    }

    /**
     * @notice Internal helper function to release an available income to a all payees if there is an availble income.
     */
    function _releaseIfAvailableIncome() private {
        IERC20 KIBToken = IERC20(_KUMAAddressProvider.getKIBToken(_riskCategory));
        uint256 availableIncome = KIBToken.balanceOf(address(this));

        if (availableIncome > 0) {
            _release(KIBToken, availableIncome);
        }
    }

    /**
     * @return Array of current payees.
     */
    function getPayees() external view returns (address[] memory) {
        return _payees.values();
    }

    /**
     * @return Total shares.
     */
    function getTotalShares() external view returns (uint256) {
        return _totalShares;
    }

    /**
     * @return Share of specific payee.
     */
    function getShare(address payee) external view returns (uint256) {
        return _shares[payee];
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyManager {}
}
