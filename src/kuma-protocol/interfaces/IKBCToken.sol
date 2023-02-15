// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {IERC721Upgradeable} from "@openzeppelin-upgradeable/contracts/token/ERC721/IERC721Upgradeable.sol";
import {IKUMAAddressProvider} from "./IKUMAAddressProvider.sol";

interface IKBCToken is IERC721Upgradeable {
    event KUMAAddressProviderSet(address KUMAAddressProvider);
    event CloneBondIssued(uint256 ghostId, CloneBond cloneBond);
    event CloneBondRedeemed(uint256 ghostId, uint256 parentId);

    /**
     * @param parentId Token id of the part KUMABondToken.
     * @param issuance Timestamp of the CloneBond issuance. Overwrites the parent's issuance.
     * @param coupon Clone bond coupon overriding the parent's.
     * Is set to lowest yield of central bank rate and minCoupon at the time of issuance.
     * @param principal Clone bond principal override the parent's. Is set to the bond realized value at issuance.
     */
    struct CloneBond {
        uint256 parentId;
        uint256 issuance;
        uint256 coupon;
        uint256 principal;
    }

    function initialize(IKUMAAddressProvider KUMAAddressProvider) external;

    function issueBond(address to, CloneBond memory cBond) external returns (uint256 tokenId);

    function redeem(uint256 tokenId) external;

    function getKUMAAddressProvider() external returns (IKUMAAddressProvider);

    function getBond(uint256) external view returns (CloneBond memory);

    function getTokenIdCounter() external returns (uint256);
}
