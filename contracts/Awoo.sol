// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract UtilityToken is ERC20("Awoo", "AWOO"), Ownable {
    event AwooBurn(address indexed user, uint256 amount);
    event AwooRewarded(address indexed user, uint256 amount);

    uint8 public _decimals = 2;
    uint256 public constant TOTAL_SUPPLY_AWOO = 200000000 * 10**2;

    address private _wulfzAddr;
    address private _stakingAddr;

    modifier masterContract() {
        require(msg.sender == _wulfzAddr);
        _;
    }

    modifier stakingContract() {
        require(msg.sender == _stakingAddr);
        _;
    }

    constructor(address wulfzAddr_, address stakingAddr_) {
        _wulfzAddr = wulfzAddr_;
        _stakingAddr = stakingAddr_;
    }

    function tokenAmount(uint256 _amount) internal view returns (uint256) {
        require(_amount != 0, "Amount is zero");
        return _amount * 10**_decimals;
    }

    function burn(address _from, uint256 _amount) external masterContract {
        _burn(_from, tokenAmount(_amount));
        emit AwooBurn(_from, _amount);
    }

    function reward(address _to, uint256 _amount) external stakingContract {
        if (_amount > 0) {
            require(
                (totalSupply() + tokenAmount(_amount)) < TOTAL_SUPPLY_AWOO,
                "MAX LIMIT SUPPLY EXCEEDED"
            );
            _mint(_to, tokenAmount(_amount));
            emit AwooRewarded(_to, _amount);
        }
    }
}
