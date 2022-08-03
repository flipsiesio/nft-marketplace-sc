// SPDX-License-Identifier: MIT 
const { ethers, network } = require("hardhat");
const fs = require("fs");
const path = require("path");
const delay = require("delay");

// JSON file to keep information about previous deployments
const OUTPUT_DEPLOY = require("./deployOutput.json");

// Creates a number of random wallets to be used while deploying contracts
function createWallets(numberWallets) {
  let createdWallets = [];
  for (let i = 0; i < numberWallets; i++) {
    let wallet = ethers.Wallet.createRandom();
    createdWallets.push(wallet);
    console.log(`New wallet №${i + 1}:`);
    console.log(`    Address: ${wallet.address}`); 
    console.log(`    Private key: ${wallet.privateKey}`);
  }
  return createdWallets;
}


// Create 2 new wallets
// Use them in NFTSale and NFTMarketplace as fee receivers
let [nftSaleFeeReceiver, nftMarketplaceFeeReceiver] = createWallets(2);

let contractName;
let card;
let cardFactory;
let cardRandomMinter;
let nftMarketplace;
let nftSale;


async function main() {


  // Contract #1: Card
  contractName = "Card";
  console.log(`[${contractName}]: Start of Deployment...`);
  _contractProto = await ethers.getContractFactory(contractName);
  contractDeployTx = await _contractProto.deploy();
  card = await contractDeployTx.deployed();
  console.log(`[${contractName}]: Deployment Finished!`);
  OUTPUT_DEPLOY.networks[network.name][contractName].address = card.address;


  // Contract #2: CardFactory
  contractName = "CardFactory";
  console.log(`[${contractName}]: Start of Deployment...`);
  _contractProto = await ethers.getContractFactory(contractName);
  // Provide the factory with card address.
  contractDeployTx = await _contractProto.deploy(card.address);
  cardFactory = await contractDeployTx.deployed();
  console.log(`[${contractName}]: Deployment Finished!`);
  OUTPUT_DEPLOY.networks[network.name][contractName].address = cardFactory.address;
  
  // Contract #3: cardRandomMinter
  contractName = "CardRandomMinter";
  console.log(`[${contractName}]: Start of Deployment...`);
  _contractProto = await ethers.getContractFactory(contractName);
  // Provide the game controller with factory address 
  contractDeployTx = await _contractProto.deploy(cardFactory.address);
  cardRandomMinter = await contractDeployTx.deployed();
  console.log(`[${contractName}]: Deployment Finished!`);
  OUTPUT_DEPLOY.networks[network.name][contractName].address = cardRandomMinter.address;

  // Contract #4: NFTSale
  contractName = "NFTSale";
  console.log(`[${contractName}]: Start of Deployment...`);
  _contractProto = await ethers.getContractFactory(contractName);
  let oneDay = 86400;
  let tenDays = 864000;
  // One BP 0.0001
  // One percent is 0.01
  // One percent in BP is 100BP
  let onePercent = 100;
  contractDeployTx = await _contractProto.deploy(card.address, nftSaleFeeReceiver.address, oneDay, tenDays, onePercent);
  nftSale = await contractDeployTx.deployed();
  console.log(`[${contractName}]: Deployment Finished!`);
  OUTPUT_DEPLOY.networks[network.name][contractName].address = nftSale.address;
  OUTPUT_DEPLOY.networks[network.name][contractName].feeReceiverAddress = nftSaleFeeReceiver.address;
  OUTPUT_DEPLOY.networks[network.name][contractName].feeReceiverPrivateKey = nftSaleFeeReceiver.privateKey;

  // Contract #5: NFTMarketplace
  contractName = "NFTMarketplace";
  console.log(`[${contractName}]: Start of Deployment...`);
  _contractProto = await ethers.getContractFactory(contractName);
  // Same as in NFTSale
  oneDay = 86400;
  tenDays = 864000;
  onePercent = 100;
  contractDeployTx = await _contractProto.deploy(card.address, nftMarketplaceFeeReceiver.address, oneDay, tenDays, onePercent);
  nftMarketplace = await contractDeployTx.deployed();
  console.log(`[${contractName}]: Deployment Finished!`);
  OUTPUT_DEPLOY.networks[network.name][contractName].address = nftMarketplace.address;
  OUTPUT_DEPLOY.networks[network.name][contractName].feeReceiverAddress = nftMarketplaceFeeReceiver.address;
  OUTPUT_DEPLOY.networks[network.name][contractName].feeReceiverPrivateKey = nftMarketplaceFeeReceiver.privateKey;

  console.log(`See Results in "${__dirname + '/deployOutput.json'}" File`);

  fs.writeFileSync(
    path.resolve(__dirname, "./deployOutput.json"),
    JSON.stringify(OUTPUT_DEPLOY, null, "  ")
  );
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });