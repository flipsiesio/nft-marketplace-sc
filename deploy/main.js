const hre = require("hardhat");
const ethers = hre.ethers;

const { constants } = require('@openzeppelin/test-helpers');
const { ZERO_ADDRESS } = constants;

const {
  getMock,
  skipDeploymentIfAlreadyDeployed,
  withImpersonatedSigner
} = require('./helpers.js');

module.exports = async ({
    getNamedAccounts,
    deployments,
    getChainId,
    getUnnamedAccounts,
    network
  }) => {

  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const pokerNFT = await deployments.get('PokerNFT');

  const nftSaleConstructorArguments = [
    pokerNFT.address
  ];
  const nftSale = await deploy("NFTSale", {
      from: deployer,
      args: nftSaleConstructorArguments,
      skipIfAlreadyDeployed: skipDeploymentIfAlreadyDeployed,
      log: true
    }
  );
}
module.exports.tags = ["main"]
module.exports.runAtTheEnd = true;
