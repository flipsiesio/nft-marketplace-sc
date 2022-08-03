# Poker NFT Marketplace

This repository contains contracts of poker game cards marketplace

### Prerequisites :page_with_curl:
- Install [Node.js](https://nodejs.org/en/download/)
- Clone this repository
- Navigate to the directory with the cloned code
- Install [Hardhat](https://hardhat.org/) with `npm install --save-dev hardhat`
- Create a [MetaMask](https://metamask.io/) wallet
  - Install MetaMask Chrome extension
  - Add [BTTC Mainnet](https://medium.com/@BitTorrent/how-to-connect-to-metamask-wallet-on-bittorrent-chain-412e9ea7a99f) to MetaMask
  - Add [BTTC Donau Testnet](https://testfaucet.bittorrentchain.io/#/:~:text=BitTorrent%20Chain%20Donau%20Network%20Configuration) to MetaMask
- Create a file called `.env` in the root of the project with the same contents as `.env.example`
- Copy your private key from MetaMask to `.env` file
```
BTTC_PRIVATE_KEY=***your private key from MetaMask***
```
:warning:__DO NOT SHARE YOUR .env FILE IN ANY WAY OR YOU RISK TO LOSE ALL YOUR FUNDS__:warning:

---
Next steps will show you how to _build_ and _deploy_ the contract :computer:.  

### 1. Build
```
npx hardhat compile
```

### 2. Test
```
npx hardhat test
```
Move to the "Deploy" step _only_ if all tests pass!

### 3. Deploy
а) __Donau__ test network  
Make sure you have _enough test BTT_ tokens for testnet. You can get it for free from [faucet](https://testfaucet.bittorrentchain.io/#/).  
```
npx hardhat run scripts/deploy.js --network donau
```  
b) __BTTC main__ network  
Make sure you have _enough real BTT_ tokens in your wallet. Deployment to the mainnet costs real BTT!
```
npx hardhat run scripts/deploy.js --network bttc
```
Deployment script takes more than 1.5 minutes to complete. Please, be patient.  

After the contracts get deployed you can find their _addresses_ and (_addresses_ + :warning:_private keys_:warning:) of some _wallets_ used in deployment in the `deployOutput.json` file. You __have to__ provide these wallets with some BTT / test BTT in order to call contracts' methods from them. Keep in mind that if you are deploying to mainnet then you have to keep your private keys secret or you risk to loose all your real BTT. But if you are deploying to testnet you might not be worried so much because you can get more test BTT from the faucet any time. 

Also if you want some other address to be the owner of deployed contracts then you can use random wallet generator script:
```
npx hardhat run scripts/createOwnerWallet.js
```  
Make sure __to save__ wallet's address and private key that will be printed in the terminal! They _are not_ saved to any file!  
Then you can provide a freshly created wallet with some real / test BTT and place its private key into `.env` file instead of a previous private key imported from MetaMask. Run deployment scripts after that.

Please note that all deployed contracts __are not verified__ on either [BttcScan](https://bttcscan.com/) or [BttcTestScan](https://testnet.bttcscan.com/). You __have__ to do it manually!