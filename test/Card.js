// SPDX-License-Identifier: MIT

/**
 * Make sure to:
 * 1) Run local Hardhat node: `npx hardhat node`
 * 2) Deploy tokens to the node: `npx hardhat run scripts/local/1_deployTokensLocal.js --network localhost`
 * Before running tests: `npx hardhat test --network localhost`
 */

const { expect } = require("chai");
const { ethers } = require("hardhat");
const { parseEther } = ethers.utils;

if (network.name != "localhost") {
  throw "[ERROR]\nNetwork is not `localhost`! Aborting tests...\nPlease run test with `npx hardhat test --network localhost`";
}

describe("Card", function () {
  let cardNFT;
  let accounts;

  beforeEach(async () => {
    accounts = await ethers.getSigners();
    const tokenFactory = await ethers.getContractFactory("Card");
    cardNFT = await tokenFactory.deploy();
    await cardNFT.deployed();
  });

  it("Should verify that the contract has been deployed by accounts[0]", async () => {
    await expect(await cardNFT.owner()).to.equal(accounts[0].address);
  });

  it("Should fail to mint if caller does not have enough rights", async () => {
    await expect(cardNFT.connect(accounts[2]).mint(accounts[3].address, 0)).to
      .be.reverted;
  });

  it("Should fail to add minter if caller does not have enough rights", async () => {
    await expect(
      cardNFT.connect(accounts[3]).setMinterRole(accounts[3].address, true)
    ).to.be.reverted;
  });

  it("Should mint from owner account", async () => {
    await cardNFT.connect(accounts[0]).mint(accounts[1].address, 0);
    expect(await cardNFT.ownerOf(0)).to.equal(accounts[1].address);
  });

  it("Should give minter's rights to another account and mint from it", async () => {
    await cardNFT.setMinterRole(accounts[4].address, true);
    await cardNFT.connect(accounts[4]).mint(accounts[5].address, 1);
    expect(await cardNFT.ownerOf(1)).to.equal(accounts[5].address);
  });

  it("Should get list of tokens owned by the address", async () => {
    await cardNFT.mint(accounts[5].address, 2);
    await cardNFT.mint(accounts[5].address, 3);
    await cardNFT.mint(accounts[5].address, 4);
    let tokens = await cardNFT.getNFTListByAddress(accounts[5].address);
    // A BigNumber array does not support `.length`
    let count = 0;
    while (true) {
      if (tokens[count] !== undefined) {
        count += 1;
      } else {
        break;
      }
    }
    expect(count).to.equal(await cardNFT.balanceOf(accounts[5].address));
  });
});
