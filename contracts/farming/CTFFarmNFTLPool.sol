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
    mapping(uint256 => mapping(address => uint256)) public locked;

    // Store the farm share, used for pro-rata distribution
    mapping(uint256 => mapping(address => uint256)) public shares;

    // Store the farm share, used for pro-rata distribution
    uint256 public totalShare;

    // total deposited 
    uint256 public totalDeposited; // total number of LPs deposited
    uint256 public startTimestamp; // start timestamp of pool
    uint256 public monthlyReward; // monthly reward, used for deflation
    uint256 public totalReward = 60480 * (10 ** 18); // total reward to be given out

    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => Pool)) public pools;

    // make pairs addresses public
    address[] public pools;

    address public dev;

    // Modifiers
    modifier onlyDev() {
        require(msg.sender = dev, "CTFFarmNFTLPool: caller is not the owner");
        _;
    }

    constructor(address _dev) {
        monthlyReward = 15120 * (10 ** 18);
        dev = _dev;
    }

    // deposit the LP tokens
    function deposit(address _poolAddr, address _amt) public {

        // add ERC20 interface to given pool address
        IERC20 poolToken = IERC20(_poolAddr);

        // check if user has sufficient LP tokens to lock
        require(amt >= poolToken.balanceOf(msg.sender), "CTFFarmNFTLPool: Insufficient LP Tokens");

        // store locked amount and time
        if (totalShare == 0) {
            // Geometric Mean
            share = Math.sqrt(_amt);
            // store share
            shares[msg.sender].add(share);
            // increment the totalShare
            totalShare.add(share);
            // update total deposited in the pool
            totalDeposited.add(_amt);
        } else {
            // calculated expected totalSupply till this point based on farming method
            uint256 expTotalSupply =
                // Uniswap formula, recheck the logic to replace totalDeposited with amount of LP or with amount of CTF
                share = _amt.mul(totalShare) / getTotalReward();
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
    function withdraw(address _poolAddr, address _amt) public {

        User storage user = users[_poolAddr][msg.sender];

        // add ERC20 interface to given pool address
        IERC20 lpToken = IERC20(_poolAddr);

        // check if user has locked sufficient amount
        require(_amt <= locked[msg.sender], "CTFFarmNFTLPool: Insufficient LP Balance");

        // return the accumulated CTFs
        CTF.mint(msg.sender, getReward());
    }

    // update monthly income
    function updateReward(_newReward) public {
        require(msg.sender == dev);
        // updatae monthly reward for inflation
        monthlyReward.add(_newReward);
    }

    // get total reward till date
    function getTotalReward() public view returns(uint256) {
        require(startTimestamp >= now, "CTFFarmNFTLPool: Farming is not yet started");
        // if less than 30 days has been passed, issue 25% of total CTF supply
        return startTimestamp.mul(monthlyReward).div(now);
    }

    // get total share of the user in CTF rewards
    function getShare(address _user) public view returns(uint256) {
        return shares[_user];
    }

    // get total reward of the user till date
    function getReward(address _user, uint256 _amt) public view returns(uint256) {
        // calculate share of the total reward pool using LPT Amt, Reverify calculation
        share = locked[msg.sender].mul(_amt).div(shares[msg.sender]);
        return getTotalReward().mul(share).div(shares[msg.sender]);
    }

    function changeDev(address _dev) public {
        require(msg.sender == dev);
        dev = _dev;
    }

}