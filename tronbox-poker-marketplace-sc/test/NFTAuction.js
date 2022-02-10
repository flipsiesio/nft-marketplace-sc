const { expect } = require("chai");
const { ethers } = require("hardhat");

function findOrder(events, tokenID) {
  for (let event of events) {
    if (event.args.tokenId == tokenID) {
      return event.args._at;
    }
  }
}

describe("Auction", () => {
  let accounts;
  let token;
  let auction;
  let n = 0;

  beforeEach(async () => {
    accounts = await ethers.getSigners();
    const tokenFactory = await ethers.getContractFactory("Card");
    token = await tokenFactory.deploy();
    const auctionFactory = await ethers.getContractFactory("NFTAuction");
    auction = await auctionFactory.deploy(token.address, accounts[0].address, 100, 1000, 3000);
    
  });

  it('should set fee receiver', async () => {
    expect(await auction.feeReceiver()).to.be.equal(accounts[0].address);
  });

  it('should mint a token', async () => {
    await token.mint(accounts[1].address, n);
    expect(await token.ownerOf(n)).to.be.equal(accounts[1].address);
  });

  it('should sell token', async () => {
    const price = 1000000000000000;
    const fee = async (p) => {
      return Math.floor(p * (await auction.feeInBps()) / (await auction.MAX_FEE()));
    }

    await token.mint(accounts[1].address, n);
    await token.connect(accounts[1]).approve(auction.address, n);
    await auction.connect(accounts[1]).createAuction(n, 500, price);
    const order = findOrder(await auction.queryFilter("AuctionCreated"), n);
    expect(await auction.getStatusOfAuction(order)).to.be.equal(0);
    
    await auction.connect(accounts[2]).bid(order, price + 1);
    await auction.connect(accounts[4]).bid(order, price + 2);

    let f = await fee(price + 2);
    let v = price + 2 + f;

    await expect(auction.connect(accounts[2]).take(order, {value: v})).to.be.revertedWith("auctionIsActive");

    await network.provider.send("evm_increaseTime", [500]);
    await expect(auction.connect(accounts[2]).take(order, {value: v})).to.be.revertedWith("senderMustBeBuyerWhoWon");
    
    await auction.connect(accounts[4]).take(order, {value: v});

    expect(await token.ownerOf(n)).to.be.equal(accounts[4].address);
    expect(await auction.getStatusOfAuction(order)).to.be.equal(1);
  });

  it('should cancel auction', async () => {
    const price = 1000000000000000;

    await token.mint(accounts[3].address, n);
    await token.connect(accounts[3]).approve(auction.address, n);
    await auction.connect(accounts[3]).createAuction(n, 500, price);
    const order = findOrder(await auction.queryFilter("AuctionCreated"), n);
    expect(await auction.getStatusOfAuction(order)).to.be.equal(0);

    await auction.connect(accounts[3]).cancelAuction(order);

    expect(await token.ownerOf(n)).to.be.equal(accounts[3].address);
    expect(await auction.getStatusOfAuction(order)).to.be.equal(2);
  });

  afterEach(() => {
    n++;
  });
});
