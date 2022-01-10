const MockNFT = artifacts.require("./mock/MockNFT.sol");
const NFTMarketplace = artifacts.require("./NFTMarketplace.sol");

const Card = artifacts.require("./Card.sol");
const CardFactory = artifacts.require("./CardFactory.sol");
const CardRandomMinter = artifacts.require("./CardRandomMinter.sol");

const { time } = require("@openzeppelin/test-helpers");

module.exports = function (deployer, network, accounts) {
  const feeInBps = 9500;
  deployer.then(() => {
    deployer.deploy(Card).then(nftInstance => {
      deployer.deploy(
        NFTMarketplace,
        nftInstance.address,
        accounts[0],
        time.duration.days(1),
        time.duration.days(10),
        feeInBps
      ).then(nftMarketplaceInstance => {
        deployer.deploy(CardFactory, nftInstance.address).then(nftFactoryInstance => {
          deployer.deploy(CardRandomMinter, nftFactoryInstance.address).then(randomMinter => {
            nftFactoryInstance.setOptionMinter(randomMinter.address, true, { from: accounts[0] })
              .then(setOptionMinterReceipt => {
                console.log(`Set option minter: ${setOptionMinterReceipt}`);
                nftInstance.setMinterRole(nftFactoryInstance.address, true, { from: accounts[0] })
                  .then(setMinterRoleReceipt => {
                    console.log(`Set minter role at NFT: ${setMinterRoleReceipt}`);
                    console.log("=== Addresses and params ===");
                    console.log(
                      nftInstance.address,
                      nftMarketplaceInstance.address,
                      nftFactoryInstance.address,
                      randomMinter.address,
                      accounts[0],
                      time.duration.days(1),
                      time.duration.days(10),
                      feeInBps
                    );
                  });
              });
          });
        });
      });
    });
  });
};
