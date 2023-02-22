# KUMA Protocol Versus contest details

- Total Prize Pool: $38,600 USDC
  - HM awards: $25,500 USDC 
  - QA report awards: $3,000 USDC
  - Gas report awards: $1,500 USDC 
  - Judge + presort awards: $8,100 USDC 
  - Scout awards: $500 USDC 
- Join [C4 Discord](https://discord.gg/code4rena) to register
- Submit findings [using the C4 form](https://code4rena.com/contests/2023-02-kuma-protocol-versus-contest/submit)
- [Read our guidelines for more details](https://docs.code4rena.com/roles/wardens)
- Starts February 17, 2023 20:00 UTC
- Ends February 22, 2023 20:00 UTC

# Overview

This repo contains source contracts and testing suites for the MCAG contracts and the KUMA Protocol. Each corresponding project directory contains documentation in the /docs folder.

The [src/kuma-protocol/](https://github.com/code-423n4/2023-02-kuma/tree/main/src/kuma-protocol) folder contains the contracts that comprise the decentralized KUMA protocol. See [docs/kuma-protocol/](https://github.com/code-423n4/2023-02-kuma/tree/main/docs/kuma-protocol/) for KUMA protocol docs.

The [src/mcag-contracts/](https://github.com/code-423n4/2023-02-kuma/tree/main/src/mcag-contracts) contains contracts that are managed by the centralized MCAG entity. See [docs/mcag-contracts/](https://github.com/code-423n4/2023-02-kuma/tree/main/docs/mcag-contracts/) for MCAG contracts docs.

## Scope
### Files in scope
|File|[SLOC](#nowhere "(nSLOC, SLOC, Lines)")|Description and [Coverage](#nowhere "(Lines hit / Total)")|Libraries|
|:-|:-:|:-|:-|
|_Contracts (12)_|
|[src/kuma-protocol/KUMAAccessController.sol](https://github.com/code-423n4/2023-02-kuma/blob/main/src/kuma-protocol/KUMAAccessController.sol)|[9](#nowhere "(nSLOC:9, SLOC:9, Lines:12)")|-| [`@openzeppelin/*`](https://openzeppelin.com/contracts/)|
|[src/mcag-contracts/AccessController.sol](https://github.com/code-423n4/2023-02-kuma/blob/main/src/mcag-contracts/AccessController.sol)|[16](#nowhere "(nSLOC:16, SLOC:16, Lines:19)")|-| [`@openzeppelin/*`](https://openzeppelin.com/contracts/)|
|[src/mcag-contracts/Blacklist.sol](https://github.com/code-423n4/2023-02-kuma/blob/main/src/mcag-contracts/Blacklist.sol)|[33](#nowhere "(nSLOC:33, SLOC:33, Lines:58)")|Central registry for blacklisted addresses that are not allowed to interact with the NFT, &nbsp;&nbsp;[100.00%](#nowhere "(Hit:5 / Total:5)")| [`@openzeppelin/*`](https://openzeppelin.com/contracts/)|
|[src/kuma-protocol/KBCToken.sol](https://github.com/code-423n4/2023-02-kuma/blob/main/src/kuma-protocol/KBCToken.sol)|[67](#nowhere "(nSLOC:62, SLOC:67, Lines:105)")|A Clone Bond NFT Token that is issued when the KIBT yield is not high enough to buy back the original Bond NFT, &nbsp;&nbsp;[100.00%](#nowhere "(Hit:21 / Total:21)")| [`@openzeppelin/*`](https://openzeppelin.com/contracts/) `@openzeppelin-upgradeable/*` `@mcag/*`|
|[src/mcag-contracts/MCAGAggregator.sol](https://github.com/code-423n4/2023-02-kuma/blob/main/src/mcag-contracts/MCAGAggregator.sol)|[67](#nowhere "(nSLOC:62, SLOC:67, Lines:121)")|Oracle that MCAG manages to publish central bank rates, &nbsp;&nbsp;[100.00%](#nowhere "(Hit:16 / Total:16)")| [`@openzeppelin/*`](https://openzeppelin.com/contracts/)|
|[src/kuma-protocol/MCAGRateFeed.sol](https://github.com/code-423n4/2023-02-kuma/blob/main/src/kuma-protocol/MCAGRateFeed.sol) [🧮](#nowhere "Uses Hash-Functions")|[75](#nowhere "(nSLOC:71, SLOC:75, Lines:122)")|Contract that reads the price from the MCAG central bank rate oracle, &nbsp;&nbsp;[100.00%](#nowhere "(Hit:28 / Total:28)")| [`@openzeppelin/*`](https://openzeppelin.com/contracts/) `@mcag/*`|
|[src/mcag-contracts/KYCToken.sol](https://github.com/code-423n4/2023-02-kuma/blob/main/src/mcag-contracts/KYCToken.sol)|[77](#nowhere "(nSLOC:73, SLOC:77, Lines:140)")|Untransferable NFT that MCAG will airdrop to KYC users, &nbsp;&nbsp;[100.00%](#nowhere "(Hit:22 / Total:22)")| [`@openzeppelin/*`](https://openzeppelin.com/contracts/)|
|[src/kuma-protocol/KUMAAddressProvider.sol](https://github.com/code-423n4/2023-02-kuma/blob/main/src/kuma-protocol/KUMAAddressProvider.sol) [🧮](#nowhere "Uses Hash-Functions")|[118](#nowhere "(nSLOC:103, SLOC:118, Lines:143)")|AddressProvider that stores the mappings for the KIBT, KUMASwap and KUMAFeeCollector for each risk class, &nbsp;&nbsp;[100.00%](#nowhere "(Hit:35 / Total:35)")| [`@openzeppelin/*`](https://openzeppelin.com/contracts/)|
|[src/mcag-contracts/KUMABondToken.sol](https://github.com/code-423n4/2023-02-kuma/blob/main/src/mcag-contracts/KUMABondToken.sol)|[134](#nowhere "(nSLOC:102, SLOC:134, Lines:224)")|NFT that MCAG will issue for each purchased real world bond, &nbsp;&nbsp;[100.00%](#nowhere "(Hit:32 / Total:32)")| [`@openzeppelin/*`](https://openzeppelin.com/contracts/)|
|[src/kuma-protocol/KUMAFeeCollector.sol](https://github.com/code-423n4/2023-02-kuma/blob/main/src/kuma-protocol/KUMAFeeCollector.sol) [🧮](#nowhere "Uses Hash-Functions")|[159](#nowhere "(nSLOC:155, SLOC:159, Lines:250)")|[100.00%](#nowhere "(Hit:82 / Total:82)")| [`@openzeppelin/*`](https://openzeppelin.com/contracts/)|
|[src/kuma-protocol/KIBToken.sol](https://github.com/code-423n4/2023-02-kuma/blob/main/src/kuma-protocol/KIBToken.sol) [🧮](#nowhere "Uses Hash-Functions")|[251](#nowhere "(nSLOC:235, SLOC:251, Lines:372)")|Interesting Bearing ERC20, one for each risk class, &nbsp;&nbsp;[100.00%](#nowhere "(Hit:123 / Total:123)")| `@openzeppelin-upgradeable/*` [`@openzeppelin/*`](https://openzeppelin.com/contracts/)|
|[src/kuma-protocol/KUMASwap.sol](https://github.com/code-423n4/2023-02-kuma/blob/main/src/kuma-protocol/KUMASwap.sol) [🧮](#nowhere "Uses Hash-Functions") [Σ](#nowhere "Unchecked Blocks")|[394](#nowhere "(nSLOC:365, SLOC:394, Lines:644)")|Main contract that always swapping a Bond NFT for the KIBT ERC20, one KUMASwap per risk class (country, term, currency), &nbsp;&nbsp;[100.00%](#nowhere "(Hit:180 / Total:180)")| [`@openzeppelin/*`](https://openzeppelin.com/contracts/) `@mcag/*` `@openzeppelin-upgradeable/*`|
|_Interfaces (10)_|
|[src/mcag-contracts/interfaces/IBlacklist.sol](https://github.com/code-423n4/2023-02-kuma/blob/main/src/mcag-contracts/interfaces/IBlacklist.sol)|[11](#nowhere "(nSLOC:11, SLOC:11, Lines:18)")|-| [`@openzeppelin/*`](https://openzeppelin.com/contracts/)|
|[src/kuma-protocol/interfaces/IMCAGRateFeed.sol](https://github.com/code-423n4/2023-02-kuma/blob/main/src/kuma-protocol/interfaces/IMCAGRateFeed.sol)|[14](#nowhere "(nSLOC:14, SLOC:14, Lines:24)")|-| [`@openzeppelin/*`](https://openzeppelin.com/contracts/) `@mcag/*`|
|[src/mcag-contracts/interfaces/MCAGAggregatorInterface.sol](https://github.com/code-423n4/2023-02-kuma/blob/main/src/mcag-contracts/interfaces/MCAGAggregatorInterface.sol)|[15](#nowhere "(nSLOC:12, SLOC:15, Lines:23)")|-||
|[src/mcag-contracts/interfaces/IKYCToken.sol](https://github.com/code-423n4/2023-02-kuma/blob/main/src/mcag-contracts/interfaces/IKYCToken.sol)|[17](#nowhere "(nSLOC:17, SLOC:17, Lines:26)")|-| [`@openzeppelin/*`](https://openzeppelin.com/contracts/)|
|[src/kuma-protocol/interfaces/IKBCToken.sol](https://github.com/code-423n4/2023-02-kuma/blob/main/src/kuma-protocol/interfaces/IKBCToken.sol)|[20](#nowhere "(nSLOC:20, SLOC:20, Lines:37)")|-| `@openzeppelin-upgradeable/*`|
|[src/kuma-protocol/interfaces/IKUMAFeeCollector.sol](https://github.com/code-423n4/2023-02-kuma/blob/main/src/kuma-protocol/interfaces/IKUMAFeeCollector.sol)|[22](#nowhere "(nSLOC:21, SLOC:22, Lines:36)")|-||
|[src/kuma-protocol/interfaces/IKUMAAddressProvider.sol](https://github.com/code-423n4/2023-02-kuma/blob/main/src/kuma-protocol/interfaces/IKUMAAddressProvider.sol)|[27](#nowhere "(nSLOC:27, SLOC:27, Lines:44)")|-| [`@openzeppelin/*`](https://openzeppelin.com/contracts/)|
|[src/mcag-contracts/interfaces/IKUMABondToken.sol](https://github.com/code-423n4/2023-02-kuma/blob/main/src/mcag-contracts/interfaces/IKUMABondToken.sol)|[32](#nowhere "(nSLOC:32, SLOC:32, Lines:57)")|-| [`@openzeppelin/*`](https://openzeppelin.com/contracts/)|
|[src/kuma-protocol/interfaces/IKIBToken.sol](https://github.com/code-423n4/2023-02-kuma/blob/main/src/kuma-protocol/interfaces/IKIBToken.sol)|[38](#nowhere "(nSLOC:30, SLOC:38, Lines:56)")|-| [`@openzeppelin/*`](https://openzeppelin.com/contracts/) `@openzeppelin-upgradeable/*`|
|[src/kuma-protocol/interfaces/IKUMASwap.sol](https://github.com/code-423n4/2023-02-kuma/blob/main/src/kuma-protocol/interfaces/IKUMASwap.sol)|[59](#nowhere "(nSLOC:53, SLOC:59, Lines:94)")|-| [`@openzeppelin/*`](https://openzeppelin.com/contracts/)|
|Total (over 22 files):| [1655](#nowhere "(nSLOC:1523, SLOC:1655, Lines:2625)") |[100.00%](#nowhere "Hit:544 / Total:544")|

## Out of scope

All other files in the repo

## External imports
* **@mcag/interfaces/IKUMABondToken.sol**
  * [src/kuma-protocol/KBCToken.sol](https://github.com/code-423n4/2023-02-kuma/blob/main/src/kuma-protocol/KBCToken.sol)
  * [src/kuma-protocol/KUMASwap.sol](https://github.com/code-423n4/2023-02-kuma/blob/main/src/kuma-protocol/KUMASwap.sol)
* **@mcag/interfaces/MCAGAggregatorInterface.sol**
  * [src/kuma-protocol/MCAGRateFeed.sol](https://github.com/code-423n4/2023-02-kuma/blob/main/src/kuma-protocol/MCAGRateFeed.sol)
  * [src/kuma-protocol/interfaces/IMCAGRateFeed.sol](https://github.com/code-423n4/2023-02-kuma/blob/main/src/kuma-protocol/interfaces/IMCAGRateFeed.sol)
* **@openzeppelin-upgradeable/contracts/interfaces/IERC20MetadataUpgradeable.sol**
  * [src/kuma-protocol/interfaces/IKIBToken.sol](https://github.com/code-423n4/2023-02-kuma/blob/main/src/kuma-protocol/interfaces/IKIBToken.sol)
* **@openzeppelin-upgradeable/contracts/security/PausableUpgradeable.sol**
  * [src/kuma-protocol/KUMASwap.sol](https://github.com/code-423n4/2023-02-kuma/blob/main/src/kuma-protocol/KUMASwap.sol)
* **@openzeppelin-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol**
  * [src/kuma-protocol/KIBToken.sol](https://github.com/code-423n4/2023-02-kuma/blob/main/src/kuma-protocol/KIBToken.sol)
* **@openzeppelin-upgradeable/contracts/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol**
  * [src/kuma-protocol/KIBToken.sol](https://github.com/code-423n4/2023-02-kuma/blob/main/src/kuma-protocol/KIBToken.sol)
* **@openzeppelin-upgradeable/contracts/token/ERC20/extensions/draft-IERC20PermitUpgradeable.sol**
  * [src/kuma-protocol/interfaces/IKIBToken.sol](https://github.com/code-423n4/2023-02-kuma/blob/main/src/kuma-protocol/interfaces/IKIBToken.sol)
* **@openzeppelin-upgradeable/contracts/token/ERC721/ERC721Upgradeable.sol**
  * [src/kuma-protocol/KBCToken.sol](https://github.com/code-423n4/2023-02-kuma/blob/main/src/kuma-protocol/KBCToken.sol)
* **@openzeppelin-upgradeable/contracts/token/ERC721/IERC721Upgradeable.sol**
  * [src/kuma-protocol/interfaces/IKBCToken.sol](https://github.com/code-423n4/2023-02-kuma/blob/main/src/kuma-protocol/interfaces/IKBCToken.sol)
* **@openzeppelin/contracts/access/AccessControl.sol**
  * [src/kuma-protocol/KUMAAccessController.sol](https://github.com/code-423n4/2023-02-kuma/blob/main/src/kuma-protocol/KUMAAccessController.sol)
  * [src/mcag-contracts/AccessController.sol](https://github.com/code-423n4/2023-02-kuma/blob/main/src/mcag-contracts/AccessController.sol)
* **@openzeppelin/contracts/access/IAccessControl.sol**
  * [src/kuma-protocol/KBCToken.sol](https://github.com/code-423n4/2023-02-kuma/blob/main/src/kuma-protocol/KBCToken.sol)
  * [src/kuma-protocol/KUMAAddressProvider.sol](https://github.com/code-423n4/2023-02-kuma/blob/main/src/kuma-protocol/KUMAAddressProvider.sol)
  * [src/kuma-protocol/KUMASwap.sol](https://github.com/code-423n4/2023-02-kuma/blob/main/src/kuma-protocol/KUMASwap.sol)
  * [src/kuma-protocol/MCAGRateFeed.sol](https://github.com/code-423n4/2023-02-kuma/blob/main/src/kuma-protocol/MCAGRateFeed.sol)
  * [src/kuma-protocol/interfaces/IKIBToken.sol](https://github.com/code-423n4/2023-02-kuma/blob/main/src/kuma-protocol/interfaces/IKIBToken.sol)
  * [src/kuma-protocol/interfaces/IKUMAAddressProvider.sol](https://github.com/code-423n4/2023-02-kuma/blob/main/src/kuma-protocol/interfaces/IKUMAAddressProvider.sol)
  * [src/kuma-protocol/interfaces/IMCAGRateFeed.sol](https://github.com/code-423n4/2023-02-kuma/blob/main/src/kuma-protocol/interfaces/IMCAGRateFeed.sol)
  * [src/mcag-contracts/Blacklist.sol](https://github.com/code-423n4/2023-02-kuma/blob/main/src/mcag-contracts/Blacklist.sol)
  * [src/mcag-contracts/KUMABondToken.sol](https://github.com/code-423n4/2023-02-kuma/blob/main/src/mcag-contracts/KUMABondToken.sol)
  * [src/mcag-contracts/KYCToken.sol](https://github.com/code-423n4/2023-02-kuma/blob/main/src/mcag-contracts/KYCToken.sol)
  * [src/mcag-contracts/MCAGAggregator.sol](https://github.com/code-423n4/2023-02-kuma/blob/main/src/mcag-contracts/MCAGAggregator.sol)
  * [src/mcag-contracts/interfaces/IBlacklist.sol](https://github.com/code-423n4/2023-02-kuma/blob/main/src/mcag-contracts/interfaces/IBlacklist.sol)
  * [src/mcag-contracts/interfaces/IKUMABondToken.sol](https://github.com/code-423n4/2023-02-kuma/blob/main/src/mcag-contracts/interfaces/IKUMABondToken.sol)
* **@openzeppelin/contracts/access/Ownable.sol**
  * [src/mcag-contracts/KUMABondToken.sol](https://github.com/code-423n4/2023-02-kuma/blob/main/src/mcag-contracts/KUMABondToken.sol)
* **@openzeppelin/contracts/interfaces/IERC20.sol**
  * [src/kuma-protocol/KIBToken.sol](https://github.com/code-423n4/2023-02-kuma/blob/main/src/kuma-protocol/KIBToken.sol)
  * [src/kuma-protocol/KUMAFeeCollector.sol](https://github.com/code-423n4/2023-02-kuma/blob/main/src/kuma-protocol/KUMAFeeCollector.sol)
  * [src/kuma-protocol/KUMASwap.sol](https://github.com/code-423n4/2023-02-kuma/blob/main/src/kuma-protocol/KUMASwap.sol)
  * [src/kuma-protocol/interfaces/IKUMASwap.sol](https://github.com/code-423n4/2023-02-kuma/blob/main/src/kuma-protocol/interfaces/IKUMASwap.sol)
* **@openzeppelin/contracts/proxy/utils/Initializable.sol**
  * [src/kuma-protocol/KUMAAddressProvider.sol](https://github.com/code-423n4/2023-02-kuma/blob/main/src/kuma-protocol/KUMAAddressProvider.sol)
  * [src/kuma-protocol/KUMAFeeCollector.sol](https://github.com/code-423n4/2023-02-kuma/blob/main/src/kuma-protocol/KUMAFeeCollector.sol)
  * [src/kuma-protocol/MCAGRateFeed.sol](https://github.com/code-423n4/2023-02-kuma/blob/main/src/kuma-protocol/MCAGRateFeed.sol)
* **@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol**
  * [src/kuma-protocol/KBCToken.sol](https://github.com/code-423n4/2023-02-kuma/blob/main/src/kuma-protocol/KBCToken.sol)
  * [src/kuma-protocol/KIBToken.sol](https://github.com/code-423n4/2023-02-kuma/blob/main/src/kuma-protocol/KIBToken.sol)
  * [src/kuma-protocol/KUMAAddressProvider.sol](https://github.com/code-423n4/2023-02-kuma/blob/main/src/kuma-protocol/KUMAAddressProvider.sol)
  * [src/kuma-protocol/KUMAFeeCollector.sol](https://github.com/code-423n4/2023-02-kuma/blob/main/src/kuma-protocol/KUMAFeeCollector.sol)
  * [src/kuma-protocol/KUMASwap.sol](https://github.com/code-423n4/2023-02-kuma/blob/main/src/kuma-protocol/KUMASwap.sol)
  * [src/kuma-protocol/MCAGRateFeed.sol](https://github.com/code-423n4/2023-02-kuma/blob/main/src/kuma-protocol/MCAGRateFeed.sol)
* **@openzeppelin/contracts/security/Pausable.sol**
  * [src/mcag-contracts/KUMABondToken.sol](https://github.com/code-423n4/2023-02-kuma/blob/main/src/mcag-contracts/KUMABondToken.sol)
* **@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol**
  * [src/kuma-protocol/KUMAFeeCollector.sol](https://github.com/code-423n4/2023-02-kuma/blob/main/src/kuma-protocol/KUMAFeeCollector.sol)
  * [src/kuma-protocol/KUMASwap.sol](https://github.com/code-423n4/2023-02-kuma/blob/main/src/kuma-protocol/KUMASwap.sol)
* **@openzeppelin/contracts/token/ERC721/ERC721.sol**
  * [src/mcag-contracts/KUMABondToken.sol](https://github.com/code-423n4/2023-02-kuma/blob/main/src/mcag-contracts/KUMABondToken.sol)
  * [src/mcag-contracts/KYCToken.sol](https://github.com/code-423n4/2023-02-kuma/blob/main/src/mcag-contracts/KYCToken.sol)
* **@openzeppelin/contracts/token/ERC721/IERC721.sol**
  * [src/mcag-contracts/KUMABondToken.sol](https://github.com/code-423n4/2023-02-kuma/blob/main/src/mcag-contracts/KUMABondToken.sol)
  * [src/mcag-contracts/interfaces/IKUMABondToken.sol](https://github.com/code-423n4/2023-02-kuma/blob/main/src/mcag-contracts/interfaces/IKUMABondToken.sol)
  * [src/mcag-contracts/interfaces/IKYCToken.sol](https://github.com/code-423n4/2023-02-kuma/blob/main/src/mcag-contracts/interfaces/IKYCToken.sol)
* **@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol**
  * [src/kuma-protocol/KUMASwap.sol](https://github.com/code-423n4/2023-02-kuma/blob/main/src/kuma-protocol/KUMASwap.sol)
  * [src/kuma-protocol/interfaces/IKUMASwap.sol](https://github.com/code-423n4/2023-02-kuma/blob/main/src/kuma-protocol/interfaces/IKUMASwap.sol)
* **@openzeppelin/contracts/utils/Address.sol**
  * [src/mcag-contracts/KYCToken.sol](https://github.com/code-423n4/2023-02-kuma/blob/main/src/mcag-contracts/KYCToken.sol)
* **@openzeppelin/contracts/utils/Counters.sol**
  * [src/kuma-protocol/KBCToken.sol](https://github.com/code-423n4/2023-02-kuma/blob/main/src/kuma-protocol/KBCToken.sol)
  * [src/mcag-contracts/KUMABondToken.sol](https://github.com/code-423n4/2023-02-kuma/blob/main/src/mcag-contracts/KUMABondToken.sol)
  * [src/mcag-contracts/KYCToken.sol](https://github.com/code-423n4/2023-02-kuma/blob/main/src/mcag-contracts/KYCToken.sol)
* **@openzeppelin/contracts/utils/structs/EnumerableSet.sol**
  * [src/kuma-protocol/KUMAFeeCollector.sol](https://github.com/code-423n4/2023-02-kuma/blob/main/src/kuma-protocol/KUMAFeeCollector.sol)
  * [src/kuma-protocol/KUMASwap.sol](https://github.com/code-423n4/2023-02-kuma/blob/main/src/kuma-protocol/KUMASwap.sol)


# Additional Context

Please see the [docs/](https://github.com/code-423n4/2023-02-kuma/tree/main/docs/) folder for more context.

## Scoping Details

```
- If you have a public code repo, please share it here: n/a
- How many contracts are in scope?: 22
- Total SLoC for these contracts?:  1634
- How many external imports are there?: n/a
- How many separate interfaces and struct definitions are there for the contracts within scope?: 3 structs, 10 interfaces
- Does most of your code generally use composition or inheritance?: inheritance
- How many external calls?: n/a
- What is the overall line coverage percentage provided by your tests?: 100%
- Is there a need to understand a separate part of the codebase / get context in order to audit this part of the protocol?: KUMA Protocol will depend on the Mimo Capital AG contracts
- Please describe required context: Please read the docs in each respective folder
- Does it use an oracle?: No
- Does the token conform to the ERC20 standard?: Yes
- Are there any novel or unique curve logic or mathematical models?: No
- Does it use a timelock function?: No
- Is it an NFT?: Yes
- Does it have an AMM?: No
- Is it a fork of a popular project?: No
- Does it use rollups?: No
- Is it multi-chain?: No
- Does it use a side-chain?: No
```

# Tests

This repo contains relevant tests for the two source projects. To run tests:

1. Make sure all git submodules are installed using `git submodule update --init`
2. Run `forge test`

Make sure `forge` is at least on the following version: `forge 0.2.0 (1a56901 2023-02-15T00:05:20.802314Z)`

To skip invariant and fuzz tests run `forge test --no-match-path "{*invariant*,*fuzz*}"`

## Quickstart Command

Alternatively use the following quickstart command:

```
rm -Rf 2023-02-kuma || true && git clone https://github.com/code-423n4/2023-02-kuma.git -j8 --recurse-submodules && cd 2023-02-kuma && git submodule update --init && foundryup && forge install && forge build && forge test --gas-report
```

## Running Static Analysis

The root folder contains a `slither.config.json` file that can be used to run static analysis on the `kuma-protocol` project. Refer to the [foundry docs](https://book.getfoundry.sh/config/static-analyzers?highlight=slither.config#slither) on how to run Slither

## Invariant testing

For the following files the invariants should be run with `fail_on_revert = true` in the `foundry.toml`:

```
[invariant]
runs = 256
depth = 256
fail_on_revert = true
```

- [KIBToken.fail.on.revert.invariant](https://github.com/code-423n4/2023-02-kuma/tree/main/test/kuma-protocol/invariants/KIBToken.fail.on.revert.invariant.sol)
- [KUMASwap.fail.on.revert.invariant](https://github.com/code-423n4/2023-02-kuma/tree/main/test/kuma-protocol/invariants/KUMASwap.fail.on.revert.invariant.sol)

Then run the tests with `forge test --match-path "*fail.on.revert*"`
