// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "./KIBTokenSetUp.t.sol";
import {WadRayMath} from "@kuma/libraries/WadRayMath.sol";

contract KIBTokenSetters is KIBTokenSetUp {
    using WadRayMath for uint256;

    function test_initialize() public {
        assertEq(_KIBToken.name(), _NAME);
        assertEq(_KIBToken.symbol(), _SYMBOL);
        assertEq(_KIBToken.decimals(), 18);
        assertEq(_KIBToken.getYield(), WadRayMath.RAY);
        assertEq(_KIBToken.getLastRefresh(), 365 days * 30);
        assertEq(address(_KIBToken.getKUMAAddressProvider()), address(_KUMAAddressProvider));

        KIBToken newKIBToken = new KIBToken();

        vm.expectEmit(false, false, false, true);
        emit CumulativeYieldUpdated(0, WadRayMath.RAY);
        vm.expectEmit(false, false, false, true);
        emit EpochLengthSet(0, 4 hours);
        vm.expectEmit(false, false, false, true);
        emit KUMAAddressProviderSet(address(_KUMAAddressProvider));
        vm.expectEmit(false, false, false, true);
        emit PreviousEpochCumulativeYieldUpdated(0, WadRayMath.RAY);
        vm.expectEmit(false, false, false, true);
        emit RiskCategorySet(_RISK_CATEGORY);
        vm.expectEmit(false, false, false, true);
        emit YieldUpdated(0, WadRayMath.RAY);

        _deployUUPSProxy(
            address(newKIBToken),
            abi.encodeWithSelector(
                IKIBToken.initialize.selector,
                _NAME,
                _SYMBOL,
                _EPOCH_LENGTH,
                _KUMAAddressProvider,
                _CURRENCY,
                _COUNTRY,
                _TERM
            )
        );
    }

    function test_initialize_RevertWhen_InitializedWithInvalidParameters() public {
        KIBToken newKIBToken = new KIBToken();
        vm.expectRevert(Errors.EPOCH_LENGTH_CANNOT_BE_ZERO.selector);
        _deployUUPSProxy(
            address(newKIBToken),
            abi.encodeWithSelector(
                IKIBToken.initialize.selector, _NAME, _SYMBOL, 0, _KUMAAddressProvider, _CURRENCY, _COUNTRY, _TERM
            )
        );

        vm.expectRevert(Errors.CANNOT_SET_TO_ADDRESS_ZERO.selector);
        _deployUUPSProxy(
            address(newKIBToken),
            abi.encodeWithSelector(
                IKIBToken.initialize.selector,
                _NAME,
                _SYMBOL,
                _EPOCH_LENGTH,
                IKUMAAddressProvider(address(0)),
                _CURRENCY,
                _COUNTRY,
                _TERM
            )
        );

        vm.expectRevert(Errors.WRONG_RISK_CATEGORY.selector);
        _deployUUPSProxy(
            address(newKIBToken),
            abi.encodeWithSelector(
                IKIBToken.initialize.selector,
                _NAME,
                _SYMBOL,
                _EPOCH_LENGTH,
                _KUMAAddressProvider,
                bytes4(0),
                _COUNTRY,
                _TERM
            )
        );

        vm.expectRevert(Errors.WRONG_RISK_CATEGORY.selector);
        _deployUUPSProxy(
            address(newKIBToken),
            abi.encodeWithSelector(
                IKIBToken.initialize.selector,
                _NAME,
                _SYMBOL,
                _EPOCH_LENGTH,
                _KUMAAddressProvider,
                _CURRENCY,
                bytes4(0),
                _TERM
            )
        );

        vm.expectRevert(Errors.WRONG_RISK_CATEGORY.selector);
        _deployUUPSProxy(
            address(newKIBToken),
            abi.encodeWithSelector(
                IKIBToken.initialize.selector,
                _NAME,
                _SYMBOL,
                _EPOCH_LENGTH,
                _KUMAAddressProvider,
                _CURRENCY,
                _COUNTRY,
                0
            )
        );
    }

    function test_setters_refreshYield() public {
        _KIBToken.refreshYield();
        uint256 referenceRate = 1000000000937303470807876290; // 3%
        _mcagAggregator.transmit(int256(referenceRate));
        vm.expectEmit(false, false, false, true);
        emit YieldUpdated(_YIELD, referenceRate);
        _KIBToken.refreshYield();
        assertEq(_KIBToken.getYield(), referenceRate);
    }

    function test_refreshYield_IntheMiddleOfAnEpoch() public {
        // Mint 10 ether
        _KIBToken.mint(address(this), 10 ether);
        // Skip 2 hours at 5% yield
        skip(2 hours);
        uint256 referenceRate = WadRayMath.RAY; // 0%
        _mcagAggregator.transmit(int256(referenceRate));
        _KIBToken.refreshYield(); // Update yield to 0%

        // Skip 2 hours at 0%
        skip(2 hours);
        _KIBToken.refreshYield();

        uint256 expectedBalance = _YIELD.rayPow(2 hours).rayMul(10 ether);
        uint256 actualBalance = _KIBToken.balanceOf(address(this));

        assertEq(actualBalance - expectedBalance, 0);
    }
}
