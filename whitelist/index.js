const { MerkleTree } = require("merkletreejs")
const keccak256 = require("keccak256")
const whitelistAddress = require("./whitelist.json")

const leafNodes = whitelistAddress.map((addr) => keccak256(addr))
const tree = new MerkleTree(leafNodes, keccak256, { sortPairs: true })

const root = tree.getHexRoot()
console.log(root)

const claimingAddress = leafNodes[0]
// const claimingAddress = "0x"
const hexProof = tree.getHexProof(claimingAddress)

console.log(hexProof)
