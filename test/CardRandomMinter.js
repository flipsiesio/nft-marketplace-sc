// SPDX-License-Identifier: MIT

const { expect } = require("chai");
const { ethers } = require("hardhat");
const { parseEther } = ethers.utils;


describe("CardRandomMinter", function () {

  let cardNFT;
  let factory;
  let minter;


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

    let minterTx = await ethers.getContractFactory("CardRandomMinter");
    minter = await minterTx.deploy(factory.address);
    await minter.deployed();

    // Give Minter's rights to the factory
    await cardNFT.connect(accounts[0]).setMinterRole(factory.address, true);
    // Give Option Minter's rights from factory to another account
    await factory.connect(accounts[0]).setMinterRole(minter.address, true);

    // Allow to mint some tokens
    await factory.setIdBoundaryForOption(0, 0, 15);
    await factory.setIdBoundaryForOption(1, 15, 30);
    await factory.setIdBoundaryForOption(2, 30, 45);
    await factory.setIdBoundaryForOption(3, 45, 60);
    await factory.setIdBoundaryForOption(4, 60, 75);
  });


  it("Should give minter rights to admin and mint 3 tokens to another account", async () => {
    await minter.connect(accounts[0]).setMinterRole(accounts[0].address, true);
    await minter.connect(accounts[0]).mintRandomFree(3, accounts[1].address, "simple_description");
    expect(await cardNFT.balanceOf(accounts[1].address)).to.equal(3);
  });

  it("Should set mint price", async () => {
    await minter.setPrice("1500");
    expect(await minter.price()).to.equal(1500);
  });

  it("Should sell tokens if enough funds was transfered", async () => {
    await minter.connect(accounts[0]).setPrice(1500);
    let result = await minter.connect(accounts[2]).mintRandom(3, { value: 4500 });
    expect(await cardNFT.balanceOf(accounts[2].address)).to.equal(3);
  });

  it("Should not sell tokens if not enough funds were transfered", async () => {
    await minter.connect(accounts[0]).setPrice(1500);
    await expect(minter.connect(accounts[3]).mintRandom(3, { value: 4499 })).to.be.reverted;
  });
});
