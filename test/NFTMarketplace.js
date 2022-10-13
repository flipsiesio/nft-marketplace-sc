const { expect } = require("chai");
const { BigNumber } = require("ethers");
const { ethers } = require("hardhat");

/**
 * Make sure to:
 * 1) Run local Hardhat node: `npx hardhat node`
 * 2) Deploy tokens to the node: `npx hardhat run scripts/local/1_deployTokensLocal.js --network localhost`
 * Before running tests: `npx hardhat test --network localhost`
 */

function findOrder(events, tokenID) {
  for (let event of events) {
    if (event.args.tokenId == tokenID) {
      return event.args.orderIndex;
    }
  }
}

if (network.name != 'localhost') {
  throw "[ERROR]\nNetwork is not `localhost`! Aborting tests...\nPlease run test with `npx hardhat test --network localhost`";
}

describe("Marketplace", () => {
  let accounts;
  let token;
  let market;
  let n = 0;

  beforeEach(async () => {
    accounts = await ethers.getSigners();
    const tokenFactory = await ethers.getContractFactory("Card");
    token = await tokenFactory.deploy();
    const marketFactory = await ethers.getContractFactory("NFTMarketplace");
    market = await marketFactory.deploy(
      token.address,
      accounts[0].address,
      100,
      1000,
      3000
    );
  });

  it("Should Set Fee Receiver", async () => {
    expect(await market.feeReceiver()).to.be.equal(accounts[0].address);
  });

  it("Should Mint a Token", async () => {
    await token.mint(accounts[1].address, n);
    expect(await token.ownerOf(n)).to.be.equal(accounts[1].address);
  });

  it("Should Sell Token", async () => {
    const price = BigNumber.from(1000000000000000);
    const fee = price.mul(await market.feeInBps()).div(await market.MAX_FEE());

    await token.mint(accounts[1].address, n);
    await token.connect(accounts[1]).approve(market.address, n);
    await market.connect(accounts[1]).acceptTokenToSell(n, price, 500);
    const order = findOrder(await market.queryFilter("OrderCreated"), n);
    expect(await market.getSellOrderStatus(order)).to.be.equal(0);

    await expect(
      market.connect(accounts[2]).bid(order, price, { value: price.add(fee) })
    )
      .to.emit(market, "Bid")
      .withArgs(order, accounts[2].address, price, price);
    await expect(
      market.connect(accounts[2]).bid(order, price, { value: price.add(fee) })
    )
      .to.emit(market, "Bid")
      .withArgs(order, accounts[2].address, price, price.mul(2));
    await expect(
      market
        .connect(accounts[1])
        .performBuyOperation(accounts[2].address, order)
    )
      .to.emit(market, "OrderFilled")
      .withArgs(order, accounts[2].address, price.mul(2));

    expect(await token.ownerOf(n)).to.be.equal(accounts[2].address);
    expect(await market.getSellOrderStatus(order)).to.be.equal(1);
  });

  it("Should Cancel Order", async () => {
    const price = 1000000000000000;

    await token.mint(accounts[3].address, n);
    await token.connect(accounts[3]).approve(market.address, n);
    await market.connect(accounts[3]).acceptTokenToSell(n, price, 500);
    const order = findOrder(await market.queryFilter("OrderCreated"), n);
    expect(await market.getSellOrderStatus(order)).to.be.equal(0);

    await market.connect(accounts[3]).getBackFromSale(order);

    expect(await token.ownerOf(n)).to.be.equal(accounts[3].address);
    expect(await market.getSellOrderStatus(order)).to.be.equal(2);
  });

  it("Should Cancel Bid", async () => {
    const price = 1000000000000000;
    const fee = (price * (await market.feeInBps())) / (await market.MAX_FEE());

    await token.mint(accounts[4].address, n);
    await token.connect(accounts[4]).approve(market.address, n);
    await market.connect(accounts[4]).acceptTokenToSell(n, price, 500);
    const order = findOrder(await market.queryFilter("OrderCreated"), n);
    expect(await market.getSellOrderStatus(order)).to.be.equal(0);

    await market.connect(accounts[5]).bid(order, price, { value: price + fee });
    await expect(
      market.connect(accounts[5]).cancelBid(order)
    ).to.be.revertedWith("NFTMarketplace: Order Is Active!");

    await network.provider.send("evm_increaseTime", [60 * 60 * 24 * 14]);
    await market.connect(accounts[5]).cancelBid(order);

    await expect(
      market.connect(accounts[5]).cancelBid(order)
    ).to.be.revertedWith("NFTMarketplace: Nothing To Cancel And Return!");
  });

  afterEach(() => {
    n++;
  });
});
