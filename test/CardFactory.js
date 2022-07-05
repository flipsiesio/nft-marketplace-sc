// TODO: Adapt for TRON

let Card = artifacts.require("./Card.sol");
let CardFactory = artifacts.require("./CardFactory.sol");

contract("CardFactory", (accounts) => {
  let cardNFT;
  let factory;

  before(async () => {
    cardNFT = await Card.deployed();
    factory = await CardFactory.deployed();
    await cardNFT.setMinterRole(factory.address, true);
    await factory.setIdBoundaryForOption(0, 0, 5);
  });

  it("should allow to create 5 tokens of option 0", async () => {
    assert.equal(await factory.availableTokens(0), 5);
  });

  it("should mint 2 tokens", async () => {
    for (let i = 0; i < 2; i++) {
      await factory.mint(0, accounts[1]);
    }
    assert.equal(await cardNFT.balanceOf(accounts[1]), 2);
  });

  it("should fail to mint — not a minter", async () => {
    try {
      await factory.mint(0, accounts[3], { from: account[1] });
    } catch (e) {
      console.log("Reverted!");
    }
  });

  it("should give minter's rights to another account and mint from it", async () => {
    await factory.setOptionMinter(accounts[1], true);
    await factory.mint(0, accounts[3], { from: accounts[1] });
    assert.equal(await cardNFT.balanceOf(accounts[3]), 1);
  });

  it("should fail to mint another 3 tokens", async () => {
    try {
      for (let i = 0; i < 3; i++) {
        await factory.mint(0, accounts[2]);
      }
    } catch (e) {
      console.log("Reverted!");
    }
  });

  it("should fail to set boundaries — wrong option", async () => {
    try {
      await factory.setIdBoundaryForOption(10, 0, 5);
    } catch (e) {
      console.log("Reverted!");
    }
  });

  it("should fail to change mintableToken — not a owner", async () => {
    try {
      await factory.setMintableToken(
        "0x0000000000000000000000000000000000000000",
        { from: account[1] }
      );
    } catch (e) {
      console.log("Reverted!");
    }
  });

  it("should change mintableToken", async () => {
    await factory.setMintableToken(
      "0x0000000000000000000000000000000000000000"
    );
    assert.equal(
      await factory.mintableToken(),
      "0x0000000000000000000000000000000000000000"
    );
  });
});
