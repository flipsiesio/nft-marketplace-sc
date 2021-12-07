const { constants, time, ether } = require('@openzeppelin/test-helpers');
const { ZERO_ADDRESS } = constants;
const { expect } = require("chai");
const { ethers } = require("hardhat");

const setupMockNFTAndNFTSale = deployments.createFixture(async ({deployments, getNamedAccounts, ethers}, options) => {
  await deployments.fixture("main", {fallbackToGlobal: false}); // ensure you start from a fresh deployments
  const { deployer } = await getNamedAccounts();
  const mockNFT = await ethers.getContract("MockNFT");
  const nftSale = await ethers.getContract("NFTSale");
  return [
    deployer,
    mockNFT,
    nftSale
  ];
});

describe("NFTSale", function () {

  let deployer;
  let mockNFT;
  let nftSale;

  let currentId = 0;
  const price = ethers.BigNumber.from(ether('1').toString());
  const duration = ethers.BigNumber.from(time.duration.days(2).toString());

  const addSellOrder = async (to) => {
      await mockNFT.mint(to, currentId++);
      const tokenId = currentId - 1;
      await mockNFT.approve(nftSale.address, tokenId, { from: to });
      await nftSale.acceptTokenToSell(tokenId, price, duration, { from: to });
  }

  beforeEach(async () => {
    [ deployer, mockNFT, nftSale ] = await setupMockNFTAndNFTSale();
  });

  it("should be configured properly", async () => {
    expect(await nftSale.nftOnSale()).to.be.equal(mockNFT.address);
    expect(await nftSale.feeReceiver()).to.be.equal(deployer);
    expect(await nftSale.minExpirationDuration()).to.be.equal(ethers.BigNumber.from(time.duration.days(1).toString()));
    expect(await nftSale.maxExpirationDuration()).to.be.equal(ethers.BigNumber.from(time.duration.days(10).toString()));
    expect(await nftSale.feeInBps()).to.be.equal(9500);
  });

  it("should get sell orders amount", async () => {
    await addSellOrder(deployer);
    expect(await nftSale.getSellOrdersAmount()).to.be.equal(1);
  });

  it("should get sell order token id", async () => {
    await addSellOrder(deployer);
    expect(await nftSale.getSellOrderTokenId(0)).to.be.equal(currentId - 1);
    await expect(nftSale.getSellOrderTokenId(1)).to.be.revertedWith("invalidIndex");
  });

  it("should get sell order seller", async () => {
    await addSellOrder(deployer);
    expect(await nftSale.getSellOrderSeller(0)).to.be.equal(deployer);
  });

  it("should get sell order expiration time", async () => {
    const latestTime = ethers.BigNumber.from((await time.latest()).toString());
    // const expectedExpirationTime = latestTime.add(duration).toNumber();
    await addSellOrder(deployer);
    const actualExpirationTime = (await nftSale.getSellOrderExpirationTime(0));

    console.log(latestTime.toString());
    console.log(actualExpirationTime.toString());
    console.log(actualExpirationTime.sub(latestTime).toString());
    console.log(duration.toString());
    // const expectedDifference = 500;
    // const actualDifference = Math.abs(actualExpirationTime - expectedExpirationTime);
    // expect(actualDifference < expectedDifference).to.be.true;
  });

  it("should get sell order price", async () => {
    await addSellOrder(deployer);
    expect(await nftSale.getSellOrderPrice(0)).to.be.equal(price);
  });

  it("should get sell order fees paid", async () => {
    await addSellOrder(deployer);
    expect(await nftSale.getSellOrderFeesPaid(0)).to.be.equal(0);
  });

  it("should get sell order status", async () => {
    await addSellOrder(deployer);
    expect(await nftSale.getSellOrderStatus(0)).to.be.equal(0);
  });

  it("should get back token from sale", async () => {
    await addSellOrder(deployer);

    await expect(nftSale.getBackFromSale(0)).to
      .emit(nftSale, "OrderRejected")
      .withArgs(0);

    expect(await mockNFT.balanceOf(deployer)).to.be.equal(1);
    expect(await nftSale.getSellOrderStatus(0)).to.be.equal(2);

    const tokenId = currentId - 1;
    await mockNFT.approve(nftSale.address, tokenId, { from: deployer });
    await nftSale.acceptTokenToSell(tokenId, price, duration, { from: deployer });
    await time.increase(time.duration.days(10));
    await nftSale.getBackFromSale(1);
    expect(await nftSale.getSellOrderStatus(1)).to.be.equal(3);

  });

  it("should accept token to sell", async () => {

  });

  it("should set price on sell order", async () => {

  });

  it("should set expiration time for sell order", async () => {

  });

  it("should perform price", async () => {

  });
});
