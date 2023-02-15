// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "./KIBTokenSetUp.t.sol";
import {WadRayMath} from "@kuma/libraries/WadRayMath.sol";

contract KIBTokenFuzzTest is BaseSetUp {
    using Roles for bytes32;
    using WadRayMath for uint256;

    function setUp() public {
        _KUMAAccessController.grantRole(Roles.KUMA_MINT_ROLE.toGranularRole(_RISK_CATEGORY), address(this));
        _KUMAAccessController.grantRole(Roles.KUMA_BURN_ROLE.toGranularRole(_RISK_CATEGORY), address(this));
        _KUMAAccessController.grantRole(Roles.KUMA_SET_EPOCH_LENGTH_ROLE.toGranularRole(_RISK_CATEGORY), address(this));
    }

    function testFuzz_MintShouldNotFail(uint256 amount, uint256, uint256 yield, uint256 warp) public {
        vm.assume(yield < 831951628484471511);
        yield = WadRayMath.RAY + yield; // 30% max
        vm.assume(warp <= type(uint32).max);
        _mcagAggregator.transmit(int256(_YIELD));
        vm.warp(block.timestamp + warp);
        amount = bound(amount, 0, (type(uint256).max / WadRayMath.WAD_RAY_RATIO) / WadRayMath.RAY);
        // The baseAmounts will be converted to a RAY and then multiplied by RAY in rayDIV, so the amount can't be more than a factor of uint.max/(WAD*WAD_RAY_RATIO) to avoid overflows
        _KIBToken.mint(address(this), amount);
        assertEq(_KIBToken.balanceOf(address(this)), amount);
    }

    function testFuzz_ConsecutiveMintShouldNotFail(uint256 amount1, uint256 amount2, uint256 yield, uint256 warp)
        public
    {
        uint256 max = (type(uint256).max / WadRayMath.WAD_RAY_RATIO) / WadRayMath.RAY;
        // The baseAmounts will be converted to a RAY and then multiplied by RAY in rayDIV, so the amount can't be more than a factor of uint.max/(WAD*WAD_RAY_RATIO) to avoid overflows
        amount1 = bound(amount1, 0, max);
        amount2 = bound(amount2, 0, max);
        vm.assume(amount1 + amount2 < max);
        yield = bound(yield, WadRayMath.RAY, WadRayMath.RAY + 831951628484471511); // 30% max
        _mcagAggregator.transmit(int256(_YIELD));

        vm.assume(warp <= type(uint32).max);
        vm.warp(block.timestamp + warp);

        _KIBToken.mint(address(this), amount1);
        _KIBToken.mint(address(this), amount2);
        assertEq(_KIBToken.balanceOf(address(this)), amount1 + amount2);
    }

    function testFuzz_BurnShouldNotFail(uint256 initialMintAmount, uint256 burnAmount) public {
        burnAmount = bound(burnAmount, 0, (type(uint256).max / WadRayMath.WAD_RAY_RATIO) / WadRayMath.RAY);
        initialMintAmount =
            bound(initialMintAmount, burnAmount, (type(uint256).max / WadRayMath.WAD_RAY_RATIO) / WadRayMath.RAY);
        _KIBToken.mint(address(this), initialMintAmount);
        assertEq(_KIBToken.balanceOf(address(this)), initialMintAmount);
        _KIBToken.burn(address(this), burnAmount);
        assertEq(_KIBToken.balanceOf(address(this)), initialMintAmount - burnAmount);
    }

    function testFuzz_TransferShouldNotFail(uint256 amount, uint256, uint256 yield, uint256 warp) public {
        vm.assume(yield < 831951628484471511);
        yield = WadRayMath.RAY + yield; // 30% max
        vm.assume(warp <= type(uint32).max);
        vm.warp(block.timestamp + warp);
        // The baseAmounts will be converted to a RAY and then multiplied by RAY in rayDIV, so the amount can't be more than a factor of uint.max/(WAD*WAD_RAY_RATIO) to avoid overflows
        vm.assume(amount <= (type(uint256).max / WadRayMath.WAD_RAY_RATIO) / WadRayMath.RAY);
        _KIBToken.mint(address(this), amount);
        assertEq(_KIBToken.balanceOf(address(this)), amount);
        bool success = _KIBToken.transfer(_alice, amount);
        assertEq(_KIBToken.balanceOf(_alice), amount);
        assertEq(success, true);
    }
}
