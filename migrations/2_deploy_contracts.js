const WulfzNFT = artifacts.require("WulfzNFT")
const StakingPool = artifacts.require("./StakingPool")
const AWOO = artifacts.require("./UtilityToken")
// const whitelist = require("../whitelist")

module.exports = async (deployer) => {
	await deployer.deploy(WulfzNFT, "Wulfz", "WULFZ")
	const WulfzContract = await WulfzNFT.deployed()

	await deployer.deploy(StakingPool, WulfzContract.address)
	const StakingContract = await StakingPool.deployed()
	await WulfzContract.setStakingPool(StakingContract.address)

	await deployer.deploy(AWOO, WulfzContract.address, StakingContract.address)
	const AwooContract = await AWOO.deployed()
	await WulfzContract.setUtilitytoken(AwooContract.address)
}
