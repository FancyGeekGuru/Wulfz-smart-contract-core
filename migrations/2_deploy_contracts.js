const WulfzNFT = artifacts.require("WulfzNFT")
// const whitelist = require("../whitelist")

module.exports = function (deployer) {
	deployer.deploy(WulfzNFT, "Wulfz", "WULFZ")
}
