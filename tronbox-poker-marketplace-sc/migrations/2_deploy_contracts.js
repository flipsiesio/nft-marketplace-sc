const MockNFT = artifacts.require("./mock/MockNFT.sol");
const NFTMarketplace = artifacts.require("./NFTMarketplace.sol");
const Card = artifacts.require("./Card.sol");
const CardFactory = artifacts.require("./CardFactory.sol");
const CardRandomMinter = artifacts.require("./CardRandomMinter.sol");
const { time } = require("@openzeppelin/test-helpers");

module.exports = async function (deployer, network, accounts) {
    const feeInBps = 9500;
    const account = "TLHVUe1sizxRUctjpsKj1iRWkhUkdRs8KW";
    await deployer.deploy(Card);
    await deployer.deploy(NFTMarketplace, Card.address, account, time.duration.days(1).toNumber(), time.duration.days(10).toNumber(), feeInBps);
    await deployer.deploy(CardFactory, Card.address);
    await deployer.deploy(CardRandomMinter, CardFactory.address);
}
