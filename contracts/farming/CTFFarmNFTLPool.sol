// SPDX-License-Identifier: MIT

pragma solidity 0.7.5;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../libraries/Math.sol";
import "../tokens/CTFToken.sol";


contract CTFFarmNFTLPool is Ownable {

    // apply safe libaries
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // The CTF TOKEN!
    CyberTimeFinanceToken public CTF;

    // dev address
    address public dev;

    // Store locked LP in balance
    mapping(address => uint256) public locked;

    // Store the farm share, used for pro-rata distribution
    mapping(address => uint256) public shares;


    // Store the farm share, used for pro-rata distribution
    uint256 public totalShare;

    // total deposited 
    uint256 public totalDeposited; // total number of LPs deposited
    uint256 public startTimestamp; // start timestamp of pool
    uint256 public monthlyReward; // monthly reward, used for deflation
    uint256 public totalReward = 60480 * (10 ** 18); // total reward to be given out

    // add ERC20 interface to given pool address
    IERC20 poolToken;

    constructor(address _dev, IERC20 _poolToken) {
        monthlyReward = 15120 * (10 ** 18);
        dev = _dev;
        poolToken = _poolToken;
    }

    // deposit the LP tokens
    function deposit(uint256 _amt) public {

        // check if user has sufficient LP tokens to lock
        require(_amt >= poolToken.balanceOf(msg.sender), "CTFFarmNFTLPool: Insufficient LP Tokens");

        // store locked amount and time
        if (totalShare == 0) {
            // Geometric Mean
            uint256 share = Math.sqrt(_amt);
            // store share
            shares[msg.sender].add(share);
            // increment the totalShare
            totalShare.add(share);
            // update total deposited in the pool
            totalDeposited.add(_amt);
        } else {
            // Uniswap formula, recheck the logic to replace totalDeposited with amount of LP or with amount of CTF
            uint256 share = _amt.mul(totalShare) / getTotalReward();
            // store share
            shares[msg.sender].add(share);
            // update totalDeposited
            totalShare.add(share);
            // update total deposited in the pool
            totalDeposited.add(_amt);
        }

        // update locked LP balance of the user
        locked[msg.sender].add(_amt);

        // transfer the LP Tokens to the farming contract
        poolToken.transferFrom(msg.sender, address(this), _amt);

    }

    // withdraw the LP days
    function withdraw(uint256 _amt) public {
        // check if user has locked sufficient amount
        require(_amt <= locked[msg.sender], "CTFFarmNFTLPool: Insufficient LP Balance");

        // return the accumulated CTFs
        CTF.mint(msg.sender, getReward(msg.sender, _amt));
    }

    // update monthly income
    function updateReward(uint256 _newReward) public {
        require(msg.sender == dev);
        // updatae monthly reward for inflation
        monthlyReward.add(_newReward);
    }

    // get total reward till date
    function getTotalReward() public view returns(uint256) {
        require(startTimestamp >= block.timestamp, "CTFFarmNFTLPool: Farming is not yet started");
        // if less than 30 days has been passed, issue 25% of total CTF supply
        return startTimestamp.mul(monthlyReward).div(block.timestamp);
    }

    // get total share of the user in CTF rewards
    function getShare(address _user) public view returns(uint256) {
        return shares[_user];
    }

    // get total reward of the user till date
    function getReward(address _user, uint256 _amt) public view returns(uint256) {
        // calculate share of the total reward pool using LPT Amt, Reverify calculation
        uint256 share = locked[_user].mul(_amt).div(shares[_user]);
        return getTotalReward().mul(share).div(shares[_user]);
    }

    function changeDev(address _dev) public {
        require(msg.sender == dev);
        dev = _dev;
    }

}