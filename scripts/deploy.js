// SPDX-License-Identifier: MIT 
const { ethers, network } = require("hardhat");
const fs = require("fs");
const path = require("path");
const delay = require("delay");

// JSON file to keep information about previous deployments
const OUTPUT_DEPLOY = require("./deployOutput.json");

let wallet = ethers.Wallet.createRandom();;
let contractName;
let token;
let oracle;
let gameController;
let poolController;
let poker;
let migrations;
let interfaces;


async function main() {


  let userAddress = process.env.BTTC_ACC_ADDR || wallet.address;

  // Contract #1: XTRXToken
  contractName = "XTRXToken";
  console.log(`[${contractName}]: Start of Deployment...`);
  _contractProto = await ethers.getContractFactory(contractName);
  contractDeployTx = await _contractProto.deploy();
  token = await contractDeployTx.deployed();
  console.log(`[${contractName}]: Deployment Finished!`);
  OUTPUT_DEPLOY.networks[network.name][contractName].address = token.address;


  // Contract #2: Oracle
  contractName = "Oracle";
  console.log(`[${contractName}]: Start of Deployment...`);
  _contractProto = await ethers.getContractFactory(contractName);
  // Provide the oracle with operator address.
  contractDeployTx = await _contractProto.deploy(userAddress);
  oracle = await contractDeployTx.deployed();
  console.log(`[${contractName}]: Deployment Finished!`);
  OUTPUT_DEPLOY.networks[network.name][contractName].oracleOperatorAddress = userAddress;
  OUTPUT_DEPLOY.networks[network.name][contractName].address = oracle.address;
  
  // Contract #3: GameController
  contractName = "GameController";
  console.log(`[${contractName}]: Start of Deployment...`);
  _contractProto = await ethers.getContractFactory(contractName);
  // Provide the game controller with oracle address 
  contractDeployTx = await _contractProto.deploy(oracle.address);
  gameController = await contractDeployTx.deployed();
  console.log(`[${contractName}]: Deployment Finished!`);
  OUTPUT_DEPLOY.networks[network.name][contractName].oracleAddress = oracle.address;
  OUTPUT_DEPLOY.networks[network.name][contractName].address = gameController.address;


  // Contract #4: PoolController
  contractName = "PoolController";
  console.log(`[${contractName}]: Start of Deployment...`);
  _contractProto = await ethers.getContractFactory(contractName);
  // Provide the pool controller with token address 
  contractDeployTx = await _contractProto.deploy(token.address);
  poolController = await contractDeployTx.deployed();
  console.log(`[${contractName}]: Deployment Finished!`);
  OUTPUT_DEPLOY.networks[network.name][contractName].address = poolController.address;

  // Contract #5: Poker
  contractName = "Poker";
  console.log(`[${contractName}]: Start of Deployment...`);
  _contractProto = await ethers.getContractFactory(contractName);
  // Provide the game with oracle, pool controller, game owner address (same as oracle operator) 
  contractDeployTx = await _contractProto.deploy(oracle.address, poolController.address, userAddress);
  poker = await contractDeployTx.deployed();
  console.log(`[${contractName}]: Deployment Finished!`);
  OUTPUT_DEPLOY.networks[network.name][contractName].pokerOperatorAddress = userAddress;
  OUTPUT_DEPLOY.networks[network.name][contractName].address = poker.address;

  // Contract #6: Migrations
  contractName = "Migrations";
  console.log(`[${contractName}]: Start of Deployment...`);
  _contractProto = await ethers.getContractFactory(contractName);
  contractDeployTx = await _contractProto.deploy();
  migrations = await contractDeployTx.deployed();
  console.log(`[${contractName}]: Deployment Finished!`);
  OUTPUT_DEPLOY.networks[network.name][contractName].address = migrations.address;

  // Interfaces from `Interfaces.sol` are abstract and can't be deployed

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
