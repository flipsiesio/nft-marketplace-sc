const hre = require("hardhat");
const ethers = hre.ethers;

const { constants, time } = require('@openzeppelin/test-helpers');
const { ZERO_ADDRESS } = constants;

const {
  skipDeploymentIfAlreadyDeployed,
  withImpersonatedSigner
} = require('./lib/helpers.js');

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

  const feeReceiver = deployer;
  const minExpirationDuration = ethers.BigNumber.from(time.duration.days(1).toString());
  const maxExpirationDuration = ethers.BigNumber.from(time.duration.days(10).toString());
  const feeInBps = 9500;

  const constructorArguments = [
    pokerNFT.address,
    feeReceiver,
    minExpirationDuration,
    maxExpirationDuration,
    feeInBps
  ];

  const nftSale = await deploy("NFTSale", {
      from: deployer,
      args: constructorArguments,
      skipIfAlreadyDeployed: skipDeploymentIfAlreadyDeployed,
      log: true
    }
  );

  const nftAuction = await deploy("NFTAuction", {
      from: deployer,
      args: constructorArguments,
      skipIfAlreadyDeployed: skipDeploymentIfAlreadyDeployed,
      log: true
    }
  );
}
module.exports.tags = ["main"];
module.exports.dependencies = ["deploy_mock"];
module.exports.runAtTheEnd = true;
