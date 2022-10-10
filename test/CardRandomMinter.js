// SPDX-License-Identifier: MIT

const { expect } = require("chai");
const { ethers } = require("hardhat");
const delay = require("delay");
const { parseUnits, parseEther } = ethers.utils;
const zeroAddress = ethers.constants.AddressZero;


// JSON file to get the list of supported tokens and their prices from
const SUPPORTED_TOKENS = require("../supportedTokens.json");

describe("CardRandomMinter", function () {

  let cardNFT;
  let factory;
  let minter;
  let randomAddress = "0x6DBAd4Bd16C15AE6dDEaA640626e5A3E151F02fC";

  beforeEach(async () => {
    [ownerAcc, clientAcc1, clientAcc2] = await ethers.getSigners();

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
    // Read supported addresses from the JSON file and add them to the minter
    for (let [token, info] of Object.entries(SUPPORTED_TOKENS)) {
      let [address, price] = Object.values(info);
        await minter.addSupportedToken(address);
        await minter.setMintPrice(address, parseUnits(price.toString(), 18));
    }

    // Give Minter's rights to the factory
    await cardNFT.connect(ownerAcc).setMinterRole(factory.address, true);
    // Give Option Minter's rights from factory to another account
    await factory.connect(ownerAcc).setMinterRole(minter.address, true);

    // Allow to mint some tokens
    await factory.setIdBoundaryForOption(0, 0, 15);
    await factory.setIdBoundaryForOption(1, 15, 30);
    await factory.setIdBoundaryForOption(2, 30, 45);
    await factory.setIdBoundaryForOption(3, 45, 60);
    await factory.setIdBoundaryForOption(4, 60, 75);
  });

  describe("Getters and Setters", () => {

    it("Should have a correct amount of supported tokens", async () => {
      let len = Object.entries(SUPPORTED_TOKENS).length;
      expect(await minter.getSupportedLength()).to.equal(len);
    });

    it("Should support existing address", async () => {
      expect(await minter.isSupported(zeroAddress)).to.equal(true);
    });

    it("Should not support non-existent address", async () => {
      expect(await minter.isSupported(randomAddress)).to.equal(false);
    });

    it("Should add a new supported token", async () => {
      await minter.addSupportedToken(randomAddress);
    });

    it("Should fail to add a new supported token if it is already supported", async () => {
      await minter.addSupportedToken(randomAddress);
      await expect(minter.addSupportedToken(randomAddress))
      .to.be.revertedWith("CardRandomMinter: Token has already been added!");
    });

    it("Should fail to add a new supported token if caller is not the owner", async () => {
      await expect(minter.connect(clientAcc1).addSupportedToken(randomAddress))
      .to.be.revertedWith("Ownable: caller is not the owner");
    });

    it("Should remove a supported token", async () => {
      // Add it first
      await minter.addSupportedToken(randomAddress);
      expect(await minter.isSupported(randomAddress)).to.equal(true);
      await minter.removeSupportedToken(randomAddress);
      expect(await minter.isSupported(randomAddress)).to.equal(false);
    });

    it("Should fail to remove a not supported token", async () => {
      await expect(minter.removeSupportedToken(randomAddress))
      .to.be.revertedWith("CardRandomMinter: Token is not supported!")
    });

    it("Should fail to remove a supported token if caller is not the owner", async () => {
      await minter.addSupportedToken(randomAddress);
      await expect(minter.connect(clientAcc1).removeSupportedToken(randomAddress))
      .to.be.revertedWith("Ownable: caller is not the owner");
    });

    it("Should get a card mint price in tokens", async () => {
      await minter.addSupportedToken(randomAddress);
      expect(await minter.getMintPrice(randomAddress)).to.equal(0);
    });

    it("Should fail to get a card mint price in not supported tokens", async () => {
      await expect(minter.getMintPrice(randomAddress))
      .to.be.revertedWith("CardRandomMinter: Token is not supported!")
    });

    it("Should set a card mint price in tokens", async () => {
      await minter.addSupportedToken(randomAddress);
      await minter.setMintPrice(randomAddress, 500);
      expect(await minter.getMintPrice(randomAddress)).to.equal(500);
    });

    it("Should fail to set a card mint price in not supported tokens", async () => {
      await expect(minter.setMintPrice(randomAddress, 500))
      .to.be.revertedWith("CardRandomMinter: Token is not supported!")
    });

    it("Should fail to set a zero mint price", async () => {
      await minter.addSupportedToken(randomAddress);
      await expect(minter.setMintPrice(randomAddress, 0))
      .to.be.revertedWith("CardRandomMinter: Price can not be zero!")
    });

    it("Should give minter rights to users", async () => {
      await minter.setMinterRole(clientAcc1.address, true);
    });

    it("Should fail to give minter rights to users if caller is not the owner", async () => {
      await expect(minter.connect(clientAcc1).setMinterRole(clientAcc1.address, true))
      .to.be.revertedWith("Ownable: caller is not the owner");
    });

    it("Should set allowed amount of cards to mint", async () => {
      await minter.setAllowedAmountOfItemsPerRandomMint(5, true);
    });

    it("Should fail to set allowed amount of cards to mint if caller is not the owner", async () => {
      await expect(minter.connect(clientAcc1).setAllowedAmountOfItemsPerRandomMint(5, true))
      .to.be.revertedWith("Ownable: caller is not the owner");
    });

    it("Should fail to set zero amount of cards to mint", async () => {
      await expect(minter.setAllowedAmountOfItemsPerRandomMint(0, true))
      .to.be.revertedWith("CardRandomMinter: Can not mint zero cards!");
    });

    it("Should set a new factory address", async () => {
      await minter.setFactory(clientAcc1.address);
    });

    it("Should fail set a new factory address if caller is not the onwner", async () => {
      await expect(minter.connect(clientAcc1).setFactory(clientAcc1.address))
      .to.be.revertedWith("Ownable: caller is not the owner");
    });

    it("Should fail set a zero factory address", async () => {
      await expect(minter.setFactory(zeroAddress))
      .to.be.revertedWith("CardRandomMinter: Factory can not have a zero address!");
    });

    it("Should set a new seed", async () => {
      await minter.setCurrentSeed(777);
    });

    it("Should fail set a new seed if caller is not the onwner", async () => {
      await expect(minter.connect(clientAcc1).setCurrentSeed(777))
      .to.be.revertedWith("Ownable: caller is not the owner");
    });

    it("Should set mint probabilities for different classes of cards", async () => {
      await minter.setProbabilitiesForClasses([0, 0, 1, 5000, 777]);
    });

    it("Should fail set new mint probabilities if caller is not the owner", async () => {
      await expect(minter.connect(clientAcc1).setProbabilitiesForClasses([0, 0, 1, 5000, 777]))
      .to.be.revertedWith("Ownable: caller is not the owner");
    });

  });



  // it("Should give minter rights to admin and mint 3 tokens to another account", async () => {
  //   await minter.connect(accounts[0]).setMinterRole(accounts[0].address, true);
  //   await minter.connect(accounts[0]).mintRandomFree(3, accounts[1].address, "simple_description");
  //   expect(await cardNFT.balanceOf(accounts[1].address)).to.equal(3);
  // });

  // it("Should set mint price", async () => {
  //   await minter.setPrice("1500");
  //   expect(await minter.price()).to.equal(1500);
  // });

  // it("Should sell tokens if enough funds was transfered", async () => {
  //   await minter.connect(accounts[0]).setPrice(1500);
  //   let result = await minter.connect(accounts[2]).mintRandom(3, { value: 4500 });
  //   expect(await cardNFT.balanceOf(accounts[2].address)).to.equal(3);
  // });

  // it("Should not sell tokens if not enough funds were transfered", async () => {
  //   await minter.connect(accounts[0]).setPrice(1500);
  //   await expect(minter.connect(accounts[3]).mintRandom(3, { value: 4499 })).to.be.reverted;
  // });
});
