// SPDX-License-Identifier: MIT

const { expect } = require("chai");
const { ethers } = require("hardhat");
const { parseEther } = ethers.utils;

/**
 * Make sure to:
 * 1) Run local Hardhat node: `npx hardhat node`
 * 2) Deploy tokens to the node: `npx hardhat run scripts/local/1_deployTokensLocal.js --network localhost`
 * Before running tests: `npx hardhat test --network localhost`
 */

if (network.name != "localhost") {
  throw "[ERROR]\nNetwork is not `localhost`! Aborting tests...\nPlease run test with `npx hardhat test --network localhost`";
}

describe("CardFactory", function () {
  let cardNFT;
  let factory;
  let accounts;

  beforeEach(async () => {
    accounts = await ethers.getSigners();

    let cardTx = await ethers.getContractFactory("Card");
    cardNFT = await cardTx.deploy();
    await cardNFT.deployed();

    let factoryTx = await ethers.getContractFactory("CardFactory");
    // NOTE! This does not give the factory card's CardMinter role
    // We have to explicitly give this role to the factory in the tests
    factory = await factoryTx.deploy(cardNFT.address);
    await factory.deployed();

    // Allow to mint some tokens
    await factory.setIdBoundaryForOption(0, 0, 15);
    await factory.setIdBoundaryForOption(1, 15, 30);
    await factory.setIdBoundaryForOption(2, 30, 45);
    await factory.setIdBoundaryForOption(3, 45, 60);
    await factory.setIdBoundaryForOption(4, 60, 75);
  });

  it("Should allow to create 15 tokens of option 0", async () => {
    expect(await factory.availableTokens(0)).to.equal(15);
  });

  it("Should mint 15 allowed tokens and fail to mint 1 more", async () => {
    // Give minter's rights to the factory
    await cardNFT.connect(accounts[0]).setMinterRole(factory.address, true);

    for (let i = 0; i < 15; i++) {
      await factory.mint(0, accounts[1].address);
      expect(await cardNFT.ownerOf(i)).to.be.equal(accounts[1].address);
    }
    await factory.mint(0, accounts[1].address);
    expect(await cardNFT.exists(15)).to.be.false;
  });

  it("Should fail to mint cards if caller does not have minter's rights", async () => {
    await expect(factory.connect(accounts[0]).mint(0, accounts[3].address)).to
      .be.reverted;
  });

  it("Should give minter's rights to another account", async () => {
    // Give Option Minter rights from factory to another account
    await factory.connect(accounts[0]).setMinterRole(accounts[1].address, true);
    // Give factory rights to call card mint function
    await cardNFT.connect(accounts[0]).setMinterRole(factory.address, true);
    // Mint tokens from that account
    await factory.connect(accounts[1]).mint(0, accounts[3].address);
    expect(await cardNFT.balanceOf(accounts[3].address)).to.equal(1);
  });

  it("Should fail to set boundaries of the invalid option", async () => {
    await expect(factory.setIdBoundaryForOption(10, 0, 5)).to.be.reverted;
  });

  it("Should fail to change the mintable token if a caller is not an owner", async () => {
    await expect(
      factory
        .connect(accounts[1])
        .setMintableToken("0x0000000000000000000000000000000000000000")
    ).to.be.reverted;
  });

  it("Should change mintable token if a caller is an onwer", async () => {
    await factory
      .connect(accounts[0])
      .setMintableToken("0x0000000000000000000000000000000000000000");
    expect(await factory.getMintableToken()).to.equal(
      "0x0000000000000000000000000000000000000000"
    );
  });
});
