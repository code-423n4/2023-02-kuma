// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {AccessController} from "@mcag/AccessController.sol";
import {Blacklist, IBlacklist} from "@mcag/Blacklist.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {Errors} from "@mcag/libraries/Errors.sol";
import {KUMABondToken} from "@mcag/KUMABondToken.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {IKUMABondToken} from "@mcag/interfaces/IKUMABondToken.sol";
import {Roles} from "@mcag/libraries/Roles.sol";
import {Test, console2} from "forge-std/Test.sol";

contract KUMABondTokenTest is Test {
    event AccessControllerSet(address accesController);
    event BlacklistSet(address blacklist);
    event BondIssued(uint256 id, IKUMABondToken.Bond bond);
    event BondRedeemed(uint256 id);
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event UriSet(string oldUri, string newUri);

    bytes16 public constant CUSIP = bytes16("037833100");
    bytes16 public constant ISIN = bytes16("US0378331005");
    bytes4 public constant CURRENCY = bytes4("USD");
    bytes4 public constant COUNTRY = bytes4("US");
    uint64 public constant TERM = 365 days;

    KUMABondToken private _kumaBondToken;
    AccessController private _accessController;
    Blacklist private _blacklist;

    address private _alice = vm.addr(1);
    address private _bob = vm.addr(2);
    address private _charlie = vm.addr(3);
    address private _multisig = 0xcc8793d5eB95fAa707ea4155e09b2D3F44F33D1E;

    IKUMABondToken.Bond private _bond;

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
        external
        returns (bytes4)
    {
        return IERC721Receiver.onERC721Received.selector;
    }

    function setUp() external {
        _accessController = new AccessController();
        _blacklist = new Blacklist(_accessController);
        _kumaBondToken = new KUMABondToken(IAccessControl(address(_accessController)), IBlacklist(address(_blacklist)));
        _bond = IKUMABondToken.Bond({
            isin: ISIN,
            cusip: CUSIP,
            currency: CURRENCY,
            country: COUNTRY,
            term: TERM,
            issuance: uint64(block.timestamp),
            maturity: uint64(block.timestamp + 365 days),
            coupon: 1000000001547125957863212449,
            principal: 10 ether,
            riskCategory: keccak256(abi.encode(CURRENCY, COUNTRY, TERM))
        });
        vm.label(address(_kumaBondToken), "KUMABondToken");
        vm.label(_alice, "Alice");
        vm.label(_bob, "Bob");
        vm.label(address(this), "Owner");
        vm.label(_charlie, "Charlie");
    }

    function test_constructor() public {
        vm.expectEmit(false, false, false, true);
        emit AccessControllerSet(address(_accessController));
        vm.expectEmit(false, false, false, true);
        emit BlacklistSet(address(_blacklist));

        KUMABondToken newKUMABondToken = new KUMABondToken(_accessController, _blacklist);

        assertEq(bytes(newKUMABondToken.name()), bytes("KUMA Bonds"));
        assertEq(bytes(newKUMABondToken.symbol()), bytes("KUMA"));
        assertEq(address(newKUMABondToken.accessController()), address(_accessController));
        assertEq(address(newKUMABondToken.blacklist()), address(_blacklist));
    }

    function test_constructor_RevertWhen_InitializedWithInvalidParameters() public {
        vm.expectRevert(Errors.CANNOT_SET_TO_ADDRESS_ZERO.selector);
        new KUMABondToken(IAccessControl(address(0)), _blacklist);
        vm.expectRevert(Errors.CANNOT_SET_TO_ADDRESS_ZERO.selector);
        new KUMABondToken(_accessController, IBlacklist(address(0)));
    }

    function test_issueBond() public {
        vm.expectEmit(true, true, true, true);
        emit BondIssued(1, _bond);
        _kumaBondToken.issueBond(address(this), _bond);
        IKUMABondToken.Bond memory newBond = _kumaBondToken.getBond(1);
        assertEq(_kumaBondToken.ownerOf(1), address(this));
        assertEq(_kumaBondToken.balanceOf(address(this)), 1);
        assertEq(_kumaBondToken.getTokenIdCounter(), 1);
        assertEq(newBond.currency, bytes4("USD"));
        assertEq(newBond.country, bytes4("US"));
        assertEq(newBond.term, uint64(365 days));
        assertEq(newBond.issuance, uint64(block.timestamp));
        assertEq(newBond.maturity, uint64(block.timestamp + 365 days));
        assertEq(newBond.coupon, 1000000001547125957863212449);
        assertEq(newBond.principal, 10 ether);
        assertEq(newBond.riskCategory, keccak256(abi.encode(CURRENCY, COUNTRY, TERM)));
    }

    function test_issueBond_RevertWhen_CallerDoesNotHaveMintRole() public {
        vm.prank(_alice);
        vm.expectRevert(
            abi.encodeWithSelector(Errors.ACCESS_CONTROL_ACCOUNT_IS_MISSING_ROLE.selector, _alice, Roles.MCAG_MINT_ROLE)
        );
        _kumaBondToken.issueBond(_alice, _bond);
    }

    function test_issueBond_RevertWhen_IssueToBlacklistedAddress() public {
        _blacklist.blacklist(_alice);
        vm.expectRevert(abi.encodeWithSelector(Errors.BLACKLIST_ACCOUNT_IS_BLACKLISTED.selector, _alice));
        _kumaBondToken.issueBond(_alice, _bond);
    }

    function test_issueBond_RevertWhen_Paused() public {
        _kumaBondToken.pause();
        vm.expectRevert("Pausable: paused");
        _kumaBondToken.issueBond(address(this), _bond);
    }

    function test_redeem() public {
        _kumaBondToken.issueBond(address(this), _bond);
        vm.expectEmit(true, true, true, true);
        emit BondRedeemed(1);
        _kumaBondToken.redeem(1);
        vm.expectRevert(abi.encodeWithSelector(Errors.ERC721_INVALID_TOKEN_ID.selector));
        _kumaBondToken.getBond(1);
    }

    function test_redeem_RevertWhen_CallerDoesNotHaveBurnRole() public {
        _kumaBondToken.issueBond(address(this), _bond);
        vm.expectRevert(
            abi.encodeWithSelector(Errors.ACCESS_CONTROL_ACCOUNT_IS_MISSING_ROLE.selector, _alice, Roles.MCAG_BURN_ROLE)
        );
        vm.prank(_alice);
        _kumaBondToken.redeem(1);
    }

    function test_redeem_RevertWhen_Paused() public {
        _kumaBondToken.issueBond(address(this), _bond);
        _kumaBondToken.pause();
        vm.expectRevert("Pausable: paused");
        _kumaBondToken.redeem(1);
    }

    function test_redeem_RevertWhen_CallerIsNotTokenOwner() public {
        _kumaBondToken.issueBond(_alice, _bond);
        vm.expectRevert(Errors.ERC721_CALLER_IS_NOT_TOKEN_OWNER.selector);
        _kumaBondToken.redeem(1);
    }

    function test_setUri() public {
        _kumaBondToken.issueBond(address(this), _bond);
        string memory newUri = "https://game.example/item-id-8u5h2m.json/";
        vm.expectEmit(false, false, false, true);
        emit UriSet("", newUri);
        _kumaBondToken.setUri(newUri);

        bytes memory expectedUri = abi.encode("https://game.example/item-id-8u5h2m.json/1");

        assertEq(abi.encode(_kumaBondToken.tokenURI(1)), expectedUri);
    }

    function test_setUri_RevertWhen_CallerDoesNotHaveSetUriRole() public {
        string memory newUri = "https://game.example/item-id-8u5h2m.json/";
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.ACCESS_CONTROL_ACCOUNT_IS_MISSING_ROLE.selector, _alice, Roles.MCAG_SET_URI_ROLE
            )
        );
        vm.prank(_alice);
        _kumaBondToken.setUri(newUri);
    }

    function test_approve() public {
        _kumaBondToken.issueBond(address(this), _bond);
        vm.expectEmit(true, true, true, true);
        emit Approval(address(this), _alice, 1);
        _kumaBondToken.approve(_alice, 1);
        assertEq(_kumaBondToken.getApproved(1), _alice);
    }

    function test_approve_RevertWhen_ToBlacklisted() public {
        _kumaBondToken.issueBond(address(this), _bond);
        _blacklist.blacklist(_alice);
        vm.expectRevert(abi.encodeWithSelector(Errors.BLACKLIST_ACCOUNT_IS_BLACKLISTED.selector, _alice));
        _kumaBondToken.approve(_alice, 1);
    }

    function test_approve_RevertWhen_MsgSenderBlacklisted() public {
        _kumaBondToken.issueBond(address(this), _bond);
        _blacklist.blacklist(address(this));
        vm.expectRevert(abi.encodeWithSelector(Errors.BLACKLIST_ACCOUNT_IS_BLACKLISTED.selector, address(this)));
        _kumaBondToken.approve(_alice, 1);
    }

    function test_approve_RevertWhen_Paused() public {
        _kumaBondToken.issueBond(address(this), _bond);
        _kumaBondToken.pause();
        vm.expectRevert("Pausable: paused");
        _kumaBondToken.approve(_alice, 1);
    }

    function test_approve_RevertWhen_ApproveToSelf() public {
        _kumaBondToken.issueBond(address(this), _bond);
        vm.expectRevert(abi.encodeWithSelector(Errors.ERC721_APPROVAL_TO_CURRENT_OWNER.selector));
        _kumaBondToken.approve(address(this), 1);
    }

    function test_approve_RevertWhen_MsgSenderNotOwner() public {
        _kumaBondToken.issueBond(address(this), _bond);
        vm.expectRevert(
            abi.encodeWithSelector(Errors.ERC721_APPROVE_CALLER_IS_NOT_TOKEN_OWNER_OR_APPROVED_FOR_ALL.selector)
        );
        vm.prank(_alice);
        _kumaBondToken.approve(_alice, 1);
    }

    function test_setApprovalForAll() public {
        _kumaBondToken.issueBond(address(this), _bond);
        vm.expectEmit(true, true, false, true);
        emit ApprovalForAll(address(this), _alice, true);
        _kumaBondToken.setApprovalForAll(_alice, true);
        assertTrue(_kumaBondToken.isApprovedForAll(address(this), _alice));
    }

    function test_setApprovalForAll_RevertWhen_MsgSenderBlacklisted() public {
        _kumaBondToken.issueBond(address(this), _bond);
        _blacklist.blacklist(address(this));
        vm.expectRevert(abi.encodeWithSelector(Errors.BLACKLIST_ACCOUNT_IS_BLACKLISTED.selector, address(this)));
        _kumaBondToken.setApprovalForAll(_alice, true);
    }

    function test_setApprovalForAll_RevertWhen_OperatorBlacklisted() public {
        _kumaBondToken.issueBond(address(this), _bond);
        _blacklist.blacklist(_alice);
        vm.expectRevert(abi.encodeWithSelector(Errors.BLACKLIST_ACCOUNT_IS_BLACKLISTED.selector, _alice));
        _kumaBondToken.setApprovalForAll(_alice, true);
    }

    function test_setApprovalForAll_RevertWhen_Paused() public {
        _kumaBondToken.issueBond(address(this), _bond);
        _kumaBondToken.pause();
        vm.expectRevert("Pausable: paused");
        _kumaBondToken.setApprovalForAll(_alice, true);
    }

    function test_transferFrom() public {
        _kumaBondToken.issueBond(address(this), _bond);
        _kumaBondToken.approve(_alice, 1);
        vm.expectEmit(true, true, true, true);
        emit Transfer(address(this), _alice, 1);
        vm.prank(_alice);
        _kumaBondToken.transferFrom(address(this), _alice, 1);
        assertEq(_kumaBondToken.ownerOf(1), _alice);
        assertEq(_kumaBondToken.balanceOf(_alice), 1);
    }

    function test_transferFrom_RevertWhen_NotApproved() public {
        _kumaBondToken.issueBond(address(this), _bond);
        vm.expectRevert(abi.encodeWithSelector(Errors.ERC721_CALLER_IS_NOT_TOKEN_OWNER_OR_APPROVED.selector));
        vm.prank(_alice);
        _kumaBondToken.transferFrom(address(this), _alice, 1);
    }

    function test_transferFrom_RevertWhen_ToBlacklisted() public {
        _kumaBondToken.issueBond(address(this), _bond);
        _kumaBondToken.approve(_alice, 1);
        _blacklist.blacklist(_alice);
        vm.expectRevert(abi.encodeWithSelector(Errors.BLACKLIST_ACCOUNT_IS_BLACKLISTED.selector, _alice));
        _kumaBondToken.transferFrom(address(this), _alice, 1);
    }

    function test_transferFrom_RevertWhen_FromBlacklisted() public {
        _kumaBondToken.issueBond(address(this), _bond);
        _kumaBondToken.approve(_alice, 1);
        _blacklist.blacklist(address(this));
        vm.expectRevert(abi.encodeWithSelector(Errors.BLACKLIST_ACCOUNT_IS_BLACKLISTED.selector, address(this)));
        _kumaBondToken.transferFrom(address(this), _alice, 1);
    }

    function test_transferFrom_RevertWhen_MsgSenderBlacklisted() public {
        _kumaBondToken.issueBond(address(this), _bond);
        _kumaBondToken.approve(_alice, 1);
        _blacklist.blacklist(_charlie);
        vm.expectRevert(abi.encodeWithSelector(Errors.BLACKLIST_ACCOUNT_IS_BLACKLISTED.selector, _charlie));
        vm.prank(_charlie);
        _kumaBondToken.transferFrom(address(this), _alice, 1);
    }

    function test_transferFrom_RevertWhen_Paused() public {
        _kumaBondToken.issueBond(address(this), _bond);
        _kumaBondToken.approve(_alice, 1);
        _kumaBondToken.pause();
        vm.expectRevert("Pausable: paused");
        _kumaBondToken.transferFrom(address(this), _alice, 1);
    }

    function test_safeTransferFrom() public {
        _kumaBondToken.issueBond(address(this), _bond);
        _kumaBondToken.approve(_alice, 1);
        vm.expectEmit(true, true, true, true);
        emit Transfer(address(this), _alice, 1);
        vm.prank(_alice);
        _kumaBondToken.safeTransferFrom(address(this), _alice, 1);
        assertEq(_kumaBondToken.ownerOf(1), _alice);
        assertEq(_kumaBondToken.balanceOf(_alice), 1);
    }

    function test_safeTransferFrom_RevertWhen_NotApproved() public {
        _kumaBondToken.issueBond(address(this), _bond);
        vm.expectRevert(abi.encodeWithSelector(Errors.ERC721_CALLER_IS_NOT_TOKEN_OWNER_OR_APPROVED.selector));
        vm.prank(_alice);
        _kumaBondToken.safeTransferFrom(address(this), _alice, 1);
    }

    function test_safeTransferFrom_RevertWhen_ToBlacklisted() public {
        _kumaBondToken.issueBond(address(this), _bond);
        _kumaBondToken.approve(_alice, 1);
        _blacklist.blacklist(_alice);
        vm.expectRevert(abi.encodeWithSelector(Errors.BLACKLIST_ACCOUNT_IS_BLACKLISTED.selector, _alice));
        _kumaBondToken.safeTransferFrom(address(this), _alice, 1);
    }

    function test_safeTransferFrom_RevertWhen_FromBlacklisted() public {
        _kumaBondToken.issueBond(address(this), _bond);
        _kumaBondToken.approve(_alice, 1);
        _blacklist.blacklist(address(this));
        vm.expectRevert(abi.encodeWithSelector(Errors.BLACKLIST_ACCOUNT_IS_BLACKLISTED.selector, address(this)));
        _kumaBondToken.safeTransferFrom(address(this), _alice, 1);
    }

    function test_safeTransferFrom_RevertWhen_MsgSenderBlacklisted() public {
        _kumaBondToken.issueBond(address(this), _bond);
        _kumaBondToken.approve(_alice, 1);
        _blacklist.blacklist(_charlie);
        vm.expectRevert(abi.encodeWithSelector(Errors.BLACKLIST_ACCOUNT_IS_BLACKLISTED.selector, _charlie));
        vm.prank(_charlie);
        _kumaBondToken.safeTransferFrom(address(this), _alice, 1);
    }

    function test_safeTransferFrom_RevertWhen_Paused() public {
        _kumaBondToken.issueBond(address(this), _bond);
        _kumaBondToken.approve(_alice, 1);
        _kumaBondToken.pause();
        vm.expectRevert("Pausable: paused");
        _kumaBondToken.safeTransferFrom(address(this), _alice, 1);
    }

    function test_pause() public {
        _kumaBondToken.pause();
        assertTrue(_kumaBondToken.paused());
        _kumaBondToken.unpause();
        assertFalse(_kumaBondToken.paused());
    }

    function test_pause_RevertWhen_CallerDoesNotHavePauseRole() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.ACCESS_CONTROL_ACCOUNT_IS_MISSING_ROLE.selector, _alice, Roles.MCAG_PAUSE_ROLE
            )
        );
        vm.prank(_alice);
        _kumaBondToken.pause();
    }

    function test_unpause_RevertWhen_CallerDoesNotHaveUnpauseRole() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.ACCESS_CONTROL_ACCOUNT_IS_MISSING_ROLE.selector, _alice, Roles.MCAG_UNPAUSE_ROLE
            )
        );
        vm.prank(_alice);
        _kumaBondToken.unpause();
    }
}
