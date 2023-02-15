// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "./BaseSetUp.t.sol";
import {Errors} from "@kuma/libraries/Errors.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

contract KUMAAddressProviderTest is BaseSetUp {
    event AccessControllerSet(address accessController);
    event KBCTokenSet(address KBCToken);
    event RateFeedSet(address rateFeed);
    event KUMABondTokenSet(address KUMABondToken);
    event KIBTokenSet(address KIBToken, bytes4 indexed currency, bytes4 indexed country, uint64 indexed term);
    event KUMASwapSet(address KUMASwap, bytes4 indexed currency, bytes4 indexed country, uint64 indexed term);
    event KUMAFeeCollectorSet(
        address KUMAFeeCollector, bytes4 indexed currency, bytes4 indexed country, uint64 indexed term
    );

    bytes4 internal constant _CURRENCY_ = "US";
    bytes4 internal constant _COUNTRY_ = "US";
    uint64 internal constant _TERM_ = 365 days * 3;
    bytes32 internal constant _RISK_CATEGORY_ = keccak256(abi.encode(_CURRENCY_, _COUNTRY_, _TERM_));

    address internal _KIBToken_;
    address internal _KUMASwap_;
    address internal _KUMAFeeCollector_;

    function setUp() public {
        // Deploy new risk category contracts
        KIBToken KIBToken_ = new KIBToken();
        _KIBToken_ = _deployUUPSProxy(
            address(KIBToken_),
            abi.encodeWithSelector(
                IKIBToken.initialize.selector,
                _NAME,
                _SYMBOL,
                _EPOCH_LENGTH,
                _KUMAAddressProvider,
                _CURRENCY_,
                _COUNTRY_,
                _TERM_
            )
        );

        KUMASwap KUMASwap_ = new KUMASwap();
        _KUMASwap_ = _deployUUPSProxy(
            address(KUMASwap_),
            abi.encodeWithSelector(
                IKUMASwap.initialize.selector,
                _KUMAAddressProvider,
                IERC20(address(_deprecationStableCoin)),
                _CURRENCY_,
                _COUNTRY_,
                _TERM_
            )
        );

        KUMAFeeCollector KUMAFeeCollector_ = new KUMAFeeCollector();
        _KUMAFeeCollector_ = _deployUUPSProxy(
            address(KUMAFeeCollector_),
            abi.encodeWithSelector(
                IKUMAFeeCollector.initialize.selector, _KUMAAddressProvider, _CURRENCY_, _COUNTRY_, _TERM_
            )
        );
    }

    function test_initialize() public {
        assertEq(address(_KUMAAddressProvider.getAccessController()), address(_KUMAAccessController));
        KUMAAddressProvider newKUMAAddressProvider = new KUMAAddressProvider();

        vm.expectEmit(false, false, false, true);
        emit AccessControllerSet(address(_KUMAAccessController));

        IKUMAAddressProvider(
            _deployUUPSProxy(
                address(newKUMAAddressProvider),
                abi.encodeWithSelector(IKUMAAddressProvider.initialize.selector, _KUMAAccessController)
            )
        );
    }

    function test_initialization_RevertWhen_InitializedWithInvalidParameters() public {
        KUMAAddressProvider newKUMAAddressProvider = new KUMAAddressProvider();
        vm.expectRevert(Errors.CANNOT_SET_TO_ADDRESS_ZERO.selector);
        _deployUUPSProxy(
            address(newKUMAAddressProvider),
            abi.encodeWithSelector(IKUMAAddressProvider.initialize.selector, address(0))
        );
    }

    function test_setKBCToken() public {
        address newKBCToken = vm.addr(10);
        vm.expectEmit(false, false, false, true);
        emit KBCTokenSet(newKBCToken);
        _KUMAAddressProvider.setKBCToken(newKBCToken);
        assertEq(_KUMAAddressProvider.getKBCToken(), newKBCToken);
    }

    function test_setKBCToken_RevertWhen_SetToAddressZero() public {
        vm.expectRevert(Errors.CANNOT_SET_TO_ADDRESS_ZERO.selector);
        _KUMAAddressProvider.setKBCToken(address(0));
    }

    function test_setKBCToken_RevertWhen_NotManager() public {
        address newKBCToken = vm.addr(10);
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.ACCESS_CONTROL_ACCOUNT_IS_MISSING_ROLE.selector, _alice, Roles.KUMA_MANAGER_ROLE
            )
        );
        vm.prank(_alice);
        _KUMAAddressProvider.setKBCToken(newKBCToken);
    }

    function test_setRateFeed() public {
        address newRateFeed = vm.addr(10);
        vm.expectEmit(false, false, false, true);
        emit RateFeedSet(newRateFeed);
        _KUMAAddressProvider.setRateFeed(newRateFeed);
        assertEq(_KUMAAddressProvider.getRateFeed(), newRateFeed);
    }

    function test_setRateFeed_RevertWhen_SetToAddressZero() public {
        vm.expectRevert(Errors.CANNOT_SET_TO_ADDRESS_ZERO.selector);
        _KUMAAddressProvider.setRateFeed(address(0));
    }

    function test_setRateFeed_RevertWhen_NotManager() public {
        address newRateFeed = vm.addr(10);
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.ACCESS_CONTROL_ACCOUNT_IS_MISSING_ROLE.selector, _alice, Roles.KUMA_MANAGER_ROLE
            )
        );
        vm.prank(_alice);
        _KUMAAddressProvider.setKBCToken(newRateFeed);
    }

    function test_setKUMABondToken() public {
        address newKUMABondToken = vm.addr(10);
        vm.expectEmit(false, false, false, true);
        emit KUMABondTokenSet(newKUMABondToken);
        _KUMAAddressProvider.setKUMABondToken(newKUMABondToken);
        assertEq(_KUMAAddressProvider.getKUMABondToken(), newKUMABondToken);
    }

    function test_setKUMABondToken_SetToAddressZero() public {
        vm.expectRevert(Errors.CANNOT_SET_TO_ADDRESS_ZERO.selector);
        _KUMAAddressProvider.setKUMABondToken(address(0));
    }

    function test_setKUMABondToken_RevertWhen_NotManager() public {
        address newKUMABondToken = vm.addr(10);
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.ACCESS_CONTROL_ACCOUNT_IS_MISSING_ROLE.selector, _alice, Roles.KUMA_MANAGER_ROLE
            )
        );
        vm.prank(_alice);
        _KUMAAddressProvider.setKBCToken(newKUMABondToken);
    }

    function test_setKIBToken() public {
        vm.expectEmit(true, true, true, true);
        emit KIBTokenSet(_KIBToken_, _CURRENCY_, _COUNTRY_, _TERM_);
        _KUMAAddressProvider.setKIBToken(_CURRENCY_, _COUNTRY_, _TERM_, _KIBToken_);
        assertEq(_KUMAAddressProvider.getKIBToken(_RISK_CATEGORY_), _KIBToken_);
    }

    function test_SetKIBToken_RevertWhen_SetToAddressZero() public {
        vm.expectRevert(Errors.CANNOT_SET_TO_ADDRESS_ZERO.selector);
        _KUMAAddressProvider.setKIBToken(_CURRENCY, _COUNTRY, _TERM, address(0));
    }

    function test_setKIBToken_RevertWhen_SetToInvalidRiskCategory() public {
        vm.expectRevert(Errors.INVALID_RISK_CATEGORY.selector);
        _KUMAAddressProvider.setKIBToken(bytes4(0), _COUNTRY_, _TERM_, _KIBToken_);
        vm.expectRevert(Errors.INVALID_RISK_CATEGORY.selector);
        _KUMAAddressProvider.setKIBToken(_CURRENCY_, bytes4(0), _TERM_, _KIBToken_);
        vm.expectRevert(Errors.INVALID_RISK_CATEGORY.selector);
        _KUMAAddressProvider.setKIBToken(_CURRENCY_, _COUNTRY_, 0, _KIBToken_);
    }

    function test_setKIBToken_RevertWhen_MismatchInRiskCategories() public {
        vm.expectRevert(Errors.RISK_CATEGORY_MISMATCH.selector);
        _KUMAAddressProvider.setKIBToken(_CURRENCY, _COUNTRY, _TERM, _KIBToken_);
    }

    function test_setKIBToken_RevertWhen_NotManager() public {
        address newKIBToken = vm.addr(10);
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.ACCESS_CONTROL_ACCOUNT_IS_MISSING_ROLE.selector, _alice, Roles.KUMA_MANAGER_ROLE
            )
        );
        vm.prank(_alice);
        _KUMAAddressProvider.setKBCToken(newKIBToken);
    }

    function test_setKUMASwap() public {
        vm.expectEmit(true, true, true, true);
        emit KUMASwapSet(_KUMASwap_, _CURRENCY_, _COUNTRY_, _TERM_);
        _KUMAAddressProvider.setKUMASwap(_CURRENCY_, _COUNTRY_, _TERM_, _KUMASwap_);
        assertEq(_KUMAAddressProvider.getKUMASwap(_RISK_CATEGORY_), _KUMASwap_);
    }

    function test_setKUMASwap_RevertWhen_SetToAddressZero() public {
        vm.expectRevert(Errors.CANNOT_SET_TO_ADDRESS_ZERO.selector);
        _KUMAAddressProvider.setKUMASwap(_CURRENCY, _COUNTRY, _TERM, address(0));
    }

    function test_setKUMASwap_RevertWhen_SetToInvalidRiskCategory() public {
        vm.expectRevert(Errors.INVALID_RISK_CATEGORY.selector);
        _KUMAAddressProvider.setKUMASwap(bytes4(0), _COUNTRY, _TERM, _KUMASwap_);
        vm.expectRevert(Errors.INVALID_RISK_CATEGORY.selector);
        _KUMAAddressProvider.setKUMASwap(_CURRENCY, bytes4(0), _TERM, _KUMASwap_);
        vm.expectRevert(Errors.INVALID_RISK_CATEGORY.selector);
        _KUMAAddressProvider.setKUMASwap(_CURRENCY, _COUNTRY, 0, _KUMASwap_);
    }

    function test_setKUMASwap_RevertWhen_MismatchInRiskCategories() public {
        vm.expectRevert(Errors.RISK_CATEGORY_MISMATCH.selector);
        _KUMAAddressProvider.setKUMASwap(_CURRENCY, _COUNTRY, _TERM, _KUMASwap_);
    }

    function test_Set_KUMA_Swap_RevertWhen_NotManager() public {
        address newKUMASwap = vm.addr(10);
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.ACCESS_CONTROL_ACCOUNT_IS_MISSING_ROLE.selector, _alice, Roles.KUMA_MANAGER_ROLE
            )
        );
        vm.prank(_alice);
        _KUMAAddressProvider.setKUMASwap(_CURRENCY, _COUNTRY, _TERM, newKUMASwap);
    }

    function test_setKUMAFeeCollector() public {
        vm.expectEmit(true, true, true, true);
        emit KUMAFeeCollectorSet(_KUMAFeeCollector_, _CURRENCY_, _COUNTRY_, _TERM_);
        _KUMAAddressProvider.setKUMAFeeCollector(_CURRENCY_, _COUNTRY_, _TERM_, _KUMAFeeCollector_);
        assertEq(_KUMAAddressProvider.getKUMAFeeCollector(_RISK_CATEGORY_), _KUMAFeeCollector_);
    }

    function test_setKUMAFeeCollector_SetToAddressZero() public {
        vm.expectRevert(Errors.CANNOT_SET_TO_ADDRESS_ZERO.selector);
        _KUMAAddressProvider.setKUMAFeeCollector(_CURRENCY, _COUNTRY, _TERM, address(0));
    }

    function test_setKUMAFeeCollector_RevertWhen_SetToInvalidRiskCategory() public {
        vm.expectRevert(Errors.INVALID_RISK_CATEGORY.selector);
        _KUMAAddressProvider.setKUMAFeeCollector(bytes4(0), _COUNTRY, _TERM, _KUMAFeeCollector_);
        vm.expectRevert(Errors.INVALID_RISK_CATEGORY.selector);
        _KUMAAddressProvider.setKUMAFeeCollector(_CURRENCY, bytes4(0), _TERM, _KUMAFeeCollector_);
        vm.expectRevert(Errors.INVALID_RISK_CATEGORY.selector);
        _KUMAAddressProvider.setKUMAFeeCollector(_CURRENCY, _COUNTRY, 0, _KUMAFeeCollector_);
    }

    function test_setKUMAFeeCollector_withMismatchInRiskCategories() public {
        vm.expectRevert(Errors.RISK_CATEGORY_MISMATCH.selector);
        _KUMAAddressProvider.setKUMAFeeCollector(_CURRENCY, _COUNTRY, _TERM, _KUMAFeeCollector_);
    }

    function test_setKUMAFeeCollector_RevertWhen_NotManager() public {
        address newFeeCollector = vm.addr(10);
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.ACCESS_CONTROL_ACCOUNT_IS_MISSING_ROLE.selector, _alice, Roles.KUMA_MANAGER_ROLE
            )
        );
        vm.prank(_alice);
        _KUMAAddressProvider.setKUMAFeeCollector(_CURRENCY, _COUNTRY, _TERM, newFeeCollector);
    }

    function test_upgrade_RevertWhen_CallerIsNotManager() public {
        KUMAAddressProvider newKUMAAddressProvider = new KUMAAddressProvider();
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.ACCESS_CONTROL_ACCOUNT_IS_MISSING_ROLE.selector, _alice, Roles.KUMA_MANAGER_ROLE
            )
        );
        vm.prank(_alice);
        UUPSUpgradeable(address(_KUMAAddressProvider)).upgradeTo(address(newKUMAAddressProvider));
    }
}
