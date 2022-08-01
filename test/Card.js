// SPDX-License-Identifier: MIT

const { expect } = require("chai");
const { ethers } = require("hardhat");
const { parseEther } = ethers.utils;

describe("Card", function () {

  let cardNFT;
  let accounts;

  beforeEach(async () => {
    accounts = await ethers.getSigners();
    const tokenFactory = await ethers.getContractFactory("Card");
    cardNFT = await tokenFactory.deploy();
    await cardNFT.deployed();
  });

  it("should verify that the contract has been deployed by accounts[0]", async () => {
    await expect(await cardNFT.owner()).to.equal(accounts[0].address);
  });

  it("should fail to mint from nonMinter account", async () => {
    await expect(cardNFT.connect(accounts[2]).mint(accounts[3].address, 0)).to.be.reverted;
  });

  it("should fail to add minter from nonOwner account", async () => {
    await expect(cardNFT.connect(accounts[3]).setMinterRole(accounts[3].address, true)).to.be.reverted;
  });

  it("should mint from owner account", async () => {
    await cardNFT.connect(accounts[0]).mint(accounts[1].address, 0);
    expect(await cardNFT.ownerOf(0)).to.equal(accounts[1].address);
  });

  it("should give minter's rights to another account and mint from it", async () => {
    await cardNFT.setMinterRole(accounts[4].address, true);
    await cardNFT.connect(accounts[4]).mint(accounts[5].address, 1);
    expect(await cardNFT.ownerOf(1)).to.equal(accounts[5].address);
  });

  it("should get all address' tokens", async () => {
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
