// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {IKIBToken} from "@kuma/interfaces/IKIBToken.sol";
import {IKUMASwap} from "@kuma/interfaces/IKUMASwap.sol";
import {IKUMABondToken} from "@mcag/interfaces/IKUMABondToken.sol";
import {MCAGAggregatorInterface} from "@mcag/interfaces/MCAGAggregatorInterface.sol";
import {Test} from "forge-std/Test.sol";
import {WadRayMath} from "@kuma/libraries/WadRayMath.sol";

contract InvariantKUMASwapUser is Test {
    using WadRayMath for uint256;

    uint256 public tokenIdCounter;

    bytes16 public constant _CUSIP = bytes16("037833100");
    bytes16 public constant _ISIN = bytes16("US0378331005");
    bytes4 internal constant _CURRENCY = "EUR";
    bytes4 internal constant _COUNTRY = "FR";

    uint256 private constant _MAX_COUPON = 1000000008319516284844715117; // 30%
    uint256 private constant _MAX_PRINCIPAL = 1e32;

    bool private _boundInputs;
    uint64 private _term;
    IKUMABondToken private _KUMABondToken;
    IKUMASwap private _KUMASwap;
    MCAGAggregatorInterface private _mcagAggregator;
    IKIBToken private _KIBToken;

    mapping(uint256 => bool) private _isBondInReserve;

    constructor(
        IKUMABondToken KUMABondToken,
        IKUMASwap KUMASwap,
        MCAGAggregatorInterface mcagAggregator,
        IKIBToken KIBToken,
        uint64 term,
        bool boundInputs
    ) {
        _KUMABondToken = KUMABondToken;
        _KUMASwap = KUMASwap;
        _mcagAggregator = mcagAggregator;
        _KIBToken = KIBToken;
        _term = term;
        _boundInputs = boundInputs;
    }

    function KUMASwapSellBond(uint256 coupon, uint256 principal, uint256 oracleRate) external {
        uint256 minCoupon = _KUMASwap.getMinCoupon();

        // Always bound as enforced at aggregator level
        oracleRate = bound(oracleRate, WadRayMath.RAY, _MAX_COUPON);

        if (_boundInputs) {
            principal = bound(principal, 0, _MAX_PRINCIPAL);
            coupon = bound(coupon, oracleRate > minCoupon ? oracleRate : minCoupon, _MAX_COUPON);
        }

        _KUMABondToken.issueBond(
            address(this),
            IKUMABondToken.Bond({
                cusip: _CUSIP,
                isin: _ISIN,
                currency: _CURRENCY,
                country: _COUNTRY,
                term: _term,
                issuance: uint64(block.timestamp),
                maturity: uint64(block.timestamp) + _term,
                coupon: coupon,
                principal: principal,
                riskCategory: _KUMASwap.getRiskCategory()
            })
        );

        _mcagAggregator.transmit(int256(oracleRate));
        ++tokenIdCounter;

        _KUMASwap.sellBond(tokenIdCounter);
    }

    function KUMASwapBuyBond(uint256 tokenId, uint256 oracleRate) external {
        tokenId = bound(tokenId, 0, tokenIdCounter);

        if (!_isBondInReserve[tokenId]) return;

        oracleRate = bound(oracleRate, WadRayMath.RAY, _MAX_COUPON);

        _mcagAggregator.transmit(int256(oracleRate));

        _KUMASwap.buyBond(tokenId);

        _isBondInReserve[tokenId] = false;
        IKUMABondToken.Bond memory bond = _KUMABondToken.getBond(tokenId);
        uint256 bondFaceValue = _getBondValue(bond.issuance, bond.term, bond.coupon, bond.principal);
        uint256 realizedBondValue =
            _KUMASwap.getBondBaseValue(tokenId).rayMul(_KIBToken.getUpdatedCumulativeYield()).rayToWad();

        if (bondFaceValue > realizedBondValue) {
            assertTrue(_KUMASwap.getCloneBond(tokenId) != 0);
        }
    }

    function _getBondValue(uint256 issuance, uint256 term, uint256 coupon, uint256 principal)
        internal
        view
        returns (uint256)
    {
        uint256 previousEpochTimestamp = _KIBToken.getPreviousEpochTimestamp();

        if (previousEpochTimestamp <= issuance) {
            return principal;
        }

        uint256 elapsedTime = previousEpochTimestamp - issuance;

        if (elapsedTime > term) {
            elapsedTime = term;
        }

        return coupon.rayPow(elapsedTime).rayMul(principal);
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
        external
        pure
        returns (bytes4)
    {
        return IERC721Receiver.onERC721Received.selector;
    }
}
