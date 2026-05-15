// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.4.0

// Author: Ant Opara
// Email: contact@theswitch.box
// hi@dead.box

pragma solidity ^0.8.28;

import {ERC20Burnable} from '@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol';
import {ERC20Permit} from '@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {ReentrancyGuard} from '@openzeppelin/contracts/utils/ReentrancyGuard.sol';
import {OFT} from '@layerzerolabs/oft-evm/contracts/OFT.sol';
import {Origin} from '@layerzerolabs/oapp-evm/contracts/oapp/OApp.sol';
import {MessagingFee} from '@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol';
import {OptionsBuilder} from '@layerzerolabs/oapp-evm/contracts/oapp/libs/OptionsBuilder.sol';

/**
 * @title DEAD Token
 * @notice ERC20 token with tiered minting, platform allocations, and idle-claim mechanics.
 * @notice Supports cross-chain minting via LayerZero messaging
 */
contract DeadToken is ERC20Burnable, ERC20Permit, OFT, ReentrancyGuard {
    using OptionsBuilder for bytes;

    /// @notice Message type identifier for tier mint requests
    uint16 public constant MSG_TYPE_TIER_MINT = 1;

    /// @notice Maximum total supply across all tiers and chains (1 billion DEAD)
    uint256 public constant SUPPLY_CAP = 1e9 * 10 ** 18;

    /// @notice Mint amount for tier 1 mints
    uint256 public constant TIER1_AMOUNT = 1e6 * 10 ** 18;

    /// @notice Total mint amount for Tier 2 mints
    uint256 public constant TIER2_AMOUNT = 1e5 * 10 ** 18;

    /// @notice Total mint amount for Tier 3 mints
    uint256 public constant TIER3_AMOUNT = 1e3 * 10 ** 18;

    /// @notice Total mint amount for Tier 4 mints
    uint256 public constant TIER4_AMOUNT = 100 * 10 ** 18;

    /// @notice initial mint amount 200 millions
    uint256 public constant INITIAL_MINT_AMOUNT = 2e8 * 10 ** 18;

    /// @notice Number of Tier 1 mints available
    uint256 public constant TIER1_LIMIT = 100;

    /// @notice Number of Tier 2 mints available
    uint256 public constant TIER2_LIMIT = 900;

    /// @notice Number of Tier 3 mints available
    uint256 public constant TIER3_LIMIT = 9000;

    /// @notice Minimum inactivity period required before tokens become claimable (90 Days)
    uint256 public constant IDLE_PERIOD = 7776000; // 90 days

    /// @notice Minimum DEAD balance a caller must hold to claim idle tokens (1M Tokens)
    uint256 public constant MIN_CLAIMER_BALANCE = 1e6 * 10 ** 18;

    /// @notice Timelock period for pool whitelist activation (60 minutes)
    uint256 public constant POOL_WHITELIST_TIMELOCK = 3600;

    /// @notice Share of each mint allocated to the creator,10/17 in ratio
    uint256 public constant CREATOR_PRECENTAGE = 588235;

    /// @notice Share of each mint allocated to the vesting contract,  5/17 in ratio
    uint256 public constant VESTING_PERCENTAGE = 294118;

    /// @notice Share of each mint allocated to platform addresses, 2/17 in ratio
    uint256 public constant PLATFORM_PERCENTAGE = 117647;

    /// @notice Share of each mint allocated to platform 1, // 50% of platformAmount
    uint256 public constant PLATFORM1_SPLIT_PPM = 500_000;

    /// @notice Share of each mint allocated to platform 1, // 30% of platformAmount
    uint256 public constant PLATFORM2_SPLIT_PPM = 300_000;

    /// @notice Share of each mint allocated to platform 1, // 20% of platformAmount
    uint256 public constant PLATFORM3_SPLIT_PPM = 200_000;

    /// @notice Denominator used for parts-per-million percentages
    uint256 public constant PPM = 1e6;

    /// @notice Native chain id for the hub chain where tier accounting occurs
    uint256 public immutable hubChainId;

    /// @notice LayerZero endpoint id (EID) for the hub chain
    uint32 public immutable hubEid;

    /// @notice Number of Tier 1 mints executed
    uint256 public tier1Count;

    /// @notice Number of Tier 2 mints executed
    uint256 public tier2Count;

    /// @notice Number of Tier 3 mints executed
    uint256 public tier3Count;

    /// @notice Destination address for vesting allocations
    address public immutable vestingContract;

    /// @notice Platform distribution address #1
    address public immutable PLATFORM_1;

    /// @notice Platform distribution address #2
    address public immutable PLATFORM_2;

    /// @notice Platform distribution address #3
    address public immutable PLATFORM_3;

    /// @notice gas limit to receive request from other chains for minting tokens
    uint128 public GAS_LIMIT;

    /// @notice Only Allow one time minting of 200M tokens
    bool public initialMinted;

    /// @notice Admin address for whitelisting purposes
    address public ADMIN;

    bool public isAdminBurned = false;

    /// @notice Tracks last transfer timestamp per address to determine idleness
    mapping(address => uint256) public lastTransferTime;

    /// @notice Whitelist of authorized switchbox callers
    mapping(address => bool) public whiteListedFactories;

    /// @notice whitelist the pool addresses
    mapping(address => bool) public whiteListedPool;

    /// @notice Pending pool whitelist requests with their activation timestamp
    mapping(address => uint256) public pendingPoolWhitelist;

    /// @notice Tracks whether a given creation id has been claimed to prevent duplicates
    mapping(bytes32 => bool) public claimedCreation;

    /// @notice Emitted when `claimer` claims all idle tokens from `target`
    event TokensClaimed(address indexed claimer, address indexed target, uint256 amount);

    /// @notice Emitted when a tiered mint occurs to `to` for `amount` under `tier`
    event DeadMinted(address indexed to, uint256 tier, uint256 amount);

    /// @notice Emitted when the whitelist status of `switchbox` is updated
    event SwitchboxWhitelistUpdated(address indexed switchbox, bool status);

    /// @notice Emitted when the whitelist status of `switchbox` is updated
    event PoolWhitelistUpdated(address indexed switchbox, bool status);

    /// @notice Emitted when a pool whitelist is scheduled
    event PoolWhitelistScheduled(address indexed pool, uint256 activationTime);

    /// @notice Emitted when a pending pool whitelist is cancelled
    event PoolWhitelistCancelled(address indexed pool);

    /// @notice Emitted when the initial 200M tokens are minted
    event InitialMint(address indexed receiver, uint256 amount);

    /// @dev Provided address is zero
    error ZeroAddress();

    /// @dev Caller is not an authorized switchbox
    error NotSwitchBox();

    /// @dev No more tokens can be minted; supply cap reached
    error SupplyCapReached();

    /// @dev Mint would exceed the global supply cap
    error MintExceedsCap();

    /// @dev Caller balance is below the minimum threshold to claim idle tokens
    error InsufficientBalanceToClaim();

    /// @dev Target address has not been idle for long enough
    error TokensNotIdleLongEnough();

    /// @dev Target address has no tokens to claim
    error NoClaimableTokens();

    /// @dev Switchbox is already whitelisted
    error AlreadyWhiteListed();

    /// @dev Switchbox is not whitelisted
    error NotWhiteListed();

    /// @dev Function can only be executed on the hub chain
    error OnlyHub();

    /// @dev when the gas limit is either same or sent zero
    error InvalidValue();

    /// @dev Creation id has already been consumed for a mint
    error AlreadyClaimed();

    /// @dev when initial supply for devs is already minted
    error AlreadyMinted();

    /// @dev pool tokens cant be claim
    error PoolAddress();

    /// @dev msg.value does not match the required fee
    error InvalidMessageValue(uint256 expected, uint256 received);

    /// @dev Admin has already been burned
    error AdminBurned();

    /// @dev Caller is not the admin
    error NotAdmin();

    /// @dev Caller is not the owner
    error NotOwner();

    /// @dev Pool whitelist is still pending timelock
    error PoolWhitelistPending();

    /// @dev No pending pool whitelist found
    error NoPendingWhitelist();

    /// @dev Invalid message type
    error InvalidMessageType();

    modifier onlyAdmin() {
        if (msg.sender != ADMIN) revert NotAdmin();
        if (isAdminBurned) revert AdminBurned();
        _;
    }

    constructor(
        address initialOwner,
        address _vestingContract,
        address _platform1,
        address _platform2,
        address _platform3,
        address _lzEndpoint,
        address _admin,
        uint256 _hubChainId,
        uint32 _hubEid
    ) ERC20Permit('DEAD') Ownable(msg.sender) OFT('DEAD', 'DEAD', _lzEndpoint, initialOwner) {
        if (
            _vestingContract == address(0) ||
            _platform1 == address(0) ||
            _platform2 == address(0) ||
            _platform3 == address(0)
        ) revert ZeroAddress();

        vestingContract = _vestingContract;
        PLATFORM_1 = _platform1;
        PLATFORM_2 = _platform2;
        PLATFORM_3 = _platform3;
        hubChainId = _hubChainId;
        hubEid = _hubEid;
        GAS_LIMIT = 500000;
        ADMIN = _admin;
    }

    receive() external payable {}

    /**
     * @notice Requests a tiered mint for `user` associated with `childSwitch` from an authorized switchbox.
     * @dev On hub chain, mints directly. On other chains, sends LayerZero message to hub.
     * @param user The ultimate recipient eligible for the creator share.
     * @param childSwitch The child switch address for unique identification.
     */
    function requestTierMint(address user, address childSwitch) external payable {
        if (!whiteListedFactories[msg.sender]) revert NotSwitchBox();
        if (user == address(0) || childSwitch == address(0)) revert ZeroAddress();

        uint256 srcChain = block.chainid;
        bytes32 creationId = keccak256(abi.encode(srcChain, msg.sender, childSwitch));

        if (srcChain == hubChainId) {
            // Direct mint on hub chain
            _mintByTierHub(user, creationId);
        } else {
            // Send cross-chain message to hub
            bytes memory payload = abi.encode(MSG_TYPE_TIER_MINT, msg.sender, user, creationId);

            bytes memory options = OptionsBuilder.newOptions().addExecutorLzReceiveOption(GAS_LIMIT, 0);

            MessagingFee memory fee = _quote(hubEid, payload, options, false);

            if (msg.value < fee.nativeFee) {
                revert InvalidMessageValue(fee.nativeFee, msg.value);
            }

            _lzSend(hubEid, payload, options, fee, address(this));

            // Refund overpayment
            uint256 overpayment = msg.value - fee.nativeFee;
            if (overpayment > 0) {
                (bool success, ) = payable(user).call{value: overpayment}('');
                require(success, 'Refund failed');
            }
        }
    }

    /**
     * @notice Configure the whitelist status for a switchbox address.
     * @param switchBox Address allowed to execute tier mints.
     */
    function setWhiteListFactory(address switchBox) external onlyAdmin {
        if (switchBox == address(0)) revert ZeroAddress();
        if (whiteListedFactories[switchBox]) revert AlreadyWhiteListed();

        whiteListedFactories[switchBox] = true;
        emit SwitchboxWhitelistUpdated(switchBox, true);
    }

    /**
     * @notice Schedule a pool address for whitelist with a 60-minute timelock.
     * @param pool Address to schedule for whitelisting.
     */
    function setWhiteListPool(address pool) external onlyAdmin {
        if (pool == address(0)) revert ZeroAddress();
        if (_isPoolWhitelistedView(pool)) revert AlreadyWhiteListed();
        if (pendingPoolWhitelist[pool] != 0) revert PoolWhitelistPending();

        uint256 activationTime = block.timestamp + POOL_WHITELIST_TIMELOCK;
        pendingPoolWhitelist[pool] = activationTime;

        emit PoolWhitelistScheduled(pool, activationTime);
    }

    /**
     * @notice Cancel a pending pool whitelist before it becomes active.
     * @param pool Address to cancel from pending whitelist.
     */
    function cancelPoolWhitelist(address pool) external onlyAdmin {
        if (pendingPoolWhitelist[pool] == 0) revert NoPendingWhitelist();
        delete pendingPoolWhitelist[pool];
        emit PoolWhitelistCancelled(pool);
    }

    /**
     * @notice Check if a pool is whitelisted.
     * @param pool Address to check.
     * @return isWhitelisted True if pool is whitelisted.
     * @return isPending True if pool is pending activation.
     * @return activationTime Timestamp when the pool becomes whitelisted.
     */
    function getPoolWhitelistStatus(
        address pool
    ) external view returns (bool isWhitelisted, bool isPending, uint256 activationTime) {
        activationTime = pendingPoolWhitelist[pool];
        isPending = activationTime != 0;
        isWhitelisted = _isPoolWhitelistedView(pool);

        if (isPending && block.timestamp >= activationTime) {
            activationTime = 0;
        }
    }

    function _isPoolWhitelistedView(address pool) internal view returns (bool) {
        if (whiteListedPool[pool]) {
            return true;
        }

        uint256 activationTime = pendingPoolWhitelist[pool];
        if (activationTime != 0 && block.timestamp >= activationTime) {
            return true;
        }

        return false;
    }

    function _isPoolWhitelisted(address pool) internal returns (bool) {
        if (whiteListedPool[pool]) {
            return true;
        }

        uint256 activationTime = pendingPoolWhitelist[pool];
        if (activationTime != 0 && block.timestamp >= activationTime) {
            delete pendingPoolWhitelist[pool];
            whiteListedPool[pool] = true;
            emit PoolWhitelistUpdated(pool, true);
            return true;
        }

        return false;
    }

    /**
     * @notice Claim idle tokens from `target` if their tokens have been idle long enough.
     * @param target Address whose idle tokens to claim.
     */
    function claimIdleTokens(address target) external nonReentrant {
        address user = msg.sender;
        if (balanceOf(user) < MIN_CLAIMER_BALANCE) {
            revert InsufficientBalanceToClaim();
        }

        if (_isPoolWhitelisted(target)) {
            revert PoolAddress();
        }
        if (target == address(0)) revert ZeroAddress();
        if (block.timestamp < lastTransferTime[target] + IDLE_PERIOD) {
            revert TokensNotIdleLongEnough();
        }

        uint256 claimableAmount = balanceOf(target);
        if (claimableAmount == 0) revert NoClaimableTokens();

        uint256 claimerAmount = (claimableAmount * 50) / 100;
        uint256 burnAmount = (claimableAmount * 40) / 100;
        uint256 platformAmount = claimableAmount - claimerAmount - burnAmount;

        uint256 platform1Amount = (platformAmount * 50) / 100;
        uint256 platform2Amount = (platformAmount * 30) / 100;
        uint256 platform3Amount = platformAmount - platform1Amount - platform2Amount;

        _transfer(target, user, claimerAmount);
        _burn(target, burnAmount);
        _transfer(target, PLATFORM_1, platform1Amount);
        _transfer(target, PLATFORM_2, platform2Amount);
        _transfer(target, PLATFORM_3, platform3Amount);

        emit TokensClaimed(user, target, claimableAmount);
    }

    function updateGasLimit(uint128 limit) external onlyOwner {
        if (limit == 0 || limit == GAS_LIMIT) {
            revert InvalidValue();
        }
        GAS_LIMIT = limit;
    }

    /**
     * @notice Mint 200M tokens initially
     * @param _receiver Address to receive minted tokens.
     */
    function mintInitial(address _receiver) external onlyOwner nonReentrant {
        if (_receiver == address(0)) revert ZeroAddress();
        if (block.chainid != hubChainId) revert OnlyHub();
        if (initialMinted) revert AlreadyMinted();
        initialMinted = true;
        _mint(_receiver, INITIAL_MINT_AMOUNT);

        emit InitialMint(_receiver, INITIAL_MINT_AMOUNT);
    }

    function getTimeUntilClaimable(address target) external view returns (uint256) {
        uint256 timeSinceLastTransfer = block.timestamp - lastTransferTime[target];
        if (timeSinceLastTransfer >= IDLE_PERIOD) {
            return 0;
        }
        return IDLE_PERIOD - timeSinceLastTransfer;
    }

    function getClaimableAmount(address target) external view returns (uint256) {
        if (
            block.timestamp < lastTransferTime[target] + IDLE_PERIOD ||
            _isPoolWhitelistedView(target) ||
            target == address(0)
        ) {
            return 0;
        }
        return balanceOf(target);
    }

    function isClaimable(address target) external view returns (bool) {
        return
            block.timestamp >= lastTransferTime[target] + IDLE_PERIOD &&
            balanceOf(target) > 0 &&
            !_isPoolWhitelistedView(target) &&
            target != address(0);
    }

    /**
     * @dev Override _lzReceive to handle both OFT transfers and custom tier mint messages
     * @notice Distinguishes message types by attempting to decode as tier mint first
     */
    function _lzReceive(
        Origin calldata _origin,
        bytes32 _guid,
        bytes calldata payload,
        address _executor,
        bytes calldata _extraData
    ) internal override {
        // Try to identify if this is a tier mint message
        // Tier mint messages will have our specific structure with MSG_TYPE_TIER_MINT prefix
        bool isTierMintMessage = false;

        if (payload.length >= 130) {
            // uint16 + 3 addresses + bytes32 = minimum bytes
            // Safely try to decode as tier mint message
            try this.decodeTierMintMessage(payload) returns (
                uint16 msgType,
                address switchbox,
                address user,
                bytes32 creationId
            ) {
                if (msgType == MSG_TYPE_TIER_MINT) {
                    isTierMintMessage = true;

                    // This is a tier mint request - only process on hub chain
                    if (block.chainid != hubChainId) revert OnlyHub();

                    // Validate switchbox is whitelisted
                    if (!whiteListedFactories[switchbox]) revert NotSwitchBox();

                    // Execute the mint
                    _mintByTierHub(user, creationId);
                }
            } catch {
                // Not a tier mint message, continue to OFT handling
            }
        }

        // If not processed as tier mint, let OFT handle it (normal token transfer)
        if (!isTierMintMessage) {
            super._lzReceive(_origin, _guid, payload, _executor, _extraData);
        }
    }

    /**
     * @dev External helper to decode tier mint message payload
     * @notice Used in try-catch to safely determine message type
     */
    function decodeTierMintMessage(
        bytes calldata payload
    ) external pure returns (uint16 msgType, address switchbox, address user, bytes32 creationId) {
        return abi.decode(payload, (uint16, address, address, bytes32));
    }

    /**
     * @dev Executes the tiered mint on the hub chain
     * @param to The creator recipient.
     * @param creationId Unique id to enforce one-time mint per creation.
     */
    function _mintByTierHub(address to, bytes32 creationId) internal nonReentrant {
        if (totalSupply() >= SUPPLY_CAP) revert SupplyCapReached();
        if (to == address(0)) revert ZeroAddress();

        if (creationId != bytes32(0)) {
            if (claimedCreation[creationId]) {
                revert AlreadyClaimed();
            }
            claimedCreation[creationId] = true;
        }

        (uint256 tier, uint256 amount) = _determineNextTierAndAmount();
        _incrementTierCount(tier);

        if (totalSupply() + amount > SUPPLY_CAP) revert MintExceedsCap();

        (uint256 creatorShare, uint256 vestingAmount, uint256 platformAmount) = _splitAllocation(amount);

        uint256 platform1Share = (platformAmount * PLATFORM1_SPLIT_PPM) / PPM;
        uint256 platform2Share = (platformAmount * PLATFORM2_SPLIT_PPM) / PPM;
        uint256 platform3Share = platformAmount - platform1Share - platform2Share;

        _mint(vestingContract, vestingAmount);
        _mint(PLATFORM_1, platform1Share);
        _mint(PLATFORM_2, platform2Share);
        _mint(PLATFORM_3, platform3Share);
        _mint(to, creatorShare);

        emit DeadMinted(to, tier, amount);
    }

    function _update(address from, address to, uint256 value) internal override {
        super._update(from, to, value);

        if (from != address(0) && value > 0) {
            lastTransferTime[from] = block.timestamp;
        }

        if (to != address(0) && value > 0) {
            uint256 receiverBalanceAfter = balanceOf(to);
            uint256 receiverBalanceBefore = receiverBalanceAfter - value;

            if (receiverBalanceBefore == 0) {
                lastTransferTime[to] = block.timestamp;
            }
        }
    }

    function _determineNextTierAndAmount() internal view returns (uint256 tier, uint256 amount) {
        if (tier1Count < TIER1_LIMIT) {
            return (1, TIER1_AMOUNT);
        }
        if (tier2Count < TIER2_LIMIT) {
            return (2, TIER2_AMOUNT);
        }
        if (tier3Count < TIER3_LIMIT) {
            return (3, TIER3_AMOUNT);
        }
        return (4, TIER4_AMOUNT);
    }

    function _incrementTierCount(uint256 tier) internal {
        if (tier == 1) {
            tier1Count++;
        } else if (tier == 2) {
            tier2Count++;
        } else if (tier == 3) {
            tier3Count++;
        }
    }

    function _splitAllocation(
        uint256 amount
    ) internal pure returns (uint256 creatorShare, uint256 vestingAmount, uint256 platformAmount) {
        creatorShare = (amount * CREATOR_PRECENTAGE) / PPM;
        vestingAmount = (amount * VESTING_PERCENTAGE) / PPM;
        platformAmount = (amount * PLATFORM_PERCENTAGE) / PPM;
    }

    function setAdmin(address _admin) external onlyOwner {
        if (isAdminBurned) revert AdminBurned();
        if (_admin == address(0)) {
            burnAdmin();
            return;
        }
        ADMIN = _admin;
    }

    function burnAdmin() internal onlyOwner {
        ADMIN = address(0);
        isAdminBurned = true;
    }
}
