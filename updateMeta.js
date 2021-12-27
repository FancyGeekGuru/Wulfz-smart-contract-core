//https://testnets-api.opensea.io/api/v1/asset/0x375df763cd7b87e3ffb8efad812aae088553664c/1/?force_update=true
const axios = require("axios")

let url =
	"https://testnets-api.opensea.io/api/v1/asset/0xA93546bF9fBf351a16AE25c3d8907DbAeaCA9C0e/"
let tokenId = 1
let end = 58
setInterval(async () => {
	if (tokenId > end) return
	try {
		await axios.get(url + tokenId + "/?force_update=true")
	} catch (error) {
		console.log(error)
		return
	}

	console.log(tokenId)
	tokenId++
}, 4000)
