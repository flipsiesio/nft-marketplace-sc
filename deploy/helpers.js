const { ether } = require("@openzeppelin/test-helpers");
const hre = require("hardhat");
const ethers = hre.ethers;

////////////////////////////////////////////
// Constants Starts
////////////////////////////////////////////

const skipDeploymentIfAlreadyDeployed = false;

////////////////////////////////////////////
// Constants Ends
////////////////////////////////////////////

const getMock = async (interface, deploy, deployer, skipDeploymentIfAlreadyDeployed, save, prepareMocks) => {
  let mock = await deploy("MockContract", {
    from: deployer
  });
  await save(interface, mock);
  const result = await hre.ethers.getContractAt(interface, mock.address);
  mock = await hre.ethers.getContractAt("MockContract", mock.address);
  if (prepareMocks) {
    await prepareMocks(mock, result);
  }
  return result;
}

const withImpersonatedSigner = async (signerAddress, action) => {
  await hre.network.provider.request({
    method: "hardhat_impersonateAccount",
    params: [signerAddress],
  });

  await hre.network.provider.send("hardhat_setBalance", [
    signerAddress,
    `0x${ether('10000').toString(16)}`,
  ]);

  const impersonatedSigner = await hre.ethers.getSigner(signerAddress);
  await action(impersonatedSigner);

  await hre.network.provider.request({
    method: "hardhat_stopImpersonatingAccount",
    params: [signerAddress],
  });
}

module.exports = {
  getMock,
  skipDeploymentIfAlreadyDeployed,
  withImpersonatedSigner
};
