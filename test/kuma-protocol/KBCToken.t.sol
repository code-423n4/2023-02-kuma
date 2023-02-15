// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "./BaseSetUp.t.sol";
import {Errors} from "@kuma/libraries/Errors.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import {WadRayMath} from "@kuma/libraries/WadRayMath.sol";

contract KBCTokenTest is BaseSetUp {
    using Roles for bytes32;
    using WadRayMath for uint256;

    event KUMAAddressProviderSet(address KUMAAddressProvider);
    event CloneBondIssued(uint256 ghostId, IKBCToken.CloneBond cloneBond);
    event CloneBondRedeemed(uint256 ghostId, uint256 parentId);

    string internal constant _SYMBOL_ = "USK360";
    bytes4 internal constant _CURRENCY_ = "US";
    bytes4 internal constant _COUNTRY_ = "US";
    uint64 internal constant _TERM_ = 365 days * 3;
    bytes32 internal constant _RISK_CATEGORY_ = keccak256(abi.encode(_CURRENCY_, _COUNTRY_, _TERM_));

    IKIBToken internal _KIBToken2;
    IKUMASwap internal _KUMASwap2;
    IKUMAFeeCollector internal _KUMAFeeCollector2;

    uint256 private constant _ORACLE_RATE = 1000000000937303470807876290; // 3%

    IKUMABondToken.Bond private _bond;

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
        external
        pure
        returns (bytes4)
    {
        return IERC721Receiver.onERC721Received.selector;
    }

    function setUp() public {
        // Deploy new risk category contracts
        KIBToken KIBToken_ = new KIBToken();
        _KIBToken2 = IKIBToken(
            _deployUUPSProxy(
                address(KIBToken_),
                abi.encodeWithSelector(
                    IKIBToken.initialize.selector,
                    _NAME,
                    _SYMBOL_,
                    _EPOCH_LENGTH,
                    _KUMAAddressProvider,
                    _CURRENCY_,
                    _COUNTRY_,
                    _TERM_
                )
            )
        );

        KUMASwap KUMASwap_ = new KUMASwap();
        _KUMASwap2 = IKUMASwap(
            _deployUUPSProxy(
                address(KUMASwap_),
                abi.encodeWithSelector(
                    IKUMASwap.initialize.selector,
                    _KUMAAddressProvider,
                    IERC20(address(_deprecationStableCoin)),
                    _CURRENCY_,
                    _COUNTRY_,
                    _TERM_
                )
            )
        );

        KUMAFeeCollector KUMAFeeCollector_ = new KUMAFeeCollector();
        _KUMAFeeCollector2 = IKUMAFeeCollector(
            _deployUUPSProxy(
                address(KUMAFeeCollector_),
                abi.encodeWithSelector(
                    IKUMAFeeCollector.initialize.selector, _KUMAAddressProvider, _CURRENCY_, _COUNTRY_, _TERM_
                )
            )
        );

        vm.label(address(_KUMASwap2), "KUMA Swap 2");
        vm.label(address(_KIBToken2), "KIBToken 2");
        vm.label(address(_KUMAFeeCollector2), "KUMAFeeCollector 2");

        _KUMAAddressProvider.setKUMAFeeCollector(_CURRENCY_, _COUNTRY_, _TERM_, address(_KUMAFeeCollector2));
        _KUMAAddressProvider.setKIBToken(_CURRENCY_, _COUNTRY_, _TERM_, address(_KIBToken2));
        _KUMAAddressProvider.setKUMASwap(_CURRENCY_, _COUNTRY_, _TERM_, address(_KUMASwap2));

        _rateFeed.setOracle(_CURRENCY_, _COUNTRY_, _TERM_, _mcagAggregator);

        _KUMAAccessController.grantRole(Roles.KUMA_MINT_ROLE.toGranularRole(_RISK_CATEGORY_), address(_KUMASwap2));
        _KUMAAccessController.grantRole(Roles.KUMA_BURN_ROLE.toGranularRole(_RISK_CATEGORY_), address(_KUMASwap2));

        _bond = IKUMABondToken.Bond({
            cusip: _CUSIP,
            isin: _ISIN,
            currency: _CURRENCY,
            country: _COUNTRY,
            term: _TERM,
            issuance: uint64(block.timestamp),
            maturity: uint64(block.timestamp + 365 days * 3),
            coupon: _YIELD,
            principal: 10 ether,
            riskCategory: _RISK_CATEGORY
        });

        _mcagAggregator.transmit(int256(_ORACLE_RATE));
        _KUMABondToken.issueBond(address(this), _bond);
        _KUMABondToken.setApprovalForAll(address(_KUMASwap), true);
        _KUMABondToken.setApprovalForAll(address(_KUMASwap2), true);
        _KUMASwap.sellBond(1);
        skip(365 days);
    }

    function test_initialize() public {
        assertEq(address(_KBCToken.getKUMAAddressProvider()), address(_KUMAAddressProvider));

        KBCToken newKBCToken = new KBCToken();

        vm.expectEmit(false, false, false, true);
        emit KUMAAddressProviderSet(address(_KUMAAddressProvider));

        _deployUUPSProxy(
            address(newKBCToken), abi.encodeWithSelector(IKBCToken.initialize.selector, _KUMAAddressProvider)
        );
    }

    function test_initialize_RevertWhen_InitializedWithInvalidParameters() public {
        KBCToken newKBCToken = new KBCToken();

        vm.expectRevert(Errors.CANNOT_SET_TO_ADDRESS_ZERO.selector);

        _deployUUPSProxy(
            address(newKBCToken),
            abi.encodeWithSelector(IKBCToken.initialize.selector, IKUMAAddressProvider(address(0)))
        );
    }

    function test_issueBond() public {
        vm.expectEmit(false, false, false, true);
        emit CloneBondIssued(
            1,
            IKBCToken.CloneBond({
                parentId: 1,
                issuance: _KIBToken.getPreviousEpochTimestamp(),
                coupon: _ORACLE_RATE,
                principal: _KUMASwap.getBondBaseValue(1).rayMul(_KIBToken.getUpdatedCumulativeYield()).rayToWad()
            })
            );
        _KUMASwap.buyBond(1);

        assertEq(_KBCToken.getBond(1).parentId, 1);
        assertEq(_KBCToken.getBond(1).coupon, _ORACLE_RATE);
        assertEq(_KBCToken.ownerOf(1), address(this));
        assertEq(_KBCToken.balanceOf(address(this)), 1);
        assertEq(_KBCToken.getTokenIdCounter(), 1);
    }

    function test_issueBond_WithDifferentRiskCategories() public {
        _bond.riskCategory = _RISK_CATEGORY_;
        _bond.maturity = uint64(block.timestamp + _TERM_);

        _KUMABondToken.issueBond(address(this), _bond);

        // Sell bond on KUMASwap with different risk category
        _KUMASwap2.sellBond(2);
        skip(365 days);

        vm.expectEmit(false, false, false, true);
        emit CloneBondIssued(
            1,
            IKBCToken.CloneBond({
                parentId: 2,
                issuance: _KIBToken2.getPreviousEpochTimestamp(),
                coupon: _ORACLE_RATE,
                principal: _KUMASwap2.getBondBaseValue(2).rayMul(_KIBToken2.getUpdatedCumulativeYield()).rayToWad()
            })
            );
        _KUMASwap2.buyBond(2);
        vm.expectEmit(false, false, false, true);
        emit CloneBondIssued(
            2,
            IKBCToken.CloneBond({
                parentId: 1,
                issuance: _KIBToken.getPreviousEpochTimestamp(),
                coupon: _ORACLE_RATE,
                principal: _KUMASwap.getBondBaseValue(1).rayMul(_KIBToken.getUpdatedCumulativeYield()).rayToWad()
            })
            );
        _KUMASwap.buyBond(1);

        assertEq(_KBCToken.getTokenIdCounter(), 2);
        assertEq(_KBCToken.getBond(1).parentId, 2);
        assertEq(_KBCToken.getBond(2).parentId, 1);
    }

    function test_issueBond_RevertWhen_NotKUMASwap() public {
        vm.expectRevert(Errors.CALLER_NOT_KUMASWAP.selector);
        _KBCToken.issueBond(
            address(this),
            IKBCToken.CloneBond({parentId: 1, issuance: block.timestamp, coupon: _ORACLE_RATE, principal: 10 ether})
        );
    }

    function test_redeemBond() public {
        _KUMASwap.buyBond(1);
        vm.expectEmit(false, false, false, true);
        emit CloneBondRedeemed(1, 1);
        _KUMASwap.claimBond(1);

        assertEq(_KBCToken.balanceOf(address(this)), 0);

        vm.expectRevert(Errors.ERC721_INVALID_TOKEN_ID.selector);
        _KBCToken.getBond(1);
    }

    function test_redeemBond_RevertWhen_NotKUMASwap() public {
        vm.expectEmit(false, false, false, true);
        emit CloneBondIssued(
            1,
            IKBCToken.CloneBond({
                parentId: 1,
                issuance: _KIBToken.getPreviousEpochTimestamp(),
                coupon: _ORACLE_RATE,
                principal: _KUMASwap.getBondBaseValue(1).rayMul(_KIBToken.getUpdatedCumulativeYield()).rayToWad()
            })
            );
        _KUMASwap.buyBond(1);
        vm.expectRevert(Errors.CALLER_NOT_KUMASWAP.selector);
        _KBCToken.redeem(1);
    }

    function test_upgrade() public {
        KBCToken newKBCToken = new KBCToken();
        UUPSUpgradeable(address(_KBCToken)).upgradeTo(address(newKBCToken));
        assertEq(_bytes32ToAddress(vm.load(address(_KBCToken), _IMPLEMENTATION_SLOT)), address(newKBCToken));
    }

    function test_upgrade_RevertWhen_CallerIsNotManager() public {
        KBCToken newKBCToken = new KBCToken();
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.ACCESS_CONTROL_ACCOUNT_IS_MISSING_ROLE.selector, _alice, Roles.KUMA_MANAGER_ROLE
            )
        );
        vm.prank(_alice);
        UUPSUpgradeable(address(_KBCToken)).upgradeTo(address(newKBCToken));
    }
}
