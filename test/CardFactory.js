// SPDX-License-Identifier: MIT

const { expect } = require("chai");
const { ethers } = require("hardhat");
const { parseEther } = ethers.utils;


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
    factory = await factoryTx.deploy(cardNFT.address);
    await factory.deployed();

    // Allow to mint some tokens
    await factory.setIdBoundaryForOption(0, 0, 15);
    await factory.setIdBoundaryForOption(1, 15, 30);
    await factory.setIdBoundaryForOption(2, 30, 45);
    await factory.setIdBoundaryForOption(3, 45, 60);
    await factory.setIdBoundaryForOption(4, 60, 75);
  });


  it("should allow to create 15 tokens of option 0", async () => {
    expect(await factory.availableTokens(0)).to.equal(15);
  });

  it("should mint 2 tokens", async () => {
    for (let i = 0; i < 2; i++) {
      await factory.mint(0, accounts[1].address);
    }
    expect(await cardNFT.balanceOf(accounts[1].address)).to.equal(2);
  });

  it("should fail to mint — not a minter", async () => {
    expect(await factory.connect(accounts[1]).mint(0, accounts[3].address)).to.be.reverted;
  });

  it("should give minter's rights to another account and mint from it", async () => {
    await factory.connect(accounts[0]).setOptionMinter(accounts[1].address, true);
    await factory.connect(accounts[1]).mint(0, accounts[3].address);
    expect(await cardNFT.balanceOf(accounts[3].address)).to.equal(1);
  });

  it("should fail to mint another 3 tokens", async () => {
    for (let i = 0; i < 3; i++) {
      expect(await factory.mint(0, accounts[2].address)).to.be.reverted;
    }
  });

  it("should fail to set boundaries — wrong option", async () => {
    expect(await factory.setIdBoundaryForOption(10, 0, 5)).to.be.reverted;
  });

  it("should fail to change mintableToken — not a owner", async () => {
    expect(await factory.connect(accounts[1]).setMintableToken(
      "0x0000000000000000000000000000000000000000",
    )).to.be.reverted;
  });

  it("should change mintableToken", async () => {
    await factory.connect(accounts[0]).setMintableToken(
      "0x0000000000000000000000000000000000000000"
    );
    expect(await factory.mintableToken()).to.equal(
      "0x0000000000000000000000000000000000000000"
    );
  });

});
