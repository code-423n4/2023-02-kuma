// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";
import {ERC721Upgradeable} from "@openzeppelin-upgradeable/contracts/token/ERC721/ERC721Upgradeable.sol";
import {Errors} from "./libraries/Errors.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IKUMAAddressProvider} from "./interfaces/IKUMAAddressProvider.sol";
import {IKUMABondToken} from "@mcag/interfaces/IKUMABondToken.sol";
import {IKBCToken} from "./interfaces/IKBCToken.sol";
import {Roles} from "./libraries/Roles.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

contract KBCToken is ERC721Upgradeable, IKBCToken, UUPSUpgradeable {
    using Counters for Counters.Counter;

    IKUMAAddressProvider private _KUMAAddressProvider;
    Counters.Counter private _tokenIdCounter;

    mapping(uint256 => CloneBond) private _bonds;

    modifier onlyKUMASwap(uint256 parentId) {
        bytes32 riskCategory = IKUMABondToken(_KUMAAddressProvider.getKUMABondToken()).getBond(parentId).riskCategory;
        if (msg.sender != _KUMAAddressProvider.getKUMASwap(riskCategory)) {
            revert Errors.CALLER_NOT_KUMASWAP();
        }
        _;
    }

    constructor() initializer {}

    function initialize(IKUMAAddressProvider KUMAAddressProvider) external override initializer {
        if (address(KUMAAddressProvider) == address(0)) {
            revert Errors.CANNOT_SET_TO_ADDRESS_ZERO();
        }
        _KUMAAddressProvider = KUMAAddressProvider;
        __ERC721_init("KUMA Bonds Clone Token", "KBCT");

        emit KUMAAddressProviderSet(address(KUMAAddressProvider));
    }

    /**
     * @notice Mints a clone bond NFT to the specified address.
     * @dev Can only be called under specific conditions :
     *      - Caller must have MINT_ROLE
     *      - Receiver must not be blacklisted
     *      - Contract must not be paused
     * @param to Clone bond NFT receiver.
     * @param cBond Clone bond struct storing metadata.
     */
    function issueBond(address to, CloneBond memory cBond)
        external
        override
        onlyKUMASwap(cBond.parentId)
        returns (uint256 tokenId)
    {
        _tokenIdCounter.increment();
        tokenId = _tokenIdCounter.current();
        _bonds[tokenId] = cBond;
        _safeMint(to, tokenId);
        emit CloneBondIssued(tokenId, cBond);
    }

    /**
     * @notice Burns a clone bond NFT.
     * @dev Can only be called under specific conditions :
     *      - Caller must have BURN_ROLE
     *      - Contract must not be paused
     * @param tokenId Clone bond Id.
     */
    function redeem(uint256 tokenId) external override onlyKUMASwap(_bonds[tokenId].parentId) {
        CloneBond memory cBond = _bonds[tokenId];
        delete _bonds[tokenId];
        _burn(tokenId);
        emit CloneBondRedeemed(tokenId, cBond.parentId);
    }

    function getKUMAAddressProvider() external view override returns (IKUMAAddressProvider) {
        return _KUMAAddressProvider;
    }

    /**
     * @param tokenId Clone bond id.
     * @return Bond struct storing metadata of the selected bond id.
     */
    function getBond(uint256 tokenId) external view override returns (CloneBond memory) {
        if (_ownerOf(tokenId) == address(0)) {
            revert Errors.ERC721_INVALID_TOKEN_ID();
        }
        return _bonds[tokenId];
    }

    /**
     * @return Current token id counter.
     */
    function getTokenIdCounter() external view override returns (uint256) {
        return _tokenIdCounter.current();
    }

    function _authorizeUpgrade(address newImplementation) internal view override {
        if (!IAccessControl(_KUMAAddressProvider.getAccessController()).hasRole(Roles.KUMA_MANAGER_ROLE, msg.sender)) {
            revert Errors.ACCESS_CONTROL_ACCOUNT_IS_MISSING_ROLE(msg.sender, Roles.KUMA_MANAGER_ROLE);
        }
    }
}
