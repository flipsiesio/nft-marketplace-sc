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

  it("Should mint 2 of 15 allowed tokens and fail to mint 14 more", async () => {
    // Give minter's rights to the factory
    await cardNFT.connect(accounts[0]).setCardMinter(factory.address, true);
    // Mint 2 of 15 tokens of option 0
    for (let i = 0; i < 2; i++) {
      await factory.mint(0, accounts[1].address);
    }
    expect(await cardNFT.balanceOf(accounts[1].address)).to.equal(2);
    // Try to mint 14 more tokens (2 + 14 > 15)
    for (let i = 0; i < 14; i++) {
      if (i < 13) {
        await factory.mint(0, accounts[1].address);
      } else {
        // The last one should fail
        await expect(factory.mint(0, accounts[1].address)).to.be.reverted;
      }
    }
  });

  it("Should fail to mint cards if caller does not have minter's rights", async () => {
    await expect(factory.connect(accounts[0]).mint(0, accounts[3].address)).to.be.reverted;
  });

  it("Should give minter's rights to another account", async () => {
    // Give Option Minter rights from factory to another account
    await factory.connect(accounts[0]).setOptionMinter(accounts[1].address, true);
    // Give factory rights to call card mint function
    await cardNFT.connect(accounts[0]).setCardMinter(factory.address, true);
    // Mint tokens from that account
    await factory.connect(accounts[1]).mint(0, accounts[3].address);
    expect(await cardNFT.balanceOf(accounts[3].address)).to.equal(1);
  });

  it("Should fail to set boundaries of the invalid option", async () => {
    await expect(factory.setIdBoundaryForOption(10, 0, 5)).to.be.reverted;
  });

  it("Should fail to change the mintable token if a caller is not an owner", async () => {
    await expect(factory.connect(accounts[1]).setMintableToken(
      "0x0000000000000000000000000000000000000000",
    )).to.be.reverted;
  });

  it("Should change mintable token if a caller is an onwer", async () => {
    await factory.connect(accounts[0]).setMintableToken(
      "0x0000000000000000000000000000000000000000"
    );
    expect(await factory.getMintableToken()).to.equal(
      "0x0000000000000000000000000000000000000000"
    );
  });

});
