const { expect } = require("chai");
const { ethers } = require("hardhat");

function findOrder(events, tokenID) {
  for (let event of events) {
    if (event.args.tokenId == tokenID) {
      return event.args.orderIndex;
    }
  }
}

describe("Sale", () => {
  let accounts;
  let token;
  let sale;
  let n = 0;

  beforeEach(async () => {
    accounts = await ethers.getSigners();
    const tokenFactory = await ethers.getContractFactory("Card");
    token = await tokenFactory.deploy();
    const saleFactory = await ethers.getContractFactory("NFTSale");
    sale = await saleFactory.deploy(
      token.address,
      accounts[0].address,
      100,
      1000,
      3000
    );
  });

  it("Should Set Fee Receiver", async () => {
    expect(await sale.feeReceiver()).to.be.equal(accounts[0].address);
  });

  it("Should Mint a Token", async () => {
    await token.mint(accounts[1].address, n);
    expect(await token.ownerOf(n)).to.be.equal(accounts[1].address);
  });

  it("Should Sell Token", async () => {
    const price = 1000000000000000;
    const fee = (price * (await sale.feeInBps())) / (await sale.MAX_FEE());

    await token.mint(accounts[1].address, n);
    await token.connect(accounts[1]).approve(sale.address, n);
    await sale.connect(accounts[1]).acceptTokenToSell(n, price, 500);
    const order = findOrder(await sale.queryFilter("OrderCreated"), n);
    expect(await sale.getSellOrderStatus(order)).to.be.equal(0);

    await sale.connect(accounts[2]).buy(order, { value: price + fee });

    expect(await token.ownerOf(n)).to.be.equal(accounts[2].address);
    expect(await sale.getSellOrderStatus(order)).to.be.equal(1);
  });

  it("Should Cancel Order", async () => {
    const price = 1000000000000000;

    await token.mint(accounts[3].address, n);
    await token.connect(accounts[3]).approve(sale.address, n);
    await sale.connect(accounts[3]).acceptTokenToSell(n, price, 500);
    const order = findOrder(await sale.queryFilter("OrderCreated"), n);
    expect(await sale.getSellOrderStatus(order)).to.be.equal(0);

    await sale.connect(accounts[3]).getBackFromSale(order);

    expect(await token.ownerOf(n)).to.be.equal(accounts[3].address);
    expect(await sale.getSellOrderStatus(order)).to.be.equal(2);
  });

  afterEach(() => {
    n++;
  });
});
