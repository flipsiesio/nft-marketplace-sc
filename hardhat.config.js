// SPDX-License-Identifier: MIT
require('dotenv').config()
const { ethers } = require("ethers");
require("@nomicfoundation/hardhat-toolbox");

// Add some .env individual variables
const BTTC_PRIVATE_KEY = process.env.BTTC_PRIVATE_KEY;
const BTTC_SCAN_KEY = process.env.BTTC_SCAN_KEY


module.exports = {
  defaultNetwork: "hardhat",
  networks: {
    // a.k.a localhost
    hardhat: {
      gas: 2100000,
      gasPrice: 8000000000,
    },
    // BTTC Donau testnet
    donau: {
      url: "https://pre-rpc.bt.io/",
      accounts: [BTTC_PRIVATE_KEY]
    },
    // BTTC mainnet
    bttc: {
      url: "https://rpc.bt.io/",
      accounts: [BTTC_PRIVATE_KEY]
    }
  },
  solidity: {
    version: "0.8.12",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts"
  },
  mocha: {
    timeout: 20000000000
  },
  etherscan: {
    apiKey: BTTC_SCAN_KEY,
    customChains: [
      {
        network: "donau",
        chainId: 1029,
        urls: {
          apiURL: "https://api-testnet.bttcscan.com/api",
          browserURL: "https://testnet.bttcscan.com/"
        }
      }
    ]
  }
}
