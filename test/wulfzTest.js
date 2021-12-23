const WulfzNFT = artifacts.require("./WulfzNFT")
// const Awoo = artifacts.require("UtilityToken")
const time = require("./timeTravel")

const { assert } = require("chai")

require("chai").use(require("chai-as-promised")).should()

contract("WulfzNFT", (accounts) => {
	let contract
	let arr = []
	// const SECONDS_IN_A_DAY = 86000

	before(async () => {
		contract = await WulfzNFT.deployed("Wulfz", "WULFZ")
	})

	describe("deployment", async () => {
		it("deploys successfully", async () => {
			const address = contract.address
			assert.notEqual(address, 0x0)
			assert.notEqual(address, "")
			assert.notEqual(address, null)
			assert.notEqual(address, undefined)
		})
	})

	describe("Minting", async () => {
		it("mint token during Private Sale", async () => {
			// Increase time 7 days
			// await time.increase(time.duration.days(6))

			let hexProof = [
				"0xf08efde51accc5349d06e5ca87f18d6ffbffd4f07f7f11510a97eed1b4ab0b6d",
				"0x378b2260ab9debc248bf2d692b5c9eadc7893e73bc489c1c84ac42fe077be88c",
				"0x641b1044852acf2baebd83fd0b5860c5301963a6c8b09c1fc34dc71f365e6df8",
				"0xfa5ac9ed4103e49efc6a080a5fca8b29526db2f533bcd93ea3237e2c5635f544",
				"0x4f1ba9d867ebfba0e05e97231ea7c516b67ead333726137a4ba67215eab12a14",
				"0xde9d1a496c007cba4ea85522be4bee233128eee84ed0296225fd55122cac96df",
			]

			const result = await contract.Presale(hexProof, {
				value: 80000000000000000,
			})

			const event = result.logs[0].args
			console.log(event)
			// assert.equal(event.tokenId, 4, "id is not correct")
			// // arr.push(event.id)
			// assert.equal(
			// 	event.from,
			// 	"0x0000000000000000000000000000000000000000",
			// 	"from is not correct"
			// )
			// assert.equal(event.to, accounts[0], "to is not correct")

			// FAILURE: cannot mint same hash twice
			// await contract.mintWulfz(2, {
			// 	value: 160000000000000000,
			// }).should.be.rejected
		})

		xit("mint token during Public Sale", async () => {
			// Increase time 7 days
			// await time.increase(time.duration.days(1))

			await contract.mintWulfz(2, {
				from: accounts[0],
				value: 160000000000000000,
			}).should.be.rejected

			const result = await contract.mintWulfz(2, {
				from: accounts[1],
				value: 80000000000000000,
			})

			const event = result.logs[0].args
			assert.equal(event.tokenId, 1, "id is not correct")
			// arr.push(event.id)
			assert.equal(
				event.from,
				"0x0000000000000000000000000000000000000000",
				"from is not correct"
			)
			assert.equal(event.to, accounts[0], "to is not correct")

			// FAILURE: cannot mint same hash twice
			await contract.mintWulfz(2, {
				value: 80000000000000000,
			}).should.be.rejected
		})
	})

	describe("indexing", async () => {
		xit("lists hashes", async () => {
			// Mint 3 more NFT tokens
			let back
			back = await contract.mint("5386E4EABC345", "uri1")
			arr.push(back.logs[0].args.id)
			back = await contract.mint("FFF567EAB5FFF", "uri2")
			arr.push(back.logs[0].args.id)
			back = await contract.mint("234AEC00EFFD0", "uri3")
			arr.push(back.logs[0].args.id)

			//check number of minted NFTs
			const qeyCount = await contract.getQeyCount()
			assert.equal(qeyCount, 4)

			let hash
			let result = []
			//check indexing and hashes of minted NFTs
			for (var i = 1; i <= qeyCount; i++) {
				hash = await contract.hashes(arr[i - 1])
				result.push(hash)
			}

			let expected = [
				"ECEA058EF4523",
				"5386E4EABC345",
				"FFF567EAB5FFF",
				"234AEC00EFFD0",
			]
			assert.equal(result.join(","), expected.join(","))
		})
	})

	describe("URIs", async () => {
		xit("retrieves URIs", async () => {
			let result1 = await contract.uri(arr[1])
			assert.equal(result1, "uri1")
			let result2 = await contract.uri(arr[2])
			assert.equal(result2, "uri2")
		})
		xit("change URI", async () => {
			await contract.setTokenUri(1, "test1")
			let result3 = await contract.uri(1)
			assert.equal(result3, "test1")
		})
		//only owner of smart contract is able to change the uri of NFT
		xit("change URI onlyOwner", async () => {
			await contract.setTokenUri(2, "test2", { from: accounts[1] }).should
				.be.rejected
		})
	})

	describe("transfering", async () => {
		xit("transferring NFT", async () => {
			let result = await contract.safeTransferFrom(
				accounts[0],
				accounts[2],
				arr[0],
				1,
				"0x0"
			)
			const event = result.logs[0].args
			assert.equal(event.to, accounts[2])
		})
	})

	//describe('selling', async () => {
	//  it('selling NFT with provision', async () => {
	//
	//    let result = await contract.safeTransferFromWithProvision(accounts[0], accounts[2], 1, 1, web3.utils.toWei('100', 'Ether'))
	//    const event = result.logs[0].args
	//    assert.equal(event.to, accounts[3])
	//  })
	//})

	describe("publish", async () => {
		xit("public sale", async () => {
			// FAILURE: non whitelist member cannot mint
			await contract.mint("ECEA058EF4524", "uri4", { from: accounts[1] })
				.should.be.rejected

			await contract.publish()
			// SUCCESS: now anybody can mint
			let back = await contract.mint("ECEA058EF4524", "uri4", {
				from: accounts[1],
			})
			arr.push(back.logs[0].args.id)
		})
	})

	describe("maximum supply and burning check", async () => {
		xit("check whether burn or not", async () => {
			let count = await contract.getQeyCount()
			while (count < 100) {
				let back = await contract.mint(
					"5386E4EAB" + count,
					"uri" + count
				)
				arr.push(back.logs[0].args.id)
				count = await contract.getQeyCount()
			}
			let balance = await contract.balanceOf(accounts[0], 2532)
			assert.equal(balance, 1)
			let result = await contract.burn("uriG1", 0, 1261, 2523)
			arr.push(result.logs[3].args.id)

			result = await contract.burn("uriG2", 3783)
			arr.push(result.logs[1].args.id)

			result = await contract.burn("uriG3", 1, 1268, 2532)
			arr.push(result.logs[3].args.id)

			balance = await contract.balanceOf(accounts[0], 2532)
			assert.equal(balance, 0)

			// for (let i of arr) {
			//   let j = await contract.tokenTypes(i)
			//   console.log(": Wulfz.test.js ~ line 134 ~ it ~ id ", i.toNumber(), "~~~~", j.toNumber())
			// }
		})
	})
})
