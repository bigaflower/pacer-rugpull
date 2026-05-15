// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IUniswapV2Router02 {
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

interface IUniswapV2Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

// -----------------------------------------------------------------------------
// XORD Token - Founders & Allocations
// Full allocation details, roles, and vesting conditions are permanently published at:
// https://xord.io/white-paper.html
//
// XORD staking at:
// https://xord.io/stakingXORD.html
//
// Public Pool Distribution (73M total):
// - 28M: Public claims (20,000 XORD per address, 0.00025 ETH fee)
// - 5M: Book rewards distribution (The Raven's Enigma promotion)
// - 40M: LP staking rewards (12% APY, anti-whale protected)
//   ⚠️ Max 10OK LP tokens can be staked per wallet — enforced on-chain
//
// 10,000,000 XORD Each:
// 0x2E432Bf92629b009eF6E04507f0588ad3E3c8433: Cesare di Monte Calvi (deployer), Writer and Creator of The Raven's Enigma, New York, NY
// 0xAb71511A5d1bDcA66212cB398246E05564e326F4: Captain (anonymous, real tankers Commander), Early seed investor, Rijeka, Croatia. Not active in crypto. Holds 10M XORD; will consult team before any token sales to avoid market impact.
//
// 1,000,000 XORD Each:
// 0x57224756645030F640AbCCD09763213F023506E7: Alex K., Financial System Architect, Monte Carlo, Monaco
// 0xAF2eECef26bEF915F1379eB9b858EcC27DA11cb4: BanderaSH-A256, Security + Infrastructure Architect, New York, NY
// 0x036705749AA95734E6d6716f9499e645F1632139: Peter M., Serendipity Archive and Planetary Aspects Software, Newcastle, Australia
// 0x25dBbad8DD3c8Fd6eA29bB6a8dE6e739Cc98f4f2: Kaja F., Marketing Advisor, Calgary, Canada
// 0xB6Fc4429D606061dDB5b9F8a26531d444958e72E: Jacques M., Native Android/Backend Developer, Vevey, Switzerland
//
// Founder and team allocations (listed above with addresses) are subject to on-chain vesting 
// (2% TGE, then linear over 360 days, claimable via the claim() function). 
// The 5M book rewards are distributed by the deployer (exactly 50,000 XORD per distribution) and are immediately liquid. 
// Publicly claimed tokens (from the 28M pool) are also immediately liquid once claimed.
// LP Staking rewards are paid from the 40M pool, which itself vests over time, and rewards are liquid once claimed by stakers.
// All token movements are transparent as per contract logic.
// -----------------------------------------------------------------------------

contract XORD is IERC20 {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    string public constant name = "XORD";
    string public constant symbol = "XORD";
    uint8 public constant decimals = 18;
    uint256 public constant override totalSupply = 100_000_000 * 10**18;

    uint256 public immutable deploymentTime;
    uint256 public constant VESTING_DURATION = 360 days;
    uint256 public constant TGE_UNLOCK_PERCENT = 2;
    uint256 public constant UNISWAP_ALLOCATION = 2_000_000 * 10**18;

    mapping(address => uint256) public allocations;
    mapping(address => uint256) public claimed;

    // Public pool split into three parts
    address public constant publicPoolAddress = 0x705bBF34AD8b1A515B20626E59E8C11d386252B3;
    uint256 public constant publicPoolAllocation = 73_000_000 * 10**18;
    uint256 public constant PUBLIC_CLAIMS_ALLOCATION = 28_000_000 * 10**18;
    uint256 public constant REWARDS_DISTRIBUTION_ALLOCATION = 5_000_000 * 10**18;
    uint256 public constant STAKING_REWARDS_ALLOCATION = 40_000_000 * 10**18;
    
    // Public claims variables
    uint256 public constant CLAIM_AMOUNT = 20_000 * 10**18;
    uint256 public constant CLAIM_FEE = 0.00025 ether;
    uint256 public constant CLAIM_DEADLINE = 29 days;
    mapping(address => bool) public hasClaimed;
    uint256 public totalPublicClaimed;
    
    // Rewards distribution tracking
    uint256 public rewardsDistributed;
    uint256 public constant BOOK_REWARD_AMOUNT = 50_000 * 10**18; // Exactly 50,000 XORD per book
    
    // Staking rewards tracking
    uint256 public stakingRewardsClaimed;

    address public constant UNISWAP_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public constant UNISWAP_FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    address public immutable deployer;
    bool public liquidityAdded = false;
    address public uniswapPair;

    // LP Staking variables
    /** @notice THIS IS AN INTERNAL TARGET RATE ONLY. ACTUAL rewards CANNOT exceed daily vesting (~111k XORD/day)
     * @dev EFFECTIVE APY WILL BE VARIABLE and likely LOWER than 12%. DO NOT TREAT 12% AS A GUARANTEE */
    // XORD token is a utility token primarily used to purchase goods, services, and digital products within the XORD ecosystem, including access to our crypto-AI platforms. It is not an investment contract, and no returns are promised.
    uint256 public constant STAKING_APY = 1200; // 12.00% in basis points
    uint256 public constant BASIS_POINTS = 10000;
    uint256 public constant SECONDS_PER_YEAR = 365 days;
    
    uint256 public constant MAX_STAKE_PER_WALLET = 100_000 * 10**18; // Max LP tokens per wallet
    // DAILY_REWARDS_CAP removed
    
    struct StakeInfo {
        uint256 amount;
        uint256 startTime;
        uint256 rewardsClaimed;
        uint256 lastClaimTime;
    }
    
    mapping(address => StakeInfo) public stakes;
    uint256 public totalStaked;
    uint256 public lastRewardReset;
    uint256 public dailyRewardsClaimed;

    event Claimed(address indexed user, uint256 amount);
    event PublicClaim(address indexed user, uint256 amount, uint256 fee);
    event RewardsDistributed(address indexed recipient, uint256 amount);
    event LiquidityAdded(address indexed pair, uint256 tokenAmount, uint256 ethAmount);
    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 amount);
    event ETHCollected(address indexed recipient, uint256 amount);
    event UnspentRewardsReclaimed(uint256 amount);

    constructor() payable {
        require(msg.value == 0, "Do not send ETH on deployment");

        deployer = msg.sender;
        deploymentTime = block.timestamp;
        lastRewardReset = block.timestamp;

        // Initial Core Allocations (Deployer, Core Team, Seed - 25M total)
        allocations[0x2E432Bf92629b009eF6E04507f0588ad3E3c8433] = 10_000_000 * 10**18; // Cesare
        allocations[0xAb71511A5d1bDcA66212cB398246E05564e326F4] = 10_000_000 * 10**18; // Captain

        allocations[0x57224756645030F640AbCCD09763213F023506E7] = 1_000_000 * 10**18; // Alex K.
        allocations[0xAF2eECef26bEF915F1379eB9b858EcC27DA11cb4] = 1_000_000 * 10**18; // BanderaSH-A256
        allocations[0x036705749AA95734E6d6716f9499e645F1632139] = 1_000_000 * 10**18; // Peter M.
        allocations[0x25dBbad8DD3c8Fd6eA29bB6a8dE6e739Cc98f4f2] = 1_000_000 * 10**18; // Kaja F.
        allocations[0xB6Fc4429D606061dDB5b9F8a26531d444958e72E] = 1_000_000 * 10**18; // Jacques M.

        // Public pool gets 73M allocation for vesting purposes
        allocations[publicPoolAddress] = publicPoolAllocation;

        _balances[address(this)] = totalSupply;
        emit Transfer(address(0), address(this), totalSupply);
    }

    // Public claim function - anyone can claim once
    function publicClaim() external payable {
        require(msg.value == CLAIM_FEE, "Incorrect fee");
        require(block.timestamp <= deploymentTime + CLAIM_DEADLINE, "Claim period ended");
        require(!hasClaimed[msg.sender], "Already claimed");
        require(totalPublicClaimed + CLAIM_AMOUNT <= PUBLIC_CLAIMS_ALLOCATION, "Claims exhausted");

        hasClaimed[msg.sender] = true;
        totalPublicClaimed += CLAIM_AMOUNT;

        _balances[address(this)] -= CLAIM_AMOUNT;
        _balances[msg.sender] += CLAIM_AMOUNT;

        emit Transfer(address(this), msg.sender, CLAIM_AMOUNT);
        emit PublicClaim(msg.sender, CLAIM_AMOUNT, CLAIM_FEE);
    }

    // Rewards distribution function - deployer only, exactly 50k XORD per book
    function distributeRewards(address recipient) external {
        require(msg.sender == deployer, "Not authorized");
        require(rewardsDistributed + BOOK_REWARD_AMOUNT <= REWARDS_DISTRIBUTION_ALLOCATION, "Exceeds rewards allocation");

        rewardsDistributed += BOOK_REWARD_AMOUNT;

        _balances[address(this)] -= BOOK_REWARD_AMOUNT;
        _balances[recipient] += BOOK_REWARD_AMOUNT;

        emit Transfer(address(this), recipient, BOOK_REWARD_AMOUNT);
        emit RewardsDistributed(recipient, BOOK_REWARD_AMOUNT);
    }

    // Reclaim unspent rewards after 1 year - deployer only
    function reclaimUnspentRewards() external {
        require(msg.sender == deployer, "Not authorized");
        require(block.timestamp >= deploymentTime + 365 days, "Too early to reclaim");
        
        uint256 unspent = REWARDS_DISTRIBUTION_ALLOCATION - rewardsDistributed;
        require(unspent > 0, "No unspent rewards");
        
        rewardsDistributed = REWARDS_DISTRIBUTION_ALLOCATION; // Mark all as distributed
        
        _balances[address(this)] -= unspent;
        _balances[deployer] += unspent;
        
        emit Transfer(address(this), deployer, unspent);
        emit UnspentRewardsReclaimed(unspent);
    }

    // Collect ETH from claims - deployer only
    function collectETH() external {
        require(msg.sender == deployer, "Not authorized");
        uint256 balance = address(this).balance;
        require(balance > 0, "No ETH to collect");
        
        (bool success, ) = deployer.call{value: balance}("");
        require(success, "ETH transfer failed");
        
        emit ETHCollected(deployer, balance);
    }

    function addInitialLiquidity() external payable {
        require(msg.sender == deployer, "Not authorized");
        require(!liquidityAdded, "Liquidity already added");
        require(msg.value > 0, "ETH required");

        address pair = IUniswapV2Factory(UNISWAP_FACTORY).getPair(address(this), WETH);
        if (pair == address(0)) {
            pair = IUniswapV2Factory(UNISWAP_FACTORY).createPair(address(this), WETH);
        }
        require(pair != address(0), "Pair creation failed");

        uniswapPair = pair;
        require(uniswapPair != address(0), "Pair assignment failed");

        _approve(address(this), UNISWAP_ROUTER, UNISWAP_ALLOCATION);

        (uint amountToken, uint amountETH, uint liquidity) = IUniswapV2Router02(UNISWAP_ROUTER).addLiquidityETH{value: msg.value}(
            address(this),
            UNISWAP_ALLOCATION,
            0,
            0,
            address(this),
            block.timestamp + 300
        );

        require(amountToken > 0 && amountETH > 0 && liquidity > 0, "Liquidity addition failed");

        liquidityAdded = true;
        emit LiquidityAdded(pair, amountToken, amountETH);
    }

    // Team member vesting claim
    function claim() external {
        require(msg.sender != publicPoolAddress, "Public pool cannot claim directly");
        uint256 amount = claimableAmount(msg.sender);
        require(amount > 0, "Nothing to claim");
        claimed[msg.sender] += amount;
        _balances[address(this)] -= amount;
        _balances[msg.sender] += amount;
        emit Transfer(address(this), msg.sender, amount);
        emit Claimed(msg.sender, amount);
    }

    // LP Staking functions
    function stakeLPTokens(uint256 amount) external {
        require(amount > 0, "Cannot stake 0");
        require(liquidityAdded, "Liquidity not added yet");
        require(uniswapPair != address(0), "Pair not created");
        
        // Anti-whale check
        require(stakes[msg.sender].amount + amount <= MAX_STAKE_PER_WALLET, "Exceeds max stake per wallet");
        
        // Transfer LP tokens from user
        require(IERC20(uniswapPair).transferFrom(msg.sender, address(this), amount), "LP transfer failed");
        
        // If user has existing stake, claim rewards first
        if (stakes[msg.sender].amount > 0) {
            claimStakingRewards();
        }
        
        // Update stake info
        stakes[msg.sender].amount += amount;
        stakes[msg.sender].startTime = block.timestamp;
        stakes[msg.sender].lastClaimTime = block.timestamp;
        
        totalStaked += amount;
        
        emit Staked(msg.sender, amount);
    }
    
    function unstakeLPTokens(uint256 amount) external {
        require(amount > 0, "Cannot unstake 0");
        require(stakes[msg.sender].amount >= amount, "Insufficient staked amount");
        
        // Claim any pending rewards first
        claimStakingRewards();
        
        // Update stake info
        stakes[msg.sender].amount -= amount;
        totalStaked -= amount;
        
        // Transfer LP tokens back to user
        require(IERC20(uniswapPair).transfer(msg.sender, amount), "LP transfer failed");
        
        emit Unstaked(msg.sender, amount);
    }
    
    function claimStakingRewards() public {
        uint256 rewards = calculateRewards(msg.sender);
        require(rewards > 0, "No rewards to claim");
        
        // Check daily cap - removed the require, keeping tracking for analytics
        _resetDailyRewardsIfNeeded();
        
        // Check if rewards available from staking pool
        uint256 available = stakingRewardsAvailable();
        
        // CHANGE 3: Implement partial claims
        uint256 claimableRewards = rewards;
        if (claimableRewards > available) {
            claimableRewards = available;
        }
        require(claimableRewards > 0, "Insufficient rewards in pool");
        
        // Update state
        stakes[msg.sender].rewardsClaimed += claimableRewards;
        stakes[msg.sender].lastClaimTime = block.timestamp;
        stakingRewardsClaimed += claimableRewards;
        dailyRewardsClaimed += claimableRewards;
        
        // Transfer rewards
        _balances[address(this)] -= claimableRewards;
        _balances[msg.sender] += claimableRewards;
        
        emit Transfer(address(this), msg.sender, claimableRewards);
        emit RewardsClaimed(msg.sender, claimableRewards);
    }
    
    function calculateRewards(address user) public view returns (uint256) {
        StakeInfo memory stake = stakes[user];
        if (stake.amount == 0) return 0;
        
        uint256 timeStaked = block.timestamp - stake.lastClaimTime;
        uint256 annualReward = (stake.amount * STAKING_APY) / BASIS_POINTS;
        uint256 reward = (annualReward * timeStaked) / SECONDS_PER_YEAR;
        
        return reward;
    }
    
    function _resetDailyRewardsIfNeeded() private {
        if (block.timestamp >= lastRewardReset + 1 days) {
            dailyRewardsClaimed = 0;
            lastRewardReset = block.timestamp;
        }
    }

    // Vesting calculation functions
    function vestedAmount(address user) public view returns (uint256) {
        uint256 allocation = allocations[user];
        if (allocation == 0) return 0;
        uint256 initialUnlock = (allocation * TGE_UNLOCK_PERCENT) / 100;
        uint256 timeElapsed = block.timestamp - deploymentTime;
        if (timeElapsed >= VESTING_DURATION) {
            return allocation;
        }
        uint256 vestingAmount = allocation - initialUnlock;
        uint256 vestedLinear = (vestingAmount * timeElapsed) / VESTING_DURATION;
        return initialUnlock + vestedLinear;
    }

    function claimableAmount(address user) public view returns (uint256) {
        if (user == publicPoolAddress) return 0;
        uint256 vested = vestedAmount(user);
        uint256 alreadyClaimed = claimed[user];
        return vested > alreadyClaimed ? vested - alreadyClaimed : 0;
    }

    // Modified public pool functions to account for three-way split
    function publicPoolVested() public view returns (uint256) {
        return vestedAmount(publicPoolAddress);
    }

    function stakingRewardsAvailable() public view returns (uint256) {
        uint256 totalVested = publicPoolVested();
        // Calculate proportional vesting for staking rewards (40M out of 73M)
        uint256 stakingVested = (totalVested * STAKING_REWARDS_ALLOCATION) / publicPoolAllocation;
        
        return stakingVested > stakingRewardsClaimed ? stakingVested - stakingRewardsClaimed : 0;
    }

    // View functions
    function getStakeInfo(address user) external view returns (
        uint256 stakedAmount,
        uint256 pendingRewards,
        uint256 totalRewardsClaimed,
        uint256 stakingTime
    ) {
        StakeInfo memory stake = stakes[user];
        return (
            stake.amount,
            calculateRewards(user),
            stake.rewardsClaimed,
            stake.amount > 0 ? block.timestamp - stake.startTime : 0
        );
    }

    function remainingClaimsAllocation() external view returns (uint256) {
        return PUBLIC_CLAIMS_ALLOCATION - totalPublicClaimed;
    }

    function remainingRewardsAllocation() external view returns (uint256) {
        return REWARDS_DISTRIBUTION_ALLOCATION - rewardsDistributed;
    }

    // Standard ERC20 functions
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, currentAllowance - amount);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner_, address spender, uint256 amount) internal {
        require(owner_ != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner_][spender] = amount;
        emit Approval(owner_, spender, amount);
    }
}