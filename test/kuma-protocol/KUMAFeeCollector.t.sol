// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "./BaseSetUp.t.sol";
import {Errors} from "@kuma/libraries/Errors.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

contract KUMAFeeCollectorTest is BaseSetUp {
    using Roles for bytes32;

    event PayeeAdded(address indexed payee, uint256 share);
    event PayeeRemoved(address indexed payee);
    event FeeReleased(uint256 income);
    event KUMAAddressProviderSet(address KUMAAddressProvider);
    event ShareUpdated(address indexed payee, uint256 newShare);
    event RiskCategorySet(bytes32 riskCategory);

    address[] private _payees;
    uint256[] private _shares;

    function setUp() public {
        _payees.push(vm.addr(6));
        _payees.push(vm.addr(7));
        _payees.push(vm.addr(8));
        _payees.push(vm.addr(9));

        _shares.push(25);
        _shares.push(25);
        _shares.push(25);
        _shares.push(25);

        _KUMAFeeCollector.changePayees(_payees, _shares);

        vm.mockCall(
            address(_KUMAAccessController),
            abi.encodeWithSelector(
                IAccessControl.hasRole.selector, Roles.KUMA_MINT_ROLE.toGranularRole(_RISK_CATEGORY), address(this)
            ),
            abi.encode(true)
        );
    }

    function test_initialize() public {
        assertEq(address(_KUMAFeeCollector.getKUMAAddressProvider()), address(_KUMAAddressProvider));
        assertEq(_KUMAFeeCollector.getRiskCategory(), _RISK_CATEGORY);

        KUMAFeeCollector newKUMAFeeCollector = new KUMAFeeCollector();

        vm.expectEmit(false, false, false, true);
        emit KUMAAddressProviderSet(address(_KUMAAddressProvider));
        vm.expectEmit(false, false, false, true);
        emit RiskCategorySet(_RISK_CATEGORY);

        IKUMAFeeCollector(
            _deployUUPSProxy(
                address(newKUMAFeeCollector),
                abi.encodeWithSelector(
                    IKUMAFeeCollector.initialize.selector, _KUMAAddressProvider, _CURRENCY, _COUNTRY, _TERM
                )
            )
        );
    }

    function test_Initialize_RevertWhen_InitializedWithInvalidParameters() public {
        KUMAFeeCollector newKUMAFeeCollector = new KUMAFeeCollector();
        vm.expectRevert(Errors.CANNOT_SET_TO_ADDRESS_ZERO.selector);
        _deployUUPSProxy(
            address(newKUMAFeeCollector),
            abi.encodeWithSelector(IKUMAFeeCollector.initialize.selector, address(0), _CURRENCY, _COUNTRY, _TERM)
        );

        vm.expectRevert(Errors.WRONG_RISK_CATEGORY.selector);
        _deployUUPSProxy(
            address(newKUMAFeeCollector),
            abi.encodeWithSelector(
                IKUMAFeeCollector.initialize.selector, _KUMAAddressProvider, bytes4(0), _COUNTRY, _TERM
            )
        );

        vm.expectRevert(Errors.WRONG_RISK_CATEGORY.selector);
        _deployUUPSProxy(
            address(newKUMAFeeCollector),
            abi.encodeWithSelector(
                IKUMAFeeCollector.initialize.selector, _KUMAAddressProvider, _CURRENCY, bytes4(0), _TERM
            )
        );

        vm.expectRevert(Errors.WRONG_RISK_CATEGORY.selector);
        _deployUUPSProxy(
            address(newKUMAFeeCollector),
            abi.encodeWithSelector(IKUMAFeeCollector.initialize.selector, _KUMAAddressProvider, _CURRENCY, _COUNTRY, 0)
        );
    }

    // ==================================== Release ====================================

    function test_release() public {
        _KIBToken.mint(address(_KUMAFeeCollector), 4 ether);
        vm.expectEmit(false, false, false, true);
        emit FeeReleased(4 ether);
        _KUMAFeeCollector.release();

        for (uint256 i; i < 4; i++) {
            assertEq(_KIBToken.balanceOf(_payees[i]), 1 ether);
        }
    }

    function test_release_RevertWhen_NoAvailableIncome() public {
        vm.expectRevert(Errors.NO_AVAILABLE_INCOME.selector);
        _KUMAFeeCollector.release();
    }

    function test_release_RevertWhen_NoPayees() public {
        for (uint256 i; i < 4; i++) {
            _KUMAFeeCollector.removePayee(_payees[i]);
        }
        _KIBToken.mint(address(_KUMAFeeCollector), 4 ether);
        vm.expectRevert(Errors.NO_PAYEES.selector);
        _KUMAFeeCollector.release();
    }

    // ==================================== Add Payee ====================================

    function test_addPayee_Without_Income() public {
        address newPayee = vm.addr(10);
        uint256 newPayeeShare = 25;
        vm.expectEmit(true, false, false, true);
        emit PayeeAdded(newPayee, newPayeeShare);
        _KUMAFeeCollector.addPayee(newPayee, newPayeeShare);

        assertEq(_KUMAFeeCollector.getPayees().length, 5);
        assertEq(_KUMAFeeCollector.getPayees()[4], newPayee);
        assertEq(_KUMAFeeCollector.getShare(newPayee), newPayeeShare);
        assertEq(_KUMAFeeCollector.getTotalShares(), 125);
    }

    function test_addPayee_WithIncome() public {
        address newPayee = vm.addr(10);
        uint256 newPayeeShare = 25;
        _KIBToken.mint(address(_KUMAFeeCollector), 4 ether);
        _KUMAFeeCollector.addPayee(newPayee, newPayeeShare);

        for (uint256 i; i < 4; i++) {
            assertEq(_KIBToken.balanceOf(_payees[i]), 1 ether);
        }
    }

    function test_AddPayee_WithAlreadyExistingPayee() public {
        vm.expectRevert(Errors.PAYEE_ALREADY_EXISTS.selector);
        _KUMAFeeCollector.addPayee(vm.addr(6), 25);
    }

    function testAddAddressZeroAsPayee() public {
        vm.expectRevert(Errors.CANNOT_SET_TO_ADDRESS_ZERO.selector);
        _KUMAFeeCollector.addPayee(address(0), 25);
    }

    function test_addPayee_RevertWhen_ZeroShare() public {
        vm.expectRevert(Errors.SHARE_CANNOT_BE_ZERO.selector);
        _KUMAFeeCollector.addPayee(vm.addr(10), 0);
    }

    function test_addPayee_RevertWhen_NotManager() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.ACCESS_CONTROL_ACCOUNT_IS_MISSING_ROLE.selector, _alice, Roles.KUMA_MANAGER_ROLE
            )
        );
        vm.prank(_alice);
        _KUMAFeeCollector.addPayee(vm.addr(10), 25);
    }

    // ==================================== Remove Payee ====================================

    function test_removePayee_WithoutIncome() public {
        address removedPayee = vm.addr(7);
        vm.expectEmit(true, false, false, false);
        emit PayeeRemoved(removedPayee);
        _KUMAFeeCollector.removePayee(removedPayee);

        assertEq(_KUMAFeeCollector.getPayees().length, 3);
        assertEq(_KUMAFeeCollector.getPayees()[1], vm.addr(9));
        assertEq(_KUMAFeeCollector.getTotalShares(), 75);
        assertEq(_KUMAFeeCollector.getShare(removedPayee), 0);
    }

    function test_removePayee_WithIncome() public {
        _KIBToken.mint(address(_KUMAFeeCollector), 4 ether);
        _KUMAFeeCollector.removePayee(vm.addr(7));

        for (uint256 i; i < 4; i++) {
            assertEq(_KIBToken.balanceOf(_payees[i]), 1 ether);
        }
    }

    function test_removePayee_RevertWhen_NonExistingPayee() public {
        vm.expectRevert(Errors.PAYEE_DOES_NOT_EXIST.selector);
        _KUMAFeeCollector.removePayee(vm.addr(11));
    }

    function test_removePayee_RevertWhen_NotManager() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.ACCESS_CONTROL_ACCOUNT_IS_MISSING_ROLE.selector, _alice, Roles.KUMA_MANAGER_ROLE
            )
        );
        vm.prank(_alice);
        _KUMAFeeCollector.removePayee(vm.addr(7));
    }

    // ==================================== Update Payee Share ====================================

    function test_updatePayeeShare_WihoutIncomeAndHigherShare() public {
        address payee = vm.addr(6);
        uint256 newShare = 50;
        vm.expectEmit(true, false, false, true);
        emit ShareUpdated(payee, newShare);
        _KUMAFeeCollector.updatePayeeShare(payee, newShare);

        assertEq(_KUMAFeeCollector.getTotalShares(), 125);
        assertEq(_KUMAFeeCollector.getShare(payee), 50);
    }

    function test_updatePayeeShare_WihoutIncomeAndLowerShare() public {
        address payee = vm.addr(6);
        uint256 newShare = 15;
        vm.expectEmit(true, false, false, true);
        emit ShareUpdated(payee, newShare);
        _KUMAFeeCollector.updatePayeeShare(payee, newShare);

        assertEq(_KUMAFeeCollector.getTotalShares(), 90);
        assertEq(_KUMAFeeCollector.getShare(payee), 15);
    }

    function test_updatePayeeShare_WithIncomeAndHigherShare() public {
        address payee = vm.addr(6);
        uint256 newShare = 50;
        _KIBToken.mint(address(_KUMAFeeCollector), 4 ether);
        _KUMAFeeCollector.updatePayeeShare(payee, newShare);

        for (uint256 i; i < 4; i++) {
            assertEq(_KIBToken.balanceOf(_payees[i]), 1 ether);
        }
    }

    function test_updatePayeeShare_RevertWhen_NonExistingPayee() public {
        vm.expectRevert(Errors.PAYEE_DOES_NOT_EXIST.selector);
        _KUMAFeeCollector.updatePayeeShare(vm.addr(11), 50);
    }

    function test_updatePayeeShare_RevertWhen_ZeroShare() public {
        vm.expectRevert(Errors.SHARE_CANNOT_BE_ZERO.selector);
        _KUMAFeeCollector.updatePayeeShare(vm.addr(6), 0);
    }

    function test_updatePayeeShare_RevertWhen_NotManager() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.ACCESS_CONTROL_ACCOUNT_IS_MISSING_ROLE.selector, _alice, Roles.KUMA_MANAGER_ROLE
            )
        );
        vm.prank(_alice);
        _KUMAFeeCollector.updatePayeeShare(vm.addr(7), 50);
    }

    // ==================================== Change Payees ====================================

    function test_changePayees_Without_Income() public {
        address[] memory newPayees = new address[](2);
        uint256[] memory newShares = new uint256[](2);

        newPayees[0] = vm.addr(10);
        newPayees[1] = vm.addr(11);
        newShares[0] = 50;
        newShares[1] = 50;

        vm.expectEmit(true, false, false, true);
        emit PayeeRemoved(_payees[3]);
        vm.expectEmit(true, false, false, true);
        emit PayeeRemoved(_payees[2]);
        vm.expectEmit(true, false, false, true);
        emit PayeeRemoved(_payees[1]);
        vm.expectEmit(true, false, false, true);
        emit PayeeRemoved(_payees[0]);
        vm.expectEmit(true, false, false, true);
        emit PayeeAdded(newPayees[0], newShares[0]);
        vm.expectEmit(true, false, false, true);
        emit PayeeAdded(newPayees[1], newShares[1]);
        _KUMAFeeCollector.changePayees(newPayees, newShares);

        assertEq(_KUMAFeeCollector.getPayees().length, 2);
        assertEq(_KUMAFeeCollector.getTotalShares(), 100);
        assertEq(_KUMAFeeCollector.getPayees()[0], newPayees[0]);
        assertEq(_KUMAFeeCollector.getPayees()[1], newPayees[1]);
        assertEq(_KUMAFeeCollector.getShare(newPayees[0]), newShares[0]);
        assertEq(_KUMAFeeCollector.getShare(newPayees[1]), newShares[1]);
    }

    function test_changePayees_WithIncome() public {
        address[] memory newPayees = new address[](2);
        uint256[] memory newShares = new uint256[](2);

        newPayees[0] = vm.addr(10);
        newPayees[1] = vm.addr(11);
        newShares[0] = 50;
        newShares[1] = 50;

        _KIBToken.mint(address(_KUMAFeeCollector), 4 ether);
        _KUMAFeeCollector.changePayees(newPayees, newShares);

        for (uint256 i; i < 4; i++) {
            assertEq(_KIBToken.balanceOf(_payees[i]), 1 ether);
        }
    }

    function test_changePayees_RevertWhen_PayeesAndSharesMistmached() public {
        address[] memory newPayees = new address[](2);
        uint256[] memory newShares = new uint256[](1);

        newPayees[0] = vm.addr(10);
        newPayees[1] = vm.addr(11);
        newShares[0] = 50;

        vm.expectRevert(abi.encodeWithSelector(Errors.PAYEES_AND_SHARES_MISMATCHED.selector, 2, 1));
        _KUMAFeeCollector.changePayees(newPayees, newShares);
    }

    function test_changePayees_RevertWhen_NoPayees() public {
        address[] memory newPayees;
        uint256[] memory newShares;

        vm.expectRevert(Errors.NO_PAYEES.selector);
        _KUMAFeeCollector.changePayees(newPayees, newShares);
    }

    function test_changePayees_RevertWhen_OnePayeeSetToAddressZero() public {
        address[] memory newPayees = new address[](2);
        uint256[] memory newShares = new uint256[](2);

        newPayees[0] = vm.addr(10);
        newPayees[1] = address(0);
        newShares[0] = 50;
        newShares[1] = 50;

        vm.expectRevert(Errors.CANNOT_SET_TO_ADDRESS_ZERO.selector);
        _KUMAFeeCollector.changePayees(newPayees, newShares);
    }

    function test_changePayees_RevertWhen_OnePayeeShareSetToZero() public {
        address[] memory newPayees = new address[](2);
        uint256[] memory newShares = new uint256[](2);

        newPayees[0] = vm.addr(10);
        newPayees[1] = vm.addr(11);
        newShares[0] = 50;
        newShares[1] = 0;

        vm.expectRevert(Errors.SHARE_CANNOT_BE_ZERO.selector);
        _KUMAFeeCollector.changePayees(newPayees, newShares);
    }

    function test_changePayees_RevertWhen_NotManager() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.ACCESS_CONTROL_ACCOUNT_IS_MISSING_ROLE.selector, _alice, Roles.KUMA_MANAGER_ROLE
            )
        );
        address[] memory newPayees = new address[](2);
        uint256[] memory newShares = new uint256[](2);

        newPayees[0] = vm.addr(10);
        newPayees[1] = vm.addr(11);
        newShares[0] = 50;
        newShares[1] = 50;

        vm.prank(_alice);
        _KUMAFeeCollector.changePayees(newPayees, newShares);
    }

    function test_upgrade_RevertWhen_CallerIsNotManager() public {
        KUMAFeeCollector newKUMAFeeCollector = new KUMAFeeCollector();
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.ACCESS_CONTROL_ACCOUNT_IS_MISSING_ROLE.selector, _alice, Roles.KUMA_MANAGER_ROLE
            )
        );
        vm.prank(_alice);
        UUPSUpgradeable(address(_KUMAFeeCollector)).upgradeTo(address(newKUMAFeeCollector));
    }
}
