const { expect } = require("chai");
const { ethers } = require("hardhat");

const setupMockNFTAndNFTSale = deployments.createFixture(async ({deployments, getNamedAccounts, ethers}, options) => {
  await deployments.fixture(); // ensure you start from a fresh deployments
  const { deployer } = await getNamedAccounts();
  const mockNFT = await ethers.getContract("MockNFT");
  const nftSale = await ethers.getContract("NFTSale");
  return {
    mockNFT,
    nftSale
  };
};

describe("NFTSale", function () {
  it("", async () => {
    const { mockNFT, nftSale } = await setupMockNFTAndNFTSale();

  });
});
