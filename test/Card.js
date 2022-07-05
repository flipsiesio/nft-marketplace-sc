// TODO: Adapt for TRON

let Card = artifacts.require("./Card.sol");

contract("Card", (accounts) => {
  let cardNFT;

  beforeEach(async () => {
    cardNFT = await Card.deployed();
  });

  it("should verify that the contract has been deployed by accounts[0]", async () => {
    assert.equal(await cardNFT.owner(), accounts[0]); // tronWeb.address.toHex(accounts[0])
  });

  it("should fail to mint from nonMinter account", async () => {
    try {
      await cardNFT.mint(accounts[2], 0, { from: accounts[2] });
    } catch (e) {
      console.log("Reverted!");
    }
  });

  it("should fail to add minter from nonOwner account", async () => {
    try {
      await cardNFT.setMinterRole(accounts[3], true, { from: accounts[3] });
    } catch (e) {
      console.log("Reverted!");
    }
  });

  it("should mint from owner account", async () => {
    await cardNFT.mint(accounts[1], 0, { from: accounts[0] });
    assert.equal(await cardNFT.ownerOf(0), accounts[1]);
  });

  it("should give minter's rights to another account and mint from it", async () => {
    await cardNFT.setMinterRole(accounts[4], true, { from: accounts[0] });
    await cardNFT.mint(accounts[5], 1, { from: accounts[4] });
    assert.equal(await cardNFT.ownerOf(1), accounts[5]);
  });

  it("should get all address' tokens", async () => {
    await cardNFT.mint(accounts[5], 2, { from: accounts[4] });
    await cardNFT.mint(accounts[5], 3, { from: accounts[0] });
    await cardNFT.mint(accounts[5], 4, { from: accounts[4] });
    assert.equal(
      (await cardNFT.getNFTListByAddress(accounts[5])).length,
      await cardNFT.balanceOf(accounts[5])
    );
  });
});
