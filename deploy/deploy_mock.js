const hre = require("hardhat");
const ethers = hre.ethers;

const { constants } = require('@openzeppelin/test-helpers');
const { ZERO_ADDRESS } = constants;
const { skipDeploymentIfAlreadyDeployed } = require('./lib/helpers.js');

module.exports = async ({
    getNamedAccounts,
    deployments
  }) => {
    const { deploy, save } = deployments;
    const { deployer } = await getNamedAccounts();
    let mockNFT = await deploy('MockNFT', {
      from: deployer,
      log: true,
      skipIfAlreadyDeployed: skipDeploymentIfAlreadyDeployed
    });
    await save('PokerNFT', mockNFT);
}
module.exports.tags = ["deploy_mock"];
