// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./Awoo.sol";

interface IWulfz {
    function getWulfzType(uint256 _tokenId) external view returns (uint256);
}

contract StakingPool is IERC721Receiver, Ownable {
    using EnumerableSet for EnumerableSet.UintSet;

    event StakeStarted(address indexed user, uint256 indexed tokenId);
    event StakeStopped(address indexed user, uint256 indexed tokenId);

    uint256[] private STAKE_REWARD_BY_TYPE = [10, 5, 50];

    IWulfz private _wulfzContract;
    UtilityToken private _utilityToken;

    struct TokenInfo {
        uint256 reward;
        uint256 lastUpdateTimeStamp;
    }

    mapping(uint256 => TokenInfo) private stakedWulfzInfo;
    mapping(address => EnumerableSet.UintSet) private stakedWulfz;

    modifier masterContract() {
        require(msg.sender == address(_wulfzContract));
        _;
    }

    constructor(address _wulfzAddr, address _awoo) {
        _wulfzContract = IWulfz(_wulfzAddr);
        _utilityToken = UtilityToken(_awoo);
    }

    function setPoolAddress(address _addr) external onlyOwner {
        _wulfzContract = IWulfz(_addr);
    }

    function setUtilitytoken(address _addr) external onlyOwner {
        _utilityToken = UtilityToken(_addr);
    }

    function startStaking(address _user, uint256 _tokenId)
        external
        masterContract
    {
        require(!stakedWulfz[msg.sender].contains(_tokenId), "Already staked");
        stakedWulfzInfo[_tokenId].lastUpdateTimeStamp = block.timestamp;
        stakedWulfz[msg.sender].add(_tokenId);

        emit StakeStarted(_user, _tokenId);
    }

    function stopStaking(address _user, uint256 _tokenId)
        external
        masterContract
    {
        require(
            stakedWulfz[msg.sender].contains(_tokenId),
            "You're not the owner"
        );
        delete stakedWulfzInfo[_tokenId];
        stakedWulfz[_user].remove(_tokenId);
        updateReward(_tokenId);

        emit StakeStopped(_user, _tokenId);
    }

    function updateReward(uint256 _tokenId) internal returns (uint256) {
        uint256 wType = _wulfzContract.getWulfzType(_tokenId);
        uint256 rewardBase = STAKE_REWARD_BY_TYPE[wType];
        uint256 interval = block.timestamp -
            stakedWulfzInfo[_tokenId].lastUpdateTimeStamp;

        stakedWulfzInfo[_tokenId].reward += (rewardBase * interval) / 86400;
        return stakedWulfzInfo[_tokenId].reward;
    }

    function getClaimableToken(address _user) public returns (uint256) {
        uint256[] memory tokens = stakedTokensOf(_user);
        uint256 totalAmount = 0;

        for (uint256 i = 0; i < tokens.length; i++) {
            totalAmount += updateReward(tokens[i]);
        }

        return totalAmount;
    }

    function getRewards(address _user) external {
        uint256 reward = getClaimableToken(_user);
        _utilityToken.reward(_user, reward);
    }

    function stakedTokensOf(address _user)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory tokens = new uint256[](stakedWulfz[_user].length());
        for (uint256 i = 0; i < stakedWulfz[_user].length(); i++) {
            tokens[i] = stakedWulfz[_user].at(i);
        }
        return tokens;
    }

    /**
     * ERC721Receiver hook for single transfer.
     * @dev Reverts if the caller is not the whitelisted NFT contract.
     */
    function onERC721Received(
        address, /*operator*/
        address, /*from*/
        uint256, // tokenId
        bytes calldata /*data*/
    ) external view override returns (bytes4) {
        require(
            address(_wulfzContract) == msg.sender,
            "You can stake only Wulfz"
        );
        return this.onERC721Received.selector;
    }
}
