const {
	expectRevert,
	time,
	ether,
	expectEvent,
} = require("@openzeppelin/test-helpers")

const WulfzNFT = artifacts.require("./WulfzNFT")
const StakingPool = artifacts.require("./StakingPool")
const Awoo = artifacts.require("UtilityToken")

const { assert } = require("chai")

require("chai").use(require("chai-as-promised")).should()

contract("WulfzNFT", (accounts) => {
	let contract, stakingPool, utilityToken
	const alice = accounts[0]
	const bob = accounts[1]
	const cat = accounts[2]

	before(async () => {
		contract = await WulfzNFT.deployed()
		stakingPool = await StakingPool.deployed()
		utilityToken = await Awoo.deployed()
	})

	describe("deployment", async () => {
		it("deploys successfully", async () => {
			const address = contract.address
			const poolAddr = stakingPool.address
			const awooAddr = utilityToken.address

			assert.notEqual(address, 0x0)
			assert.notEqual(address, "")
			assert.notEqual(address, null)
			assert.notEqual(address, undefined)

			assert.notEqual(poolAddr, 0x0)
			assert.notEqual(poolAddr, "")
			assert.notEqual(poolAddr, null)
			assert.notEqual(poolAddr, undefined)

			assert.notEqual(awooAddr, 0x0)
			assert.notEqual(awooAddr, "")
			assert.notEqual(awooAddr, null)
			assert.notEqual(awooAddr, undefined)

			let res = await contract.setStakingPool(poolAddr)
			assert(res.logs[0].args.addr, poolAddr, "pool address not matched")

			res = await contract.setUtilitytoken(awooAddr)
			assert(res.logs[0].args.addr, awooAddr, "awoo address not matched")

			res = await stakingPool.setUtilitytoken(awooAddr)
			assert(
				res.logs[0].args.addr,
				awooAddr,
				"awoo address not matched, from Pool"
			)
		})
	})

	describe("PreSale", async () => {
		it("mint token during Private Sale", async () => {
			// Increase time 7 days
			// await time.increase(time.duration.days(6))

			let hexProof = [
				"0x4375e4c5afa2155eb46491b7422fdccffcbf97a1858dd8143bf04f2db3673e52",
				"0x4601f5318179a9c10466d135c0be6857271ff968184b8e37e101ac26d6c229fb",
				"0x919d8549b7b5f1a92e99fb686d6b55335c7ff028e8c91e23b3070bcdf03c9ebd",
				"0x62aab45490c7ccc20e4f9b3d26b486c0c17aad4aceed8b372f57fb1556b58421",
				"0xe9df134f5f7cf04195f09f8d0a42e96bd86b6a209963ec2235d8f21ee5d5b76e",
				"0x520bab349415f38b8bf2bc796a7101a5d722c68b2b362762f72e1c8d9e91f267",
			]

			const result = await contract.Presale(hexProof, {
				from: alice,
				value: 80000000000000000,
			})

			const res1 = result.logs[0].args
			const res2 = result.logs[1].args

			assert.equal(res1.tokenId, 1, "Presale is failed")
			// arr.push(event.id)
			assert.equal(
				res1.from,
				"0x0000000000000000000000000000000000000000",
				"from is not correct"
			)
			assert.equal(res1.to, accounts[0], "TO is not correct")
			assert.equal(res2.user, accounts[0], "USER ADDR is not correct")
			assert.equal(res2.tokenId, 1, "Presale is failed")
			assert.equal(res2.wType, 0, "Wulfz type is not correct")
		})
	})

	describe("PublicSale", async () => {
		it("mint token during Public Sale", async () => {
			let res1 = await contract.PublicSale(2, {
				from: bob,
				value: 160000000000000000,
			})

			res1 = res1.logs[3].args
			assert(res1.user, bob, "user mismatched")
			assert(res1.tokenId, 3, "tokenId mismatched")

			let res2 = await contract.PublicSale(1, {
				from: cat,
				value: 160000000000000000,
			})

			res2 = res2.logs[1].args
			assert(res2.user, cat, "user mismatched")
			assert(res2.tokenId, 4, "tokenId mismatched")

			contract.PublicSale(3, {
				from: alice,
				value: 240000000000000000,
			}).should.be.rejected

			contract.PublicSale(2, {
				from: alice,
				value: 159000000000000000,
			}).should.be.rejected
		})
	})

	describe("Staking", async () => {
		it("Stake Wulfz", async () => {
			contract.startStaking(3, { from: alice }).should.be.rejected

			await contract.startStaking(3, { from: bob })
			await contract.startStaking(2, { from: bob })

			contract.startStaking(3, { from: bob }).should.be.rejected
			contract.startStaking(2, { from: alice }).should.be.rejected

			contract.changeName(3, "asdf", {
				from: bob,
			}).should.be.rejected

			contract.approve(cat, 2, { from: bob }).should.be.rejected
		})
		it("UnStake Wulfz", async () => {
			time.increase(time.duration.days(2))

			contract.stopStaking(2, {
				from: alice,
			}).should.be.rejected

			await contract.stopStaking(2, {
				from: bob,
			})

			// res = await stakingPool.stakedTokensOf(bob)
			// console.log(res)

			// console.log(await utilityToken.balanceOf(bob))
			// console.log(await utilityToken.decimals())
		})
		it("Get Reward", async () => {
			time.increase(time.duration.days(100))
			await stakingPool.getReward(bob)
			// console.log(await utilityToken.balanceOf(bob))

			await contract.stopStaking(2, {
				from: bob,
			}).should.be.rejected

			await contract.stopStaking(3, {
				from: bob,
			})

			time.increase(time.duration.days(100))
			stakingPool.getReward(bob).should.be.rejected
		})
	})
})
