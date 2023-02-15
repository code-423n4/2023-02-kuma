// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {AccessController} from "@mcag/AccessController.sol";
import {Errors} from "@mcag/libraries/Errors.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {KYCToken, IKYCToken} from "@mcag/KYCToken.sol";
import {Roles} from "@mcag/libraries/Roles.sol";
import {Test, console2} from "forge-std/Test.sol";

contract KYCTokenTest is Test {
    event AccessControllerSet(address accesController);
    event Mint(address indexed to, IKYCToken.KYCData kycData);
    event Burn(uint256 tokenId, IKYCToken.KYCData kycData);
    event UriSet(string oldUri, string newUri);

    address private _alice = vm.addr(1);
    address private _multisig = 0xcc8793d5eB95fAa707ea4155e09b2D3F44F33D1E;
    IKYCToken.KYCData private _kycData;

    AccessController private _accessController;
    KYCToken private _kycToken;

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
        external
        returns (bytes4)
    {
        return IERC721Receiver.onERC721Received.selector;
    }

    function setUp() public {
        _accessController = new AccessController();
        _kycToken = new KYCToken(IAccessControl(_accessController));

        _kycData = IKYCToken.KYCData({owner: address(this), kycInfo: keccak256(abi.encode("John", "Doe", "ID12345"))});
    }

    function test_constructor() public {
        vm.expectEmit(false, false, false, true);
        emit AccessControllerSet(address(_accessController));

        KYCToken newKYCToken = new KYCToken(_accessController);

        assertEq(address(newKYCToken.accessController()), address(_accessController));
    }

    function test_constructor_RevertWhen_InitializedWithInvalidParameters() public {
        vm.expectRevert(Errors.CANNOT_SET_TO_ADDRESS_ZERO.selector);
        new KYCToken(IAccessControl(address(0)));
    }

    function test_mint() public {
        vm.expectEmit(true, false, false, true);
        emit Mint(address(this), _kycData);
        _kycToken.mint(address(this), _kycData);

        IKYCToken.KYCData memory kycData = _kycToken.getKycData(1);

        assertEq(_kycToken.getTokenIdCounter(), 1);
        assertEq(kycData.owner, address(this));
        assertEq(kycData.kycInfo, _kycData.kycInfo);
        assertEq(_kycToken.ownerOf(1), address(this));
        assertEq(_kycToken.balanceOf(address(this)), 1);
    }

    function test_mint_RevertWhen_CallerDoesNotHaveMintRole() public {
        vm.expectRevert(
            abi.encodeWithSelector(Errors.ACCESS_CONTROL_ACCOUNT_IS_MISSING_ROLE.selector, _alice, Roles.MCAG_MINT_ROLE)
        );
        vm.prank(_alice);
        _kycToken.mint(_alice, _kycData);
    }

    function test_burn() public {
        _kycToken.mint(address(this), _kycData);
        vm.expectEmit(false, false, false, true);
        emit Burn(1, _kycData);
        _kycToken.burn(1);

        vm.expectRevert(Errors.ERC721_INVALID_TOKEN_ID.selector);
        _kycToken.getKycData(1);

        assertEq(_kycToken.getTokenIdCounter(), 1);
        assertEq(_kycToken.balanceOf(address(this)), 0);
    }

    function test_burn_RevertWhen_CallerDoesNotHaveBurnRole() public {
        vm.expectRevert(
            abi.encodeWithSelector(Errors.ACCESS_CONTROL_ACCOUNT_IS_MISSING_ROLE.selector, _alice, Roles.MCAG_BURN_ROLE)
        );
        vm.prank(_alice);
        _kycToken.burn(1);
    }

    function test_burn_RevertWhen_InvalidTokenId() public {
        vm.expectRevert(Errors.ERC721_INVALID_TOKEN_ID.selector);
        _kycToken.burn(1);
    }

    function test_setUri() public {
        _kycToken.mint(address(this), _kycData);
        string memory newUri = "https://game.example/item-id-8u5h2m.json/";
        vm.expectEmit(false, false, false, true);
        emit UriSet("", newUri);
        _kycToken.setUri(newUri);

        bytes memory expectedUri = abi.encode("https://game.example/item-id-8u5h2m.json/1");

        assertEq(abi.encode(_kycToken.tokenURI(1)), expectedUri);
    }

    function test_setUri_RevertWhen_CallerDoesNotHaveSetUriRole() public {
        string memory newUri = "https://game.example/item-id-8u5h2m.json/";
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.ACCESS_CONTROL_ACCOUNT_IS_MISSING_ROLE.selector, _alice, Roles.MCAG_SET_URI_ROLE
            )
        );
        vm.prank(_alice);
        _kycToken.setUri(newUri);
    }

    function test_approve_RevertWhen_Called() public {
        vm.expectRevert(Errors.TOKEN_IS_NOT_TRANSFERABLE.selector);
        _kycToken.approve(address(this), 1);
    }

    function test_setApprovalForAll_RevertWhen_Called() public {
        vm.expectRevert(Errors.TOKEN_IS_NOT_TRANSFERABLE.selector);
        _kycToken.setApprovalForAll(address(this), true);
    }

    function test_transferFrom_RevertWhen_Called() public {
        vm.expectRevert(Errors.TOKEN_IS_NOT_TRANSFERABLE.selector);
        _kycToken.transferFrom(_alice, address(this), 1);
    }

    function test_safeTransferFrom_RevertWhen_Called() public {
        vm.expectRevert(Errors.TOKEN_IS_NOT_TRANSFERABLE.selector);
        _kycToken.safeTransferFrom(address(this), _alice, 1);
    }
}
