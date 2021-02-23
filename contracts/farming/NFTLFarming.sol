// SPDX-License-Identifier: MIT

pragma solidity 0.7.5;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../tokens/NFTLToken.sol";


contract NFTLFarm is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of NFTLs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accNFTLPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws tokens to a pool. Here's what happens:
        //   1. The pool's `accNFTLPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }
    // Info of each pool.
    struct PoolInfo {
        IERC20 token; // Address of token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. NFTLs to distribute per block.
        uint256 lastRewardBlock; // Last block number that NFTLs distribution occurs.
        uint256 accNFTLPerShare; // Accumulated NFTLs per share, times 1e12.
    }
    // The NFTL TOKEN!
    NFTLToken public nftl;
    // Dev address.
    address public devaddr;
    // address to receive the team rewards
    address public teamRewardsReceiver;
    // Block number when bonus NFTL period ends.
    uint256 public bonusEndBlock;
    // NFTL tokens created per block.
    uint256 public nftlPerBlock;
    // Bonus muliplier for early nftl makers.
    uint256 public constant BONUS_MULTIPLIER = 10;
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when NFTL mining starts.
    uint256 public startBlock;

    // team share, normalised by 10000
    uint256 public teamShare;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);

    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);

    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    constructor(
        NFTLToken _nftl,
        address _devaddr,
        address _teamRewardsReceiver,
        uint256 _nftlPerBlock,
        uint256 _teamShare,
        uint256 _startBlock,
        uint256 _bonusEndBlock
    ) public {
        nftl = _nftl;
        devaddr = _devaddr;
        nftlPerBlock = _nftlPerBlock;
        teamShare = _teamShare;
        bonusEndBlock = _bonusEndBlock;
        startBlock = _startBlock;
        teamRewardsReceiver = _teamRewardsReceiver;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new token to the pool. Can only be called by the owner.
    // XXX DO NOT add the same token more than once. Rewards will be messed up if you do.
    function add(
        uint256 _allocPoint,
        IERC20 _token,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock =
            block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfo({
                token: _token,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accNFTLPerShare: 0
            })
        );
    }

    // Update the given pool's NFTL allocation point. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(
            _allocPoint
        );
        poolInfo[_pid].allocPoint = _allocPoint;
    }


    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to)
        public
        view
        returns (uint256)
    {
        if (_to <= bonusEndBlock) {
            return _to.sub(_from).mul(BONUS_MULTIPLIER);
        } else if (_from >= bonusEndBlock) {
            return _to.sub(_from);
        } else {
            return
                bonusEndBlock.sub(_from).mul(BONUS_MULTIPLIER).add(
                    _to.sub(bonusEndBlock)
                );
        }
    }

    // View function to see pending NFTLs on frontend.
    function pendingNFTL(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accNFTLPerShare = pool.accNFTLPerShare;
        uint256 tokenSupply = pool.token.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && tokenSupply != 0) {
            uint256 multiplier =
                getMultiplier(pool.lastRewardBlock, block.number);
            uint256 nftlReward =
                multiplier.mul(nftlPerBlock).mul(pool.allocPoint).div(
                    totalAllocPoint
                );
            accNFTLPerShare = accNFTLPerShare.add(
                nftlReward.mul(1e12).div(tokenSupply)
            );
        }
        return user.amount.mul(accNFTLPerShare).div(1e12).sub(user.rewardDebt);
    }

    // Update reward vairables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 tokenSupply = pool.token.balanceOf(address(this));
        if (tokenSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 nftlReward =
            multiplier.mul(nftlPerBlock).mul(pool.allocPoint).div(
                totalAllocPoint
            );

        // staker share
        uint256 teamReward = nftlReward.mul(teamShare).div(10000);
        // mint reward for stakers
        nftl.mint(address(this), nftlReward.sub(teamReward));
        // mint reward of the team
        nftl.mint(teamRewardsReceiver, teamReward);

        pool.accNFTLPerShare = pool.accNFTLPerShare.add(
            nftlReward.mul(1e12).div(tokenSupply)
        );
        pool.lastRewardBlock = block.number;
    }

    // Deposit Tokens for NFTL allocation.
    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending =
                user.amount.mul(pool.accNFTLPerShare).div(1e12).sub(
                    user.rewardDebt
                );
            safeNFTLTransfer(msg.sender, pending);
        }
        pool.token.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(pool.accNFTLPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw tokens
    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending =
            user.amount.mul(pool.accNFTLPerShare).div(1e12).sub(
                user.rewardDebt
            );
        safeNFTLTransfer(msg.sender, pending);
        user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(pool.accNFTLPerShare).div(1e12);

        pool.token.safeTransfer(address(msg.sender), _amount);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.token.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }

    // Safe nftl transfer function, just in case if rounding error causes pool to not have enough NFTLs.
    function safeNFTLTransfer(address _to, uint256 _amount) internal {
        uint256 nftlBal = nftl.balanceOf(address(this));
        if (_amount > nftlBal) {
            nftl.transfer(_to, nftlBal);
        } else {
            nftl.transfer(_to, _amount);
        }
    }

    // Update dev address by the previous dev.
    function dev(address _devaddr) public {
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
    }

    function updateTeamShare(uint256 _newShare) public {
        require(msg.sender == devaddr, "dev: wut?");
        require(_newShare < 0 && _newShare > 100, "Wrong Values");
        teamShare = _newShare;
    }
}