# MCAG Contracts

This repo's contracts all belong to and are maintained by MIMO Capital AG (MCAG).

## Access Controller

`AccessController` contract in charge of granting and revoking the MCAG roles :

- `MCAG_MINT_ROLE`
- `MCAG_BURN_ROLE`
- `MCAG_BLACKLIST_ROLE`
- `MCAG_PAUSE_ROLE`
- `MCAG_UNPAUSE_ROLE`
- `MCAG_TRANSMITTER_ROLE`
- `MCAG_SET_URI_ROLE`

All the above role will initially be granted only to the MCAG multisig.

## Blacklist

As a regulated entity MCAG will maintain a `Blacklist` contract for its regulated products. In the context of the `KUMABondToken`blacklisted addresses will be unable to transfer and appove tokens, minting to that address will also be blocked.

The company blacklists an address via the `blacklist()` method. The specified account will be added to the blacklist.

Only the `MCAG_BLACKLIST_ROLE` may call blacklist

The company removes an address from the blacklist via the `unblacklist()` method. The specified account will be removed from the blacklist.

Only the `MCAG_BLACKLIST_ROLE` may call unblacklist

## KUMA Bond Token

KUMA Bond Tokens are ERC721 tokens (NFTs) whose value is backed by a physical bond. MCAG is the centralized entity that holds the physical bonds and mints new KUMA Bonds NFTs every time a user buys a claim to the physical bonds off-chain. The NFT holder can sell the NFT back to MCAG for the market-rate of the bond. Users are able to transfer the NFTs freely, but the physical bonds are always held solely by MCAG.

KUMA Bond Tokens have the following metadatas :

| Param Name     | Type    | Description                                                                                     |
| -------------- | ------- | ----------------------------------------------------------------------------------------------- |
| `cusip`        | bytes16 | Bond CUISP number                                                                               |
| `isin`         | bytes16 | Bond ISIN number                                                                                |
| `currency`     | bytes4  | Currency of the bond - example : USD                                                            |
| `country`      | bytes4  | Treasury issuer - example : US                                                                  |
| `term`         | uint64  | Lifetime of the bond ie maturity in seconds - issuance date - example : 10 years                |
| `issuance`     | uint64  | Bond issuance date - timestamp in seconds                                                       |
| `maturity`     | uint64  | Date on which the principal amount becomes due - timestamp is seconds                           |
| `coupon`       | uint256 | Annual interest rate paid on the bond per - rate per second                                     |
| `principal`    | uint256 | Bond face value ie redeemable amount                                                            |
| `riskCategory` | bytes32 | Unique risk category identifier computed with `keccack256(abi.encode(currency, country, term))` |

### Write Methods

#### `issueBond(address to, Bond calldata bond)`

Mints a KUMA Bond Token to an address.

Requirements :

- Caller must have be granted the `MCAG_MINT_ROLE`
- `to` must not be blacklisted
- `contract` must be unpaused

| Param Name | Type    | Description                              |
| ---------- | ------- | ---------------------------------------- |
| `to`       | address | Bond NFT receiver                        |
| `bond`     | struct  | Bond struct containing all NFT metadatas |

#### `redeem(uint256 tokenId)`

Burns a KUMA Bond Token from an address.

Requirements :

- Caller must have be granted the `MCAG_BURN_ROLE`
- `to` must not be blacklisted
- `contract` must be unpaused

| Param Name | Type    | Description |
| ---------- | ------- | ----------- |
| `tokenId`  | uint256 | Bond id     |

#### `setUri(string memory newUri)`

Sets the base URI for all KUMA Bond Tokens.

Requirements :

- Caller must have be granted the `MCAG_SET_URI_ROLE`

| Param Name | Type   | Description  |
| ---------- | ------ | ------------ |
| `newUri`   | string | New base URI |

#### `pause()`

Pauses the contract.

Requirements :

- Caller must have be granted the `MCAG_PAUSE_ROLE`
- Contract must be unpaused

#### `unPause()`

Pauses the contract.

Requirements :

- Caller must have be granted the `MCAG_UNPAUSE_ROLE`
- Contract must be paused

### View Methods

#### `accessController()`

Returns the `AccessController` address.

#### `getTokenIdCounter()`

Returns the current `tokenIdCounter`.

#### `getBond(tokenId)`

Returns a specific bond metadatas.

##### Call Params

| Name      | Type   | Description |
| --------- | ------ | ----------- |
| `tokenId` | string | Bond id     |

##### Return Values

| Name | Type   | Description                                          |
| ---- | ------ | ---------------------------------------------------- |
| NA   | struct | Bond struct storing metadata of the selected bond id |

### ERC721 Methods

The `KUMABondToken` contract is fully `ERC721` compatible but adds the following requriements :

- `approve` :
  - Contract must be unpaused
  - Caller and `spender` must not be blacklisted
- `setApprovalForAll` :
  - Contract must be unpaused
  - Caller and `operator` must not be blacklisted
- `safeTransferFrom` :
  - Contract must be unpaused
  - Caller, `to` and `from` must not be blacklisted

## KYC Token

KYCTokens are non transferrable ERC721 tokens minted to a specific address only after the owner of that address has undergone a "Know Your Customer" (KYC) verification process with MCAG.

Because the KYCToken is non-transferrable, it cannot be traded or transferred from one address to another. This means that the token remains assigned to the address it was minted to and can only be used by the owner of that address.

KYC Tokens have the following metadatas :

| Param Name | Type    | Description                                                                     |
| ---------- | ------- | ------------------------------------------------------------------------------- |
| `owner`    | address | Address of the KYCToken owner                                                   |
| `kycInfo`  | bytes32 | Hash of the owner KYC infor - example : `keccak256(abi.encode(name, idNumber))` |

### Write Methods

#### `mint(address to, KYCData calldata kycData)`

Mints a KYC Token to an address.

Requirements :

- Caller must have be granted the `MCAG_MINT_ROLE`
- `to` must not be blacklisted
- `contract` must be unpaused

| Param Name | Type    | Description                                 |
| ---------- | ------- | ------------------------------------------- |
| `to`       | address | KYC Token receiver                          |
| `kycData`  | struct  | KYCData struct containing all NFT metadatas |

#### `burn(uint256 tokenId)`

Burns a KYC Token from an address.

Requirements :

- Caller must have be granted the `MCAG_BURN_ROLE`

| Param Name | Type    | Description |
| ---------- | ------- | ----------- |
| `tokenId`  | uint256 | KYCToken id |

#### `setUri(string memory newUri)`

Sets the base URI for all KUMA Bond Tokens.

Requirements :

- Caller must have be granted the `MCAG_SET_URI_ROLE`

| Param Name | Type   | Description  |
| ---------- | ------ | ------------ |
| `newUri`   | string | New base URI |

### View Methods

#### `accessController()`

Returns the `AccessController` address.

#### `getTokenIdCounter()`

Returns the current `tokenIdCounter`.

#### `getKycData(uint256 tokenId)`

Returns a specific token metadatas.

### ERC721 Methods

The `KYCToken` contract is fully `ERC721` compatible but as it is non-transferrable, calls to `approve`, `setApprovalForAll`, `transferFrom` and `safeTransferFrom` will all revert with the custom error `TOKEN_IS_NOT_TRANSFERABLE()`.

## MCAG Aggregator

The `MCAGAggregator` is an MCAG maintained central bank rate oracle partially compatible with the Chainlink `AggregatorV3Interface` (does not support the `roundData()` method). It maintains the latest central bank rate for a specific risk category and includes an MCAG fee (e.g. the difference between actual rate and returned rate). There is one `MCAGAggragator` for each risk class, since different risk classes have different interest rates.

Central bank rates are usually expressed as linear rate but these rate will be transformed by transmitters to exponential per-second rate in 27 decimals before publishing them per the following formula :

<!-- prettier-ignore -->
$$ yield = 1 + annualRate^{\frac{1}{31536000}} * 10^{27} $$

### Write Methods

#### `transmit(int256 answer)`

Transmits a new central bank rate to the contract.

Requirements :

- Caller must be granted the `MCAG_TRANSMITTER_ROLE`
- `answer` must lower or equal to the set `_maxAnswer`

| Param Name | Type   | Description                                                          |
| ---------- | ------ | -------------------------------------------------------------------- |
| `answer`   | int256 | New central bank rate as a per second cumualtive rate in 27 decimals |

#### `setMaxAnswer(int256 newMaxAnswer)`

Sets a new max answer.

Requirements :

- Caller must be granted the `MCAG_MANAGER_ROLE`

| Param Name     | Type   | Description                                            |
| -------------- | ------ | ------------------------------------------------------ |
| `newMaxAnswer` | int256 | New maximum sensible answer the contract should accept |

### View Methods

#### `latestRoundData()`

| Return Value      | Type    | Description                                          |
| ----------------- | ------- | ---------------------------------------------------- |
| `roundId`         | uint80  | Latest `_roundId`                                    |
| `answer`          | int256  | Latest answer transmitted                            |
| `startedAt`       | uint256 | Unused variable here only to follow Chainlink format |
| `updatedAt`       | uint256 | Timestamp of the last transmitted answer             |
| `answeredInRound` | uint80  | Latest `_roundId`                                    |

#### `description()`

Returns the description of the oracle - for example "10 YEAR US TREASURY".

#### `maxAnswer()`

Returns the maximum sensible answer the contract should accept.

#### `decimals()`

Returns number of decimals used to get its user representation.

#### `version()`

Returns the contract version.

## Contract Addresses

## Goerli Deployments

| Contract            | Etherscan                                                                           |
| ------------------- | ----------------------------------------------------------------------------------- |
| AccessController    | https://goerli.etherscan.io/address/0x6032c57B4921c1CCa22e362d128b942C7631132b#code |
| Blacklist           | https://goerli.etherscan.io/address/0x474fe24CdCd84A8fC0aEb7590d7e27fADC0742c3#code |
| KUMABondToken       | https://goerli.etherscan.io/address/0xA66283481d89183c007c4Ed4254E38d4Fe5b6D4E#code |
| MCAGAggregator FR12 | https://goerli.etherscan.io/address/0x462c0B56068c43162870ddc442f4FfC408c1c651#code |
| MCAGAggregator US12 | https://goerli.etherscan.io/address/0x1CCEc88d9aA573BCd3aa5761E7A645cD0e65844B#code |

## Binance Smart Chain Deployments

| Contract         | Etherscan                                                                   |
| ---------------- | --------------------------------------------------------------------------- |
| AccessController | https://bscscan.com/address/0x1b5b38E4AA8Baa2B1b58442C453b0bF75FE1cF4b#code |
| Blacklist        | https://bscscan.com/address/0x75b019Af9046d87D51d1b789Ac1494751F7AF287#code |
| KUMABondToken    | https://bscscan.com/address/0x23022554c5EACF1f7D574C154E5e7D6A6F7AA99b#code |
