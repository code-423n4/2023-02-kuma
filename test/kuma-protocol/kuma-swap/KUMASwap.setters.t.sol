// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "./KUMASwapSetUp.t.sol";

contract KUMASwapSetters is KUMASwapSetUp {
    using Roles for bytes32;

    function test_initialize() public {
        assertEq(address(_KUMASwap.getKUMAAddressProvider()), address(_KUMAAddressProvider));
        assertEq(address(_KUMASwap.getDeprecationStableCoin()), address(_deprecationStableCoin));
        assertEq(_KUMASwap.getRiskCategory(), _RISK_CATEGORY);
        assertEq(_KUMASwap.getMaxCoupons(), 365);

        KUMASwap newKUMASwap = new KUMASwap();

        vm.expectEmit(false, false, false, true);
        emit DeprecationStableCoinSet(address(0), address(_deprecationStableCoin));
        vm.expectEmit(false, false, false, true);
        emit KUMAAddressProviderSet(address(_KUMAAddressProvider));
        vm.expectEmit(false, false, false, true);
        emit RiskCategorySet(_RISK_CATEGORY);

        _deployUUPSProxy(
            address(newKUMASwap),
            abi.encodeWithSelector(
                IKUMASwap.initialize.selector, _KUMAAddressProvider, _deprecationStableCoin, _CURRENCY, _COUNTRY, _TERM
            )
        );
    }

    function test_initialize_RevertWhen_InitializedWithInvalidParameters() public {
        KUMASwap newKUMASwap = new KUMASwap();

        vm.expectRevert(Errors.CANNOT_SET_TO_ADDRESS_ZERO.selector);
        _deployUUPSProxy(
            address(newKUMASwap),
            abi.encodeWithSelector(
                IKUMASwap.initialize.selector,
                IKUMAAddressProvider(address(0)),
                _deprecationStableCoin,
                _CURRENCY,
                _COUNTRY,
                _TERM
            )
        );

        vm.expectRevert(Errors.CANNOT_SET_TO_ADDRESS_ZERO.selector);
        _deployUUPSProxy(
            address(newKUMASwap),
            abi.encodeWithSelector(
                IKUMASwap.initialize.selector, _KUMAAddressProvider, IERC20(address(0)), _CURRENCY, _COUNTRY, _TERM
            )
        );

        vm.expectRevert(Errors.WRONG_RISK_CATEGORY.selector);
        _deployUUPSProxy(
            address(newKUMASwap),
            abi.encodeWithSelector(
                IKUMASwap.initialize.selector, _KUMAAddressProvider, _deprecationStableCoin, bytes4(0), _COUNTRY, _TERM
            )
        );

        vm.expectRevert(Errors.WRONG_RISK_CATEGORY.selector);
        _deployUUPSProxy(
            address(newKUMASwap),
            abi.encodeWithSelector(
                IKUMASwap.initialize.selector, _KUMAAddressProvider, _deprecationStableCoin, bytes4(0), _COUNTRY, _TERM
            )
        );

        vm.expectRevert(Errors.WRONG_RISK_CATEGORY.selector);
        _deployUUPSProxy(
            address(newKUMASwap),
            abi.encodeWithSelector(
                IKUMASwap.initialize.selector, _KUMAAddressProvider, _deprecationStableCoin, _CURRENCY, bytes4(0), _TERM
            )
        );

        vm.expectRevert(Errors.WRONG_RISK_CATEGORY.selector);
        _deployUUPSProxy(
            address(newKUMASwap),
            abi.encodeWithSelector(
                IKUMASwap.initialize.selector, _KUMAAddressProvider, _deprecationStableCoin, _CURRENCY, _COUNTRY, 0
            )
        );
    }

    // ==================================== Pause ====================================

    /**
     * @notice Tests pause function.
     */
    function test_pause() public {
        _KUMASwap.pause();
        (, bytes memory data) = address(_KUMASwap).call(abi.encodeWithSelector(bytes4(keccak256("paused()"))));
        (bool paused) = abi.decode(data, (bool));
        assertTrue(paused);
    }

    /**
     * @notice Tests pause function access control.
     */
    function test_pause_RevertWhen_NotManager() public {
        vm.prank(_alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.ACCESS_CONTROL_ACCOUNT_IS_MISSING_ROLE.selector,
                _alice,
                Roles.KUMA_SWAP_PAUSE_ROLE.toGranularRole(_RISK_CATEGORY)
            )
        );
        _KUMASwap.pause();
    }

    // ==================================== Unpause ====================================

    /**
     * @notice Tests unpause function.
     */
    function test_unpause() public {
        _KUMASwap.pause();
        _KUMASwap.unpause();
        (, bytes memory data) = address(_KUMASwap).call(abi.encodeWithSelector(bytes4(keccak256("paused()"))));
        (bool paused) = abi.decode(data, (bool));
        assertFalse(paused);
    }

    /**
     * @notice Tests unpause function access control.
     */
    function test_unpause_RevertWhen_NotManager() public {
        _KUMASwap.pause();
        vm.prank(_alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.ACCESS_CONTROL_ACCOUNT_IS_MISSING_ROLE.selector,
                _alice,
                Roles.KUMA_SWAP_UNPAUSE_ROLE.toGranularRole(_RISK_CATEGORY)
            )
        );
        _KUMASwap.unpause();
    }

    // ==================================== Set Fees ====================================

    /**
     * @notice Tests setFees function.
     */
    function test_setFees() public {
        vm.expectEmit(false, false, false, true);
        emit FeeSet(1e3, 1 ether);
        _KUMASwap.setFees(1e3, 1 ether);
        assertEq(_KUMASwap.getVariableFee(), 1e3);
        assertEq(_KUMASwap.getFixedFee(), 1 ether);
    }

    /**
     * @notice Tests setFees access control.
     */
    function test_setFees_RevertWhen_NotManager() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.ACCESS_CONTROL_ACCOUNT_IS_MISSING_ROLE.selector, _alice, Roles.KUMA_MANAGER_ROLE
            )
        );
        vm.prank(_alice);
        _KUMASwap.setFees(1e3, 1 ether);
    }

    // ==================================== Set Deprecation Stable Coin ====================================

    /**
     * @notice Tests that manager can set a new deprecation stable coin.
     */
    function test_setDeprecationStableCoin() public {
        IERC20 newDeprecationStableCoin = IERC20(vm.addr(7));
        vm.expectEmit(false, false, false, true);
        emit DeprecationStableCoinSet(address(_deprecationStableCoin), address(newDeprecationStableCoin));
        _KUMASwap.setDeprecationStableCoin(newDeprecationStableCoin);
    }

    /**
     * @notice Tests that address zero cannot be set as a new deprecation stable coin.
     */
    function test_setDeprecationStableCoin_RevertWhen_Address_Zero() public {
        vm.expectRevert(Errors.CANNOT_SET_TO_ADDRESS_ZERO.selector);
        _KUMASwap.setDeprecationStableCoin(IERC20(address(0)));
    }

    /**
     * @notice Tests that a new deprecation stable coin cannot be set after deprecation mode is enabled.
     */
    function test_setDeprecationStableCoin_RevertWhen_DeprecationModeEnabled() public {
        _KUMASwap.initializeDeprecationMode();
        skip(2 days);
        _KUMASwap.enableDeprecationMode();
        vm.expectRevert(Errors.DEPRECATION_MODE_ENABLED.selector);
        _KUMASwap.setDeprecationStableCoin(IERC20(address(0)));
    }

    /**
     * @notice Test setDeprecationSatbleCoin access control.
     */
    function test_setDeprecationStableCoin_RevertWhen_NotManager() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.ACCESS_CONTROL_ACCOUNT_IS_MISSING_ROLE.selector, _alice, Roles.KUMA_MANAGER_ROLE
            )
        );
        vm.prank(_alice);
        _KUMASwap.setDeprecationStableCoin(_deprecationStableCoin);
    }

    // ==================================== Initialize Deprecation Mode ====================================

    /**
     * @notice Tests that manager can intialize deprecation mode.
     */
    function test_initializeDeprecationMode() public {
        vm.expectEmit(false, false, false, false);
        emit DeprecationModeInitialized();
        _KUMASwap.initializeDeprecationMode();

        assertTrue(_KUMASwap.isDeprecationInitialized());
        assertEq(_KUMASwap.getDeprecationInitializedAt(), block.timestamp);
    }

    /**
     * @notice Tests that manager canno initialize deprecation mode when it is already intialized.
     */
    function test_initializeDeprecationMode_RevertWhen_IsAlreadyInitialized() public {
        _KUMASwap.initializeDeprecationMode();
        vm.expectRevert(Errors.DEPRECATION_MODE_ALREADY_INITIALIZED.selector);
        _KUMASwap.initializeDeprecationMode();
    }

    /**
     * @notice Tests that deprecation mode cannot be initialized after it is enabled.
     */
    function test_initializeDeprecationMode_RevertWhen_IsAlreadyEnabled() public {
        _KUMASwap.initializeDeprecationMode();
        skip(2 days);
        _KUMASwap.enableDeprecationMode();
        vm.expectRevert(Errors.DEPRECATION_MODE_ENABLED.selector);
        _KUMASwap.initializeDeprecationMode();
    }

    /**
     * @notice Tests initializeDeprecationMode access control.
     */
    function test_initializeDeprecationMode_RevertWhen_NotManager() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.ACCESS_CONTROL_ACCOUNT_IS_MISSING_ROLE.selector, _alice, Roles.KUMA_MANAGER_ROLE
            )
        );
        vm.prank(_alice);
        _KUMASwap.initializeDeprecationMode();
    }

    // ==================================== Uninitialize Deprecation Mode ====================================

    /**
     * @notice Tests that manager can unintialize deprecation mode.
     */
    function test_uninitializeDeprecationMode() public {
        _KUMASwap.initializeDeprecationMode();
        vm.expectEmit(false, false, false, false);
        emit DeprecationModeUninitialized();
        _KUMASwap.uninitializeDeprecationMode();

        assertFalse(_KUMASwap.isDeprecationInitialized());
        assertEq(_KUMASwap.getDeprecationInitializedAt(), 0);
    }

    /**
     * @notice Tests that manager cannot uninitialize deprecation mode when it is not initialized.
     */
    function test_uninitializeDeprecationMode_RevertWhen_IsNotInitialized() public {
        vm.expectRevert(Errors.DEPRECATION_MODE_NOT_INITIALIZED.selector);
        _KUMASwap.uninitializeDeprecationMode();
    }

    /**
     * @notice Tests that deprecation mode cannot be uininitialized after it is enabled.
     */
    function test_uninitializeDeprecationMode_RevertWhen_IsAlreadyEnabled() public {
        _KUMASwap.initializeDeprecationMode();
        skip(2 days);
        _KUMASwap.enableDeprecationMode();
        vm.expectRevert(Errors.DEPRECATION_MODE_ENABLED.selector);
        _KUMASwap.uninitializeDeprecationMode();
    }

    /**
     * @notice Tests uninitializeDeprecationMode access control.
     */
    function test_uninitializeDeprecationMode_RevertWhen_NotManager() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.ACCESS_CONTROL_ACCOUNT_IS_MISSING_ROLE.selector, _alice, Roles.KUMA_MANAGER_ROLE
            )
        );
        vm.prank(_alice);
        _KUMASwap.uninitializeDeprecationMode();
    }

    // ==================================== Enable Deprecation Mode ====================================

    /**
     * @notice Tests that manager can enable depracation mode.
     */
    function test_enableDeprecationMode() public {
        _KUMABondToken.issueBond(address(this), _bond);
        _KUMASwap.sellBond(1);
        _KUMASwap.sellBond(2);
        _KUMASwap.initializeDeprecationMode();
        skip(2 days);
        vm.expectEmit(false, false, false, false);
        emit DeprecationModeEnabled();
        _KUMASwap.enableDeprecationMode();

        assertTrue(_KUMASwap.isDeprecated());
        assertEq(_KIBToken.getYield(), WadRayMath.RAY);
    }

    /**
     * @notice Tests that deprecation mode cannot be enabled if hasn't been initialized.
     */
    function test_enableDeprecationMode_RevertWhen_NotInitialized() public {
        vm.expectRevert(Errors.DEPRECATION_MODE_NOT_INITIALIZED.selector);
        _KUMASwap.enableDeprecationMode();
    }

    /**
     * @notice Tests that deprecation mode cannot be enable if it has been intialized less than 2 days ago.
     */
    function test_enableDeprecationMode_RevertWhen_TimeElapsedLt2Days() public {
        _KUMASwap.initializeDeprecationMode();
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.ELAPSED_TIME_SINCE_DEPRECATION_MODE_INITIALIZATION_TOO_SHORT.selector, 0, 2 days
            )
        );
        _KUMASwap.enableDeprecationMode();
    }

    /**
     * @notice Tests tha deprecation mode cannot be enable when it is already enabled.
     */
    function test_enableDeprecationMode_RevertWhen_AlreadyEnabled() public {
        _KUMASwap.initializeDeprecationMode();
        skip(2 days);
        _KUMASwap.enableDeprecationMode();
        vm.expectRevert(Errors.DEPRECATION_MODE_ENABLED.selector);
        _KUMASwap.enableDeprecationMode();
    }

    /**
     * @notice Tests enableDeprecationMode access control.
     */
    function test_enableDeprecationMode_RevertWhen_NotManager() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.ACCESS_CONTROL_ACCOUNT_IS_MISSING_ROLE.selector, _alice, Roles.KUMA_MANAGER_ROLE
            )
        );
        vm.prank(_alice);
        _KUMASwap.enableDeprecationMode();
    }
}
