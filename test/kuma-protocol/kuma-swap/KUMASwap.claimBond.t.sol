// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "./KUMASwapSetUp.t.sol";

contract KUMASwapClaimBond is KUMASwapSetUp {
    using Roles for bytes32;
    using WadRayMath for uint256;

    /**
     * @notice Tests claimBond function.
     */
    function test_claimBond() public {
        IKUMABondToken.Bond memory bond_ = _bond;
        uint256 newYield = 1000000001847694957439350563; // 6%
        bond_.coupon = newYield;
        _KUMABondToken.issueBond(_alice, bond_);

        _KUMASwap.sellBond(1);

        vm.startPrank(_alice);
        _KUMASwap.sellBond(2);
        vm.stopPrank();

        skip(365 days);

        _KUMASwap.buyBond(2);

        vm.expectEmit(false, false, false, true);
        emit BondClaimed(2, 1);
        _KUMASwap.claimBond(2);

        assertEq(_KUMASwap.getCoupons().length, 1);
        assertEq(_KUMASwap.getCoupons()[0], _YIELD);
        assertEq(_KUMASwap.getCloneBond(2), 0);
        assertEq(_KBCToken.balanceOf(address(this)), 0);
        assertEq(_KIBToken.getYield(), _YIELD);

        vm.expectRevert(Errors.ERC721_INVALID_TOKEN_ID.selector);
        _KBCToken.getBond(1);
        vm.expectRevert(Errors.ERC721_INVALID_TOKEN_ID.selector);
        _KBCToken.getBond(2);
    }

    /**
     * @notice Tests claimBond access control.
     */
    function test_claimBond_RevertWhen_NotClaimRole() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.ACCESS_CONTROL_ACCOUNT_IS_MISSING_ROLE.selector,
                _alice,
                Roles.KUMA_SWAP_CLAIM_ROLE.toGranularRole(_RISK_CATEGORY)
            )
        );
        vm.prank(_alice);
        _KUMASwap.claimBond(1);
    }

    /**
     * @notice Tests claimBond data validation by trying to claim a bond not available for claim.
     */
    function test_claimBond_RevertWhen_NotAvailableForClaim() public {
        _KUMASwap.sellBond(1);
        vm.expectRevert(Errors.BOND_NOT_AVAILABLE_FOR_CLAIM.selector);
        _KUMASwap.claimBond(1);
    }
}
