const NFTMarketplace = artifacts.require("./NFTMarketplace.sol");
const NFTSale = artifacts.require("./NFTSale.sol");
const Card = artifacts.require("./Card.sol");
const CardFactory = artifacts.require("./CardFactory.sol");
const CardRandomMinter = artifacts.require("./CardRandomMinter.sol");
const { time } = require("@openzeppelin/test-helpers");

module.exports = async function (deployer, network, accounts) {
    const feeInBps = 9500;
    const account = "TLHVUe1sizxRUctjpsKj1iRWkhUkdRs8KW";
    await deployer.deploy(Card);
    await deployer.deploy(NFTMarketplace, Card.address, account, time.duration.days(1).toNumber(), time.duration.days(10).toNumber(), feeInBps);
    await deployer.deploy(NFTSale, Card.address, account, time.duration.days(1).toNumber(), time.duration.days(10).toNumber(), feeInBps);
    await deployer.deploy(CardFactory, Card.address);
    await deployer.deploy(CardRandomMinter, CardFactory.address);

    let card = await Card.deployed();
    let factory = await CardFactory.deployed();

    await card.setMinterRole(CardFactory.address, true);
    await factory.setMinterRole(CardRandomMinter.address, true);

    await factory.setIdBoundaryForOption(0, 0, 6500);
    await factory.setIdBoundaryForOption(1, 6500, 7271);
    await factory.setIdBoundaryForOption(2, 7271, 7771);
    await factory.setIdBoundaryForOption(3, 7771, 7796);
    await factory.setIdBoundaryForOption(4, 7796, 7803);
}
