// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

interface IWulfzNFT {
    function setUtilitytoken(address _addr) external;

    function setStakingPool(address _addr) external;

    function canAdopt(uint256 _tokenId) external view returns (bool);

    function isAdoptionStart() external view returns (bool);

    function adopt(uint256 _parent) external;

    function isEvolveStart() external view returns (bool);

    function evolve(uint256 _tokenId) external;
}
