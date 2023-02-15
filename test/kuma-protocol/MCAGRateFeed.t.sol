// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "./BaseSetUp.t.sol";
import {MCAGAggregatorInterface} from "@mcag/interfaces/MCAGAggregatorInterface.sol";
import {Errors} from "@kuma/libraries/Errors.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import {WadRayMath} from "@kuma/libraries/WadRayMath.sol";

contract MCAGRateFeedTest is BaseSetUp {
    event AccessControllerSet(address accessController);
    event OracleSet(address oracle, bytes4 indexed currency, bytes4 indexed country, uint64 indexed term);

    MCAGAggregatorInterface private _oracle = MCAGAggregatorInterface(vm.addr(7));

    function setUp() public {
        vm.etch(address(_oracle), "0xmcagaggregator");

        vm.mockCall(
            address(_oracle),
            abi.encodeWithSelector(_oracle.latestRoundData.selector),
            abi.encode(1, _YIELD, 0, block.timestamp, 1)
        );
        vm.mockCall(address(_oracle), abi.encodeWithSelector(_oracle.decimals.selector), abi.encode(27));
        _rateFeed.setOracle(_CURRENCY, _COUNTRY, _TERM, _oracle);
    }

    function test_initialize() public {
        assertEq(address(_rateFeed.getAccessController()), address(_KUMAAccessController));
        assertEq(_rateFeed.minRateCoupon(), WadRayMath.RAY);
        assertEq(_rateFeed.decimals(), 27);

        MCAGRateFeed newRateFeed = new MCAGRateFeed();

        vm.expectEmit(false, false, false, true);
        emit AccessControllerSet(address(_KUMAAccessController));

        _deployUUPSProxy(
            address(newRateFeed),
            abi.encodeWithSelector(IMCAGRateFeed.initialize.selector, address(_KUMAAccessController))
        );
    }

    function test_initialize_RevertWhen_InitializedWithInvalidParameters() public {
        MCAGRateFeed newRateFeed = new MCAGRateFeed();
        vm.expectRevert(Errors.CANNOT_SET_TO_ADDRESS_ZERO.selector);
        _deployUUPSProxy(address(newRateFeed), abi.encodeWithSelector(IMCAGRateFeed.initialize.selector, address(0)));
    }

    function test_setOracle() public {
        vm.expectEmit(true, true, true, true);
        emit OracleSet(address(_oracle), _CURRENCY, _COUNTRY, _TERM);
        _rateFeed.setOracle(_CURRENCY, _COUNTRY, _TERM, _oracle);

        assertEq(address(_rateFeed.getOracle(_RISK_CATEGORY)), address(_oracle));
    }

    function test_setOracle_RevertWhen_NotManager() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.ACCESS_CONTROL_ACCOUNT_IS_MISSING_ROLE.selector, _alice, Roles.KUMA_MANAGER_ROLE
            )
        );
        vm.prank(_alice);
        _rateFeed.setOracle(_CURRENCY, _COUNTRY, _TERM, _oracle);
    }

    function test_setOracle_RevertWhen_WrongRiskCategoryOrAddressZero() public {
        vm.expectRevert(Errors.WRONG_RISK_CATEGORY.selector);
        _rateFeed.setOracle(bytes4(0), _COUNTRY, _TERM, _oracle);
        vm.expectRevert(Errors.WRONG_RISK_CATEGORY.selector);
        _rateFeed.setOracle(_CURRENCY, bytes4(0), _TERM, _oracle);
        vm.expectRevert(Errors.WRONG_RISK_CATEGORY.selector);
        _rateFeed.setOracle(_CURRENCY, _COUNTRY, 0, _oracle);
        vm.expectRevert(Errors.CANNOT_SET_TO_ADDRESS_ZERO.selector);
        _rateFeed.setOracle(_CURRENCY, _COUNTRY, _TERM, MCAGAggregatorInterface(address(0)));
    }

    function test_getRate_WhenOracleDecimalsEqRateFeedDecimals() public {
        assertEq(_rateFeed.getRate(_RISK_CATEGORY), _YIELD);
    }

    function test_getRate_WhenOracleDecimalsGtRateFeedDecimals() public {
        vm.mockCall(
            address(_oracle),
            abi.encodeWithSelector(_oracle.latestRoundData.selector),
            abi.encode(1, 100000000154712595786321244904586, 0, block.timestamp, 1)
        ); // 5% as 32 decimals
        vm.mockCall(address(_oracle), abi.encodeWithSelector(_oracle.decimals.selector), abi.encode(32));
        assertEq(_rateFeed.getRate(_RISK_CATEGORY), _YIELD);
    }

    function test_getRate_WhenOracleDecimalsLtRateFeedDecimals() public {
        vm.mockCall(
            address(_oracle),
            abi.encodeWithSelector(_oracle.latestRoundData.selector),
            abi.encode(1, 10000000015471259578632, 0, block.timestamp, 1)
        ); // 5% as 22 decimals
        vm.mockCall(address(_oracle), abi.encodeWithSelector(_oracle.decimals.selector), abi.encode(22));
        assertEq(_rateFeed.getRate(_RISK_CATEGORY), 10000000015471259578632 * 10 ** 5);
    }

    function test_getRate_WhenOracleRateLtZero() public {
        vm.mockCall(
            address(_oracle),
            abi.encodeWithSelector(_oracle.latestRoundData.selector),
            abi.encode(1, -1, 0, block.timestamp, 1)
        );
        assertEq(_rateFeed.getRate(_RISK_CATEGORY), WadRayMath.RAY);
    }

    function test_getRate_WhenOracleRateLtRay() public {
        vm.mockCall(
            address(_oracle),
            abi.encodeWithSelector(_oracle.latestRoundData.selector),
            abi.encode(1, 0, 0, block.timestamp, 1)
        );
        assertEq(_rateFeed.getRate(_RISK_CATEGORY), WadRayMath.RAY);
    }

    function test_upgrade_RevertWhen_CallerIsNotManager() public {
        MCAGRateFeed newMCAGRateFeed = new MCAGRateFeed();
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.ACCESS_CONTROL_ACCOUNT_IS_MISSING_ROLE.selector, _alice, Roles.KUMA_MANAGER_ROLE
            )
        );
        vm.prank(_alice);
        UUPSUpgradeable(address(_rateFeed)).upgradeTo(address(newMCAGRateFeed));
    }
}
