// SPDX-License-Identifier: MIT

pragma solidity 0.7.5;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../tokens/CTFToken.sol";

contract CTFFarm is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of CTFs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accCTFPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accCTFPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }
    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. CTFs to distribute per block.
        uint256 lastRewardBlock; // Last block number that CTFs distribution occurs.
        uint256 accCTFPerShare; // Accumulated CTFs per share, times 1e12.
    }
    // The CTF TOKEN!
    CyberTimeFinanceToken public ctf;
    // Dev address.
    address public devaddr;
    // LP Token Fee Receiver
    address public lpFeeReceiver;
    // Block number when bonus CTF period ends.
    uint256 public bonusEndBlock;
    // CTF tokens created per block.
    uint256 public ctfPerBlock;
    // Bonus muliplier for early ctf makers.
    uint256 public constant BONUS_MULTIPLIER = 10;
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when CTF mining starts.
    
    uint256 public startBlock;
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    constructor(
        CyberTimeFinanceToken _ctf,
        address _devaddr,
        address _lpFeeReceiver,
        uint256 _ctfPerBlock,
        uint256 _startBlock,
        uint256 _bonusEndBlock
    ) public {
        ctf = _ctf;
        devaddr = _devaddr;
        lpFeeReceiver = _lpFeeReceiver;
        ctfPerBlock = _ctfPerBlock;
        bonusEndBlock = _bonusEndBlock;
        startBlock = _startBlock;
    }


    modifier validatePool(uint256 _pid) { 
        require ( _pid < poolInfo.length , "farm: pool do not exists");
        _; 
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.

    function checkPoolDuplicate ( 
        IERC20 _lpToken 
    ) public { 
        uint256 length = poolInfo.length ;
        for (uint256 pid = 0; pid < length ; ++pid) {
            require (poolInfo[pid].lpToken!=_lpToken , "add: existing pool?"); 
        }
    }

    function add(
        uint256 _allocPoint,
        IERC20 _lpToken,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        checkPoolDuplicate(_lpToken);
        uint256 lastRewardBlock =
            block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accCTFPerShare: 0
            })
        );
    }


    // Update the given pool's CTF allocation point. Can only be called by the owner.
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

    // View function to see pending CTFs on frontend.
    function pendingCTF(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accCTFPerShare = pool.accCTFPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier =
                getMultiplier(pool.lastRewardBlock, block.number);
            uint256 ctfReward =
                multiplier.mul(ctfPerBlock).mul(pool.allocPoint).div(
                    totalAllocPoint
                );
            accCTFPerShare = accCTFPerShare.add(
                ctfReward.mul(1e12).div(lpSupply)
            );
        }
        return user.amount.mul(accCTFPerShare).div(1e12).sub(user.rewardDebt);
    }

    // Update reward vairables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public validatePool(_pid) {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 ctfReward =
            multiplier.mul(ctfPerBlock).mul(pool.allocPoint).div(
                totalAllocPoint
            );
        pool.accCTFPerShare = pool.accCTFPerShare.add(
            ctfReward.mul(1e12).div(lpSupply)
        );
        pool.lastRewardBlock = block.number;
        ctf.mint(devaddr, ctfReward.div(10));
        ctf.mint(address(this), ctfReward);
    }

    // Deposit LP tokens to MasterChef for CTF allocation.
    function deposit(uint256 _pid, uint256 _amount) public validatePool(_pid) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending =
                user.amount.mul(pool.accCTFPerShare).div(1e12).sub(
                    user.rewardDebt
                );
            safeCTFTransfer(msg.sender, pending);
        }

        // amount minus 2% LP fees
        uint256 fees = _amount.mul(2).div(100);

        user.amount = user.amount.add(_amount.sub(fees));
        user.rewardDebt = user.amount.mul(pool.accCTFPerShare).div(1e12);

        pool.lpToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );

        // send fees in the form of LP tokens to feeReceiver addr
        pool.lpToken.transfer(lpFeeReceiver, fees);
        emit Deposit(msg.sender, _pid, _amount.sub(fees));
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public validatePool(_pid){
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending =
            user.amount.mul(pool.accCTFPerShare).div(1e12).sub(
                user.rewardDebt
            );

        user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(pool.accCTFPerShare).div(1e12);

        safeCTFTransfer(msg.sender, pending);

        pool.lpToken.safeTransfer(address(msg.sender), _amount);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        user.amount = 0;
        user.rewardDebt = 0;
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
    }

    // Safe ctf transfer function, just in case if rounding error causes pool to not have enough CTFs.
    function safeCTFTransfer(address _to, uint256 _amount) internal {
        uint256 ctfBal = ctf.balanceOf(address(this));
        if (_amount > ctfBal) {
            ctf.transfer(_to, ctfBal);
        } else {
            ctf.transfer(_to, _amount);
        }
    }

    // Update dev address by the previous dev.
    function dev(address _devaddr) public {
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
    }
}