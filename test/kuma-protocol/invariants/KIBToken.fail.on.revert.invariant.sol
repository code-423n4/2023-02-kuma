// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "../BaseSetUp.t.sol";
import {InvariantKIBTokenAdmin} from "./actors/InvariantKIBTokenAdmin.sol";
import {InvariantKIBTokenUser} from "./actors/InvariantKIBTokenUser.sol";
import {Roles} from "@kuma/libraries/Roles.sol";
import {Warper} from "./actors/Warper.sol";
import {WadRayMath} from "@kuma/libraries/WadRayMath.sol";

contract KIBTokenInvariantFailOnRevert is BaseSetUp {
    using Roles for bytes32;

    InvariantKIBTokenAdmin private _admin;
    InvariantKIBTokenUser private _user;
    Warper private _warper;

    function setUp() public {
        _user = new InvariantKIBTokenUser(_KIBToken, _rateFeed, _alice, address(this));
        _admin = new InvariantKIBTokenAdmin(_KIBToken, _rateFeed, address(_user));
        _warper = new Warper();

        _KUMAAccessController.grantRole(Roles.KUMA_MINT_ROLE.toGranularRole(_RISK_CATEGORY), address(this));
        _KUMAAccessController.grantRole(Roles.KUMA_MINT_ROLE.toGranularRole(_RISK_CATEGORY), address(_admin));
        _KUMAAccessController.grantRole(Roles.KUMA_BURN_ROLE.toGranularRole(_RISK_CATEGORY), address(_admin));
        _KUMAAccessController.grantRole(
            Roles.KUMA_SET_EPOCH_LENGTH_ROLE, address(_admin)
        );

        vm.label(address(_admin), "Admin");
        vm.label(address(_user), "User");

        bytes4[] memory warperSelectors = new bytes4[](1);
        warperSelectors[0] = _warper.warp.selector;

        bytes4[] memory adminSelectors = new bytes4[](4);
        adminSelectors[0] = _admin.KIBTokenMint.selector;
        adminSelectors[1] = _admin.KIBTokenBurn.selector;
        adminSelectors[2] = _admin.KIBTokenSetEpochLength.selector;
        adminSelectors[3] = _admin.KIBTokenSetYield.selector;

        bytes4[] memory userSelectors = new bytes4[](2);
        userSelectors[0] = _user.KIBTokenTransfer.selector;
        userSelectors[1] = _user.KIBTokenTransferFrom.selector;

        targetSelector(FuzzSelector({addr: address(_admin), selectors: adminSelectors}));
        targetSelector(FuzzSelector({addr: address(_warper), selectors: warperSelectors}));
        targetSelector(FuzzSelector({addr: address(_user), selectors: userSelectors}));
        excludeContract(address(_KIBToken));
        excludeContract(address(_KUMASwap));
        excludeContract(address(_KBCToken));
        excludeContract(address(_KUMAAddressProvider));
        excludeContract(address(_KUMABondToken));
        excludeContract(address(_rateFeed));
        excludeContract(address(_KUMAFeeCollector));
        excludeContract(address(_mcagAccessController));
        excludeContract(address(_KUMAAccessController));
        excludeContract(address(_deprecationStableCoin));
        excludeContract(address(_blacklist));
        excludeContract(address(_mcagAggregator));
        excludeContract(_bytes32ToAddress(vm.load(address(_KIBToken), _IMPLEMENTATION_SLOT)));
        excludeContract(_bytes32ToAddress(vm.load(address(_KUMASwap), _IMPLEMENTATION_SLOT)));
        excludeContract(_bytes32ToAddress(vm.load(address(_KBCToken), _IMPLEMENTATION_SLOT)));
        excludeContract(_bytes32ToAddress(vm.load(address(_KUMAAddressProvider), _IMPLEMENTATION_SLOT)));
        excludeContract(_bytes32ToAddress(vm.load(address(_rateFeed), _IMPLEMENTATION_SLOT)));
        excludeContract(_bytes32ToAddress(vm.load(address(_KUMAFeeCollector), _IMPLEMENTATION_SLOT)));
    }

    function invariant_totalBaseSupplyLtetotalSupply() public {
        assertTrue(WadRayMath.rayToWad(_KIBToken.getTotalBaseSupply()) <= _KIBToken.totalSupply());
    }

    function invariant_baseBalanceLteBalance() public {
        assertTrue(WadRayMath.rayToWad(_KIBToken.getBaseBalance(address(_user))) <= _KIBToken.balanceOf(address(_user)));
        assertTrue(
            WadRayMath.rayToWad(_KIBToken.getBaseBalance(address(_admin))) <= _KIBToken.balanceOf(address(_admin))
        );
        assertTrue(WadRayMath.rayToWad(_KIBToken.getBaseBalance(_alice)) <= _KIBToken.balanceOf(_alice));
    }

    function invariant_GettersShouldNotRevert() public view {
        _KIBToken.getKUMAAddressProvider();
        _KIBToken.getUpdatedCumulativeYield();
        _KIBToken.getCumulativeYield();
        _KIBToken.getEpochLength();
        _KIBToken.getBaseBalance(address(_user));
        _KIBToken.getTotalBaseSupply();
        _KIBToken.getLastRefresh();
        _KIBToken.getYield();
        _KIBToken.totalSupply();
        _KIBToken.symbol();
        _KIBToken.name();
        _KIBToken.decimals();
        _KIBToken.balanceOf((address(_user)));
        _KIBToken.allowance(address(_user), _alice);
    }
}
