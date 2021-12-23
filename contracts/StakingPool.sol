// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./Awoo.sol";

interface IWulfz {
    function getWulfzType(uint256 _tokenId) external view returns (uint256);

    function balanceOf(address _user) external view returns (uint256);

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external;

    function tokenOfOwnerByIndex(address _user, uint256 _index)
        external
        view
        returns (uint256);
}

contract StakingPool is IERC721Receiver, Ownable {
    using EnumerableSet for EnumerableSet.UintSet;

    event StakeStarted(address indexed user, uint256 indexed tokenId);
    event StakeStopped(address indexed user, uint256 indexed tokenId);

    uint256[] private STAKE_REWARD_BY_TYPE = [10, 5, 50];

    IWulfz private _wulfzContract;
    UtilityToken private _utilityToken;
    string private _privateKey;

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

    function startStaking(
        address _user,
        uint256 _tokenId,
        bytes32 hashInput
    ) external masterContract {
        require(
            verify(
                abi.encodePacked(
                    _tokenId,
                    _wulfzContract.getWulfzType(_tokenId)
                ),
                hashInput
            ),
            "Invalid action."
        );

        stakedWulfzInfo[_tokenId].lastUpdateTimeStamp = block.timestamp;
        stakedWulfz[msg.sender].add(_tokenId);

        emit StakeStarted(_user, _tokenId);
    }

    function stopStaking(address _user, uint256 _tokenId)
        external
        masterContract
    {
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
        uint256 ownedCount = _wulfzContract.balanceOf(_user);
        uint256 totalAmount = 0;

        for (uint256 i = 0; i < ownedCount; i++) {
            uint256 _tokenId = _wulfzContract.tokenOfOwnerByIndex(_user, i);
            totalAmount += updateReward(_tokenId);
        }

        return totalAmount;
    }

    function getRewards(address _user) external {
        uint256 reward = getClaimableToken(_user);
        _utilityToken.reward(_user, reward);
    }

    // verify if the input values is valid
    function verify(bytes memory input, bytes32 hashInput)
        private
        view
        returns (bool)
    {
        return hashInput == sha256(abi.encodePacked(input, _privateKey));
    }

    /* get staked ship list of a staker */
    function stakedTokensOf(address _user)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory tokens = new uint256[](stakedWulfz[_user].length());
        for (uint256 i = 0; i < stakedWulfz[_user].length(); i++) {
            tokens[i] = stakedWulfz[_user].at(i);
        }
        return tokens;
    }

    function setSecret(string memory _sec) external onlyOwner {
        _privateKey = _sec;
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
