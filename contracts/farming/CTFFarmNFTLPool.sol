// SPDX-License-Identifier: MIT

pragma solidity 0.7.5;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../libraries/Math.sol";
import "../tokens/CTFToken.sol";

// remove
import "hardhat/console.sol";


contract CTFFarmNFTLPool is Ownable {

    // apply safe libaries
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // dev address
    address public dev;

    // Store locked LP in balance
    mapping(address => uint256) public locked;

    // Store the farm share, used for pro-rata distribution
    mapping(address => uint256) public shares;

    // global counters
    uint256 public totalShare; // Store the farm share, used for pro-rata distribution
    uint256 public totalDeposited; // total number of LPs deposited

    // total deposited 
    uint256 public startBlock; // start timestamp of pool
    uint256 public blockReward; // per block reward
    uint256 public endBlock; // block at which the farming will end

    // set up the fees
    uint256 public depositFee; // fee rate, normalised by 1000
    address public feeReceiver; // // address where fees should be received

    // add interfaces
    IERC20 poolToken; // add ERC20 inteface to poolToken
    CyberTimeFinanceToken public CTF; // add CTF interface to CTF address

    constructor(
        address _dev,
        address _poolToken,
        address _CTFAddress,
        uint256 _depositFee,
        address _feeReceiver,
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _blockReward
    ) {
        dev = _dev;
        poolToken = IERC20(_poolToken);
        CTF = CyberTimeFinanceToken(_CTFAddress);
        depositFee = _depositFee;
        feeReceiver = _feeReceiver;
        startBlock = _startBlock;
        endBlock = _endBlock;
        blockReward = _blockReward;
    }

    // deposit the LP tokens
    function deposit(uint256 _amt) public {
        // check if user has sufficient LP tokens to lock
        require(_amt <= poolToken.balanceOf(msg.sender), "CTFFarmNFTLPool: Insufficient LP Tokens");

        // store locked amount and time
        if (totalShare == 0) {
            // Geometric Mean
            uint256 share = Math.sqrt(_amt);
            // store share
            shares[msg.sender] = shares[msg.sender].add(share);

            console.log("intial share", share);
            // increment the totalShare
            totalShare = totalShare.add(share);
            // update total deposited in the pool
            totalDeposited = totalDeposited.add(_amt);

        } else {
            // Uniswap formula, recheck the logic to replace totalDeposited with amount of LP or with amount of CTF
            uint256 share = _amt.mul(totalShare) / getAccumulatedReward();
            // store share
            shares[msg.sender] = shares[msg.sender].add(share);
            // update totalDeposited
            totalShare = totalShare.add(share);
            // update total deposited in the pool
            totalDeposited = totalDeposited.add(_amt);
        }

        // update locked LP balance of the user
        locked[msg.sender] = locked[msg.sender].add(_amt);

        // transfer the LP Tokens to the farming contract
        poolToken.transferFrom(msg.sender, address(this), _amt);

        // send fees to feeReceiver
        poolToken.transfer(feeReceiver, _amt.mul(depositFee).div(1000));
    }

    // withdraw the LP days
    function withdraw(uint256 _amt) public {
        // check if user has locked sufficient amount
        require(_amt <= locked[msg.sender], "CTFFarmNFTLPool: Insufficient LP Balance");

        // get share by provided amount
        uint256 share = shares[msg.sender].mul(_amt).div(locked[msg.sender]);

        // get accumulated reward per user, accumulatedReward * userShare / totalShare
        uint256 reward = getAccumulatedReward().mul(share).div(totalShare);

        console.log("reward is", reward / 1e18);

        // substract the share
        shares[msg.sender] = shares[msg.sender].sub(share);

        // update totalDeposited
        totalShare = totalShare.sub(share);

        // update total deposited in the pool
        totalDeposited = totalDeposited.sub(_amt);

        // return the accumulated CTFs
        CTF.mint(msg.sender, reward);

        // mint 10% to the team address
        CTF.mint(feeReceiver, reward.mul(10).div(100));

        // give the LP Tokens back
        poolToken.transfer(msg.sender, _amt.sub(_amt.mul(depositFee).div(1000)));
    }

    // update block reward
    function updateBlockReward(uint256 _newReward) public {
        require(msg.sender == dev);
        // updatae monthly reward for inflation
        blockReward = blockReward.add(_newReward);
    }


    // get total reward till date
    function getAccumulatedReward() public view returns(uint256) {
        require(startBlock <= block.timestamp, "CTFFarmNFTLPool: Farming is not yet started");
        return blockReward.mul(block.number - startBlock);
    }

    // get total share of the user in CTF rewards
    function getShare(address _user) public view returns(uint256) {
        return shares[_user];
    }

    function changeDev(address _dev) public {
        require(msg.sender == dev);
        dev = _dev;
    }

}