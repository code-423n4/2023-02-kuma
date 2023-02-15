// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {AccessController} from "@mcag/AccessController.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {Blacklist, IBlacklist} from "@mcag/Blacklist.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {MCAGAggregator, MCAGAggregatorInterface} from "@mcag/MCAGAggregator.sol";
import {MCAGRateFeed, IMCAGRateFeed} from "@kuma/MCAGRateFeed.sol";
import {KBCToken, IKBCToken} from "@kuma/KBCToken.sol";
import {KUMAAddressProvider, IKUMAAddressProvider} from "@kuma/KUMAAddressProvider.sol";
import {KUMAFeeCollector, IKUMAFeeCollector} from "@kuma/KUMAFeeCollector.sol";
import {KIBToken, IKIBToken} from "@kuma/KIBToken.sol";
import {KUMAAccessController} from "@kuma/KUMAAccessController.sol";
import {KUMABondToken, IKUMABondToken} from "@mcag/KUMABondToken.sol";
import {KUMASwap, IKUMASwap} from "@kuma/KUMASwap.sol";
import {MockERC20} from "@kuma/mocks/MockERC20.sol";
import {Roles} from "@kuma/libraries/Roles.sol";
import {Test, stdStorage, console2} from "forge-std/Test.sol";

abstract contract BaseSetUp is Test {
    using Roles for bytes32;

    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    string internal constant _NAME = "KUMA Interest Bearing Token";
    string internal constant _SYMBOL = "FRK360";
    bytes4 internal constant _SAFE_TRANSFER_FROM_SELECTOR =
        bytes4(keccak256("safeTransferFrom(address,address,uint256)"));
    bytes16 internal constant _CUSIP = bytes16("037833100");
    bytes16 internal constant _ISIN = bytes16("US0378331005");
    bytes4 internal constant _CURRENCY = "EUR";
    bytes4 internal constant _COUNTRY = "FR";
    uint64 internal constant _TERM = 365 days * 30;
    bytes32 internal constant _RISK_CATEGORY = keccak256(abi.encode(_CURRENCY, _COUNTRY, _TERM));
    uint256 internal constant _YIELD = 1000000001547125957863212449; // % 5 per year
    uint256 internal constant _EPOCH_LENGTH = 4 hours;

    address internal _alice = vm.addr(1);
    address internal _bob = vm.addr(2);
    address internal _clara = vm.addr(3);

    IAccessControl internal _mcagAccessController = IAccessControl(vm.addr(4));

    IAccessControl internal _KUMAAccessController;
    IBlacklist internal _blacklist;
    MockERC20 internal _deprecationStableCoin;
    MCAGAggregatorInterface internal _mcagAggregator;
    IKUMAAddressProvider internal _KUMAAddressProvider;
    IKUMABondToken internal _KUMABondToken;
    IKBCToken internal _KBCToken;
    IKIBToken internal _KIBToken;
    IKUMASwap internal _KUMASwap;
    IKUMAFeeCollector internal _KUMAFeeCollector;
    IMCAGRateFeed internal _rateFeed;

    constructor() {
        vm.warp(365 days * 30);

        // MCAGAggregator
        MCAGAggregator mcagAggregator =
            new MCAGAggregator("30 YEAR FR TREASURY", 1000000008319516284844715117, _mcagAccessController);
        _mcagAggregator = MCAGAggregatorInterface(address(mcagAggregator));

        // Access Controller
        KUMAAccessController KUMAAccessController_ = new KUMAAccessController();
        _KUMAAccessController = IAccessControl(KUMAAccessController_);

        // Blacklist
        Blacklist blacklist = new Blacklist(_KUMAAccessController);
        _blacklist = IBlacklist(address(blacklist));

        // KUMAAddressProvider
        KUMAAddressProvider KUMAAddressProvider_ = new KUMAAddressProvider();
        _KUMAAddressProvider = IKUMAAddressProvider(
            _deployUUPSProxy(
                address(KUMAAddressProvider_),
                abi.encodeWithSelector(IKUMAAddressProvider.initialize.selector, address(KUMAAccessController_))
            )
        );

        // KBCToken
        KBCToken KBCToken_ = new KBCToken();
        _KBCToken = IKBCToken(
            _deployUUPSProxy(
                address(KBCToken_), abi.encodeWithSelector(IKBCToken.initialize.selector, _KUMAAddressProvider)
            )
        );

        // KIBToken
        KIBToken KIBToken_ = new KIBToken();
        _KIBToken = IKIBToken(
            _deployUUPSProxy(
                address(KIBToken_),
                abi.encodeWithSelector(
                    IKIBToken.initialize.selector,
                    _NAME,
                    _SYMBOL,
                    _EPOCH_LENGTH,
                    _KUMAAddressProvider,
                    _CURRENCY,
                    _COUNTRY,
                    _TERM
                )
            )
        );

        // Deprecation Stable Coin
        _deprecationStableCoin = new MockERC20();

        // KUMASwap
        KUMASwap KUMASwap_ = new KUMASwap();
        _KUMASwap = IKUMASwap(
            _deployUUPSProxy(
                address(KUMASwap_),
                abi.encodeWithSelector(
                    IKUMASwap.initialize.selector,
                    _KUMAAddressProvider,
                    _deprecationStableCoin,
                    _CURRENCY,
                    _COUNTRY,
                    _TERM
                )
            )
        );

        // KUMABondToken
        KUMABondToken KUMABondToken_ = new KUMABondToken(_mcagAccessController, _blacklist);
        _KUMABondToken = IKUMABondToken(address(KUMABondToken_));

        // KUMAFeeCollector
        KUMAFeeCollector KUMAFeeCollector_ = new KUMAFeeCollector();
        _KUMAFeeCollector = IKUMAFeeCollector(
            _deployUUPSProxy(
                address(KUMAFeeCollector_),
                abi.encodeWithSelector(
                    IKUMAFeeCollector.initialize.selector, _KUMAAddressProvider, _CURRENCY, _COUNTRY, _TERM
                )
            )
        );

        // MCAGRateFeed
        MCAGRateFeed MCAGRateFeed_ = new MCAGRateFeed();
        _rateFeed = IMCAGRateFeed(
            _deployUUPSProxy(
                address(MCAGRateFeed_), abi.encodeWithSelector(IMCAGRateFeed.initialize.selector, _KUMAAccessController)
            )
        );

        skip(_EPOCH_LENGTH);

        _KUMAAccessController.grantRole(Roles.KUMA_SWAP_PAUSE_ROLE.toGranularRole(_RISK_CATEGORY), address(this));
        _KUMAAccessController.grantRole(Roles.KUMA_SWAP_UNPAUSE_ROLE.toGranularRole(_RISK_CATEGORY), address(this));
        _KUMAAccessController.grantRole(Roles.KUMA_SWAP_CLAIM_ROLE.toGranularRole(_RISK_CATEGORY), address(this));
        _KUMAAccessController.grantRole(Roles.KUMA_MINT_ROLE.toGranularRole(_RISK_CATEGORY), address(_KUMASwap));
        _KUMAAccessController.grantRole(Roles.KUMA_BURN_ROLE.toGranularRole(_RISK_CATEGORY), address(_KUMASwap));

        _KUMAAddressProvider.setKBCToken(address(_KBCToken));
        _KUMAAddressProvider.setKUMABondToken(address(_KUMABondToken));
        _KUMAAddressProvider.setRateFeed(address(_rateFeed));
        _KUMAAddressProvider.setKIBToken(_CURRENCY, _COUNTRY, _TERM, address(_KIBToken));
        _KUMAAddressProvider.setKUMASwap(_CURRENCY, _COUNTRY, _TERM, address(_KUMASwap));
        _KUMAAddressProvider.setKUMAFeeCollector(_CURRENCY, _COUNTRY, _TERM, address(_KUMAFeeCollector));

        _rateFeed.setOracle(_CURRENCY, _COUNTRY, _TERM, _mcagAggregator);

        vm.label(_alice, "Alice");
        vm.label(_bob, "Bob");
        vm.label(address(this), "Owner");
        vm.label(address(_KIBToken), "KIBToken");
        vm.label(address(_KUMABondToken), "KUMABondToken");
        vm.label(address(_KBCToken), "KBCToken");
        vm.label(address(_KUMASwap), "KUMASwap");
        vm.label(address(_rateFeed), "RateFeed");
        vm.label(address(_KUMAFeeCollector), "FeeCollector");
        vm.label(address(_deprecationStableCoin), "DeprecationStableCoin");

        vm.mockCall(
            address(_mcagAccessController),
            abi.encodeWithSelector(_KUMAAccessController.hasRole.selector),
            abi.encode(true)
        );
        _mcagAggregator.transmit(int256(_YIELD));
    }

    function _deployUUPSProxy(address implementationContract, bytes memory data) internal returns (address) {
        ERC1967Proxy proxy = new ERC1967Proxy(implementationContract, data);
        return address(proxy);
    }

    function _bytes32ToAddress(bytes32 data) internal pure returns (address) {
        return address(uint160(uint256(data)));
    }
}
