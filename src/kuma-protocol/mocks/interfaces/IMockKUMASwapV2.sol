// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {IKUMAAddressProvider} from "../../interfaces/IKUMAAddressProvider.sol";

interface IMockKUMASwapV2 is IERC721Receiver {
    event BondBought(uint256 tokenId, uint256 KIBTokenBurned, address indexed buyer);
    event BondClaimed(uint256 tokenId, uint256 cloneTokenId);
    event BondExpired(uint256 tokenId);
    event BondSold(uint256 tokenId, uint256 KIBTokenMinted, address indexed seller);
    event DeprecationModeInitialized();
    event DeprecationModeEnabled();
    event DeprecationModeUninitialized();
    event DeprecationStableCoinSet(address oldDeprecationStableCoin, address newDeprecationStableCoin);
    event FeeCharged(uint256 fee);
    event FeeSet(uint16 variableFee, uint256 fixedFee);
    event MinCouponUpdated(uint256 oldMinCoupon, uint256 newMinCoupon);
    event KIBTRedeemed(address indexed redeemer, uint256 redeemedStableCoinAmount);

    function reinitialize() external;

    function sellAsset(uint256 tokenId) external;

    function buyAsset(uint256 tokenId) external;

    function buyAssetForStableCoin(uint256 tokenId, address buyer, uint256 amount) external;

    function claimAsset(uint256 tokenId) external;

    function redeemKIBT(uint256 amount) external;

    function pause() external;

    function unpause() external;

    function expireBond(uint256 tokenId) external;

    function setFees(uint16 variableFee, uint256 fixedFee) external;

    function setDeprecationStableCoin(IERC20 newDeprecationStableCoin) external;

    function initializeDeprecationMode() external;

    function uninitializeDeprecationMode() external;

    function enableDeprecationMode() external;

    function getRiskCategory() external view returns (bytes32);

    function getMaxCoupons() external view returns (uint16);

    function getKUMAAddressProvider() external returns (IKUMAAddressProvider);

    function isDeprecationInitialized() external view returns (bool);

    function getDeprecationInitializedAt() external view returns (uint56);

    function isDeprecated() external view returns (bool);

    function getVariableFee() external view returns (uint16);

    function getDeprecationStableCoin() external view returns (IERC20);

    function getFixedFee() external view returns (uint256);

    function getMinCoupon() external view returns (uint256);

    function getCoupons() external view returns (uint256[] memory);

    function getCouponIndex(uint256 coupon) external view returns (uint256);

    function getBondReserve() external view returns (uint256[] memory);

    function getExpiredBonds() external view returns (uint256[] memory);

    function getBondIndex(uint256 tokenId) external view returns (uint256);

    function getCloneBond(uint256 tokenId) external view returns (uint256);

    function getCouponInventory(uint256 coupon) external view returns (uint256);

    function isInReserve(uint256 tokenId) external view returns (bool);

    function isExpired() external view returns (bool);

    function getBondBaseValue(uint256 tokenId) external view returns (uint256);

    function getDummyVar0() external view returns (uint256);

    function version() external pure returns (uint8);
}
