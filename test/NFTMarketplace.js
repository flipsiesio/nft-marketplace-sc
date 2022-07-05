const { expect } = require("chai");
const { BigNumber } = require("ethers");
const { ethers } = require("hardhat");

function findOrder(events, tokenID) {
  for (let event of events) {
    if (event.args.tokenId == tokenID) {
      return event.args.orderIndex;
    }
  }
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

  it("should set fee receiver", async () => {
    expect(await market.feeReceiver()).to.be.equal(accounts[0].address);
  });

  it("should mint a token", async () => {
    await token.mint(accounts[1].address, n);
    expect(await token.ownerOf(n)).to.be.equal(accounts[1].address);
  });

  it("should sell token", async () => {
    const price = BigNumber.from(1000000000000000);
    const fee = price.mul(await market.feeInBps()).div(await market.MAX_FEE());

    await token.mint(accounts[1].address, n);
    await token.connect(accounts[1]).approve(market.address, n);
    await market.connect(accounts[1]).acceptTokenToSell(n, price, 500);
    const order = findOrder(await market.queryFilter("OrderCreated"), n);
    expect(await market.getSellOrderStatus(order)).to.be.equal(0);

    await market
      .connect(accounts[2])
      .bid(order, price, { value: price.add(fee) });
    await market
      .connect(accounts[2])
      .bid(order, price, { value: price.add(fee) });
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

  it("should cancel order", async () => {
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

  it("should cancel bid", async () => {
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
    ).to.be.revertedWith("orderIsActive");

    await network.provider.send("evm_increaseTime", [60 * 60 * 24 * 14]);
    await market.connect(accounts[5]).cancelBid(order);

    await expect(
      market.connect(accounts[5]).cancelBid(order)
    ).to.be.revertedWith("nothingToCancelAndReturn");
  });

  afterEach(() => {
    n++;
  });
});
