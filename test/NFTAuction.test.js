const { expect } = require("chai");
const { ethers } = require("hardhat");

const setupMockNFTAndNFTAuction = deployments.createFixture(async ({deployments, getNamedAccounts, ethers}, options) => {
  await deployments.fixture("main", {fallbackToGlobal: false}); // ensure you start from a fresh deployments
  const { deployer } = await getNamedAccounts();
  const mockNFT = await ethers.getContract("MockNFT");
  const nftAuction = await ethers.getContract("NFTAuction");
  return [
    mockNFT,
    nftAuction
  ];
});

describe("NFTAuction", function () {

  let mockNFT;
  let nftAuction;

  beforeEach(async () => {
    [ mockNFT, nftAuction ] = await setupMockNFTAndNFTAuction();
  });

  it("should be configured properly", async () => {

  });

});
