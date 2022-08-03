// SPDX-License-Identifier: MIT 
const { ethers, network } = require("hardhat");

/**
 * Creates a single random wallet to be used for testnet 
 * NOTE Address and private key of the wallet will be displayed in the terminal. Copy them and save somewhere else!
 * NOTE Place this wallet's private key into '.env' BTTC_PRIVATE_KEY in order to deploy conctracts from its address
 */

async function main() {

  let wallet = ethers.Wallet.createRandom();
  console.log(`New wallet:`);
  console.log(`    Address: ${wallet.address}`); 
  console.log(`    Private key: ${wallet.privateKey}`);

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });