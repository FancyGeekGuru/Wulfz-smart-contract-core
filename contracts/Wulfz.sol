// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "./interface/IWulfz.sol";
import "./Profile.sol";
import "./Awoo.sol";
import "./StakingPool.sol";

contract WulfzNFT is IWulfzNFT, Profile, Ownable {
    enum WulfzType {
        Genesis,
        Pupz,
        Alpha
    }

    struct WulfzInfo {
        WulfzType wType;
        bool bStaked;
        uint256 lastBreedTime;
    }

    event WulfzMinted(
        address indexed user,
        uint256 indexed tokenId,
        uint256 indexed wType
    );

    uint256 public constant MINT_PRICE = 80000000000000000; // 0.08 ETH
    uint256 public constant BREED_PRICE = 600;
    uint256 public constant EVOLVE_PRICE = 1500;
    uint256[] private COOLDOWN_TIME_FOR_BREED = [14 days, 0, 7 days];

    uint256[] private MAX_SUPPLY_BY_TYPE = [5555, 10000, 100];
    uint256[] private START_ID_BY_TYPE = [0, 6000, 5600];
    uint256[] public totalSupplyByType = [0, 0, 0];

    uint256 private _startTimeOfPrivateSale;
    uint256 private _startTimeOfPublicSale;
    uint256 private _startTimeOfStaking;
    uint256 private _startTimeOfAdopt;
    uint256 private _startTimeOfEvolve;

    mapping(uint256 => WulfzInfo) public wulfz;

    mapping(address => bool) private claimInPresale; // whitelist address => bool
    mapping(address => uint256) private claimInPublicSale; // userAddress => uint256

    string public _baseTokenURI =
        "https://ipfs.io/ipfs/QmerhyiggKaU6GMgLyVxi9sw7BcBGYzthgFs5zVAH5w9xQ/";

    UtilityToken private _utilityToken; // AWOO utility token contract
    StakingPool private _pool;

    constructor(string memory _name, string memory _symbol)
        Profile(_name, _symbol)
    {
        _startTimeOfPrivateSale = 1640624400; // Mon Dec 27 2021 12:00:00 GMT-0500 (Eastern Standard Time)
        _startTimeOfPublicSale = 1640710800; // Tue Dec 28 2021 12:00:00 GMT-0500 (Eastern Standard Time)
        _startTimeOfStaking = 1641574800; // Fri Jan 07 2022 12:00:00 GMT-0500 (Eastern Standard Time)
        _startTimeOfAdopt = 1646110800; // Tue Mar 01 2022 00:00:00 GMT-0500 (Eastern Standard Time)
        _startTimeOfEvolve = 1654056000; // Wed Jun 01 2022 00:00:00 GMT-0400 (Eastern Daylight Time)

        // first 55 tokens
        // for (uint256 i = 0; i < 55; i++) {
        //     mintOne(WulfzType.Genesis);
        // }
    }

    /**
     * @dev return the Base URI of the token
     */

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev set the _baseTokenURI
     * @param _newURI of the _baseTokenURI
     */

    function setBaseURI(string calldata _newURI) external onlyOwner {
        _baseTokenURI = _newURI;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Balance is zero");
        payable(msg.sender).transfer(balance);
    }

    function getWulfzType(uint256 _tokenId) public view returns (uint256) {
        return uint256(wulfz[_tokenId].wType);
    }

    /**
     * @dev Mint the _amount of tokens, Only whitelisters can mint
     */
    function Presale(bytes32[] calldata _proof) external payable {
        require(msg.value >= MINT_PRICE, "Minting Price is not enough");
        // require(
        //     block.timestamp > _startTimeOfPrivateSale,
        //     "Private Sale is not started yet"
        // );
        // require(
        //     block.timestamp < _startTimeOfPrivateSale + 86400,
        //     "Private Sale is already ended"
        // );

        require(
            !claimInPresale[msg.sender],
            "You've already mint token. If you want more, you can mint during Public Sale"
        );

        bytes32 merkleTreeRoot = 0xc8f014712fe82fef4018b76d7a839027b82b25fd876b3a2a22e4070ecfc2833f;
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_proof, merkleTreeRoot, leaf),
            "Sorry, you're not whitelisted. Please try Public Sale"
        );

        mintOne(WulfzType.Genesis);
        claimInPresale[msg.sender] = true;
    }

    /**
     * @dev Mint the _amount of tokens
     * @param _amount is the token counts which will be minted
     */
    function PublicSale(uint256 _amount) external payable {
        require(
            msg.value >= MINT_PRICE * _amount,
            "Minting Price is not enough"
        );
        // require(
        //     block.timestamp > _startTimeOfPublicSale,
        //     "Public Sale is not started yet"
        // );
        // require(
        //     block.timestamp < _startTimeOfPublicSale + 86400,
        //     "Public Sale is already ended"
        // );
        require(_amount < 3, "You can only require at most 2");
        require(
            claimInPublicSale[msg.sender] < 3,
            "You can only possess at most 2"
        );

        for (uint256 i = 0; i < _amount; i++) {
            mintOne(WulfzType.Genesis);
            claimInPublicSale[msg.sender]++;
        }
    }

    function mintOne(WulfzType _type) private {
        require(
            totalSupplyByType[uint256(_type)] <
                MAX_SUPPLY_BY_TYPE[uint256(_type)],
            "All tokens are minted"
        );

        uint256 tokenId = ++totalSupplyByType[uint256(_type)];
        tokenId += START_ID_BY_TYPE[uint256(_type)];
        _safeMint(msg.sender, tokenId);
        wulfz[tokenId].wType = _type;

        emit WulfzMinted(msg.sender, tokenId, uint256(_type));
    }

    function setUtilitytoken(address _addr) external onlyOwner {
        _utilityToken = UtilityToken(_addr);
    }

    function setStakingPool(address _addr) external onlyOwner {
        _pool = StakingPool(_addr);
    }

    function setStartTimeOfPrivateSale(uint256 _timeStamp) external onlyOwner {
        _startTimeOfPrivateSale = _timeStamp;
    }

    function setStartTimeOfPublicSale(uint256 _timeStamp) external onlyOwner {
        _startTimeOfPublicSale = _timeStamp;
    }

    /*******************************************************************************
     ***                            Staking Logic                                 ***
     ******************************************************************************** */
    function setStakingTime(uint256 _timeStamp) external onlyOwner {
        _startTimeOfStaking = _timeStamp;
    }

    function startStaking(uint256 _tokenId) external {
        require(
            block.timestamp > _startTimeOfStaking,
            "Staking Mechanism is not started yet"
        );
        require(ownerOf(_tokenId) == msg.sender);
        require(
            !wulfz[_tokenId].bStaked,
            "This Token is already staked. Please try another token."
        );

        _pool.startStaking(msg.sender, _tokenId);
        _safeTransfer(msg.sender, address(_pool), _tokenId, "");
        wulfz[_tokenId].bStaked = true;
    }

    function stopStaking(uint256 _tokenId) external {
        require(ownerOf(_tokenId) == msg.sender);
        require(
            wulfz[_tokenId].bStaked,
            "This token hasn't ever been staked yet."
        );
        _pool.stopStaking(msg.sender, _tokenId);
        _safeTransfer(address(_pool), msg.sender, _tokenId, "");
        wulfz[_tokenId].bStaked = false;
    }

    /*******************************************************************************
     ***                            Adopting Logic                               ***
     ********************************************************************************/
    function setAdoptTime(uint256 _timeStamp) external onlyOwner {
        _startTimeOfAdopt = _timeStamp;
    }

    function canAdopt(uint256 _tokenId) public view returns (bool) {
        uint256 wType = uint256(wulfz[_tokenId].wType);

        require(
            wulfz[_tokenId].wType != WulfzType.Pupz,
            "Try adopting with Genesis or Alpha Wulfz"
        );

        uint256 lastBreedTime = wulfz[_tokenId].lastBreedTime;
        uint256 cooldown = COOLDOWN_TIME_FOR_BREED[wType];

        return (block.timestamp - lastBreedTime) > cooldown;
    }

    function isAdoptionStart() public view returns (bool) {
        return block.timestamp > _startTimeOfAdopt;
    }

    function adopt(uint256 _parent) external {
        require(
            canAdopt(_parent),
            "Already adopt in the past days. Genesis Wulfz can adopt every 14 days and Alpha can do every 7 days."
        );
        require(isAdoptionStart(), "Adopting Pupz is not ready yet");
        require(
            ownerOf(_parent) == msg.sender,
            "You're not owner of this token"
        );
        require(
            !wulfz[_parent].bStaked,
            "This Token is already staked. Please try another token."
        );

        mintOne(WulfzType.Pupz);
        wulfz[_parent].lastBreedTime = block.timestamp;

        _utilityToken.burn(msg.sender, BREED_PRICE);
    }

    /*******************************************************************************
     ***                            Evolution Logic                              ***
     ********************************************************************************/
    function setEvolveTime(uint256 _timeStamp) external onlyOwner {
        _startTimeOfEvolve = _timeStamp;
    }

    function isEvolveStart() public view returns (bool) {
        return block.timestamp > _startTimeOfEvolve;
    }

    function evolve(uint256 _tokenId) external {
        require(isEvolveStart(), "Evolving Wulfz is not ready yet");
        require(
            ownerOf(_tokenId) == msg.sender,
            "You're not owner of this token"
        );
        require(wulfz[_tokenId].wType == WulfzType.Genesis);
        require(
            !wulfz[_tokenId].bStaked,
            "This Token is already staked. Please try another token."
        );

        _burn(_tokenId);
        mintOne(WulfzType.Alpha);

        _utilityToken.burn(msg.sender, EVOLVE_PRICE);
    }

    /*******************************************************************************
     ***                            Profile Change                               ***
     ********************************************************************************/
    function changeName(uint256 _tokenId, string memory newName)
        public
        override
    {
        require(ownerOf(_tokenId) == msg.sender);
        super.changeName(_tokenId, newName);

        _utilityToken.burn(msg.sender, NAME_CHANGE_PRICE);
    }

    function changeBio(uint256 _tokenId, string memory _bio) public override {
        require(ownerOf(_tokenId) == msg.sender);
        super.changeBio(_tokenId, _bio);

        _utilityToken.burn(msg.sender, BIO_CHANGE_PRICE);
    }
}
