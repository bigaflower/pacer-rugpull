// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ERC20} from "solady/tokens/ERC20.sol";
import {ReentrancyGuard} from "solady/utils/ReentrancyGuard.sol";
import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {IUniswapV4Router04} from "v4-router/interfaces/IUniswapV4Router04.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {Initializable} from "solady/utils/Initializable.sol";
import {UUPSUpgradeable} from "solady/utils/UUPSUpgradeable.sol";
import {Ownable} from "solady/auth/Ownable.sol";
import {LibClone} from "solady/utils/LibClone.sol";
import "./Interfaces.sol";

/// @title StrategicReserve - An ERC20 token that constantly churns NFTs from a collection
/// @author Strategic Reserve (https://strategicreserve.fun/)
/// @notice This contract implements an ERC20 token backed by NFTs from a specific collection
///         Users can trade the token on Uniswap V4, and the contract uses trading fees to buy and sell NFTs
/// @dev Uses ERC1967 proxy pattern with immutable args for gas-efficient upgrades
contract StrategicReserve is Initializable, UUPSUpgradeable, Ownable, ReentrancyGuard, ERC20 {
    //
    //    _____ __             __             _
    //   / ___// /__________ _/ /____  ____ _(_)____
    //   \__ \/ __/ ___/ __ `/ __/ _ \/ __ `/ / ___/
    //  ___/ / /_/ /  / /_/ / /_/  __/ /_/ / / /__
    // /____/\__/_/   \__,_/\__/\___/\__, /_/\___/
    //    / __ \___  ________  _____/____/___
    //   / /_/ / _ \/ ___/ _ \/ ___/ | / / _ \
    //  / _, _/  __(__  )  __/ /   | |/ /  __/
    // /_/ |_|\___/____/\___/_/    |___/\___/

    /* ═══════════════════════════════════════════════════ */
    /*                      CONSTANTS                      */
    /* ═══════════════════════════════════════════════════ */
    /// @notice The name of the ERC20 token
    string tokenName;
    /// @notice The symbol of the ERC20 token
    string tokenSymbol;
    /// @notice Address of the Uniswap V4 hook contract
    address public hookAddress;
    /// @notice The NFT collection this reserve is tied to
    IERC721 public collection;
    /// @notice Maximum token supply (1 billion tokens)
    uint256 public constant MAX_SUPPLY = 1_000_000_000 * 1e18;
    /// @notice Dead address for burning tokens
    address public constant DEAD_ADDR = 0x000000000000000000000000000000000000dEaD;
    /// @notice Contract version for upgrade tracking
    uint256 public constant VERSION = 1;

    /* ═══════════════════════════════════════════════════ */
    /*                   STATE VARIABLES                   */
    /* ═══════════════════════════════════════════════════ */
    /// @notice Multiplier for NFT resale price (in basis points, e.g., 1200 = 1.2x)
    uint256 public priceMultiplier;
    /// @notice Days for price to decay from priceMultiplier to decayFloor
    uint256 public decayDays;
    /// @notice Floor multiplier after full decay (e.g., 300 = 0.3x, can be below purchase price)
    uint256 public decayFloor;
    /// @notice NFT purchase history for sale listings
    struct NFTPurchase {
        uint128 price;          // Price paid for NFT
        uint40 time;            // Timestamp when purchased
        uint16 priceMultiplier; // priceMultiplier at purchase
        uint16 decayFloor;      // decayFloor at purchase
        uint16 decayDays;       // decayDays at purchase
    }
    /// @notice Mapping of NFT token IDs to their purchase data
    mapping(uint256 => NFTPurchase) private _nftPurchaseData;
    /// @notice Current accumulated fees available for NFT purchases
    uint256 public currentFees;
    /// @notice ETH accumulated from NFT sales, waiting to be used for token buyback
    uint256 public ethToTwap;
    /// @notice Amount of ETH to use per TWAP buyback operation
    uint256 public twapIncrement;
    /// @notice Number of blocks to wait between TWAP operations
    uint256 public twapDelayInBlocks;
    /// @notice Block number of the last TWAP operation
    uint256 public lastTwapBlock;
    /// @notice Block number when the last NFT was bought
    uint256 public lastBuyBlock;
    /// @notice ETH amount increment for maximum buy price calculation
    uint256 public buyIncrement;
    /// @notice Last successful NFT purchase price (for adaptive floor calculation)
    uint256 public lastBuyPrice;
    /// @notice Starting % of last buy price after reset (basis points, default: 7000 = 70%)
    uint256 public floorResetPct;
    /// @notice Maximum allowed purchase as % of last buy (basis points, default: 12500 = 125%)
    uint256 public maxBuyCapPct;
    /// @notice Toggle to disable adaptive floor protection (defaults to false = enabled)
    bool public disableAdaptiveFloor;
    /// @notice Whether marketplace enforcement is enabled for buyTargetNFT calls
    bool public isMarketEnforced;
    /// @notice Operation blocking mode (0=disabled, 1=blockDuringBuy, 2=blockDuringSell, 3=both)
    uint8 public opBlock;
    /// @notice Active operation type for cross-contract attack prevention
    enum ActiveOp { NONE, BUY, SELL, BUYOWN }
    ActiveOp private _activeOp;
    /// @notice Permission level for untracked fee recovery (0=factory, 1=factory+strategists, 2=public)
    uint8 public recoverFeesAllowance;
    /// @notice Marketplace fee in basis points (e.g., 100 = 1%, max 1250 = 12.5%)
    mapping(address => uint256) public marketplaceFee;

    /// @notice Maximum number of strategists allowed to prevent unbounded array growth
    uint256 public constant MAX_STRATEGISTS = 50;
    /// @notice Maximum number of guardians allowed to prevent unbounded array growth
    uint256 public constant MAX_GUARDIANS = 10;
    /// @notice List of authorized strategists
    address[] public strategists;
    /// @notice Level for each strategist (0=none, 1=level1, 2=level2)
    mapping(address => uint8) public strategistLevel;
    /// @notice List of authorized guardians (can only call clearAllStrategists)
    address[] public guardians;
    /// @notice Quick guardian lookup
    mapping(address => bool) public isGuardian;
    /// @notice When true, allows public to buy own NFTs. Default false = strategists only.
    bool public isPubSelfBuy;
    /// @notice When true, allows public to call nftSync. Default false = factory/strategists only.
    bool public isPubSync;

    /// @notice Restricts NFT purchases to specific token IDs when enabled
    bool public isIdRestricted;
    /// @notice Mapping of allowed token IDs for attribute-restricted collections
    mapping(uint256 => bool) public allowedTokenId;
    /// @notice Addresses authorized to distribute tokens freely (airdrops, team allocations)
    mapping(address => bool) public isDistributor;

    /// @notice Minimum reserve vault fee (10%)
    uint128 private constant MIN_RESVAULT_FEE = 1000;
    /// @notice Maximum reserve vault fee (20%)
    uint128 private constant MAX_RESVAULT_FEE = 2000;
    /// @notice Maximum reserve fee cap (adjustable)
    uint128 public maxReserveFee;
    /// @notice Reserve vault fee percentage in bips up to max
    uint128 public reserveVaultFee;

    /// @notice Address to receive community fee split
    address public communityAddr;
    /// @notice Community fee percentage in bips (additive on top of min vault fee)
    uint128 public communityFee;
    /// @notice Whether custom fees (vault + community) are permanently locked
    bool public isFeesLocked;

    /// @notice Fee handling modes for EOA transfer taxation
    enum FeeHandlingMode {
        BURN,     // 0: Send tokens to dead address (permanent removal) - DEFAULT
        RESERVE   // 1: Send tokens to destination address for safekeeping
    }
    /// @notice Fee handling mode for EOA transfers (BURN=0, RESERVE=1)
    FeeHandlingMode public eoaFeeHandler;
    /// @notice Destination address for RESERVE mode EOA fees
    address public eoaFeeAddr;

    /// @notice Unified time-based state tracking for all major changes
    struct TimeState {
        // Fee locking (2-stage with snapshot validation)
        uint40 feeInit;           // Timestamp when fee lock Stage 1 initiated
        uint16 feeVault;          // Vault fee at lock initiation for validation
        uint16 feeCommunity;      // Community fee at lock initiation for validation
        // Community address change (simple 15-day wait)
        uint40 communityInit;     // Timestamp when community addr change initiated
        address pendingCommunity; // Pending community address
        // Vault address change (simple 30-day wait)
        uint40 vaultInit;         // Timestamp when vault addr change initiated
        address pendingVault;     // Pending vault address
        // Deployment & pricing tracking
        uint40 pricingTimeLock;   // Timestamp until which pricing params are locked
    }
    TimeState public timeState;

    /// @notice When true, upgrades are PERMANENTLY blocked
    bool public upgradeBlock;
    /// @notice Timestamp when upgrade lockout was initiated (for 2-stage safety)
    uint256 public upgradeBlockInitTime;

    /// @notice Storage gap for future upgrades (prevents storage collisions)
    uint256[50] private __gap;

    /* ═══════════════════════════════════════════════════ */
    /*                    CUSTOM EVENTS                    */
    /* ═══════════════════════════════════════════════════ */
    /// @notice Emitted when the protocol buys an NFT
    event NFTBoughtByProtocol(uint256 indexed tokenId, uint256 purchasePrice);
    /// @notice Emitted when the protocol sells an NFT
    event NFTSoldByProtocol(uint256 indexed tokenId, uint256 price, address buyer);
    /// @notice Emitted when nftSync reconciles NFT listing status
    event NFTResync(uint256 indexed tokenId, uint256 listPrice);
    /// @notice Emitted when transfer allowance is increased by the hook
    event AllowanceIncreased(uint256 amount);
    /// @notice Emitted when transfer allowance is spent
    event AllowanceSpent(address indexed from, address indexed to, uint256 amount);
    /// @notice Emitted when the contract implementation is upgraded
    event ContractUpgraded(address indexed oldImplementation, address indexed newImplementation, uint256 version);
    /// @notice Emitted when untracked ETH is recovered
    event UntrackedFeesRecovered(uint256 amount, address indexed caller);
    /// @notice Emitted when recovery allowance mode is updated
    event RecoverFeesAllowanceUpdated(uint8 mode);
    /// @notice Emitted when public self-buy is enabled/disabled
    event PublicSelfBuyUpdated(bool enabled);
    /// @notice Emitted when strategist level is updated
    event StrategistUpdated(address indexed strategist, uint8 level);
    /// @notice Emitted when all strategists are nuked
    event NukedStrategists();
    /// @notice Emitted when guardian status is updated
    event GuardianUpdated(address indexed guardian, bool status);
    /// @notice Emitted when allowed token IDs are updated for attribute restrictions
    event AllowedTokenIdsUpdated(uint256[] tokenIds, bool status);
    /// @notice Emitted when a distributor's authorization status is updated
    event DistributorUpdated(address indexed distributor, bool status);
    /// @notice Emitted when custom fees are updated
    event CustomFeesUpdated(uint128 oldVaultFee, uint128 newVaultFee, uint128 oldCommunityFee, uint128 newCommunityFee);
    /// @notice Emitted for all address changes (community, vault, etc)
    event AddressChange(string message, address addr);
    /// @notice Emitted when custom fees are permanently locked
    event FeesLocked(uint128 lockedVaultFee, uint128 lockedCommunityFee);
    /// @notice Emitted during fee lock process
    event FeeLockProcess(string stage);
    /// @notice Emitted during upgrade lock process
    event UpgradeLockProcess(string stage);
    /// @notice Emitted when floor protection parameters are adjusted
    event FloorProtectAdjusted(
        uint256 buyIncrement,
        uint256 maxBuyCapPct,
        uint256 floorResetPct,
        bool disableAdaptiveFloor
    );
    /// @notice Emitted when marketplace fee is set for an address
    event MarketplaceFeeSet(address indexed marketplace, uint256 feeBips);

    /* ═══════════════════════════════════════════════════ */
    /*                    CUSTOM ERRORS                    */
    /* ═══════════════════════════════════════════════════ */
    /// @notice NFT is not currently for sale
    error NFTNotForSale();
    /// @notice Sent ETH amount is less than the NFT sale price
    error NFTPriceTooLow();
    /// @notice Price multiplier is outside valid range
    error InvalidMultiplier();
    /// @notice Decay days outside valid range
    error InvalidDecayDays();
    /// @notice Floor price cannot exceed starting multiplier
    error FloorAboveStart();
    /// @notice Pricing params change invalid
    error InvalidPricingState();
    /// @notice No ETH available for TWAP operations
    error NoETHToTwap();
    /// @notice Not enough blocks have passed since last TWAP
    error TwapDelayNotMet();
    /// @notice Not enough ETH in fees to make purchase
    error NotEnoughEth();
    /// @notice Purchase price exceeds time-based maximum
    error PriceTooHigh();
    /// @notice Caller is not the factory contract
    error NotFactory();
    /// @notice Contract already owns this NFT
    error NFTAlreadyOwnByReserve();
    /// @notice External call didn't result in NFT acquisition
    error NeedToBuyNFT();
    /// @notice Contract doesn't own the specified NFT
    error NotNFTOwner();
    /// @notice Caller is not the authorized hook contract
    error NotHook();
    /// @notice Invalid NFT collection address
    error InvalidCollection();
    /// @notice External call to marketplace failed
    error ExternalCallFailed(bytes reason);
    /// @notice Invalid target address for external call
    error InvalidTarget();
    /// @notice Token transfer not authorized
    error InvalidTransfer();
    /// @notice Marketplace or function signature not whitelisted
    error InvalidMarketOrSignature();
    /// @notice Another operation is currently in progress
    error OperationInProgress();
    /// @notice Invalid opBlock mode (must be 0-3)
    error InvalidMode();
    /// @notice NFT was not successfully transferred from contract
    error NFTNotTransferred();
    /// @notice Caller not authorized for this operation
    error NotAuthorized();
    /// @notice Too many strategists (exceeds MAX_STRATEGISTS limit)
    error TooManyStrategists();
    /// @notice Too many guardians (exceeds MAX_GUARDIANS limit)
    error TooManyGuardians();
    /// @notice Token does not meet collection's attribute requirements
    error InvalidAttribute();
    /// @notice Custom fee exceeds maximum or violates constraints
    error InvalidCustomFee();
    /// @notice Cannot modify locked custom fees
    error CustomFeesLocked();
    /// @notice Lock process active - cannot change fees or re-initiate yet
    error LockProcessActive();
    /// @notice Must wait 24 hours before finalizing lock
    error LockDelayNotMet();
    /// @notice Upgrades have been permanently locked out
    error NoLongerUpgradeable();
    /// @notice Must wait 24 hours before finalizing upgrade lockout
    error LockoutDelayNotMet();
    /// @notice Upgrade lockout already active
    error AlreadyLockedOut();
    /// @notice Token name or symbol is empty
    error EmptyTokenField();
    /// @notice Implementation address is invalid
    error InvalidImplementation();
    /// @notice Buy increment is outside valid range
    error IncrementOutOfRange();
    /// @notice Max buy cap percentage is too low
    error CapTooLow();
    /// @notice Floor reset percentage is too high
    error ResetPercentTooHigh();
    /// @notice Strategist level is invalid
    error InvalidStrategistLevel();
    /// @notice Collection is not ID restricted
    error CollectionNotIdRestricted();
    /// @notice Timelock period not met
    error TimelockNotMet();
    /// @notice Hook handles first-time vault setup
    error HookHandlesFirstSetup();
    /// @notice V1 reserve uses fixed fee cap
    error V1UsesFixedCap();
    /// @notice Maximum fee value is invalid
    error InvalidMaxFee();
    /// @notice Cannot use nftSync before first NFT purchase
    error CannotSyncYet();
    /// @notice Marketplace fee exceeds maximum (12.5%)
    error InvalidMarketplaceFee();
    /// @notice Requested fee exceeds whitelisted maximum for marketplace
    error FeeExceedsMax();

    /* ═══════════════════════════════════════════════════ */
    /*                     CONSTRUCTOR                     */
    /* ═══════════════════════════════════════════════════ */
    /// @notice Constructor disables initializers to prevent implementation contract initialization
    /// @dev This is required for the proxy pattern to work correctly
    constructor() {
        _disableInitializers();
    }

    /// @notice Initializes the contract with required addresses and permissions
    /// @param _collection Address of the NFT collection contract
    /// @param _hook Address of the StrategicHook contract
    /// @param _tokenName Name of the token
    /// @param _tokenSymbol Symbol of the token
    /// @param _buyIncrement Buy increment for the token
    /// @param _owner Owner of the contract
    /// @param _isIdRestricted Enable attribute-based token ID restrictions
    /// @param _upgradeBlock When true, upgrades are immediately and permanently blocked
    function initialize(
        address _collection,
        address _hook,
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _buyIncrement,
        address _owner,
        bool _isIdRestricted,
        bool _upgradeBlock
    ) external initializer {
        if (_collection == address(0)) revert InvalidCollection();
        if (bytes(_tokenName).length == 0) revert EmptyTokenField();
        if (bytes(_tokenSymbol).length == 0) revert EmptyTokenField();

        collection = IERC721(_collection);
        hookAddress = _hook;
        tokenName = _tokenName;
        tokenSymbol = _tokenSymbol;
        lastBuyBlock = block.number;
        buyIncrement = _buyIncrement;
        isIdRestricted = _isIdRestricted;
        upgradeBlock = _upgradeBlock;

        // Initialize owner without validation in case we want to disable upgradeability
        _initializeOwner(_owner);

        // Initialize state variables that have default values
        priceMultiplier = 1200; // 1.2x
        decayFloor = 1100;      // 1.1x floor after full decay
        decayDays = 365;        // 1 year decay period
        twapIncrement = 1 ether;
        twapDelayInBlocks = 1;
        isMarketEnforced = true; // Enable marketplace enforcement by default

        // Phase 2 adaptive floor protection defaults
        floorResetPct = 7000;   // Start at 70% of last buy
        maxBuyCapPct = 12500;   // Cap at 125% of last buy (25% buffer)
        maxReserveFee = 1600;   // Default cap for non-V1 (16%)

        _mint(factory(), MAX_SUPPLY);
    }

    /// @notice Restricts function access to the Factory only
    modifier onlyFactory() {
        if (msg.sender != factory()) revert NotFactory();
        _;
    }

    /// @notice Restricts function access to Factory or authorized guardians
    modifier onlyFactoryGuardian() {
        if (msg.sender != factory() && !isGuardian[msg.sender]) {
            revert NotAuthorized();
        }
        _;
    }

    /// @notice Restricts function access to Factory, strategists (level>=1), or public if flag enabled
    /// @param publicFlag Storage variable indicating if public access is enabled for this function
    /// @dev Level2 strategists inherit all strategist permissions
    modifier onlyFactoryStratPub(bool publicFlag) {
        if (msg.sender != factory() && strategistLevel[msg.sender] < 1 && !publicFlag) {
            revert NotAuthorized();
        }
        _;
    }

    /// @notice Restricts function access to Factory, level2 strategists, or public if flag enabled
    /// @param publicFlag Storage variable indicating if public access is enabled for this function
    modifier onlyFactoryStratL2Pub(bool publicFlag) {
        if (msg.sender != factory() && strategistLevel[msg.sender] < 2 && !publicFlag) {
            revert NotAuthorized();
        }
        _;
    }

    /// @notice Restricts function access to Factory or Level 2 strategists
    modifier onlyFactoryStratL2() {
        if (msg.sender != factory() && strategistLevel[msg.sender] < 2) {
            revert NotAuthorized();
        }
        _;
    }

    /// @notice Restricts function access to Factory or Reserve Owner
    modifier onlyFactoryResOwner() {
        address reserveOwner = owner();
        if (msg.sender != factory() && msg.sender != reserveOwner) {
            revert NotAuthorized();
        }
        _;
    }

    /// @notice Authorizes contract upgrades (UUPS pattern)
    /// @param newImplementation Address of the new implementation contract
    /// @dev Only callable by contract owner, validates implementation is a contract
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {
        if (upgradeBlock) revert NoLongerUpgradeable();
        if (newImplementation == address(0)) revert InvalidImplementation();
        if (newImplementation.code.length == 0) revert InvalidImplementation();
        emit ContractUpgraded(address(this), newImplementation, VERSION);
    }

    /// @notice Returns the current implementation address
    /// @return result The address of the current implementation contract
    /// @dev Reads from the ERC1967 implementation slot
    function getImplementation() external view returns (address result) {
        assembly {
            result := sload(_ERC1967_IMPLEMENTATION_SLOT)
        }
    }

    /// @notice Returns the name of the token
    /// @return The token name as a string
    function name() public view override returns (string memory) {
        return tokenName;
    }

    /// @notice Returns the symbol of the token
    /// @return The token symbol as a string
    function symbol() public view override returns (string memory) {
        return tokenSymbol;
    }

    /// @notice Updates the hook address
    /// @dev Can only be called by Factory (prevents malicious hook redirection)
    /// @param _hookAddress New hook address
    function updateHookAddress(address _hookAddress) external onlyFactory {
        hookAddress = _hookAddress;
    }

    /// @notice Updates the name of the token
    /// @dev Can only be called by the factory
    /// @param _tokenName New name for the token
    function updateName(string memory _tokenName) external onlyFactory {
        tokenName = _tokenName;
    }

    /// @notice Updates the symbol of the token
    /// @dev Can only be called by the factory
    /// @param _tokenSymbol New symbol for the token
    function updateSymbol(string memory _tokenSymbol) external onlyFactory {
        tokenSymbol = _tokenSymbol;
    }

    /// @notice Configure pricing parameters
    /// @param _multiplier Starting sale multiplier (1100-10000, e.g., 1200 = 1.2x)
    /// @param _floor Minimum multiplier after decay (e.g., 300 = 30%, can be < 1000)
    /// @param _days Days to decay from multiplier to floor (180-500)
    /// @param _lockUntil Timestamp until which pricing params are locked (0 = skip update, keeps existing lock)
    /// @dev Only callable by factory
    function setPricingParams(uint256 _multiplier, uint256 _floor, uint256 _days, uint256 _lockUntil)
        external onlyFactory
    {
        // Check if currently locked
        if (block.timestamp < timeState.pricingTimeLock) revert InvalidPricingState();

        // Validate parameters
        if (_multiplier < 1100 || _multiplier > 10000) revert InvalidMultiplier();
        if (_days < 180 || _days > 500) revert InvalidDecayDays();
        if (_floor > _multiplier) revert FloorAboveStart();

        // Update pricing
        priceMultiplier = _multiplier;
        decayFloor = _floor;
        decayDays = _days;

        // Set new lock expiration (0 = skip, keeps existing lock)
        if (_lockUntil > 0) {
            if (_lockUntil > 35_000_000_000) revert InvalidPricingState(); // Sanity check
            timeState.pricingTimeLock = uint40(_lockUntil);
        }
    }

    /// @notice Enables or disables marketplace enforcement for buyTargetNFT
    /// @param _enable True to enable marketplace enforcement, false to disable
    /// @dev Only callable by factory
    function setMarketEnforce(bool _enable) external onlyFactory {
        isMarketEnforced = _enable;
    }

    /// @notice Sets the operation blocking mode
    /// @param _mode Operation blocking mode (0=disabled, 1=blockDuringBuy, 2=blockDuringSell, 3=both)
    /// @dev Only callable by factory
    function setOpBlock(uint8 _mode) external onlyFactory {
        if (_mode > 3) revert InvalidMode();
        opBlock = _mode;
    }

    /// @notice Sets the permission level for untracked fee recovery
    /// @param _mode 0=factory only, 1=factory+strategists, 2=public
    /// @dev Only callable by factory
    function setRecoverFeesAllowance(uint8 _mode) external onlyFactory {
        if (_mode > 2) revert InvalidMode();
        recoverFeesAllowance = _mode;
        emit RecoverFeesAllowanceUpdated(_mode);
    }

    /// @notice PERMANENTLY lockout all future upgrades (two-stage: 24h delay)
    /// @dev Stage 1: Call once to initiate 24h timer. Stage 2: Call again after 24h to finalize FOREVER.
    /// @dev Callable by Factory or Reserve Owner. Once finalized, NO ONE can ever upgrade this contract again.
    function lockoutUpgrades() external onlyFactoryResOwner {
        if (upgradeBlock) revert AlreadyLockedOut();

        // Stage 1: Initiate 24h delay
        if (upgradeBlockInitTime == 0) {
            upgradeBlockInitTime = block.timestamp;
            emit UpgradeLockProcess("Stage 1: 24-hour delay initiated");
            return;
        }

        // Stage 2: Finalize after 24h
        if (block.timestamp < upgradeBlockInitTime + 24 hours) {
            revert LockoutDelayNotMet();
        }

        upgradeBlock = true;
        delete upgradeBlockInitTime;
        emit UpgradeLockProcess("Stage 2: Permanent lockout finalized");
    }

    /// @notice Adjustment of floor protection parameters
    /// @dev Pass 0 to skip updating a parameter (except _disableAdaptive which always sets)
    /// @param _buyIncrement Per-block growth rate in wei (0=skip)
    /// @param _maxBuyCapPct Maximum allowed purchase as % of last buy in basis points (0=skip)
    /// @param _floorResetPct Starting % of last buy price in basis points (0=skip, max: 9000)
    /// @param _disableAdaptive Toggle adaptive floor (always sets, no skip)
    function adjustFloorProtect(
        uint256 _buyIncrement,
        uint256 _maxBuyCapPct,
        uint256 _floorResetPct,
        bool _disableAdaptive
    ) external onlyFactory {
        // Update per-block growth increment
        if (_buyIncrement > 0) {
            if (_buyIncrement < 0.000001 ether || _buyIncrement > 100 ether) revert IncrementOutOfRange();
            buyIncrement = _buyIncrement;
        }

        // Update max buy cap (% of last buy)
        if (_maxBuyCapPct > 0) {
            if (_maxBuyCapPct < 11000) revert CapTooLow();
            maxBuyCapPct = _maxBuyCapPct;
        }

        // Update floor reset % - must be <= 90%
        if (_floorResetPct > 0) {
            if (_floorResetPct > 9000) revert ResetPercentTooHigh();
            floorResetPct = _floorResetPct;
        }

        // Toggle adaptive floor protection
        disableAdaptiveFloor = _disableAdaptive;

        // Emit event with current state values
        emit FloorProtectAdjusted(buyIncrement, maxBuyCapPct, floorResetPct, disableAdaptiveFloor);
    }

    /// @notice Enable or disable public access to buyOwnNFT
    /// @param enabled true = public allowed, false = strategists only
    function setPubSelfBuy(bool enabled) external onlyFactory {
        isPubSelfBuy = enabled;
        emit PublicSelfBuyUpdated(enabled);
    }

    /// @notice Enable or disable public access to nftSync
    /// @param enabled true = public allowed, false = factory/strategists only
    function setPubSync(bool enabled) external onlyFactory {
        isPubSync = enabled;
    }

    /// @notice Set maximum marketplace fee allowed for whitelisted address
    /// @param marketplace Address to receive fees (e.g., OpenSea fee collector)
    /// @param feeBips Maximum fee in basis points (100 = 1%, max 1250 = 12.5%)
    /// @dev Only callable by Factory. Set to 0 to remove marketplace from whitelist. Actual fee is determined by requestedFeeBips at sale time.
    function setMarketplaceFee(address marketplace, uint256 feeBips) external onlyFactory {
        if (feeBips > 1250) revert InvalidMarketplaceFee();
        marketplaceFee[marketplace] = feeBips;
        emit MarketplaceFeeSet(marketplace, feeBips);
    }

    /// @notice Set or update strategist level
    /// @param strategist Address to update
    /// @param level Strategist level: 0=remove, 1=level1, 2=level2
    function setStrategist(address strategist, uint8 level) external onlyFactory {
        if (level > 2) revert InvalidStrategistLevel();

        if (level > 0 && strategistLevel[strategist] == 0) {
            // Adding new strategist
            if (strategists.length >= MAX_STRATEGISTS) revert TooManyStrategists();
            strategists.push(strategist);
        } else if (level == 0 && strategistLevel[strategist] > 0) {
            // Removing strategist (swap & pop)
            uint256 len = strategists.length;
            for (uint256 i = 0; i < len; i++) {
                if (strategists[i] == strategist) {
                    strategists[i] = strategists[len - 1];
                    strategists.pop();
                    break;
                }
            }
        }

        strategistLevel[strategist] = level;
        emit StrategistUpdated(strategist, level);
    }

    /// @notice Remove all strategists (nuclear option)
    function clearAllStrategists() external onlyFactoryGuardian {
        uint256 len = strategists.length;
        for (uint256 i = 0; i < len; i++) {
            delete strategistLevel[strategists[i]];
        }
        delete strategists;
        emit NukedStrategists();
    }

    /// @notice Add or remove guardian authorization
    /// @param guardian Address to update
    /// @param status true = authorized, false = revoked
    /// @dev Guardians can ONLY call clearAllStrategists() for emergency kill-switch
    function setGuardian(address guardian, bool status) external onlyFactory {
        if (status && !isGuardian[guardian]) {
            // Add guardian - enforce maximum
            if (guardians.length >= MAX_GUARDIANS) revert TooManyGuardians();
            guardians.push(guardian);
            isGuardian[guardian] = true;
            emit GuardianUpdated(guardian, true);
        } else if (!status && isGuardian[guardian]) {
            // Remove guardian (swap & pop)
            uint256 len = guardians.length;
            for (uint256 i = 0; i < len; i++) {
                if (guardians[i] == guardian) {
                    guardians[i] = guardians[len - 1];
                    guardians.pop();
                    break;
                }
            }
            isGuardian[guardian] = false;
            emit GuardianUpdated(guardian, false);
        }
    }

    /// @notice Set allowed token IDs for attribute-restricted collections
    /// @param tokenIds Array of token IDs to update
    /// @param status True to allow, false to disallow
    /// @dev Only callable by factory. Requires isIdRestricted to be enabled
    function setAllowedTokenIds(uint256[] calldata tokenIds, bool status) external onlyFactory {
        if (!isIdRestricted) revert CollectionNotIdRestricted();
        for (uint256 i = 0; i < tokenIds.length; i++) {
            allowedTokenId[tokenIds[i]] = status;
        }
        emit AllowedTokenIdsUpdated(tokenIds, status);
    }

    /// @notice Authorize or revoke distributor status for an address
    /// @param distributor Address to update
    /// @param status True to authorize, false to revoke
    /// @dev Callable by Factory or Reserve Owner. Enables one-way token distribution (airdrops, team allocations)
    function setDistributor(address distributor, bool status) external onlyFactoryResOwner {
        isDistributor[distributor] = status;
        emit DistributorUpdated(distributor, status);
    }

    /// @notice Allocate accumulated reserve tokens to recipient
    /// @param to Recipient address (only used if Factory calls)
    /// @param amount Amount to send (only used if Factory calls)
    /// @dev Factory: sends to 'to' address. Public: sends 100% to StrategicAdvance.handleReserveAlloc()
    function allocReserveTokens(address to, uint256 amount) external {
        if (msg.sender == factory()) {
            require(to != address(0), "Invalid recipient");
            _transfer(address(this), to, amount);
        } else {
            address advance = IStrategicFactory(factory()).getStrategicAdvance(address(this));
            require(advance != address(0), "No Advance contract");
            uint256 balance = balanceOf(address(this));
            _transfer(address(this), advance, balance);
            IStrategicAdvance(advance).handleReserveAlloc(balance);
        }
    }

    /// @notice Set fee handling mode and destination for EOA transfers
    /// @param mode Fee handling mode (BURN=0, RESERVE=1)
    /// @param destination Destination address (only used for RESERVE mode)
    /// @dev Only callable by Factory. BURN is default (mode=0). RESERVE mode sends to destination or Reserve if address(0).
    function setEOAFeeHandling(FeeHandlingMode mode, address destination) external onlyFactory {
        eoaFeeHandler = mode;
        eoaFeeAddr = destination;
    }

    /// @notice Set custom fees (vault + community)
    /// @param _vaultFeeBips New reserve vault fee in basis points (1000-2000 = 10-20%)
    /// @param _communityFeeBips New community fee in basis points (0-1000 = 0-10%)
    /// @dev Callable by Factory or Reserve Owner. Validates vault 1000-2000, community 0-1000, combined ≤ 2000. Cannot modify if locked.
    function setCustomFees(uint128 _vaultFeeBips, uint128 _communityFeeBips) external onlyFactoryResOwner {
        if (isFeesLocked) revert CustomFeesLocked();

        // Block fee changes during active lock window (96 hours)
        if (timeState.feeInit > 0 && block.timestamp < timeState.feeInit + 96 hours) {
            revert LockProcessActive();
        }

        if (_vaultFeeBips < MIN_RESVAULT_FEE || _vaultFeeBips > MAX_RESVAULT_FEE) revert InvalidCustomFee();
        if (_communityFeeBips > 1000) revert InvalidCustomFee();

        // Validate combined fee caps
        if (IStrategicFactory(factory()).v1Reserve() != address(this)) {
            // Standard reserves: adjustable cap
            if (_vaultFeeBips + _communityFeeBips > maxReserveFee) revert InvalidCustomFee();
        } else {
            // V1: hard-coded 2000 cap
            if (_vaultFeeBips + _communityFeeBips > MAX_RESVAULT_FEE) revert InvalidCustomFee();
        }

        uint128 oldVaultFee = reserveVaultFee;
        uint128 oldCommunityFee = communityFee;

        reserveVaultFee = _vaultFeeBips;
        communityFee = _communityFeeBips;

        emit CustomFeesUpdated(oldVaultFee, _vaultFeeBips, oldCommunityFee, _communityFeeBips);
    }

    /// @notice Set community fee recipient address
    /// @param _addr New community address
    /// @dev Only callable by Reserve Owner. First-time from address(0) is immediate. Changes require 15-day timelock.
    function setCommunityAddr(address _addr) external onlyOwner {
        // Block during fee lock window
        if (timeState.feeInit > 0 && block.timestamp < timeState.feeInit + 96 hours) {
            revert LockProcessActive();
        }

        // First-time from address(0) → immediate
        if (communityAddr == address(0)) {
            communityAddr = _addr;
            emit AddressChange("Community address set", _addr);
            return;
        }

        // Changing to new address → start/restart timelock
        if (timeState.pendingCommunity != _addr) {
            timeState.pendingCommunity = _addr;
            timeState.communityInit = uint40(block.timestamp + 15 days);
            emit AddressChange("Community address change proposed", _addr);
            return;
        }

        // Same address + timelock met → execute
        if (block.timestamp < timeState.communityInit) revert TimelockNotMet();
        communityAddr = _addr;
        delete timeState.pendingCommunity;
        delete timeState.communityInit;
        emit AddressChange("Community address updated", _addr);
    }

    /// @notice Process vault address change with 30-day timelock
    /// @param current Current vault address from Hook
    /// @param proposed Proposed new vault address
    /// @return canExecute True if Hook should proceed with update
    /// @dev Only callable by Hook. Manages 30-day timelock for vault address changes.
    function processVaultChange(address current, address proposed) external returns (bool canExecute) {
        if (msg.sender != hookAddress) revert NotHook();
        if (current == address(0)) revert HookHandlesFirstSetup();

        // New address → start/restart timelock
        if (timeState.pendingVault != proposed) {
            timeState.pendingVault = proposed;
            timeState.vaultInit = uint40(block.timestamp + 30 days);
            emit AddressChange("Vault address change proposed", proposed);
            return false;
        }

        // Same address + timelock met → execute
        if (block.timestamp >= timeState.vaultInit) {
            delete timeState.pendingVault;
            timeState.vaultInit = uint40(block.timestamp);
            emit AddressChange("Vault address updated", proposed);
            return true;
        }

        revert TimelockNotMet();
    }

    /// @notice Adjust maximum reserve fee cap for this reserve
    /// @param _newMax New maximum in basis points (1000-1900)
    /// @dev Callable by Factory or Level 2 strategists
    /// @dev V1 reserve uses fixed 2000 cap and cannot adjust this value
    function setMaxReserveFee(uint128 _newMax) external onlyFactoryStratL2 {
        if (isFeesLocked) revert CustomFeesLocked();

        // V1 doesn't use this variable, blocked from adjusting
        if (IStrategicFactory(factory()).v1Reserve() == address(this)) revert V1UsesFixedCap();

        // Non-V1: can set between MIN_RESVAULT_FEE and (MAX_RESVAULT_FEE - 100) = 1900
        if (_newMax < MIN_RESVAULT_FEE || _newMax > MAX_RESVAULT_FEE - 100) revert InvalidMaxFee();

        maxReserveFee = _newMax;
    }

    /// @notice Lock custom fees permanently (two-stage: 24h delay, 72h window)
    /// @dev Call once to initiate 24h timer. Call again after 24h (within 96h total) to finalize.
    function lockCustomFees() external onlyFactoryResOwner {
        if (isFeesLocked) revert CustomFeesLocked();

        // Stage 1: No active lock process → initiate
        if (timeState.feeInit == 0) {
            timeState.feeInit = uint40(block.timestamp);
            timeState.feeVault = uint16(reserveVaultFee);
            timeState.feeCommunity = uint16(communityFee);
            emit FeeLockProcess("Stage 1: 24-hour delay initiated");
            return;
        }

        uint256 elapsed = block.timestamp - timeState.feeInit;

        // Window expired (> 96h) → JUST RESET (requires another call to restart)
        if (elapsed > 96 hours) {
            delete timeState.feeInit;
            delete timeState.feeVault;
            delete timeState.feeCommunity;
            emit FeeLockProcess("Window expired: Lock process reset. Call again to restart Stage 1.");
            return;
        }

        // Too early (< 24h) → revert
        if (elapsed < 24 hours) {
            revert LockDelayNotMet();
        }

        // Stage 2: 24h-96h window → finalize if fees unchanged
        if (reserveVaultFee != timeState.feeVault || communityFee != timeState.feeCommunity) {
            revert LockProcessActive(); // Fees were changed - security violation
        }

        // Finalize permanent lock
        isFeesLocked = true;
        delete timeState.feeInit;
        delete timeState.feeVault;
        delete timeState.feeCommunity;

        emit FeeLockProcess("Stage 2: Permanent lock finalized");
        emit FeesLocked(reserveVaultFee, communityFee);
    }

    /* ═══════════════════════════════════════════════════ */
    /*                 MECHANISM FUNCTIONS                 */
    /* ═══════════════════════════════════════════════════ */
    /// @notice Returns the maximum price allowed for buying an NFT, increasing over time
    /// @return The maximum price in ETH (wei) that can be used for buying
    /// @dev Phase 2: Starts at floorResetPct of last buy, grows by buyIncrement per block, caps at maxBuyCapPct
    function getMaxPriceForBuy() public view returns (uint256) {
        uint256 blocksSinceLastBuy = block.number - lastBuyBlock;

        // Fallback logic if adaptive disabled
        if (disableAdaptiveFloor) {
            return (blocksSinceLastBuy + 1) * buyIncrement;
        }

        // Determine base price: either % of last buy, or buyIncrement for first purchase
        uint256 basePrice = lastBuyPrice > 0
            ? (lastBuyPrice * floorResetPct / 10000)
            : buyIncrement;

        // Calculate price: base + per-block growth
        uint256 calculatedPrice = basePrice + (blocksSinceLastBuy * buyIncrement);

        // Apply cap if purchase history exists
        if (lastBuyPrice > 0 && maxBuyCapPct > 0) {
            uint256 maxAllowed = (lastBuyPrice * maxBuyCapPct) / 10000;
            if (calculatedPrice > maxAllowed) {
                return maxAllowed;
            }
        }

        return calculatedPrice;
    }

    /// @notice Allows the hook or advance contract to deposit trading fees
    /// @dev Callable by Hook (every swap) or Advance (rare operations), uses msg.value for fee amount
    function addFees() external payable {
        if (msg.sender != hookAddress) {
            address advance = IStrategicFactory(factory()).getStrategicAdvance(address(this));
            if (msg.sender != advance) revert NotAuthorized();
        }
        currentFees += msg.value;
    }

    /// @notice Recovers untracked ETH and adds to ethToTwap for token buybacks
    /// @dev Calculates: untracked = balance - (currentFees + ethToTwap)
    /// @dev Permission levels: 0=factory only, 1=factory+strategists, 2=public
    function recoverUntrackedFees() external nonReentrant {
        // Permission check based on recoverFeesAllowance
        if (recoverFeesAllowance == 0) {
            if (msg.sender != factory()) revert NotAuthorized();
        } else if (recoverFeesAllowance == 1) {
            if (msg.sender != factory() && strategistLevel[msg.sender] == 0) {
                revert NotAuthorized();
            }
        }
        // recoverFeesAllowance == 2: public access, no check needed

        uint256 trackedBalance = currentFees + ethToTwap;
        uint256 actualBalance = address(this).balance;

        if (actualBalance > trackedBalance) {
            uint256 untracked = actualBalance - trackedBalance;
            ethToTwap += untracked;
            emit UntrackedFeesRecovered(untracked, msg.sender);
        }
    }

    /// @notice Increases the transient transfer allowance for pool operations
    /// @param amountAllowed Amount to add to the current allowance
    /// @dev Only callable by the hook contract, uses transient storage
    function increaseTransferAllowance(uint256 amountAllowed) external {
        if (msg.sender != hookAddress) revert NotHook();
        uint256 currentAllowance = getTransferAllowance();
        assembly {
            tstore(0, add(currentAllowance, amountAllowed))
        }
        emit AllowanceIncreased(amountAllowed);
    }

    /// @notice Buys a specific NFT using accumulated fees
    /// @param value Amount of ETH to spend on the NFT purchase
    /// @param data Calldata for the external marketplace call
    /// @param expectedId The token ID expected to be acquired
    /// @param target The marketplace contract to call
    /// @dev Protected against reentrancy, validates NFT acquisition
    function buyTargetNFT(uint256 value, bytes calldata data, uint256 expectedId, address target)
        external
        nonReentrant
    {
        // Check if sell operation is active and blocking is enabled
        if ((opBlock == 2 || opBlock == 3) && _activeOp == ActiveOp.SELL) {
            revert OperationInProgress();
        }

        // Check if buyOwn operation is active - ALWAYS block (buyOwn is both buy and sell)
        if (_activeOp == ActiveOp.BUYOWN) {
            revert OperationInProgress();
        }

        // Store both balance and nft amount before calling external
        uint256 ethBalanceBefore = address(this).balance;
        uint256 nftBalanceBefore = collection.balanceOf(address(this));

        // Check owner
        try collection.ownerOf(expectedId) returns (address owner) {
            if (owner == address(this)) {
                revert NFTAlreadyOwnByReserve();
            }
        } catch {
            // Id doesn't exist, likely og nft: pass check
        }

        // Attribute restriction validation
        if (isIdRestricted && !allowedTokenId[expectedId]) {
            revert InvalidAttribute();
        }

        // Ensure value is not more than currentFees
        if (value > currentFees) {
            revert NotEnoughEth();
        }

        // Ensure value doesn't exceed the time-based maximum price
        if (value > getMaxPriceForBuy()) {
            revert PriceTooHigh();
        }

        // Ensure target is not the collection itself
        if (target == address(collection)) revert InvalidTarget();

        // Market enforcement validation
        if (isMarketEnforced) {
            bytes4 sig = bytes4(data);
            if (!IStrategicFactory(factory()).isCallAllowed(target, sig)) {
                revert InvalidMarketOrSignature();
            }
        }

        // Set operation flag before external call
        _activeOp = ActiveOp.BUY;

        // Call external
        (bool success, bytes memory reason) = target.call{value: value}(data);
        if (!success) {
            revert ExternalCallFailed(reason);
        }

        // Ensure we now have one more NFT
        uint256 nftBalanceAfter = collection.balanceOf(address(this));

        if (nftBalanceAfter != nftBalanceBefore + 1) {
            revert NeedToBuyNFT();
        }

        // Ensure we are now owner of expectedId
        if (collection.ownerOf(expectedId) != address(this)) {
            revert NotNFTOwner();
        }

        // Calculate actual cost of the NFT to base new price on
        uint256 cost = ethBalanceBefore - address(this).balance;
        currentFees -= cost;

        // List NFT for sale with purchase data (snapshot pricing params)
        _nftPurchaseData[expectedId] = NFTPurchase({
            price: _toUint128(cost),
            time: uint40(block.timestamp),
            priceMultiplier: uint16(priceMultiplier),
            decayFloor: uint16(decayFloor),
            decayDays: uint16(decayDays)
        });

        // Update last buy block to reset max price calculation
        lastBuyBlock = block.number;

        // Track last buy price for adaptive floor protection
        lastBuyPrice = cost;

        // Clear operation flag after success
        _activeOp = ActiveOp.NONE;

        emit NFTBoughtByProtocol(expectedId, cost);
    }

    /// @notice Sells an NFT owned by the contract for the listed price
    /// @param tokenId The ID of the NFT to sell
    /// @param feeRecipient Optional marketplace fee recipient (address(0) = no fee)
    /// @param requestedFeeBips Marketplace fee to charge in basis points (0-12.5%, must not exceed whitelisted max)
    function sellTargetNFT(uint256 tokenId, address feeRecipient, uint256 requestedFeeBips) public payable nonReentrant {
        // Check if buy operation is active and blocking is enabled
        if ((opBlock == 1 || opBlock == 3) && _activeOp == ActiveOp.BUY) {
            revert OperationInProgress();
        }

        // Check if buyOwn operation is active - ALWAYS block (buyOwn is both buy and sell)
        if (_activeOp == ActiveOp.BUYOWN) {
            revert OperationInProgress();
        }

        // Verify NFT is for sale
        if (_nftPurchaseData[tokenId].price == 0) revert NFTNotForSale();

        // Calculate sale price using stored pricing params
        uint256 salePrice = _calcSalePrice(tokenId);

        // Verify sent ETH matches sale price
        if (msg.value != salePrice) revert NFTPriceTooLow();

        // Verify contract owns the NFT
        if (collection.ownerOf(tokenId) != address(this)) revert NotNFTOwner();

        // Set operation flag before transfer
        _activeOp = ActiveOp.SELL;

        // Transfer NFT to buyer
        collection.transferFrom(address(this), msg.sender, tokenId);

        // Verify NFT left our contract
        if (collection.ownerOf(tokenId) == address(this)) {
            revert NFTNotTransferred();
        }

        // Remove NFT from sale
        delete _nftPurchaseData[tokenId];

        // Handle marketplace fee (if requested)
        uint256 marketFee = 0;
        if (feeRecipient != address(0) && requestedFeeBips > 0) {
            // Only whitelisted address can claim its own fee
            if (msg.sender != feeRecipient) revert NotAuthorized();

            // Verify marketplace is whitelisted (non-zero max fee)
            if (marketplaceFee[feeRecipient] == 0) revert NotAuthorized();

            // Validate requested fee doesn't exceed whitelisted maximum
            if (requestedFeeBips > marketplaceFee[feeRecipient]) revert FeeExceedsMax();

            marketFee = (salePrice * requestedFeeBips) / 10000; // Convert fee to ETH
            SafeTransferLib.safeTransferETH(feeRecipient, marketFee);
        }

        // Add sale proceeds (minus marketFee) to TWAP buyback
        ethToTwap += (salePrice - marketFee);

        // Clear operation flag after success
        _activeOp = ActiveOp.NONE;

        emit NFTSoldByProtocol(tokenId, salePrice, msg.sender);
    }

    /// @notice "Buys" an NFT the contract already owns, raising its listing price
    /// @param tokenId The ID of the NFT to self-purchase
    /// @dev Simulates buying at current listing price, relists at priceMultiplier higher
    /// @dev Moves cost from currentFees → ethToTwap (converts NFT budget to buyback budget)
    function buyOwnNFT(uint256 tokenId) external nonReentrant onlyFactoryStratPub(isPubSelfBuy) {
        // Verify ownership and listing status
        if (collection.ownerOf(tokenId) != address(this)) revert NotNFTOwner();
        if (_nftPurchaseData[tokenId].price == 0) revert NFTNotForSale();

        // Attribute restriction
        if (isIdRestricted && !allowedTokenId[tokenId]) revert InvalidAttribute();

        // The "purchase cost" is the current listing price (using stored pricing params)
        uint256 cost = _calcSalePrice(tokenId);

        // Apply identical validations as buyTargetNFT
        if (cost > currentFees) revert NotEnoughEth();
        if (cost > getMaxPriceForBuy()) revert PriceTooHigh();

        // Check operation blocking - buyOwnNFT is both buy and sell, ALWAYS block if ANY operation active
        if (_activeOp != ActiveOp.NONE) revert OperationInProgress();

        // Set operation flag
        _activeOp = ActiveOp.BUYOWN;

        // Execute the "purchase" - move funds between internal pools
        currentFees -= cost;
        ethToTwap += cost;

        // Update listing with new purchase data (snapshot current pricing params)
        _nftPurchaseData[tokenId] = NFTPurchase({
            price: _toUint128(cost),
            time: uint40(block.timestamp),
            priceMultiplier: uint16(priceMultiplier),
            decayFloor: uint16(decayFloor),
            decayDays: uint16(decayDays)
        });

        // Update adaptive floor tracking
        lastBuyBlock = block.number;
        lastBuyPrice = cost;

        // Clear operation flag
        _activeOp = ActiveOp.NONE;

        // Emit event
        emit NFTBoughtByProtocol(tokenId, cost);
    }

    /// @notice Reconciles owned NFTs with listed NFTs in nftForSale mapping
    /// @param startTokenId Starting collection tokenId (inclusive)
    /// @param endTokenId Ending collection tokenId (inclusive)
    /// @return listed Count of NFTs newly listed for sale
    /// @return delisted Count of NFTs removed from listings
    /// @dev Values synced NFTs at lastBuyPrice (most recent collection purchase price)
    /// @dev ALWAYS blocked if any operation is active (non-configurable)
    function nftSync(uint256 startTokenId, uint256 endTokenId)
        external
        nonReentrant
        onlyFactoryStratPub(isPubSync)
        returns (uint256 listed, uint256 delisted)
    {
        // ALWAYS block if ANY operation is active
        if (_activeOp != ActiveOp.NONE) revert OperationInProgress();

        // Set operation flag
        _activeOp = ActiveOp.BUYOWN;

        // Validate we have purchase history to value synced NFTs
        if (lastBuyPrice == 0) revert CannotSyncYet();

        // Get owned NFTs via Lens
        address lens = IStrategicFactory(factory()).strategicLens();
        require(lens != address(0), "Lens not set");
        uint256[] memory ownedTokenIds = IStrategicLens(lens).getAcctNFTs(
            address(this),
            address(collection),
            startTokenId,
            endTokenId
        );

        // List unlisted NFTs we own
        for (uint256 i = 0; i < ownedTokenIds.length; i++) {
            uint256 tokenId = ownedTokenIds[i];

            if (isIdRestricted && !allowedTokenId[tokenId]) continue;

            if (_nftPurchaseData[tokenId].price == 0) {
                _nftPurchaseData[tokenId] = NFTPurchase({
                    price: _toUint128(lastBuyPrice),
                    time: uint40(block.timestamp),
                    priceMultiplier: uint16(priceMultiplier),
                    decayFloor: uint16(decayFloor),
                    decayDays: uint16(decayDays)
                });
                listed++;

                // Calculate listing price for event emission
                uint256 listPrice = _calcSalePrice(tokenId);
                emit NFTResync(tokenId, listPrice);
            }
        }

        // Delist NFTs we don't own
        for (uint256 tokenId = startTokenId; tokenId <= endTokenId; tokenId++) {
            if (_nftPurchaseData[tokenId].price > 0) {
                try collection.ownerOf(tokenId) returns (address owner) {
                    if (owner != address(this)) {
                        delete _nftPurchaseData[tokenId];
                        delisted++;
                        emit NFTResync(tokenId, 0);
                    }
                } catch {
                    delete _nftPurchaseData[tokenId];
                    delisted++;
                    emit NFTResync(tokenId, 0);
                }
            }
        }

        _activeOp = ActiveOp.NONE;
    }

    /// @notice Processes token buyback using TWAP mechanism
    /// @dev Can be called once every twapDelayInBlocks, uses ethToTwap for buyback
    /// @dev Caller receives 0.5% reward, remaining ETH is used to buy and burn tokens
    function processTokenTwap() external nonReentrant {
        if (ethToTwap == 0) revert NoETHToTwap();

        // Check if enough blocks have passed since last TWAP
        if (block.number < lastTwapBlock + twapDelayInBlocks) revert TwapDelayNotMet();

        // Calculate amount to burn - either twapIncrement or remaining ethToTwap
        uint256 burnAmount = twapIncrement;
        if (ethToTwap < twapIncrement) {
            burnAmount = ethToTwap;
        }

        // Set reward to 0.5% of burnAmount
        uint256 reward = (burnAmount * 5) / 1000;
        burnAmount -= reward;

        // Update state
        ethToTwap -= burnAmount + reward;
        lastTwapBlock = block.number;

        _buyAndBurnTokens(burnAmount);

        // Send reward to caller
        SafeTransferLib.forceSafeTransferETH(msg.sender, reward);
    }

    /* ═══════════════════════════════════════════════════ */
    /*                  INTERNAL FUNCTIONS                 */
    /* ═══════════════════════════════════════════════════ */
    /// @notice Safely casts uint256 to uint128, reverting on overflow
    /// @param value The uint256 value to cast
    /// @return The value as uint128
    function _toUint128(uint256 value) private pure returns (uint128) {
        if (value > type(uint128).max) revert("Uint128 overflow");
        return uint128(value);
    }

    /// @notice Calculate sale price with time-based decay
    /// @param tokenId The NFT token ID to calculate sale price for
    /// @return Sale price with multiplier and decay applied
    function _calcSalePrice(uint256 tokenId) internal view returns (uint256) {
        NFTPurchase memory purchase = _nftPurchaseData[tokenId];
        uint256 daysElapsed = (block.timestamp - purchase.time) / 1 days;

        uint256 currentMultiplier;
        if (daysElapsed < purchase.decayDays) {
            // Partial decay - linear interpolation
            uint256 decay = (purchase.priceMultiplier - purchase.decayFloor) * daysElapsed / purchase.decayDays;
            currentMultiplier = purchase.priceMultiplier - decay;
        } else {
            // Full decay - use floor
            currentMultiplier = purchase.decayFloor;
        }

        return purchase.price * currentMultiplier / 1000;
    }

    /// @notice Gets the current sale price for an NFT including time-based decay
    /// @param tokenId The NFT token ID to check
    /// @return The current sale price with decay applied (0 if not listed)
    /// @dev Public view function for backwards compatibility - UIs call this to get current price
    function nftForSale(uint256 tokenId) external view returns (uint256) {
        if (_nftPurchaseData[tokenId].price == 0) return 0;
        return _calcSalePrice(tokenId);
    }

    /// @notice Buys tokens with ETH and burns them by sending to dead address
    /// @param amountIn The amount of ETH to spend on tokens that will be burned
    /// @dev Creates a pool key and swaps ETH for tokens, sending tokens to dead address
    function _buyAndBurnTokens(uint256 amountIn) internal {
        PoolKey memory key =
            PoolKey(Currency.wrap(address(0)), Currency.wrap(address(this)), 0, 60, IHooks(hookAddress));

        router().swapExactTokensForTokens{value: amountIn}(amountIn, 0, true, key, "", DEAD_ADDR, block.timestamp);
    }

    /// @notice Validates token transfers using a transient allowance system
    /// @param from The address sending tokens
    /// @param to The address receiving tokens
    /// @param amount The amount of tokens being transferred
    /// @dev Reverts if transfer isn't through the hook
    function _afterTokenTransfer(address from, address to, uint256 amount) internal override {
        // On reserve launch, we need to allow for supply mint transfer
        if (from == address(0)) {
            return;
        }

        // Transfers to and from the poolManager require a transient allowance thats set by the hook
        if ((from == address(poolManager()) || to == address(poolManager()))) {
            uint256 transferAllowance = getTransferAllowance();
            require(transferAllowance >= amount, InvalidTransfer());
            assembly {
                let newAllowance := sub(transferAllowance, amount)
                tstore(0, newAllowance)
            }
            emit AllowanceSpent(from, to, amount);
            return;
        }

        // Check factory-controlled transfer validation
        (bool isValid, bool shouldTax) = IStrategicFactory(factory()).validTransfer(from, to, address(this));

        // Revert if transfer not allowed
        if (!isValid) revert InvalidTransfer();

        // No tax if distributor (takes precedence over shouldTax flag)
        if (isDistributor[from]) return;

        // Apply EOA tax if Factory determined it should be taxed
        if (shouldTax) {
            // Get EOA config for tax calculation
            (bool enabled, uint8 taxMode, uint8 discount, bool sigEnabled, uint8 sigTaxMode, uint8 sigDiscount) = IStrategicFactory(factory()).reserveEOAConfig(address(this));

            // if tx is executed via Advance, assume signed
            address authorizedAdvance = IStrategicFactory(factory()).getStrategicAdvance(address(this));
            bool isSigned = (msg.sender == authorizedAdvance && authorizedAdvance != address(0));

            // Select config based on transfer type
            bool configEnabled = isSigned ? sigEnabled : enabled;
            uint8 configTaxMode = isSigned ? sigTaxMode : taxMode;
            uint8 configDiscount = isSigned ? sigDiscount : discount;

            if (configEnabled && configTaxMode > 0) {
                // Get default fee based on taxMode (1 = buy, 2 = sell)
                uint128 baseFee = (configTaxMode == 1)
                    ? IStrategicHook(hookAddress).defaultFeeBuy()
                    : IStrategicHook(hookAddress).defaultFeeSell();
                // Apply discount: baseFee * (100 - discount) / 100
                uint256 feeAmount = (amount * baseFee * (100 - configDiscount)) / (10000 * 100);

                if (feeAmount > 0) {
                    // Route tax based on configured mode (read from local storage)
                    if (eoaFeeHandler == FeeHandlingMode.BURN) {
                        // BURN: Immediate deflationary processing
                        _transfer(to, DEAD_ADDR, feeAmount);
                    } else {
                        // RESERVE: Accumulate in Reserve or destination for later distribution
                        address destination = eoaFeeAddr != address(0) ? eoaFeeAddr : address(this);
                        _transfer(to, destination, feeAmount);
                    }
                }
            }
        }
    }

    /// @notice Gets the current transient transfer allowance
    /// @return transferAllowance The current allowance amount
    /// @dev Reads from transient storage slot 0
    function getTransferAllowance() public view returns (uint256 transferAllowance) {
        assembly {
            transferAllowance := tload(0)
        }
    }


    /// @notice Handles receipt of NFTs (ERC721 receiver)
    /// @dev Only accepts NFTs from the designated collection
    /// @return The function selector to confirm receipt
    function onERC721Received(address, address, uint256, bytes calldata) external view returns (bytes4) {
        if (msg.sender != address(collection)) {
            revert InvalidCollection();
        }

        return this.onERC721Received.selector;
    }

    /* ═══════════════════════════════════════════════════ */
    /*                   GETTER FUNCTIONS                  */
    /* ═══════════════════════════════════════════════════ */
    /// @notice Returns the factory address from proxy bytecode
    /// @return The Factory address
    /// @dev Reads from bytes 0-20 of the proxy's immutable args
    function factory() public view returns (address) {
        bytes memory args = LibClone.argsOnERC1967(address(this), 0, 20);
        return address(bytes20(args));
    }

    /// @notice Returns the router address from proxy bytecode
    /// @return The Uniswap V4 router contract interface
    /// @dev Reads from bytes 20-40 of the proxy's immutable args
    function router() public view returns (IUniswapV4Router04) {
        bytes memory args = LibClone.argsOnERC1967(address(this), 20, 40);
        return IUniswapV4Router04(payable(address(bytes20(args))));
    }

    /// @notice Returns the pool manager address from proxy bytecode
    /// @return The Uniswap V4 pool manager contract interface
    /// @dev Reads from bytes 40-60 of the proxy's immutable args
    function poolManager() public view returns (IPoolManager) {
        bytes memory args = LibClone.argsOnERC1967(address(this), 40, 60);
        return IPoolManager(address(bytes20(args)));
    }

    /// @notice Allows the contract to receive ETH
    receive() external payable {}
}
