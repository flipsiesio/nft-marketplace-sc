# Poker NFT Marketplace

This repository contains contracts of poker game cards marketplace

#### Table on contents
[Prerequisites](#preq)
[Build & Deploy](#build_and_deploy)  
[Wallets](#wallets)  
[Smart-Contract Logic](#logic)  
- [CardRandomMinter](#minter)
    - [Supported Tokens](#tokens)
  - [Functions](#functions)
  - [Logic Flow Example](#example)

<a name="preq"/>
### Prerequisites 
- Install [Node.js](https://nodejs.org/en/download/)
- Clone this repository
- Navigate to the directory with the cloned code
- Install [Hardhat](https://hardhat.org/) with `npm install --save-dev hardhat`
- Create a [MetaMask](https://metamask.io/) wallet
  - Install MetaMask Chrome extension
  - Add [BTTC Mainnet](https://doc.bt.io/docs/wallet#metamask) to MetaMask
  - Add [BTTC Donau Testnet](https://testfaucet.bittorrentchain.io/#/:~:text=BitTorrent%20Chain%20Donau%20Network%20Configuration) to MetaMask
- Create a file called `.env` in the root of the project with the same contents as `.env.example`
- Copy your wallet's private key (see [Wallets](#wallets)) to `.env` file
```
BTTC_PRIVATE_KEY=***your private key***
```

:warning:__DO NOT SHARE YOUR .env FILE IN ANY WAY OR YOU RISK TO LOSE ALL YOUR FUNDS__:warning:

<a name="build_and_deploy"/>
### Build & Deploy  
The following information will guide you through the process of building and deploying the contracts yourself.


#### 1. Build
```
npx hardhat compile
```

#### 2. Test
First, you have to start a local Hardhat node:
```
npx hardhat node
```

Then you have to deploy some ERC20 tokens to the local network:
```
npx hardhat run scripts/local/1_deployTokensLocal.js --network localhost
```
Now run tests:
```
npx hardhat test --network localhost
```
Move to the "Deploy" step __only__ if all tests pass!

#### 3. Deploy
а) __Donau__ test network  
Make sure you have _enough test BTT_ tokens for testnet in your wallet ([Wallets](#wallets)) . You can get it for free from [faucet](https://testfaucet.bittorrentchain.io/#/).  
```
npx hardhat run scripts/deployRemote.js --network donau
```  
b) __BTTC main__ network  
Make sure you have _enough real BTT_ tokens in your wallet ([Wallets](#wallets)). Deployment to the mainnet costs __real__ BTT!
```
npx hardhat run scripts/deployRemote.js --network bttc
```
Deploy to testnet/mainnet takes more than 1.5 minutes to complete. Please, be patient.  

---
After contracts get deployed, you can find their addresses in `scripts/remote/deployOutputRemote.json` file. But two contracts are a bit different from the rest:
- While deploying a `NFTSale` contract, a new wallet gets generated to become a _fee receiver_ collecting fees from NFT sales. This wallet's :warning:private key:warning: and address are saved in the file
- While deploying a `NFTMarketplace` contract, a new wallet gets generated to become a _fee receiver_ collecting fees from NFT sales. This wallet's :warning:private key:warning: and address are saved in the file  

You can import these wallets' credentials to MetaMask to be able to withdraw collected fees afterwards. __Save them somewhere else!__

Please note that all deployed contracts __are not verified__ on either [BttcScan](https://bttcscan.com/) or [BttcTestScan](https://testnet.bttcscan.com/). You __have__ to do it manually!

<a name="wallets"/>
### Wallets
For deployment you will need to use either _your existing wallet_ or _a generated one_. 

#### Using existing wallet
If you choose to use your existing wallet, then you will need to be able to export (copy/paste) its private key. For example, you can export private key from your MetaMask wallet.  
Wallet's address and private key should be pasted into the `.env` file (see [Prerequisites](#preq)).  

#### Creating a new wallet
If you choose to create a fresh wallet for this project, you should use `createWallet.js` script :
```
npx hardhat run scripts/general/createWallet.js
```
This will generate a single new wallet and show its address and private key. __Save them somewhere else! __
A new wallet _does not_ hold any tokens. You have to provide it with tokens of your choice.  
Wallet's address and private key should be pasted into the `.env` file (see [Prerequisites](#prerequisites)).

<a name="logic"/>
#### 4. Smart Contract Logic 
<a name="minter"/>
##### CardRandomMinter
The contract is used to mint random playing cards to the users.  
_Roles_:
- _Owner_. The address which deployed the contract. Has rights to:
    - Add admins
  - Remove admins
- _Admin_. The address added to the admins list by the owner. Has rights to:
    - Add [supported tokens](#supported_tokens)
  - Remove supported tokens
  - Specify a card mint price in each of supported tokens
  - Change the address of card minting factory contract
  - Grant minter rights to users
  - Withdraw revenue
    - (some other functions)
- _Minter_. The address added to the minters list by the admin. Has rights to:
    - Mint random cards _for free_ to other users
- _User_. Any address not from owners/admins/minters lists

<a name="tokens"/>
__Supported Tokens__
Currently there are several tokens that can be used by the user to _pay for a card mint_:
(addresses provided for BTTC mainnet)
- BTT (Native): 0x0000000000000000000000000000000000000000
- Ethereum (wETH): 0x1249C65AfB11D179FFB3CE7D4eEDd1D9b98AD006
- TRX (wTRX): 0xEdf53026aeA60f8F75FcA25f8830b7e2d6200662
- BNB (wBNB): 0x185a4091027E2dB459a2433F85f894dC3013aeB5
- USDT-E: 0xE887512ab8BC60BcC9224e1c3b5Be68E26048B8B
- USDT-T: 0xdB28719F7f938507dBfe4f0eAe55668903D34a15
- USDT-B: 0x9B5F27f6ea9bBD753ce3793a07CbA3C74644330d
- USDC-E: 0xAE17940943BA9440540940DB0F1877f101D39e8b
- USDC-T: 0x935faA2FCec6Ab81265B301a30467Bbc804b43d3
- USDC-B: 0xCa424b845497f7204D9301bd13Ff87C0E2e86FCF  

Default __mint price__ in each of this tokens is 0.1. For example: a user has to pay 0.1 BNB to mint a single random card.

<a name="functions"/>
__Functions__
`isAdmin`: Checks if provided address is an admin
`addAdmin`: Adds a new admin address
`removeAdmin`: Removes an address from admin list
`isSupported`: Checks if provided token is supported
`addSupportedToken`: Adds a supported token to pay for card mint
`removeSupportedToken`: Removes a supported token
`getSupportedLength`: Returns the number of supported tokens
`setMintPrice`: Sets the mint price for each supported token. __Note__ that if _decimals_ are used in the token, then the price must be set already multiplied by _decimals_. For example, if _decimals_ of ABC token is 4 and you want a user to pay 1 ABC for a random card mint, you have to set the price of 1 * 10 ^ 4 = 10_000 (`setMintPrice(ABCAddress, 10000)`)
`getMintPrice`: Returns the card mint price in provided tokens
`setMinterRole`: Gives rights to mint cards for free
`setAllowedAmountOfItemsPerRandomMint`: Sets the amount of items that can be randomly minted at once
`setFactory`: Changes the factory that mints cards
`setCurrentSeed`: Changes the source of randomness for random card mint
`setProbabilitiesForClasses`: Sets probabilty of each class of cards to be randomly minted
`mintRandomFree`: Mints a set of random items (cards) for free
`mintRandom`: Mints a set of random items (cards) for provided tokens
`getRevenue`: Transfers all collected funds to the owner of the contract

<a name="example"/>
__Logic Flow Example__
- Account with address X deploys the `CardRandomMinter` contract. He becomes the _owner_ of the contract
- The owner adds address A to the admins list (`addAdmin`). Address A becomes the _admin_
- The admin adds address B to the minters list (`setMinterRole`). Address B becomes the _minter_
- The minter mints some random card for free to Bob (`mintRandomFree`)
- The admin adds a new supported token - ABC (`addSupportedToken`)
- Alice checks that ABC token is supported (`isSupported`)
- Alice mints 5 random cards for herself (`mintRandom`). She pays ABC tokens for the mint. She gets 5 random cards transferred to her account
- Sam also decides to mint some random cards. He mints not 5, but 20 cards (`mintRandom`). He also pays ABC tokens for that. He gets 20 random cards transferred to his account
- The owner withdraws ABC tokens paid by Alice and Sam (`getRevenue`)

