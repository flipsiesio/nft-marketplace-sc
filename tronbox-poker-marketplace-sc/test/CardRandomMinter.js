// TODO: Adapt for TRON

const Card = artifacts.require("./Card.sol");
const CardFactory = artifacts.require("./CardFactory.sol");
const CardRandomMinter = artifacts.require("./CardRandomMinter.sol");

contract('CardRandomMinter', (accounts) => {
  let cardNFT;
  let factory;
  let minter;

  before(async () => {
    cardNFT = await Card.deployed();
    factory = await CardFactory.deployed();
    minter = await CardRandomMinter.deployed();
    await cardNFT.setMinterRole(factory.address, true);
    await factory.setOptionMinter(minter.address, true);

    // Allow to mint some tokens
    await factory.setIdBoundaryForOption(0, 0, 15);
    await factory.setIdBoundaryForOption(1, 15, 30);
    await factory.setIdBoundaryForOption(2, 30, 45);
    await factory.setIdBoundaryForOption(3, 45, 60);
    await factory.setIdBoundaryForOption(4, 60, 75);
  });

  it('should give minting rights to admin and mint 3 nft to another account', async () => {
    await minter.setMinter(accounts[0], true);
    await minter.mintRandomFree(3, accounts[1]);
    assert.equal(await cardNFT.balanceOf(accounts[1]), 3);
  });

  it('should set price', async () => {
    await minter.setPrice("1500");
    assert.equal(await minter.price(), 1500);
  })

  it('should sell 3 tokens', async () => {
    let result = await minter.mintRandom(3, {from: accounts[2], value: 4500});
    assert.equal(await cardNFT.balanceOf(accounts[2]), 3);
  });

  it('shouldn\'t sell 3 tokens', async () => {
    try {
      await minter.mintRandom(3, {from: accounts[3], value: 4499});
    } catch (e) {
      console.log("Reverted!");
    }
  });
})