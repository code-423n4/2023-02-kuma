// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "../BaseSetUp.t.sol";
import {InvariantKUMASwapUser} from "./actors/InvariantKUMASwapUser.sol";
import {Warper} from "./actors/Warper.sol";

contract KUMASwapInvariant is BaseSetUp {
    InvariantKUMASwapUser private _user;
    Warper private _warper;

    function setUp() public {
        _user = new InvariantKUMASwapUser(_KUMABondToken, _KUMASwap, _mcagAggregator, _KIBToken, _TERM, false);
        _warper = new Warper();

        vm.label(address(_warper), "Warper");
        vm.label(address(_user), "User");

        bytes4[] memory warperSelectors = new bytes4[](1);
        warperSelectors[0] = _warper.warp.selector;

        bytes4[] memory userSelectors = new bytes4[](2);
        userSelectors[0] = _user.KUMASwapSellBond.selector;
        userSelectors[1] = _user.KUMASwapBuyBond.selector;

        targetSelector(FuzzSelector({addr: address(_warper), selectors: warperSelectors}));
        targetSelector(FuzzSelector({addr: address(_user), selectors: userSelectors}));
        excludeContract(address(_KIBToken));
        excludeContract(address(_KUMASwap));
        excludeContract(address(_KBCToken));
        excludeContract(address(_KUMAAddressProvider));
        excludeContract(address(_KUMABondToken));
        excludeContract(address(_KUMAFeeCollector));
        excludeContract(address(_rateFeed));
        excludeContract(address(_deprecationStableCoin));
        excludeContract(address(_mcagAccessController));
        excludeContract(address(_KUMAAccessController));
        excludeContract(address(_blacklist));
        excludeContract(address(_mcagAggregator));
        excludeContract(_bytes32ToAddress(vm.load(address(_KIBToken), _IMPLEMENTATION_SLOT)));
        excludeContract(_bytes32ToAddress(vm.load(address(_KUMASwap), _IMPLEMENTATION_SLOT)));
        excludeContract(_bytes32ToAddress(vm.load(address(_KBCToken), _IMPLEMENTATION_SLOT)));
        excludeContract(_bytes32ToAddress(vm.load(address(_KUMAAddressProvider), _IMPLEMENTATION_SLOT)));
        excludeContract(_bytes32ToAddress(vm.load(address(_rateFeed), _IMPLEMENTATION_SLOT)));
        excludeContract(_bytes32ToAddress(vm.load(address(_KUMAFeeCollector), _IMPLEMENTATION_SLOT)));

        vm.prank(address(_user));
        _KUMABondToken.setApprovalForAll(address(_KUMASwap), true);

        vm.mockCall(
            address(_mcagAccessController),
            abi.encodeWithSelector(_KUMAAccessController.hasRole.selector),
            abi.encode(true)
        );
    }

    /**
     * @notice KIBToken yield must always be equal to lowest rate between lowest coupon in reserve and oracle rate
     */
    function invariant_KUMAswapYieldEqLowestRate() public {
        uint256 yield = _KIBToken.getYield();
        uint256 lowestCoupon = _KUMASwap.getMinCoupon();
        uint256 oracleRate = _rateFeed.getRate(_RISK_CATEGORY);
        uint256 expectedYield = oracleRate <= lowestCoupon ? oracleRate : lowestCoupon;
        assertEq(yield, expectedYield);
    }

    /**
     * @notice If a bond is not in reserve anymore but is still in the KUMASwap then there must be  a child Ghost Bond
     */
    function invariant_KUMAswapCloneBond() public {
        for (uint256 i = 1; i <= _user.tokenIdCounter(); i++) {
            if (_KUMABondToken.ownerOf(i) == address(_KUMASwap) && !_KUMASwap.isInReserve(_user.tokenIdCounter())) {
                assertTrue(_KUMASwap.getCloneBond(i) != 0);
            }
        }
    }
}
