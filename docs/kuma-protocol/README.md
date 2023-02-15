# KUMA Protocol

- [KUMA Protocol](#kuma-protocol)
- [Brief Overview of Components](#brief-overview-of-components)
- [Sample use cases](#sample-use-cases)
  - [User Scenario 1:](#user-scenario-1)
  - [User Scenario 2:](#user-scenario-2)
- [Components In-Depth](#components-in-depth)
  - [KUMA Interest Bearing Token (KIBToken)](#kuma-interest-bearing-token-kibtoken)
    - [Interest Bearing Logic](#interest-bearing-logic)
      - [Yield](#yield)
      - [Epoch](#epoch)
    - [ERC20 Compliance and Updates](#erc20-compliance-and-updates)
    - [ERC20 Token Transfers](#erc20-token-transfers)
    - [Balance Accounting](#balance-accounting)
  - [Decentralized Access Control](#decentralized-access-control)
    - [Pause](#pause)
    - [Unpause](#unpause)
  - [Centralized Access Controller](#centralized-access-controller)
  - [KUMASwap](#kumaswap)
    - [Selling Bonds](#selling-bonds)
    - [Buying Bonds](#buying-bonds)
  - [KUMA Bond ERC721 tokens](#kuma-bond-erc721-tokens)
  - [KUMA Bond Clone Token (KBCT)](#kuma-bond-clone-token-kbct)
  - [Keepers](#keepers)
    - [Keeper Failures](#keeper-failures)
- [Deprecation Mode](#deprecation-mode)

Crypto users are incentivized through token yields. Some projects have created significant yields. However, there is a lack of stable, low-risk yield generation that is transparent and verifiable. It is unclear where income is generated from, and a lack of transparency and regulation are major deterrents for major institutions and risk-averse individuals to adopt crypto.

[Bonds](https://www.khanacademy.org/economics-finance-domain/core-finance/stock-and-bonds/bonds-tutorial/v/introduction-to-bonds) are financial assets that generate low-risk income. They are common in traditional finance, but have not yet been adopted in the crypto world due to the complexity of bridging centralized entities with decentralized systems. The KUMA Protocol aims to tokenize bonds on the blockchain to create assets that generate low-risk income while also utilizing the transparency and verifiability of smart contracts. Tokenizing bonds on the blockchain with publicly verifiable smart contracts enables users to hold stable, interest-bearing tokens and limits their risk exposure to off-chain bonds. The KUMA Protocol enables permissionless participation and generates stable yields backed by trustworthy central entities. This document explains how tokenized bonds are created, backed, and maintained, enabling users to securely participate in an interest-bearing on-chain economy.

# Brief Overview of Components

![Overview Diagram](/docs/diagrams/TokenizedBondsOverviewDiagram.svg)

The following components comprise the KUMA Protocol:

- **Mimo Capital AG (MCAG)** - The centralized entity that holds the physical bonds represented by KUMA Bonds NFTs is MCAG. MCAG mints new KUMA Bonds NFTs every time a user buys a claim to the physical bonds off-chain. Users are able to trade and sell the tokenized versions of the bonds, but the physical bonds are always held solely by MCAG. Additionally, MCAG maintains the central bank oracle and a multisig with a manager role in the MCAG access controller to manage centralized aspects of the system.
- **KUMA Bonds NFTs** - ERC721 NFTs that represent ownership of a physical bond. The NFT holder can redeem the NFT off-chain from MCAG for the market-rate bond value at any point.
- **KUMA Interest Bearing Bond Tokens (KIBT)** -
  Rebase ERC20 tokens that represent a share of all bonds backed by the protocol. These tokens automatically accrue rewards for token holders, meaning that users' balances will increase over time just by holding the token in their address. This allows users to interact with a more liquid and divisible form of bonds while still earning real-time interest on their tokens. KIBTokens are backed by the bonds held in the KUMA Interest Bearing Swap Contract (see next point). Each risk class has its own KIBToken.
- **KUMA Interest Bearing Swap Contract** - The Swap contract holds all KUMA Bonds NFTs that back the KIBT. Users can sell and buy bonds from this contract by burning or minting KIBT. Each risk class has its own Interest Bearing Swap Contract.
- **Central Bank Oracle** - Informs the protocol of the central bank rates for newly issued bonds. The central bank rate is used to keep the protocol competitive and avoid an excessively high KIBT rate. There is one oracle for each risk class, since different risk classes have different interest **rates**.
- **Rate Feed** - The rate feed contract reads rate data from the central bank oracles. Unlike oracles, of which there is one oracle per risk category, there is only one RateFeed for the whole protocol, and the risk category is passed in as an argument for fetching data.
- **Keepers** - Keepers monitor the `KIBT` and `KUMASwap` contracts to keep the `KIBT` yield up-to-date.
- **KUMA DAO Access Controller** - The Access Controller for the decentralized contracts of the KUMA protocol.
- **MCAG Access Controller** - The Access Controller used to enforce centralized MCAG access

![KUMA Token Types](/docs/diagrams/KumaTokenTypes.webp)

# Sample use cases

## User Scenario 1:

![User Scenario 1 diagram](/docs/diagrams/UserScenario1.svg)

Users who buy KUMA Bonds NFTs from MCAG don't have to deposit them in the `KUMASwap` contract. The simplest user scenario is when a user buys a KUMA Bonds NFT from MCAG, holds it until maturity, and redeems it from MCAG after maturity. This scenario might be useful for institutional investors who want a publicly verifiable ownership of a bond for auditing purposes or those who want to keep their operations in crypto but want bond income.

## User Scenario 2:

![User Scenario 2 diagram](/docs/diagrams/UserScenario2.svg)

The second simplest user scenario is when a user buys a KUMA Bonds NFT from MCAG, optionally holds the bond for some time, and sells the bond to the `KUMASwap` by calling `sellBond` while the `KIBT` yield is equal or lower that of the bond's coupon. In this case, the Bond is deposited to the `KUMASwap` contract and the user receives newly minted KIBT that can then be used in the DeFi system - either held to earn real-time interest, swapped for other assets, or wrapped and used as collateral in DeFi protocols. This is useful for users who want to earn real-time rewards or granulate the value of the bond.

Note: The `KUMASwap` contract won't allow users to sell bonds to the contract which have a lower coupon than that of the central bank rate.

For more complicated scenarios that involve the generation of clone NFTs, see scenario 3 & 4 in the KUMA Clone Bond Token section.

# Components In-Depth

This section contains In-Depth technical notes on specific components.

## KUMA Interest Bearing Token (KIBToken)

KIBTokens are rebase tokens minted and burned by the `KUMASwap` contract upon sale and purchase of KUMA Bonds NFTs. KUMABondTokens back KIBTokens and determine the yield earned on them. Yield collected by the KUMA Bonds NFTs reserve in `KUMASwap` is distributed to KIBTokens holders directly by increasing their wallet balance on a set interval (epoch).

There will be one `KIBToken` contract per existing risk category. Each risk category is defined by a unique:

- Currency
- Country
- Term

### Interest Bearing Logic

#### Yield

`yield` is represented as an exponential per-second rate in 27 decimal format. The rate is calculated as follows:

<!-- prettier-ignore -->
$$ yield = 1 + annualRate^{\frac{1}{31536000}} * 10^{27} $$

`cumulativeYield` represents the aggregate interest accrued over time. It is calculated with a 1-second precision based on the block timestamp. `cumulativeYield` is updated whenever the `_refreshCumulativeYield()` internal function is called, which will update the value to the current time (`_lastRefresh`).

`cumulativeYield` is calculated as follows:

<!-- prettier-ignore -->
$$ newCumulativeYield = oldCumulativeYield * (1 + yield)^{timeElapsed} $$

Here `timeElapsed` refers to the time elapsed bewteen the last `_cumulativeYield` refresh and the current timestamp.

`previousEpochCumulativeYield` also represents the aggregate interest accrued over time with a 1-second precision but is based on the `previousEpochTimestamp`. `previousEpochCumulativeYield` is updated whenever the `_refreshPreviousEpochCumulativeYield()` internal function is called.

`previousEpochCumulativeYield` is calculated as follows:

<!-- prettier-ignore -->
$$ newPreviousEpochCumulativeYield = oldPreviousEpochCumulativeYield * (1 + yield)^{timeElapsedToEpoch} $$

Here `timeElapsedToEpoch` refers to the time elapsed between the last `cumulativeYield` refresh and the `previousEpochTimestamp`.

Setting `yield` to `RAY` (1e27) - which is also its initial value at deployment - sets yield to zero. A positive yield will increase the `cumulativeYield` over time.

#### Epoch

Although interest accrues each second, balances only increase each epoch. This is done to :

- Provide keepers with enough time to expire a bond (see [Keepers](#keeper-failures))
- Avoid leftover residual dust amounts when transferring all of a user's balance, since most frontend wallets do not refresh a user's balance on a per second basis.
- Enable adapting epochs to bond term lengths if the DAO votes to do so. For example a 1 year T-Bill might have a 4 hour rebase while a 30 year bond could have a daily or weekly rebase.

Thus `balanceOf` and `totalSupply` both rely on the internal function `_calculatePreviousEpochCumulativeYield()`. The `_calculatePreviousEpochCumulativeYield()` is called in `_refreshCumulativeYield` to update the `_previousEpochCumulativeYield` state.

Even though only `_previousEpochCumulativeYield` is used to return external `KIBT` balances , the more accurate `cumulativeYield` state is kept to track the yield earned between epochs.

Epochs add a layer of flexibility that enables `KIBTokens` to adapt to investment strategies with different time horizons.

### ERC20 Compliance and Updates

All standard EIP20 methods are implemented for KIBTokens, such as `balanceOf`, `transfer`, `transferFrom`, `approve`, `totalSupply` ...

However the underlying logic of those methods can differ from EIP20 standards in some cases in order fit an interest bearing token behavior :

- `balanceOf` will always return the balance of the user at the last epoch.
- `totalSupply` will always return the most up to date total supply of KIBTokens, which includes the principal supply (`totalBaseSupply`) + the yield generated by the principal balance up to the last epoch timestamp.

### ERC20 Token Transfers

Transfers behave mostly like the standard EIP20 method with the exception of the available balance check and the `cumulativeYield` refresh.

### Balance Accounting

A `baseBalances` mapping stores the time-discounted cumulative yield earned at the latest `transfer`, `mint` or `burn` for an address. When multiplied by the cumulative yield, this `baseBalances` mapping returns the correct accrued rewards. To avoid any rounding errors caused by storing this intermediate state between `balanceOf` reads, `baseBalances` is stored in 27 decimals. This gives high enough accuracy so that the 18 decimal values returned by `balanceOf` are always accurate when formatted to 18 decimals. `WadRayMath` is used to convert and operate on and 27 and 18 decimal values.

## Decentralized Access Control

All access control logic for the decentralized contracts (`KUMASwap`, `KIBToken`, `KBCToken`, and `MCAGRateFeed`) is handled by the the KUMA protocol's [AccessController](https://github.com/mimo-capital/tokenized-bonds/blob/main/src/AccessController.sol) contract. The following roles will be added to the KUMA protocol's access control:

|    Entity     | Mint KIBT | Burn KIBT | Pause KUMASwap | Un-Pause KUMASwap | Set KIBT Epoch | Manager | KIBT Swap Claim |
| :-----------: | :-------: | :-------: | :------------: | :---------------: | :------------: | :-----: | :-------------: |
|   KUMASwap    |    ✅     |    ✅     |                |                   |                |         |                 |
| MCAG MultiSig |           |           |                |                   |                |         |       ✅        |
|   KUMA DAO    |           |           |       ✅       |        ✅         |       ✅       |   ✅    |                 |

- `KIBT_MINT_ROLE` - Mints KIBTokens
- `KIBT_BURN_ROLE` - Burns KIBTokens
- `KIBT_SWAP_PAUSE_ROLE` - Pauses `KUMASwap`, which prevents all transfers, minting, and burning of KUMA Bonds NFTs
- `KIBT_SWAP_UNPAUSE_ROLE` - Unpauses `KUMASwap`, which re-enables transfers, minting, and burning of KUMA Bonds NFTs after a pause
- `KIBT_SET_EPOCH_LENGTH_ROLE` - Sets KIBToken epoch length
- `KUMA_MANAGER_ROLE` - Sets configs of the protocol like `sellBond` fees, `minGas` in `KIBTSwap` , `KUMAFeeCollector` payees and shares, and contract addresses in the `KUMAAddressProvider`
- `KIBT_SWAP_CLAIM_ROLE` - Claims the parent bonds of a clone bond in `KIBTSwap`

### Pause

A `pause()` function exists along with a `MIB_SWAP_PAUSE_ROLE` in the event where the DAO wishes to implement a failsafe mechanism in the future.

- Only the `KIBT_SWAP_PAUSE_ROLE` may call pause
- Pausing emits a Pause() event

### Unpause

An `unpause()` function exists along with a `MIB_SWAP_UNPAUSE_ROLE` in the event where the DAO wishes to implement a failsafe mechanism in the future.

- Only the `KIBT_SWAP_UNPAUSE_ROLE` role may call unpause
- Unpausing emits an Unpause() event

## Centralized Access Controller

All centralized access control logic is outsourced to the centralized [AccessController](https://github.com/mimo-capital/tokenized-bonds/blob/main/src/AccessController.sol) contract. The contract has the following roles on deploy and gives all roles to the MCAG multi-sig address:

|    Entity     | Mint KUMABondToken | Burn KUMABondToken | Pause KUMABondToken | Un-Pause KUMABondToken | MCAG Aggregator | KUMABondToken Blacklist | Manager |
| :-----------: | :----------------: | :----------------: | :-----------------: | :--------------------: | :-------------: | :---------------------: | :-----: |
|   KUMASwap    |                    |                    |                     |                        |                 |                         |         |
| MCAG MultiSig |         ✅         |         ✅         |         ✅          |           ✅           |       ✅        |           ✅            |   ✅    |
|   KUMA DAO    |                    |                    |                     |                        |                 |                         |         |

- `MCAG_MINT_ROLE` - Mints KUMA Bond NFT tokens
- `MCAG_BURN_ROLE` - Burns KUMA Bond NFT tokens
- `MCAG_BLACKLIST_ROLE` - Modifies the Blacklist for KUMA Bonds NFT
- `MCAG_PAUSE_ROLE` - Pauses the KUMA Bonds NFT
- `MCAG_UNPAUSE_ROLE` - Unpauses the KUMA Bonds NFT
- `MCAG_TRANSMITTER_ROLE` - Updates the central bank oracle data
- `MCAG_MANAGER_ROLE` - Sets the max answer for the MCAG aggregator contract

The roles outlined above may be reassigned. The `DEFAULT_ADMIN_ROLE` role has the ability to reassign all roles (including itself), and is initially assigned to the MCAG Multisig address.

## KUMASwap

The `KUMASwap` allows users to sell KUMA Bonds NFTs to in exchange for `KIBT` using `sellBond`, and buy KUMA Bonds NFTs with `KIBT` using `buyBond`. The `KUMASwap` contract is responsible for:

1. Ensuring KIBTokens backing by :
   - Minting `KIBToken` upon KUMA Bonds NFT sale
   - Burning `KIBToken` upon KUMA Bonds NFT purchase
2. Generating fee income for the `KUMADAO`.

There is one `KUMASwap` contract per existing risk category similar to the `KIBToken` .

### Selling Bonds

The following conditions must be met to sell a KUMA Bonds NFT to the contract:

- The contract must be unpaused
- The maximum amount of unique coupons in reserve must not have be reached
- The sold bond risk category must match the `KUMASwap` risk category
- The sold bond must not have reached maturity
- The sold bond coupon must greater or equal to the current `RateFeed` rate.

The amount of minted `KIBToken` to the seller is calculated as follows :

<!-- prettier-ignore -->
$$ bondValue = bond.principal * (bond.coupon^{elapsedTime}) $$

<!-- prettier-ignore -->
$$ fee = (bondValue * variableFee) + fixedFee $$

$$ mintedAmount = bondValue - fee $$

Here `elapsedTime` refers to the time elapsed between the bond `issuance` and the `previousEpochTimestamp`.

![](/docs/diagrams/sellBondRequirements.svg)

For each bond sold to `KUMASwap`, the bond token ID is added to the `_bondReserve` `UintSet`, and the bond coupon is added to the `_coupons` `UintSet` array, only if the coupon value does not already exist in the `_coupons` array. This optimization is done mainly to minimize the gas cost of the `_updateMinCoupon()` function, which loops through all the bonds in the reserve to find the lowest coupon. As central bank rates are updated infrequently (typically less than once a month), all bonds issued between two central bank rate updates should have the same coupon. Therefore, there is no need to loop over bonds with the same coupon in the `_updateMinCoupon()` function.

### Buying Bonds

The following conditions must be met to buy a KUMA Bonds NFT from the contract:

- The contract must be unpaused
- The bought bond must be in reserve

![](/docs/diagrams/buyBondRequirements.svg)

The `KUMASwap` contract will burn `KIBT` from the user's balance before sending the Bonds NFT. A `KBCToken` is issued during `buyBond` if the bond's face value (i.e. the value of the bond given its coupon) is greater than that of the bond's realized value (i.e. how much `KIBT` accrual the bond has backed).

<!-- prettier-ignore -->
$$ bondFaceValue = bond.principal * (bond.coupon^{elapsedTime}) $$

<!-- prettier-ignore -->
$$ bondRealizedValue = \frac{bond.principal}{R_0} * R_1 $$
$$ burnedAmount = bondRealizedValue $$

Here `elapsedTime` refers to the time elapsed between the `previousEpochTimestamp` and the bond `issuance`.

Where $R_0$ is the KIBT cumulativeYield at the time of depositing the bond to the KUMASwap contract and $R_1$ is the KIBT cumulativeYield at the time of buying the bond.

While in traditional finance a "bond face value" refers to the nominal or dollar value of a security (i.e. the `bond.principal` in this project) the `bondFaceValue` used in the `buyBondFunction()` is slightly different. It accounts for both the principal and the accrued interest up until the `previousEpochTimestamp`.

## KUMA Bond ERC721 tokens

The KUMA Bonds NFTs follow the ERC721 standard and encode the physical bond they represent through the following metadata:

```solidity
    struct Bond {
        bytes16 cusip; // The Committee on Uniform Security Identification Procedures code of the bond, if applicable
        bytes16 isin; // The International Securities Identification Number of the bond
        bytes4 currency; // Currency of the bond - example : USD
        bytes4 country; // Treasury issuer - example : US
        uint64 term; // Lifetime of the bond ie maturity in seconds - issuance date - example : 10 years
        uint64 issuance; // Bond issuance date - timestamp in seconds
        uint64 maturity; // Date on which the principal amount becomes due - timestamp is seconds
        uint256 coupon; // Annual interest rate paid on the bond per - rate per second
        uint256 principal; // Bond face value
        bytes32 riskCategory; // Unique risk category identifier computed with keccack256(abi.encode(currency, country, term)). Each KIBT belongs to a single riskCategory
    }
```

There is always at least one KUMA Bonds NFT for each bond owned by MCAG. Some bonds can be represented by two bond tokens (i.e. if a clone token exists for the bond). See clone NFTs for more details.

## KUMA Bond Clone Token (KBCT)

When the central bank rate drops lower than the current `KIBToken` yield, Clone Bonds lower the coupon of bonds that were bought by users from the `KUMASwap` contract. This ensures that at any point in time there are enough KIBTokens in circulation to buy all the bonds from the `KUMASwap` reserve.

The lowest paying yield corresponds to the lowest yield between the central bank rate and the lowest coupon in the `KUMASwap` reserve. The `KIBToken` yield always corresponds to the lowest paying yield.

To understand why `KIBTSupply` might be a problem without clone NFTs, consider the case where the `KUMASwap` contract holds 2 different one year bonds $1,000 bonds - one with a 3% coupon and one with a 5% coupon. If we also assume the central bank rate is higher than either bond coupon, the KIBT yield will be that of the lowest bond in the swap contract (in this case 3%). Since the 5% bond appreciates more quickly than the `KIBT` total supply, there won't be enough `KIBT` for users to buy both bonds from the `KUMASwap`. Clone NFTs fix this through lowering the reward coupons of the bond so that they can be redeemed by the circulating KIBT supply. In this case, a Clone NFT would be issued for the 5% bond so that it can be redeemed as a 3% bond.

A clone bond is always paired with a parent bond from the reserve and will have a lower coupon overriding its parent coupon when the bond is valued. For each clone bond present, the parent bond cannot be redeemed by a user and can only be redeemed by the MCAG multisig when the clone bond has been redeemed by MCAG. KBCTokens metadata are the following :

```solidity
struct CloneBond {
  uint256 parentId; // The parentId of the `CloneBond`'s parent bond
  uint256 issuance; // The timestamp of the time the clone bond was issued (different than that of the parent bond's issuance)
  uint256 coupon; // The coupon of the `CloneBond`
  uint256 principal; // The principal of the `CloneBond`; equal to the realizedValue of the parent bond on the `CloneBond`'s issuance
}
```

KBCTokens can only be issued by the `KUMASwap` in the `buyBond` function.

Clone bond coupons are only created if the bond's face value is greater than that of the amount of `KIBT` the bond has backed in the `KUMASwap` contract. This happens when the central bank bond rate for a given risk category decreases past the minimum coupon held by the `KUMASwap` contract.

## Keepers

Keepers do the work of making sure that the KIBT yield is always at the highest possible rate that is backed by existing bonds in the `KUMASwap` contract, and that all bonds in the `KUMASwap` contract can be bought with the circulating KIBT supply. This is done through relying on keepers to call the following functions:

- `KUMASwap.expireBond()` when a bond held by the `KUMASwap` contract has reached maturity but hasn't been bought. This adds the expired bond id to the set of `_expiredBonds` and sets the `KIBT` accrual rate to 0% (corresponding to a yield of 1e27) until all expired bonds are bought.
- `KIBT.refreshYield()` when the KIBT rate needs to be updated to reflect that of the bonds held in the `KUMASwap` contract and the central banks bond rates. This can sometimes occur after the central bank oracle rate is updated.

### Keeper Failures

Keepers have until the end of the epoch of the expiration of a bond to call `_expireBond()`. The time a keeper is given to call `_expireBond` can vary considerably (e.g. if one bond expires near the end of an epoch, but another bond expires near the start of an epoch, keepers will have much less time to call `expireBond` on the former bond than the latter). The following problems occur if keepers fail to call `_expireBond()` within the epoch of the bond expiration:

- If the expired bond doesn't generate a clone bond when it is bought using `buyBond`, the buyer will have to burn more `KIBToken`s than if a keeper called `_expireBond()` on time.
- If the expired bond generates a clone bond token, the clone bond has a higher principal than it should have.

Keepers will be incentivized to call these functions through rewards; to be confirmed by the team.

# Deprecation Mode

`KIBT` is minted and burned such that the total supply is always sufficient to buy out all of the KUMA Bonds NFTs held in the contract. However, in extreme cases, some of the `KIBT` supply may become inaccessible (e.g. if large amounts of `KIBT` are hacked or lost to unknown addresses). This could result in Kuma Bonds NFTs being locked in the `KUMASwap` contract. To mitigate this scenario, the DAO can vote to put the `KUMASwap` contract in deprecation mode where users can buy bonds with stablecoins through voted-on parameters. Since there is a unique `KUMASwap` contract for each risk category, one deprecated `KUMASwap` contract for a given risk category does not impact other `KUMASwap` contracts for different risk categories.

When deprecation mode is activated, the `KIBT` yield is set to 0 (i.e. all `KIBT` tokens stop earning interest). After all of the bonds have been bought in the corresponding `KUMASwap` contract, users can redeem any of their leftover `KIBT` for stablecoin held in the `KUMASwap` contract through `redeemKIBT()`. The `KIBT`to stablecoin conversion rate is determined by how much stablecoin is held in the `KUMASwap` contract - e.g. If there's 100k KIBT and 100k stablecoin, each KIBT gives you the right to redeem 1 stablecoin.

Once entered, deprecation mode is irreversible for a given KUMA Bonds NFT risk category. After deprecation mode is enabled, `sellBond` in the `KUMASwap` contract is disabled; so users who have outstanding KUMA Bonds NFTs from the deprecated risk category can only redeem them directly through MCAG.

:bulb: One known limitation of the deprecation mode is the fact that the manager role can spend the buyer's allowance in the `buyBondForStableCoin()` function. In theory, the manager could sell a bond to the buyer worth less than their approved amount. This was done purposely to avoid having to build a full on-chain bidding system. We accept this risk because the `KUMA_MANAGER_ROLE` will only be granted to the KUMA DAO and not a random party.
