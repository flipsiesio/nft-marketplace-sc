const { expect } = require("chai");
const { ethers } = require("hardhat");
const delay = require("delay");
const { parseUnits, parseEther } = ethers.utils;
const zeroAddress = ethers.constants.AddressZero;

/**
 * NOTE: This test must be running on `localhost` network!
 *
 * In order for this test suite to pass make sure to:
 * 1) Run local Hardhat node: `npx hardhat node`
 * 2) Deploy tokens to the node: `npx hardhat run scripts/local/1_deployTokensLocal.js --network localhost`
 * 3) Run this test suite with `npx hardhat test test/CardRandomMinter.js --network localhost`
 */

if (network.name != "localhost") {
  throw "[ERROR]\nNetwork is not `localhost`! Aborting tests...\nPlease run test with `npx hardhat test --network localhost`";
}

const SUPPORTED_TOKENS = require("../scripts/local/supportedTokensLocal.json");

describe("CardRandomMinter", function () {
  let cardNFT;
  let factory;
  let minter;
  let token;
  let randomAddress = "0x6DBAd4Bd16C15AE6dDEaA640626e5A3E151F02fC";
  let provider = ethers.provider;

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
    // NOTE! By default only 2 addresses are admins. But for the test on local `hardhat` network
    //       we have to add another account.
    await minter.addAdmin(ownerAcc.address);

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

    let addresses = new Array();

    // Read all tokens addresses from the file and add each of the tokens to supported tokens
    // NOTE: This is only done for `getRevenue` method to work correctly.
    // NOTE: If test runs *not* on `localhost` network - `getRevenue` will revert as it will
    //       try to call the address from `localhost` while running on another network!
    for (let [token, info] of Object.entries(SUPPORTED_TOKENS)) {
      let [address, price] = Object.values(info);
      await minter.addSupportedToken(address);
      // `price` in JSON file is without `decimals`, so we have to multiply it by `decimals` using `parseEther`
      await minter.setMintPrice(address, parseEther(price.toString()));

      // Use one of the addresses from the file to connect token contract to
      if (address != zeroAddress) {
        addresses.push(address);
      }
    }

    // Pick one random address from all supported addresses from the file
    let oneOfAddresses =
      addresses[Math.floor(Math.random() * addresses.length)];
    let newToken = await ethers.getContractFactory("Rummy");
    // Connect mock contract to one of the addresses.
    // This imitates ERC20 token in mainnet or testnet.
    token = await ethers.getContractAt("Rummy", oneOfAddresses);
    // Mint these tokens to 2 of 3 accounts
    // Use `parseEther` because of `decimals`
    await token.mintTo(ownerAcc.address, parseEther("1000"));
    await token.mintTo(clientAcc1.address, parseEther("1000"));
    // Allow transfer of all minted tokens
    await token.connect(ownerAcc).approve(minter.address, parseEther("1000"));
    await token.connect(clientAcc1).approve(minter.address, parseEther("1000"));
    // This one actually does not have any tokens
    await token.connect(clientAcc2).approve(minter.address, parseEther("1000"));
  });

  describe("Getters and Setters", () => {
    it("Should support existing address", async () => {
      expect(await minter.isSupported(token.address)).to.equal(true);
    });

    it("Should not support non-existent address", async () => {
      expect(await minter.isSupported(randomAddress)).to.equal(false);
    });

    it("Should add a new supported token", async () => {
      await minter.addSupportedToken(randomAddress);
    });

    it("Should fail to add a new supported token if it is already supported", async () => {
      await minter.addSupportedToken(randomAddress);
      await expect(minter.addSupportedToken(randomAddress)).to.be.revertedWith(
        "CardRandomMinter: token has already been added!"
      );
    });

    it("Should fail to add a new supported token if caller is not an admin!", async () => {
      await expect(
        minter.connect(clientAcc1).addSupportedToken(randomAddress)
      ).to.be.revertedWith("CardRandomMinter: caller is not an admin!");
    });

    it("Should remove a supported token", async () => {
      // Add it first
      await minter.addSupportedToken(randomAddress);
      expect(await minter.isSupported(randomAddress)).to.equal(true);
      await minter.removeSupportedToken(randomAddress);
      expect(await minter.isSupported(randomAddress)).to.equal(false);
    });

    it("Should fail to remove a not supported token", async () => {
      await expect(
        minter.removeSupportedToken(randomAddress)
      ).to.be.revertedWith("CardRandomMinter: token is not supported!");
    });

    it("Should fail to remove a supported token if caller is not an admin!", async () => {
      await minter.addSupportedToken(randomAddress);
      await expect(
        minter.connect(clientAcc1).removeSupportedToken(randomAddress)
      ).to.be.revertedWith("CardRandomMinter: caller is not an admin!");
    });

    it("Should get a card mint price in tokens", async () => {
      await minter.addSupportedToken(randomAddress);
      expect(await minter.getMintPrice(randomAddress)).to.equal(0);
    });

    it("Should fail to get a card mint price in not supported tokens", async () => {
      await expect(minter.getMintPrice(randomAddress)).to.be.revertedWith(
        "CardRandomMinter: token is not supported!"
      );
    });

    it("Should set a card mint price in tokens", async () => {
      await minter.addSupportedToken(randomAddress);
      await minter.setMintPrice(randomAddress, 500);
      expect(await minter.getMintPrice(randomAddress)).to.equal(500);
    });

    it("Should fail to set a card mint price in not supported tokens", async () => {
      await expect(minter.setMintPrice(randomAddress, 500)).to.be.revertedWith(
        "CardRandomMinter: token is not supported!"
      );
    });

    it("Should fail to set a zero mint price", async () => {
      await minter.addSupportedToken(randomAddress);
      await expect(minter.setMintPrice(randomAddress, 0)).to.be.revertedWith(
        "CardRandomMinter: price can not be zero!"
      );
    });

    it("Should check if address is an admin", async () => {
      expect(await minter.isAdmin(randomAddress)).to.equal(false);
      expect(await minter.isAdmin(ownerAcc.address)).to.equal(true);
      expect(await minter.isAdmin(zeroAddress)).to.equal(false);
    });

    it("Should add a new admin", async () => {
      expect(await minter.isAdmin(randomAddress)).to.equal(false);
      await minter.addAdmin(randomAddress);
      expect(await minter.isAdmin(randomAddress)).to.equal(true);
    });

    it("Should fail to add an already existing admin", async () => {
      await expect(minter.addAdmin(ownerAcc.address)).to.be.revertedWith(
        "CardRandomMinter: address is already an admin!"
      );
    });

    it("Should fail to add a zero address admin", async () => {
      await expect(minter.addAdmin(zeroAddress)).to.be.revertedWith(
        "CardRandomMinter: zero address can not be an admin!"
      );
    });

    it("Should delete an admin", async () => {
      expect(await minter.isAdmin(ownerAcc.address)).to.equal(true);
      await minter.removeAdmin(ownerAcc.address);
      expect(await minter.isAdmin(ownerAcc.address)).to.equal(false);
    });

    it("Should fail to delete a non-existent admin", async () => {
      await expect(minter.removeAdmin(zeroAddress)).to.be.revertedWith(
        "CardRandomMinter: no such admin!"
      );
    });

    it("Should give minter rights to users", async () => {
      await minter.setMinterRole(clientAcc1.address, true);
    });

    it("Should fail to give minter rights to users if caller is not an admin!", async () => {
      await expect(
        minter.connect(clientAcc1).setMinterRole(clientAcc1.address, true)
      ).to.be.revertedWith("CardRandomMinter: caller is not an admin!");
    });

    it("Should set allowed amount of cards to mint", async () => {
      await minter.setAllowedAmountOfItemsPerRandomMint(5, true);
    });

    it("Should fail to set allowed amount of cards to mint if caller is not an admin!", async () => {
      await expect(
        minter.connect(clientAcc1).setAllowedAmountOfItemsPerRandomMint(5, true)
      ).to.be.revertedWith("CardRandomMinter: caller is not an admin!");
    });

    it("Should fail to set zero amount of cards to mint", async () => {
      await expect(
        minter.setAllowedAmountOfItemsPerRandomMint(0, true)
      ).to.be.revertedWith("CardRandomMinter: can not mint zero cards!");
    });

    it("Should set a new factory address", async () => {
      await minter.setFactory(clientAcc1.address);
    });

    it("Should fail set a new factory address if caller is not the onwner", async () => {
      await expect(
        minter.connect(clientAcc1).setFactory(clientAcc1.address)
      ).to.be.revertedWith("CardRandomMinter: caller is not an admin!");
    });

    it("Should fail set a zero factory address", async () => {
      await expect(minter.setFactory(zeroAddress)).to.be.revertedWith(
        "CardRandomMinter: factory can not have a zero address!"
      );
    });

    it("Should set a new seed", async () => {
      await minter.setCurrentSeed(777);
    });

    it("Should fail set a new seed if caller is not the onwner", async () => {
      await expect(
        minter.connect(clientAcc1).setCurrentSeed(777)
      ).to.be.revertedWith("CardRandomMinter: caller is not an admin!");
    });

    it("Should set mint probabilities for different classes of cards", async () => {
      await minter.setProbabilitiesForClasses([0, 0, 1, 5000, 777]);
    });

    it("Should fail to set new mint probabilities if caller is not an admin!", async () => {
      await expect(
        minter
          .connect(clientAcc1)
          .setProbabilitiesForClasses([0, 0, 1, 5000, 777])
      ).to.be.revertedWith("CardRandomMinter: caller is not an admin!");
    });
  });

  describe("Mint Functions", () => {
    describe("Free Mint", () => {
      it("Should mint cards for free", async () => {
        let startBalance = await cardNFT.balanceOf(clientAcc1.address);
        await minter.setAllowedAmountOfItemsPerRandomMint(10, true);
        await minter.setMinterRole(ownerAcc.address, true);
        await minter.mintRandomFree(5, clientAcc1.address, "");
        let endBalance = await cardNFT.balanceOf(clientAcc1.address);
        expect(endBalance.sub(startBalance)).to.equal(5);
      });

      it("Should fail to mint cards for free if caller is not a minter", async () => {
        await minter.setAllowedAmountOfItemsPerRandomMint(10, true);
        await expect(
          minter.mintRandomFree(5, clientAcc1.address, "")
        ).to.be.revertedWith("CardRandomMinter: caller is not a minter!");
      });
    });

    describe("Payed Mint", () => {
      describe("For Native Tokens", () => {
        it("Should mint cards for native tokens", async () => {
          let startBalance = await cardNFT.balanceOf(ownerAcc.address);
          await minter.setAllowedAmountOfItemsPerRandomMint(10, true);
          await minter.setMinterRole(ownerAcc.address, true);
          await minter.mintRandom(5, zeroAddress, { value: parseEther("1") });
          let endBalance = await cardNFT.balanceOf(ownerAcc.address);
          expect(endBalance.sub(startBalance)).to.equal(5);
        });

        it("Should fail to mint cards for native tokens if not enough tokens were sent", async () => {
          await minter.setAllowedAmountOfItemsPerRandomMint(10, true);
          await minter.setMinterRole(ownerAcc.address, true);
          // Default price is 0.1
          await expect(
            minter.mintRandom(5, zeroAddress, {
              value: parseEther("0.000000000001"),
            })
          ).to.be.revertedWith(
            "CardRandomMinter: not enough native tokens were provided to pay for mint!"
          );
        });

        it("Should fail to mint cards for native tokens if card number is zero", async () => {
          await minter.setAllowedAmountOfItemsPerRandomMint(10, true);
          await minter.setMinterRole(ownerAcc.address, true);
          await expect(
            minter.mintRandom(0, zeroAddress, { value: parseEther("1") })
          ).to.be.revertedWith("CardRandomMinter: can not mint zero cards!");
        });

        it("Should fail to mint cards for native tokens if token is not supported", async () => {
          await minter.setAllowedAmountOfItemsPerRandomMint(10, true);
          await minter.setMinterRole(ownerAcc.address, true);
          await expect(
            minter.mintRandom(5, randomAddress, { value: parseEther("1") })
          ).to.be.revertedWith("CardRandomMinter: token is not supported!");
        });

        it("Should fail to mint cards for native tokens if amount was not allowed", async () => {
          // Allow 10 cards
          await minter.setAllowedAmountOfItemsPerRandomMint(10, true);
          await minter.setMinterRole(ownerAcc.address, true);
          // Try to mint 8 cards
          await expect(
            minter.mintRandom(8, zeroAddress, { value: parseEther("1") })
          ).to.be.revertedWith(
            "CardRandomMinter: this exact amount of tokens is not allowed to be minted!"
          );
        });
      });

      describe("For ERC20 Tokens", () => {
        it("Should mint cards for ERC20 tokens", async () => {
          let startBalance = await cardNFT.balanceOf(ownerAcc.address);
          await minter.setAllowedAmountOfItemsPerRandomMint(10, true);
          await minter.setMinterRole(ownerAcc.address, true);
          await minter.connect(ownerAcc).mintRandom(5, token.address);
          let endBalance = await cardNFT.balanceOf(ownerAcc.address);
          expect(endBalance.sub(startBalance)).to.equal(5);
        });

        it("Should fail to mint cards for ERC20 tokens if caller does not have enough ERC20 tokens", async () => {
          await minter.setAllowedAmountOfItemsPerRandomMint(10, true);
          await minter.setMinterRole(clientAcc2.address, true);
          await expect(
            minter.connect(clientAcc2).mintRandom(5, token.address)
          ).to.be.revertedWith(
            "CardRandomMinter: not enough ERC20 tokens to pay for the mint!"
          );
        });

        it("Should fail to mint cards for ERC20 tokens if card number is zero", async () => {
          await minter.setAllowedAmountOfItemsPerRandomMint(10, true);
          await minter.setMinterRole(ownerAcc.address, true);
          await expect(minter.mintRandom(0, token.address)).to.be.revertedWith(
            "CardRandomMinter: can not mint zero cards!"
          );
        });

        it("Should fail to mint cards for ERC20 tokens if token is not supported", async () => {
          await minter.setAllowedAmountOfItemsPerRandomMint(10, true);
          await minter.setMinterRole(ownerAcc.address, true);
          await expect(minter.mintRandom(5, randomAddress)).to.be.revertedWith(
            "CardRandomMinter: token is not supported!"
          );
        });

        it("Should fail to mint cards for ERC20 tokens if mint price was not set", async () => {
          // Deploy a new token and add it to supported
          // But do not set a mint price for it
          let newToken = await ethers.getContractFactory("Rummy");
          let dummy = await newToken.deploy();
          await minter.addSupportedToken(dummy.address);
          await minter.setAllowedAmountOfItemsPerRandomMint(10, true);
          await minter.setMinterRole(ownerAcc.address, true);
          await expect(minter.mintRandom(5, dummy.address)).to.be.revertedWith(
            "CardRandomMinter: mint price was not set for this token!"
          );
        });
      });
    });
  });

  if (network.name == "localhost") {
    describe("Get Revenue", () => {
      it("Should withdraw all native tokens revenue from the contract", async () => {
        await minter.setAllowedAmountOfItemsPerRandomMint(15, true);
        await minter.setMinterRole(ownerAcc.address, true);
        // First mint some tokens to pay for the mint
        // 2 native tokens go to the minter
        await minter.mintRandom(15, zeroAddress, { value: parseEther("2") });
        let startBalance = await provider.getBalance(ownerAcc.address);
        // Now get the revenue
        // 2 native tokens should go to the owner
        await minter.connect(ownerAcc).getRevenue(zeroAddress);
        let endBalance = await provider.getBalance(ownerAcc.address);
        // `lt` because some of tokens are spent for gas
        expect(endBalance.sub(startBalance)).to.be.lt(parseEther("2"));
      });

      it("Should withdraw ERC20 token revenue from the contract", async () => {
        await minter.setAllowedAmountOfItemsPerRandomMint(15, true);
        await minter.setMinterRole(ownerAcc.address, true);
        // First mint some tokens to pay for the mint
        // 15 * 0.1 = 1.5 ERC20
        await minter.connect(ownerAcc).mintRandom(15, token.address);
        let startBalance = await token.balanceOf(ownerAcc.address);
        // Now get the revenue
        await minter.connect(ownerAcc).getRevenue(token.address);
        let endBalance = await token.balanceOf(ownerAcc.address);
        expect(endBalance.sub(startBalance)).to.equal(parseEther("1.5"));
      });

      it("Should withdraw no revenue if no cards were minted", async () => {
        let startBalance = await token.balanceOf(ownerAcc.address);
        await minter.connect(ownerAcc).getRevenue(token.address);
        let endBalance = await token.balanceOf(ownerAcc.address);
        // Balance should stay the same
        expect(endBalance).to.equal(startBalance);
      });
    });
  }
});
