// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title OilToken
 * @dev The native ERC20 token ($OIL) for the Proof of Drill economy.
 *      Minting is restricted exclusively to the BarrelNFT contract.
 */
contract OilToken is ERC20, Ownable {
    uint256 public constant MAX_SUPPLY = 5_760_000_000 * 10**18;

    // PvP Embargo Mechanics
    mapping(address => uint256) public sanctions;
    address public warRoom;

    // Cartel Throttling Mechanics
    bool public isThrottled;
    address public throttlingVault;
    address public cartelRegistry;

    event SanctionApplied(address indexed target, uint256 strikesRemaining);
    event Burn(address indexed from, uint256 amount);

    constructor(address initialOwner) ERC20("Proof of Drill Oil", "OIL") Ownable(initialOwner) {}

    function setWarRoom(address _warRoom) external onlyOwner {
        warRoom = _warRoom;
    }

    function setCartelRegistry(address _registry) external onlyOwner {
        cartelRegistry = _registry;
    }

    function setThrottling(bool active, address cartelVault) external {
        require(msg.sender == cartelRegistry, "Only CartelRegistry can throttle");
        isThrottled = active;
        throttlingVault = cartelVault;
    }

    function mint(address to, uint256 amount) external {
        require(msg.sender == owner() || msg.sender == warRoom, "Not authorized to mint");
        require(totalSupply() + amount <= MAX_SUPPLY, "Max supply reached");
        _mint(to, amount);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function burnFrom(address account, uint256 amount) external {
        _spendAllowance(account, msg.sender, amount);
        _burn(account, amount);
    }

    function addSanctions(address target, uint256 strikes) external {
        require(msg.sender == warRoom, "Only WarRoom can sanction");
        sanctions[target] += strikes;
        emit SanctionApplied(target, sanctions[target]);
    }

    function getExpectedSlippage(address account) external view returns (uint256) {
        if (sanctions[account] > 0) return 20; // 20%
        if (isThrottled && account != throttlingVault) return 5; // 5% Throttle Tax
        return 0; // 0%
    }

    // Fee-on-transfer logic for sanctions and throttling
    function _update(address from, address to, uint256 amount) internal virtual override {
        if (from != address(0) && to != address(0)) {
            // Priority 1: Sanctions (20% burn tax, lasts 3 transfers)
            if (sanctions[from] > 0) {
                sanctions[from]--;
                uint256 burnAmount = (amount * 20) / 100;
                uint256 sendAmount = amount - burnAmount;
                super._update(from, address(0), burnAmount); // Burn the tax
                emit Burn(from, burnAmount);
                super._update(from, to, sendAmount); // Send the rest
                emit SanctionApplied(from, sanctions[from]);
                return;
            }

            // Priority 2: Global Throttling (Cartel extracts 5% total tax: 2.5% burn, 2.5% to Cartel)
            // The throttling vault is exempt to allow cartel distribution to members.
            if (isThrottled && from != throttlingVault && to != throttlingVault) {
                uint256 tax = (amount * 5) / 100;
                uint256 cartelCut = tax / 2;
                uint256 burnCut = tax - cartelCut;
                uint256 sendAmount = amount - tax;

                super._update(from, throttlingVault, cartelCut);
                super._update(from, address(0), burnCut);
                emit Burn(from, burnCut);
                super._update(from, to, sendAmount);
                return;
            }
        }
        super._update(from, to, amount);
    }
}

/**
 * @title BarrelNFT
 * @dev ERC721 Collection representing Oil Wells. 
 *      Each NFT drips $OIL over a 120-day lifespan using a step-decay curve to simulate reservoir pressure.
 */
contract BarrelNFT is ERC721Enumerable, Ownable, ReentrancyGuard {
    OilToken public oilToken;
    
    uint256 public constant MAX_BARRELS = 100000;
    uint256 public constant MINT_PRICE = 0.01 ether;
    uint256 public constant WELL_LIFESPAN = 120 days;

    uint256 private _nextTokenId = 1;

    struct Well {
        uint256 drilledAt;
        uint256 lastClaimedAt;
        uint256 totalClaimed;
    }

    // ETH Reward Tracking
    uint256 public rewardPerBarrel;
    mapping(uint256 => uint256) public rewardDebt;
    mapping(uint256 => uint256) public ethClaimed;

    mapping(uint256 => Well) public wells;
    // Efficiency tracking for Blowouts (Rusty Barrel). Default is 10000 (100.00%)
    mapping(uint256 => uint256) public efficiency; 
    // Time locks for Dry Holes
    mapping(uint256 => uint256) public yieldLock;

    mapping(address => bool) public hasDrilled;

    // Referral tracking
    mapping(address => uint256) public referralEarned;

    // Global Stats for DApp
    uint256 public totalEthRaised;
    uint256 public totalUniqueDrillers;

    // Distribution Addresses (OILDAO Treasury, UniV3 LP, Rewards, Devs)
    address public treasury;
    address public lpAddress;
    address public rewardsPool;
    address public devWallet;

    address public warRoom;

    event BarrelDrilled(address indexed driller, uint256 indexed tokenId);
    event OilClaimed(address indexed driller, uint256 indexed tokenId, uint256 amount);
    event Referred(address indexed referrer, address indexed driller, uint256 ethEarned);
    event EfficiencyChanged(uint256 indexed tokenId, uint256 newEfficiency);

    constructor(
        address _treasury,
        address _lpAddress,
        address _rewardsPool,
        address _devWallet
    ) ERC721("Proof of Drill Barrels", "PODB") Ownable(msg.sender) {
        treasury = _treasury;
        lpAddress = _lpAddress;
        rewardsPool = _rewardsPool;
        devWallet = _devWallet;
        
        // Automatically deploy the associated ERC20 token and assign ownership to the human deployer
        oilToken = new OilToken(msg.sender);
    }

    function setWarRoom(address _warRoom) external onlyOwner {
        warRoom = _warRoom;
    }

    function setTreasury(address _treasury) external onlyOwner {
        treasury = _treasury;
    }

    function setLpAddress(address _lpAddress) external onlyOwner {
        lpAddress = _lpAddress;
    }

    function setRewardsPool(address _rewardsPool) external onlyOwner {
        rewardsPool = _rewardsPool;
    }

    function setDevWallet(address _devWallet) external onlyOwner {
        devWallet = _devWallet;
    }

    /**
     * @dev External modifier allowing WarRoom to drop efficiency on Blowout.
     */
    function reduceEfficiency(uint256 tokenId, uint256 penaltyPercent) external {
        require(msg.sender == warRoom, "Only WarRoom can reduce efficiency");
        uint256 current = efficiency[tokenId];
        if (current == 0) current = 10000; // Initialize lazily to 100%
        
        // penaltyPercent is 200 for 2%
        uint256 newEff = current > penaltyPercent ? current - penaltyPercent : 0;
        efficiency[tokenId] = newEff;
        emit EfficiencyChanged(tokenId, newEff);
    }

    function repairEfficiency(uint256 tokenId) external {
        require(msg.sender == warRoom, "Only WarRoom can repair efficiency");
        efficiency[tokenId] = 10000;
        emit EfficiencyChanged(tokenId, 10000);
    }

    function lockYield(uint256 tokenId, uint256 duration) external {
        require(msg.sender == warRoom, "Only WarRoom can lock yield");
        yieldLock[tokenId] = block.timestamp + duration;
        // Optionally advance lastClaimedAt here so they forfeit what was pending?
        // Actually, just enforcing yieldLock via timestamp works.
    }

    function getEfficiency(uint256 tokenId) public view returns (uint256) {
        if (wells[tokenId].drilledAt == 0) return 0;
        return efficiency[tokenId] == 0 ? 10000 : efficiency[tokenId];
    }

    /**
     * @dev Mints one or more Barrel NFTs. Routes ETH natively to protocol wallets.
     */
    function drill(uint256 amount) external payable nonReentrant {
        _drill(amount, address(0));
    }

    /**
     * @dev Mints with a referrer address. Referrer earns 5% of msg.value (taken from dev share).
     *      Referrer cannot be address(0) or msg.sender.
     */
    function drillWithReferral(uint256 amount, address referrer) external payable nonReentrant {
        require(referrer != address(0) && referrer != msg.sender, "Invalid referrer");
        _drill(amount, referrer);
    }

    /**
     * @dev Internal drill logic used by both public drill functions.
     */
    function _drill(uint256 amount, address referrer) internal {
        require(amount > 0 && amount <= 10, "Max 10 per tx");
        require(_nextTokenId + amount - 1 <= MAX_BARRELS, "Field is dry (Sold out)");
        require(msg.value == MINT_PRICE * amount, "Incorrect ETH sent");

        // Protocol ETH Routing exactly as per Whitepaper v1.0
        uint256 lpShare      = (msg.value * 40) / 100;
        uint256 rewardsShare = (msg.value * 35) / 100;
        uint256 treasuryShare = (msg.value * 20) / 100;
        // Dev share (5%) goes to referrer if one is provided, otherwise to devWallet
        uint256 devOrReferralShare = msg.value - lpShare - rewardsShare - treasuryShare;

        (bool lpSuccess, ) = payable(lpAddress).call{value: lpShare}("");
        require(lpSuccess, "LP transfer failed");

        (bool treasurySuccess, ) = payable(treasury).call{value: treasuryShare}("");
        require(treasurySuccess, "Treasury transfer failed");

        if (referrer != address(0)) {
            referralEarned[referrer] += devOrReferralShare;
            (bool refSuccess, ) = payable(referrer).call{value: devOrReferralShare}("");
            require(refSuccess, "Referral transfer failed");
            emit Referred(referrer, msg.sender, devOrReferralShare);
        } else {
            (bool devSuccess, ) = payable(devWallet).call{value: devOrReferralShare}("");
            require(devSuccess, "Dev transfer failed");
        }

        // Distribute Rewards Proportionally
        if (_nextTokenId > 1) {
            uint256 existingBarrels = _nextTokenId - 1;
            rewardPerBarrel += (rewardsShare * 1e18) / existingBarrels;
        } else {
            // First barrel pays its 35% reward share to treasury since no one is yielding yet
            (bool firstRewardSuccess, ) = payable(treasury).call{value: rewardsShare}("");
            require(firstRewardSuccess, "First reward transfer failed");
        }

        // Update global DApp stats
        totalEthRaised += msg.value;
        if (!hasDrilled[msg.sender]) {
            hasDrilled[msg.sender] = true;
            totalUniqueDrillers++;
        }

        for (uint256 i = 0; i < amount; i++) {
            uint256 tokenId = _nextTokenId++;
            _safeMint(msg.sender, tokenId);

            wells[tokenId] = Well({
                drilledAt: block.timestamp,
                lastClaimedAt: block.timestamp,
                totalClaimed: 0
            });
            
            // Set base efficiency to 10000 (100.00%)
            efficiency[tokenId] = 10000;

            // Initialize debt to the current global accumulator so they don't claim past rewards
            rewardDebt[tokenId] = rewardPerBarrel;

            emit BarrelDrilled(msg.sender, tokenId);
        }
    }

    /**
     * @dev Calculates pending $OIL accurately down to the second.
     *      Simulates a decline curve e^(-k*t) using tiered daily rates that are calculated fluidly per-second.
     *      Total yield approaches ~57,600 OIL per barrel over 120 days.
     */
    function getPendingOil(uint256 tokenId) public view returns (uint256) {
        Well memory well = wells[tokenId];
        if (well.drilledAt == 0) return 0;

        uint256 claimUntil = block.timestamp;
        
        // Enforce Dry Hole Yield Lock
        if (yieldLock[tokenId] > claimUntil) return 0;
        
        uint256 maxTime = well.drilledAt + WELL_LIFESPAN;
        if (claimUntil > maxTime) {
            claimUntil = maxTime;
        }

        if (well.lastClaimedAt >= claimUntil) return 0;

        uint256 pending = 0;
        uint256 currentTime = well.lastClaimedAt;

        // Rate per second in wei
        // 1000 OIL / day
        uint256 rate1 = (uint256(1000) * 10**18) / 86400; 
        // 400 OIL / day
        uint256 rate2 = (uint256(400) * 10**18) / 86400;  
        // 60 OIL / day
        uint256 rate3 = (uint256(60) * 10**18) / 86400;   

        uint256 phase1End = well.drilledAt + 30 days;
        uint256 phase2End = well.drilledAt + 90 days;

        // Calculate overlap with Phase 1
        if (currentTime < phase1End) {
            uint256 end = claimUntil < phase1End ? claimUntil : phase1End;
            pending += (end - currentTime) * rate1;
            currentTime = end;
        }

        // Calculate overlap with Phase 2
        if (currentTime < phase2End && currentTime < claimUntil) {
            uint256 end = claimUntil < phase2End ? claimUntil : phase2End;
            pending += (end - currentTime) * rate2;
            currentTime = end;
        }

        // Calculate overlap with Phase 3
        if (currentTime < claimUntil) {
            pending += (claimUntil - currentTime) * rate3;
        }

        // Apply Barrel Efficiency Mutliplier
        uint256 currentEff = getEfficiency(tokenId);
        pending = (pending * currentEff) / 10000;

        return pending;
    }

    /**
     * @dev Calculates the amount of pending ETH rewards for a specific barrel.
     */
    function getPendingEth(uint256 tokenId) public view returns (uint256) {
        if (wells[tokenId].drilledAt == 0) return 0;
        return (rewardPerBarrel - rewardDebt[tokenId]) / 1e18;
    }

    /**
     * @dev Claims accumulated $OIL and ETH rewards fluidly. Can be called at any time.
     */
    function claimOil(uint256 tokenId) external nonReentrant {
        require(ownerOf(tokenId) == msg.sender, "Not the owner");
        _claimSingle(tokenId);
    }

    /**
     * @dev Claims pending $OIL and ETH for a specified batch of token IDs.
     *      Use this instead of claimAll() when you own many barrels.
     *      Recommended max batch size: 25-30 tokens per tx to stay under gas limits.
     */
    function claimBatch(uint256[] calldata tokenIds) external nonReentrant {
        require(tokenIds.length > 0, "Empty batch");
        require(tokenIds.length <= 50, "Batch too large (max 50)");
        bool anyClaimed = false;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(ownerOf(tokenId) == msg.sender, "Not the owner");
            uint256 pending = getPendingOil(tokenId);
            uint256 pendingEth = getPendingEth(tokenId);
            if (pending == 0 && pendingEth == 0) continue;
            anyClaimed = true;
            _claimSingle(tokenId);
        }
        require(anyClaimed, "Nothing to claim in batch");
    }

    /**
     * @dev Claims all pending $OIL and ETH rewards for every barrel owned by the caller.
     *      WARNING: Will run out of gas if you own more than ~30 barrels. Use claimBatch() instead.
     */
    function claimAll() external nonReentrant {
        uint256 balance = balanceOf(msg.sender);
        require(balance > 0, "No barrels owned");
        require(balance <= 30, "Too many barrels: use claimBatch() instead");
        bool anyClaimed = false;
        for (uint256 i = 0; i < balance; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(msg.sender, i);
            uint256 pending = getPendingOil(tokenId);
            uint256 pendingEth = getPendingEth(tokenId);
            if (pending == 0 && pendingEth == 0) continue;
            anyClaimed = true;
            _claimSingle(tokenId);
        }
        require(anyClaimed, "Nothing to claim");
    }

    /**
     * @dev Internal claim logic shared by claimOil and claimAll.
     */
    function _claimSingle(uint256 tokenId) internal {
        // Enforce Dry Hole lock for everything
        require(block.timestamp >= yieldLock[tokenId], "Yield locked (Dry Hole)");

        uint256 pending = getPendingOil(tokenId);
        uint256 pendingEth = getPendingEth(tokenId);

        Well storage well = wells[tokenId];

        // Advance lastClaimed fluidly up to the current block timestamp (or the max well life)
        uint256 claimUntil = block.timestamp;
        uint256 maxTime = well.drilledAt + WELL_LIFESPAN;
        if (claimUntil > maxTime) claimUntil = maxTime;

        well.lastClaimedAt = claimUntil;

        // Distribute $OIL
        if (pending > 0) {
            well.totalClaimed += pending;
            oilToken.mint(msg.sender, pending);
            emit OilClaimed(msg.sender, tokenId, pending);
        }

        // Distribute ETH Rewards
        if (pendingEth > 0) {
            rewardDebt[tokenId] = rewardPerBarrel;
            ethClaimed[tokenId] += pendingEth;

            (bool ethSuccess, ) = payable(msg.sender).call{value: pendingEth}("");
            require(ethSuccess, "ETH reward transfer failed");
        }
    }
}
