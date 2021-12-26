const MockNFT = artifacts.require("./mock/MockNFT.sol");
const NFTMarketplace = artifacts.require("./NFTMarketplace.sol");
const { time } = require("@openzeppelin/test-helpers");

module.exports = function (deployer, network, accounts) {
  const feeInBps = 9500;
  deployer.then(() => {
    deployer.deploy(MockNFT).then(mockNftInstance => {
      deployer.deploy(
        NFTMarketplace,
        mockNftInstance.address,
        accounts[0],
        time.duration.days(1),
        time.duration.days(10),
        feeInBps
      ).then(nftMarketplaceInstance => {
        console.log(
          nftMarketplaceInstance.address
          mockNftInstance.address,
          accounts[0],
          time.duration.days(1),
          time.duration.days(10),
          feeInBps
        );
      });
    });
  });
};
