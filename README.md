# KUMA Protocol contest details

- Total Prize Pool: $38,600 USDC
  - HM awards: $25,500 USDC 
  - QA report awards: $3,000 USDC
  - Gas report awards: $1,500 USDC 
  - Judge + presort awards: $8,100 USDC 
  - Scout awards: $500 USDC 
- Join [C4 Discord](https://discord.gg/code4rena) to register
- Submit findings [using the C4 form](https://code4rena.com/contests/2023-02-kuma-protocol-contest/submit)
- [Read our guidelines for more details](https://docs.code4rena.com/roles/wardens)
- Starts February 17, 2023 20:00 UTC
- Ends February 22, 2023 20:00 UTC

## Automated Findings / Publicly Known Issues

Automated findings output for the contest can be found [here](add link to report) within an hour of contest opening.

_Note for C4 wardens: Anything included in the automated findings output is considered a publicly known issue and is ineligible for awards._

# Overview

This repo contains source contracts and testing suites for the MCAG contracts and the KUMA Protocol. Each corresponding project directory contains documentation in the /docs folder.

The [src/kuma-protocol/](https://github.com/code-423n4/2023-02-kuma/src/kuma-protocol/) folder contains the contracts that comprise the decentralized KUMA protocol. See [docs/kuma-protocol/](https://github.com/code-423n4/2023-02-kuma/docs/kuma-protocol/) for KUMA protocol docs.

The [src/mcag-contracts/](https://github.com/code-423n4/2023-02-kuma/src/mcag-contracts/) contains contracts that are managed by the centralized MCAG entity. See [docs/mcag-contracts/](https://github.com/code-423n4/2023-02-kuma/docs/mcag-contracts/) for MCAG contracts docs.

# Scope

### KUMA Protocol

| Contract                                                                                                                                                  | SLOC | Purpose                                                                                                                 | Libraries used                                           |
| --------------------------------------------------------------------------------------------------------------------------------------------------------- | ---- | ----------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------- |
| [src/kuma-protocol/KUMASwap.sol](https://github.com/code-423n4/2023-02-kuma/src/kuma-protocol/KUMASwap.sol)                                               | 396  | Main contract that always swapping a Bond NFT for the KIBT ERC20, one KUMASwap per risk class (country, term, currency) | [`@openzeppelin/*`](https://openzeppelin.com/contracts/) |
| [src/kuma-protocol/KIBToken.sol](https://github.com/code-423n4/2023-02-kuma/src/kuma-protocol/KIBToken.sol)                                               | 248  | Interesting Bearing ERC20, one for each risk class                                                                      | [`@openzeppelin/*`](https://openzeppelin.com/contracts/) |
| [src/kuma-protocol/KUMAFeeCollector.sol](https://github.com/code-423n4/2023-02-kuma/src/kuma-protocol/KUMAFeeCollector.sol)                               | 157  |                                                                                                                         | [`@openzeppelin/*`](https://openzeppelin.com/contracts/) |
| [src/kuma-protocol/KUMAAddressProvider.sol](https://github.com/code-423n4/2023-02-kuma/src/kuma-protocol/KUMAAddressProvider.sol)                         | 117  | AddressProvider that stores the mappings for the KIBT, KUMASwap and KUMAFeeCollector for each risk class                | [`@openzeppelin/*`](https://openzeppelin.com/contracts/) |
| [src/kuma-protocol/MCAGRateFeed.sol](https://github.com/code-423n4/2023-02-kuma/src/kuma-protocol/MCAGRateFeed.sol)                                       | 74   | Contract that reads the price from the MCAG central bank rate oracle                                                    | [`@openzeppelin/*`](https://openzeppelin.com/contracts/) |
| [src/kuma-protocol/KBCToken.sol](https://github.com/code-423n4/2023-02-kuma/src/kuma-protocol/KBCToken.sol)                                               | 63   | A Clone Bond NFT Token that is issued when the KIBT yield is not high enough to buy back the original Bond NFT          | [`@openzeppelin/*`](https://openzeppelin.com/contracts/) |
| [src/kuma-protocol/KUMAAccessController.sol](https://github.com/code-423n4/2023-02-kuma/src/kuma-protocol/KUMAAccessController.sol)                       | 9    |                                                                                                                         | [`@openzeppelin/*`](https://openzeppelin.com/contracts/) |
| [src/kuma-protocol/interfaces/IKUMASwap.sol](https://github.com/code-423n4/2023-02-kuma/src/kuma-protocol/interfaces/IKUMASwap.sol)                       | 58   |                                                                                                                         | [`@openzeppelin/*`](https://openzeppelin.com/contracts/) |
| [src/kuma-protocol/interfaces/IKIBToken.sol](https://github.com/code-423n4/2023-02-kuma/src/kuma-protocol/interfaces/IKIBToken.sol)                       | 35   |                                                                                                                         | [`@openzeppelin/*`](https://openzeppelin.com/contracts/) |
| [src/kuma-protocol/interfaces/IKUMAAddressProvider.sol](https://github.com/code-423n4/2023-02-kuma/src/kuma-protocol/interfaces/IKUMAAddressProvider.sol) | 26   |                                                                                                                         | [`@openzeppelin/*`](https://openzeppelin.com/contracts/) |
| [src/kuma-protocol/interfaces/IKUMAFeeCollector.sol](https://github.com/code-423n4/2023-02-kuma/src/kuma-protocol/interfaces/IKUMAFeeCollector.sol)       | 20   |                                                                                                                         |
| [src/kuma-protocol/interfaces/IKBCToken.sol](https://github.com/code-423n4/2023-02-kuma/src/kuma-protocol/interfaces/IKBCToken.sol)                       | 18   |                                                                                                                         | [`@openzeppelin/*`](https://openzeppelin.com/contracts/) |
| [src/kuma-protocol/interfaces/IMCAGRateFeed.sol](https://github.com/code-423n4/2023-02-kuma/src/kuma-protocol/interfaces/IMCAGRateFeed.sol)               | 13   |                                                                                                                         | [`@openzeppelin/*`](https://openzeppelin.com/contracts/) |
| Total                                                                                                                                                     | 1234 |                                                                                                                         |                                                          |

### Mimo Capital AG Contracts

| Contract                                                                                                                                                          | SLOC | Purpose                                                                                  | Libraries used                                           |
| ----------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---- | ---------------------------------------------------------------------------------------- | -------------------------------------------------------- |
| [src/mcag-contracts/KUMABondToken.sol](https://github.com/code-423n4/2023-02-kuma/src/mcag-contracts/KUMABondToken.sol)                                           | 134  | NFT that MCAG will issue for each purchased real world bond                              | [`@openzeppelin/*`](https://openzeppelin.com/contracts/) |
| [src/mcag-contracts/KYCToken.sol](https://github.com/code-423n4/2023-02-kuma/src/mcag-contracts/KYCToken.sol)                                                     | 77   | Untransferable NFT that MCAG will airdrop to KYC users                                   | [`@openzeppelin/*`](https://openzeppelin.com/contracts/) |
| [src/mcag-contracts/MCAGAggregator.sol](https://github.com/code-423n4/2023-02-kuma/src/mcag-contracts/MCAGAggregator.sol)                                         | 67   | Oracle that MCAG manages to publish central bank rates                                   | [`@openzeppelin/*`](https://openzeppelin.com/contracts/) |
| [src/mcag-contracts/Blacklist.sol](https://github.com/code-423n4/2023-02-kuma/src/mcag-contracts/Blacklist.sol)                                                   | 33   | Central registry for blacklisted addresses that are not allowed to interact with the NFT | [`@openzeppelin/*`](https://openzeppelin.com/contracts/) |
| [src/mcag-contracts/AccessController.sol](https://github.com/code-423n4/2023-02-kuma/src/mcag-contracts/AccessController.sol)                                     | 16   |                                                                                          | [`@openzeppelin/*`](https://openzeppelin.com/contracts/) |
| [src/mcag-contracts/interfaces/IKUMABondToken.sol](https://github.com/code-423n4/2023-02-kuma/src/mcag-contracts/interfaces/IKUMABondToken.sol)                   | 32   |                                                                                          | [`@openzeppelin/*`](https://openzeppelin.com/contracts/) |
| [src/mcag-contracts/interfaces/IKYCToken.sol](https://github.com/code-423n4/2023-02-kuma/src/mcag-contracts/interfaces/IKYCToken.sol)                             | 17   |                                                                                          | [`@openzeppelin/*`](https://openzeppelin.com/contracts/) |
| [src/mcag-contracts/interfaces/MCAGAggregatorInterface.sol](https://github.com/code-423n4/2023-02-kuma/src/mcag-contracts/interfaces/MCAGAggregatorInterface.sol) | 15   |                                                                                          |                                                          |
| [src/mcag-contracts/interfaces/IBlacklist.sol](https://github.com/code-423n4/2023-02-kuma/src/mcag-contracts/interfaces/IBlacklist.sol)                           | 11   |                                                                                          | [`@openzeppelin/*`](https://openzeppelin.com/contracts/) |
| Total                                                                                                                                                             | 402  |                                                                                          |                                                          |

## Out of scope

All other files in the repo

# Additional Context

Please see the [docs/](https://github.com/code-423n4/2023-02-kuma/docs/) folder for more context.

## Scoping Details

```
- If you have a public code repo, please share it here: n/a
- How many contracts are in scope?: 22
- Total SLoC for these contracts?:  1634
- How many external imports are there?: n/a
- How many separate interfaces and struct definitions are there for the contracts within scope?: 3 structs, 10 interfaces
- Does most of your code generally use composition or inheritance?: inheritance
- How many external calls?: n/a
- What is the overall line coverage percentage provided by your tests?:
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

## Running Static Analysis

The root folder contains a `slither.config.json` file that can be used to run static analysis on the `kuma-protocol` project. Refer to the [foundry docs](https://book.getfoundry.sh/config/static-analyzers?highlight=slither.config#slither) on how to run Slither

## Invariant testing

For the following files the invariants should be run with `fail_on_revert = true` :

- [KIBToken.fail.on.revert.invariant](./test/kuma-protocol/invariants/KIBToken.fail.on.revert.invariant.sol)
- [KUMASwap.fail.on.revert.invariant](./test/kuma-protocol/invariants/KUMASwap.fail.on.revert.invariant.sol)
