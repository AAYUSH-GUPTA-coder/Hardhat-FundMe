// function deployFunc() {
//     console.log("Hi!");
// }

// module.exports.default = deployFunc

const { network } = require("hardhat")
const { networkConfig, developentChains } = require("../hepler-hardhat-config")
const { verify } = require("../utils/verify")

module.exports = async ({ getNamedAccounts, deployments }) => {
    // hre.getNamedAccounts
    // hre.deployments
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()
    //  we get the deployer(address who will deploy the smart contract) from getNamedAccouts
    //  defined namedAccounts/deployer address in config function
    const chainId = network.config.chainId
    // if chainID is X use address Y
    let ethUsdPriceFeedAddress
    if (chainId == 31337) {
        // getting all MockV3Aggregator contract address along with other info
        const ethUsdAggregator = await deployments.get("MockV3Aggregator")
        // getting and storing MockV3Aggregator address
        ethUsdPriceFeedAddress = ethUsdAggregator.address
    } else {
        ethUsdPriceFeedAddress = networkConfig[chainId]["ethUsdPriceFeed"]
    }

    // if the chainlink ethUsdPriceFeed contract doesn't exist, we deploy a minimal version of contract
    // for our local testing
    const args = [ethUsdPriceFeedAddress]
    // chainID will be used, when we deploy our smart contracts to different chains/localhost/hardhat network
    const fundMe = await deploy("FundMe", {
        from: deployer,
        args: args,
        log: true,
    })
    if (!chainId == 31337 && process.env.ETHERSCAN_API_KEY) {
        await verify(fundMe.address, args)
    }
    log("------------------------------------------------------------")
}

module.exports.tags = ["all", "fundme"]
