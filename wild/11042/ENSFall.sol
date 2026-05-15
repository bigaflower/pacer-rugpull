// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// lib/openzeppelin-contracts/contracts/utils/Context.sol

// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol

// OpenZeppelin Contracts (last updated v5.1.0) (utils/StorageSlot.sol)
// This file was procedurally generated from scripts/generate/templates/StorageSlot.js.

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC-1967 implementation slot:
 * ```solidity
 * contract ERC1967 {
 *     // Define the slot. Alternatively, use the SlotDerivation library to derive the slot.
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(newImplementation.code.length > 0);
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * TIP: Consider using this library along with {SlotDerivation}.
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    struct Int256Slot {
        int256 value;
    }

    struct StringSlot {
        string value;
    }

    struct BytesSlot {
        bytes value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly ("memory-safe") {
            r.slot := slot
        }
    }

    /**
     * @dev Returns a `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly ("memory-safe") {
            r.slot := slot
        }
    }

    /**
     * @dev Returns a `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly ("memory-safe") {
            r.slot := slot
        }
    }

    /**
     * @dev Returns a `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly ("memory-safe") {
            r.slot := slot
        }
    }

    /**
     * @dev Returns a `Int256Slot` with member `value` located at `slot`.
     */
    function getInt256Slot(bytes32 slot) internal pure returns (Int256Slot storage r) {
        assembly ("memory-safe") {
            r.slot := slot
        }
    }

    /**
     * @dev Returns a `StringSlot` with member `value` located at `slot`.
     */
    function getStringSlot(bytes32 slot) internal pure returns (StringSlot storage r) {
        assembly ("memory-safe") {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` representation of the string storage pointer `store`.
     */
    function getStringSlot(string storage store) internal pure returns (StringSlot storage r) {
        assembly ("memory-safe") {
            r.slot := store.slot
        }
    }

    /**
     * @dev Returns a `BytesSlot` with member `value` located at `slot`.
     */
    function getBytesSlot(bytes32 slot) internal pure returns (BytesSlot storage r) {
        assembly ("memory-safe") {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` representation of the bytes storage pointer `store`.
     */
    function getBytesSlot(bytes storage store) internal pure returns (BytesSlot storage r) {
        assembly ("memory-safe") {
            r.slot := store.slot
        }
    }
}

// lib/openzeppelin-contracts/contracts/access/Ownable.sol

// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol

// OpenZeppelin Contracts (last updated v5.5.0) (utils/ReentrancyGuard.sol)

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If EIP-1153 (transient storage) is available on the chain you're deploying at,
 * consider using {ReentrancyGuardTransient} instead.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 *
 * IMPORTANT: Deprecated. This storage-based reentrancy guard will be removed and replaced
 * by the {ReentrancyGuardTransient} variant in v6.0.
 *
 * @custom:stateless
 */
abstract contract ReentrancyGuard {
    using StorageSlot for bytes32;

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.ReentrancyGuard")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant REENTRANCY_GUARD_STORAGE =
        0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00;

    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    /**
     * @dev Unauthorized reentrant call.
     */
    error ReentrancyGuardReentrantCall();

    constructor() {
        _reentrancyGuardStorageSlot().getUint256Slot().value = NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    /**
     * @dev A `view` only version of {nonReentrant}. Use to block view functions
     * from being called, preventing reading from inconsistent contract state.
     *
     * CAUTION: This is a "view" modifier and does not change the reentrancy
     * status. Use it only on view functions. For payable or non-payable functions,
     * use the standard {nonReentrant} modifier instead.
     */
    modifier nonReentrantView() {
        _nonReentrantBeforeView();
        _;
    }

    function _nonReentrantBeforeView() private view {
        if (_reentrancyGuardEntered()) {
            revert ReentrancyGuardReentrantCall();
        }
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be NOT_ENTERED
        _nonReentrantBeforeView();

        // Any calls to nonReentrant after this point will fail
        _reentrancyGuardStorageSlot().getUint256Slot().value = ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _reentrancyGuardStorageSlot().getUint256Slot().value = NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _reentrancyGuardStorageSlot().getUint256Slot().value == ENTERED;
    }

    function _reentrancyGuardStorageSlot() internal pure virtual returns (bytes32) {
        return REENTRANCY_GUARD_STORAGE;
    }
}

// contracts/ENSFall.sol

/**
 * @title ENSFall
 * @notice Dutch auction marketplace for unwrapped ENS names.
 *         Seller escrows their ENS name. Price decays exponentially
 *         over 21 days from START_PRICE to zero — identical curve to
 *         the ENS Temporary Premium Auction.
 *
 *         Buyer pays current price → gets name instantly.
 *         Seller receives 95.8% directly to their wallet.
 *         4.2% fee sent directly to feeRecipient.
 *
 * @dev Exponential decay formula (ENS-style):
 *      price = startPrice * 0.5^(elapsed / 1_day)
 *      - Price halves every 24 hours
 *      - 21 halvings over 21 days
 *      - Smoothly interpolated between halvings (no step-jumps)
 *      - Explicitly returns 0 at/after AUCTION_DURATION
 *
 *      Mainnet START_PRICE: 42069 ETH
 *      Price curve (mainnet):
 *        Day  0 → 42069.000 ETH
 *        Day  1 → 21034.500 ETH
 *        Day  2 → 10517.250 ETH
 *        Day  3 →  5258.625 ETH
 *        Day  4 →  2629.313 ETH
 *        Day  5 →  1314.656 ETH
 *        Day  6 →   657.328 ETH
 *        Day  7 →   328.664 ETH
 *        Day  8 →   164.332 ETH
 *        Day  9 →    82.166 ETH
 *        Day 10 →    41.083 ETH
 *        Day 11 →    20.542 ETH
 *        Day 12 →    10.271 ETH
 *        Day 13 →     5.135 ETH
 *        Day 14 →     2.568 ETH
 *        Day 15 →     1.284 ETH
 *        Day 16 →     0.642 ETH
 *        Day 17 →     0.321 ETH
 *        Day 18 →     0.160 ETH
 *        Day 19 →     0.080 ETH
 *        Day 20 →     0.040 ETH
 *        Day 21 →     0.000 ETH
 *
 * @dev Security model:
 *   - Unwrapped ENS only (ERC721 on BaseRegistrar) — no NameWrapper complexity
 *   - Name held in escrow by this contract during auction
 *   - Per-token approval only — never setApprovalForAll
 *   - Checks-Effects-Interactions pattern throughout
 *   - ReentrancyGuard on all state-changing external functions
 *   - Direct ETH push to seller and feeRecipient on purchase (CEI ensures all
 *     state is finalised before any external call; nonReentrant guards re-entry)
 *   - Owner can ONLY: update feeRecipient, rescue unlisted tokens, or emergency-
 *     return all listed names to their original sellers
 *   - No receive() / fallback() — accidental ETH reverts
 *   - ENS name expiry verified at list time AND purchase time
 *   - EXPIRY_BUFFER = 90 days (full ENS grace period)
 *   - Cancel permitted at any time by seller (no minimum listing duration)
 *   - Expired auctions permissionlessly reclaimable by anyone → seller
 *   - Seller always receives payment to their own listing address
 */

/// @dev Minimal ENS BaseRegistrar interface (unwrapped names)
interface IENSBaseRegistrar {
    function ownerOf(uint256 tokenId) external view returns (address);
    function nameExpires(uint256 id) external view returns (uint256);
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
}

contract ENSFall is ReentrancyGuard, Ownable {

    // ═══════════════════════════════════════════════════════════════
    // Immutables & Constants
    // ═══════════════════════════════════════════════════════════════

    /// @notice ENS BaseRegistrar (unwrapped ERC721 names)
    ///         Mainnet + Sepolia: 0x57f1887a8BF19b14fC0dF6Fd9B2acc9Af147eA85
    IENSBaseRegistrar public immutable ENS_REGISTRAR;

    /// @notice Starting auction price in wei. Set at deploy time.
    ///         Mainnet: 42069 ether. Sepolia testing: 0.1 ether.
    ///         No price oracle — denominated purely in ETH.
    uint256 public immutable START_PRICE;

    /// @notice Auction duration in seconds. Set at deploy time.
    ///         Mainnet: 21 days. Sepolia testing: 12 hours.
    uint256 public immutable AUCTION_DURATION;

    /// @notice Half-life: price halves every 1 day (ENS-style)
    uint256 public constant HALF_LIFE = 1 days;

    /// @notice Total halvings over full auction (21 days / 1 day = 21)
    uint256 public constant TOTAL_HALVINGS = 21;

    /// @notice Fee in basis points: 420 = 4.2%
    uint256 public constant FEE_BPS = 420;

    /// @notice Basis point denominator
    uint256 public constant BPS_DENOMINATOR = 10_000;

    /// @notice Minimum time before ENS name expiry required to LIST.
    ///         111 days = 21-day auction window + 90-day buyer buffer.
    ///         Ensures buyer always receives a name with at least 90 days
    ///         of valid registration remaining after the auction completes.
    ///         Fixed regardless of AUCTION_DURATION so Sepolia test deploys
    ///         have the same listing eligibility rule as mainnet.
    uint256 public constant LIST_EXPIRY_BUFFER = 111 days;

    /// @notice Minimum time before ENS name expiry required at PURCHASE time.
    ///         90 days = full ENS grace period safety buffer.
    ///         Guards against a name expiring while in escrow between list and purchase.
    uint256 public constant EXPIRY_BUFFER = 90 days;

    // ═══════════════════════════════════════════════════════════════
    // State
    // ═══════════════════════════════════════════════════════════════

    /// @notice Address that receives the 4.2% protocol fee
    address public feeRecipient;

    /// @notice Backup admin wallet — has identical admin powers to owner.
    ///         Cannot change ownership or replace itself — only owner can update backupAdmin.
    ///         Set to address(0) to disable.
    address public backupAdmin;

    struct Listing {
        address seller;   // Original owner who listed — always receives payment
        uint256 tokenId;  // ENS label hash (the ERC721 tokenId)
        uint256 listedAt; // Block timestamp when listing was created
        bool    active;   // False once purchased, cancelled, or reclaimed
    }

    /// @notice All listings, keyed by tokenId
    mapping(uint256 => Listing) public listings;

    /// @notice All active tokenIds for frontend enumeration
    uint256[] public listedTokenIds;

    /// @notice O(1) removal index
    mapping(uint256 => uint256) private _listingIndex;

    // ═══════════════════════════════════════════════════════════════
    // Events
    // ═══════════════════════════════════════════════════════════════

    event Listed(
        uint256 indexed tokenId,
        address indexed seller,
        uint256 startPrice,
        uint256 listedAt
    );

    event Purchased(
        uint256 indexed tokenId,
        address indexed buyer,
        address indexed seller,
        uint256 pricePaid,
        uint256 sellerReceived,
        uint256 feeCollected
    );

    event Cancelled(
        uint256 indexed tokenId,
        address indexed seller
    );

    event AuctionExpired(
        uint256 indexed tokenId,
        address indexed seller,
        address indexed calledBy
    );

    event FeeRecipientUpdated(
        address indexed oldRecipient,
        address indexed newRecipient
    );

    event BackupAdminUpdated(
        address indexed oldAdmin,
        address indexed newAdmin
    );

    event TokenRescued(
        uint256 indexed tokenId,
        address indexed to
    );

    event EmergencyReturn(
        uint256 indexed tokenId,
        address indexed seller
    );

    // ═══════════════════════════════════════════════════════════════
    // Constructor
    // ═══════════════════════════════════════════════════════════════

    /**
     * @param _ensRegistrar    ENS BaseRegistrar address
     *                         (0x57f1887a8BF19b14fC0dF6Fd9B2acc9Af147eA85 on mainnet + Sepolia)
     * @param _startPrice      Auction start price in wei.
     *                         Mainnet: 42069 ether. Sepolia test: 0.1 ether.
     * @param _feeRecipient    Address that receives the 4.2% protocol fee
     * @param _auctionDuration Auction duration in seconds.
     *                         Mainnet: 21 days (1814400). Sepolia test: 12 hours (43200).
     * @param _backupAdmin     Optional backup admin wallet with identical admin powers to owner.
     *                         Pass address(0) to disable.
     */
    constructor(
        address _ensRegistrar,
        uint256 _startPrice,
        address _feeRecipient,
        uint256 _auctionDuration,
        address _backupAdmin
    ) Ownable(msg.sender) {
        require(_ensRegistrar    != address(0),                      "ENSFall: zero registrar");
        require(_startPrice      >  0,                               "ENSFall: zero start price");
        require(_feeRecipient    != address(0),                      "ENSFall: zero fee recipient");
        require(_auctionDuration >  0,                               "ENSFall: zero duration");
        require(
            _auctionDuration <= TOTAL_HALVINGS * HALF_LIFE,
            "ENSFall: duration exceeds price curve"
        );

        ENS_REGISTRAR    = IENSBaseRegistrar(_ensRegistrar);
        START_PRICE      = _startPrice;
        feeRecipient     = _feeRecipient;
        AUCTION_DURATION = _auctionDuration;
        backupAdmin      = _backupAdmin;
    }

    // ═══════════════════════════════════════════════════════════════
    // Modifiers
    // ═══════════════════════════════════════════════════════════════

    /**
     * @dev Allows either the owner OR the backupAdmin to call admin functions.
     *      backupAdmin cannot update itself — only owner can call setBackupAdmin().
     */
    modifier onlyAdminOrOwner() {
        require(
            msg.sender == owner() ||
            (backupAdmin != address(0) && msg.sender == backupAdmin),
            "ENSFall: not authorized"
        );
        _;
    }

    // ═══════════════════════════════════════════════════════════════
    // Core: List
    // ═══════════════════════════════════════════════════════════════

    /**
     * @notice List an unwrapped ENS name for Dutch auction.
     * @dev Caller must approve this contract for the specific tokenId first
     *      (approve, NOT setApprovalForAll). Name transfers into escrow here.
     *      Payment always goes to msg.sender (the seller). No alternate address.
     *
     *      Name must have at least LIST_EXPIRY_BUFFER (111 days) remaining before expiry.
     *      This covers the full 21-day auction plus a 90-day post-auction buffer for the buyer.
     *
     * @param tokenId ENS label hash (uint256(keccak256(label)))
     */
    function list(uint256 tokenId) external nonReentrant {
        require(!listings[tokenId].active,                     "ENSFall: already listed");
        require(ENS_REGISTRAR.ownerOf(tokenId) == msg.sender,  "ENSFall: not owner");

        uint256 expiry = ENS_REGISTRAR.nameExpires(tokenId);
        require(
            expiry >= block.timestamp + LIST_EXPIRY_BUFFER,
            "ENSFall: name expires too soon"
        );

        // Effects first
        listings[tokenId] = Listing({
            seller:   msg.sender,
            tokenId:  tokenId,
            listedAt: block.timestamp,
            active:   true
        });
        _listingIndex[tokenId] = listedTokenIds.length;
        listedTokenIds.push(tokenId);

        // Interaction: escrow the name
        ENS_REGISTRAR.transferFrom(msg.sender, address(this), tokenId);

        emit Listed(tokenId, msg.sender, START_PRICE, block.timestamp);
    }

    // ═══════════════════════════════════════════════════════════════
    // Core: Purchase
    // ═══════════════════════════════════════════════════════════════

    /**
     * @notice Purchase the ENS name at the current Dutch auction price.
     *         Overpayment is refunded immediately to buyer.
     *         Seller receives 95.8% directly. Protocol fee (4.2%) sent directly
     *         to feeRecipient. All state finalised before any ETH is moved (CEI).
     *
     * @param tokenId ENS label hash to purchase
     */
    function purchase(uint256 tokenId) external payable nonReentrant {
        Listing storage listing = listings[tokenId];

        // Cache storage reads (saves ~200 gas per repeated SLOAD)
        bool    isActive = listing.active;
        address seller   = listing.seller;
        uint256 listedAt = listing.listedAt;

        require(isActive, "ENSFall: not listed");

        uint256 elapsed = block.timestamp - listedAt;
        require(elapsed < AUCTION_DURATION, "ENSFall: auction expired");

        // Guard: name hasn't expired while in escrow
        uint256 expiry = ENS_REGISTRAR.nameExpires(tokenId);
        require(expiry >= block.timestamp + EXPIRY_BUFFER, "ENSFall: name expired");

        uint256 price = _calcPrice(elapsed);
        require(price > 0,         "ENSFall: zero price");
        require(msg.value >= price, "ENSFall: insufficient payment");

        // Effects — all state finalised before any external interaction
        listing.active = false;
        _removeFromList(tokenId);

        uint256 fee          = (price * FEE_BPS) / BPS_DENOMINATOR;
        uint256 sellerAmount = price - fee;
        uint256 refund       = msg.value - price;

        emit Purchased(tokenId, msg.sender, seller, price, sellerAmount, fee);

        // Interactions — name to buyer, then ETH out (refund → fee → seller)
        ENS_REGISTRAR.transferFrom(address(this), msg.sender, tokenId);

        if (refund > 0) {
            (bool refunded,) = msg.sender.call{value: refund}("");
            require(refunded, "ENSFall: refund failed");
        }

        if (fee > 0) {
            (bool feeSent,) = feeRecipient.call{value: fee}("");
            require(feeSent, "ENSFall: fee transfer failed");
        }

        (bool sellerPaid,) = seller.call{value: sellerAmount}("");
        require(sellerPaid, "ENSFall: seller payment failed");
    }

    // ═══════════════════════════════════════════════════════════════
    // Core: Cancel
    // ═══════════════════════════════════════════════════════════════

    /**
     * @notice Cancel listing and reclaim the escrowed ENS name.
     *         Only the original seller can cancel. No waiting period —
     *         seller may cancel at any time, including within the first 24 hours.
     */
    function cancel(uint256 tokenId) external nonReentrant {
        Listing storage listing = listings[tokenId];
        require(listing.active,               "ENSFall: not listed");
        require(listing.seller == msg.sender, "ENSFall: not seller");

        listing.active = false;
        _removeFromList(tokenId);

        emit Cancelled(tokenId, msg.sender);

        ENS_REGISTRAR.transferFrom(address(this), msg.sender, tokenId);
    }

    // ═══════════════════════════════════════════════════════════════
    // Core: Reclaim Expired
    // ═══════════════════════════════════════════════════════════════

    /**
     * @notice Permissionlessly return an expired listing's name back to the seller.
     *         Anyone can call this after AUCTION_DURATION has elapsed.
     *         Prevents names being permanently locked if a seller loses access.
     *
     * @param tokenId ENS label hash of the expired listing
     */
    function reclaimExpired(uint256 tokenId) external nonReentrant {
        Listing storage listing = listings[tokenId];
        require(listing.active, "ENSFall: not listed");
        require(
            block.timestamp >= listing.listedAt + AUCTION_DURATION,
            "ENSFall: auction still active"
        );

        address seller = listing.seller;
        listing.active = false;
        _removeFromList(tokenId);

        emit AuctionExpired(tokenId, seller, msg.sender);

        ENS_REGISTRAR.transferFrom(address(this), seller, tokenId);
    }

    // ═══════════════════════════════════════════════════════════════
    // View: Price — ENS-style fixed-point exponential decay
    // ═══════════════════════════════════════════════════════════════

    /// @dev WAD fixed-point base (1e18 = 1.0)
    uint256 private constant WAD = 1e18;

    /// @dev ln(2) × WAD — used for fractional-period exponential approximation
    uint256 private constant LN2 = 693147180559945309;

    /**
     * @notice Current auction price for a listed name.
     * @param tokenId ENS label hash
     * @return price in wei (0 if not active or expired)
     */
    function currentPrice(uint256 tokenId) public view returns (uint256) {
        Listing storage listing = listings[tokenId];
        if (!listing.active) return 0;

        uint256 elapsed = block.timestamp - listing.listedAt;
        if (elapsed >= AUCTION_DURATION) return 0;

        return _calcPrice(elapsed);
    }

    /**
     * @notice Preview the price at any elapsed time (useful for frontends and testing).
     * @param secondsElapsed Seconds since listing start (0 → AUCTION_DURATION)
     * @return price in wei
     */
    function previewPrice(uint256 secondsElapsed) external view returns (uint256) {
        if (secondsElapsed >= AUCTION_DURATION) return 0;
        return _calcPrice(secondsElapsed);
    }

    /**
     * @dev Core price calculation — ENS-style inline fixed-point exponential.
     *
     *      price = START_PRICE × 2^(−n) × 2^(−f)
     *        where n = elapsed / HALF_LIFE  (integer halvings, exact via >>)
     *              f = remainder / HALF_LIFE (fraction in [0,1))
     *
     *      2^(−f) = e^(−f·ln2) ≈ 1 − x + x²/2 − x³/6 + x⁴/24
     *        where x = f·ln2 ∈ [0, ln2) ≈ [0, 0.693)
     *      4-term Taylor series: <0.15% error, consistent with ENS ExponentialPremiumPriceOracle.
     *      Directional bias: price very slightly above true exponential (favours sellers marginally).
     *
     *      All arithmetic in WAD (1e18) fixed-point. No overflow risk.
     */
    function _calcPrice(uint256 elapsed) internal view returns (uint256) {
        uint256 halvings  = elapsed / HALF_LIFE;
        uint256 remainder = elapsed % HALF_LIFE;

        if (halvings >= TOTAL_HALVINGS) return 0;

        // Integer part: exact bit-shift
        uint256 intPrice = START_PRICE >> halvings;
        if (intPrice == 0) return 0;

        // Fractional part: Taylor polynomial approximation of 2^(−f)
        uint256 f  = (remainder * WAD) / HALF_LIFE;
        uint256 x  = (LN2 * f) / WAD;
        uint256 x2 = (x  * x)  / WAD;
        uint256 x3 = (x2 * x)  / WAD;
        uint256 x4 = (x3 * x)  / WAD;

        // Group pos/neg terms to avoid intermediate underflow
        uint256 pos        = WAD + x2 / 2 + x4 / 24;
        uint256 neg        = x   + x3 / 6;
        uint256 fracFactor = pos > neg ? pos - neg : 0;

        return (intPrice * fracFactor) / WAD;
    }

    // ═══════════════════════════════════════════════════════════════
    // View: Listings
    // ═══════════════════════════════════════════════════════════════

    function getActiveListings() external view returns (uint256[] memory) {
        return listedTokenIds;
    }

    function activeListingCount() external view returns (uint256) {
        return listedTokenIds.length;
    }

    function getListing(uint256 tokenId) external view returns (
        address seller,
        uint256 listedAt,
        bool    active,
        uint256 price,
        uint256 expiresAt,
        uint256 secondsRemaining
    ) {
        Listing storage l = listings[tokenId];
        seller           = l.seller;
        listedAt         = l.listedAt;
        active           = l.active;
        price            = currentPrice(tokenId);
        expiresAt        = l.active ? l.listedAt + AUCTION_DURATION : 0;
        secondsRemaining = (l.active && block.timestamp < expiresAt)
                           ? expiresAt - block.timestamp
                           : 0;
    }

    // ═══════════════════════════════════════════════════════════════
    // Admin: Fee recipient, rescue, emergency return
    // ═══════════════════════════════════════════════════════════════

    /**
     * @notice Update the backup admin wallet. Owner-only — backupAdmin cannot replace itself.
     *         Pass address(0) to revoke backup admin access.
     */
    function setBackupAdmin(address newAdmin) external onlyOwner {
        address old = backupAdmin;
        backupAdmin = newAdmin;
        emit BackupAdminUpdated(old, newAdmin);
    }

    /**
     * @notice Update fee recipient. Callable by owner or backupAdmin.
     */
    function setFeeRecipient(address newRecipient) external onlyAdminOrOwner {
        require(newRecipient != address(0), "ENSFall: zero address");
        address old = feeRecipient;
        feeRecipient = newRecipient;
        emit FeeRecipientUpdated(old, newRecipient);
    }

    /**
     * @notice Rescue an ENS name sent to this contract without list().
     *         Owner can ONLY act on tokens with NO active listing.
     *         Active escrow names are completely untouchable by owner.
     *
     * @param tokenId ENS label hash of the unlisted stuck token
     * @param to      Recipient address
     */
    function rescueUnlistedToken(uint256 tokenId, address to) external onlyAdminOrOwner {
        require(!listings[tokenId].active, "ENSFall: active listing");
        require(to != address(0),           "ENSFall: zero address");

        emit TokenRescued(tokenId, to);
        ENS_REGISTRAR.transferFrom(address(this), to, tokenId);
    }

    /**
     * @notice Emergency: return ALL listed names to their original sellers.
     *         Owner-only. Use when migrating to a new contract version or
     *         when a critical bug requires evacuating all escrowed names.
     *         Names are returned to the seller address recorded at listing time.
     *         Owner cannot redirect names — they go exclusively to their sellers.
     *
     * @dev    Iterates backwards through listedTokenIds for safe in-place removal.
     *         Gas cost scales with listing count (~80k gas per name).
     *         For large listing counts, call in batches via emergencyReturnBatch().
     */
    function emergencyReturnAll() external onlyAdminOrOwner nonReentrant {
        uint256 i = listedTokenIds.length;
        while (i > 0) {
            unchecked { --i; }
            uint256 tokenId = listedTokenIds[i];
            address seller  = listings[tokenId].seller;

            // Effects
            listings[tokenId].active = false;
            delete _listingIndex[tokenId];
            listedTokenIds.pop();

            emit EmergencyReturn(tokenId, seller);

            // Interaction
            ENS_REGISTRAR.transferFrom(address(this), seller, tokenId);
        }
    }

    /**
     * @notice Emergency: return a specific batch of listed names to their sellers.
     *         Use this if emergencyReturnAll() would hit the block gas limit.
     *
     * @param tokenIds Array of tokenIds to return (must all be active listings)
     */
    function emergencyReturnBatch(uint256[] calldata tokenIds) external onlyAdminOrOwner nonReentrant {
        for (uint256 i = 0; i < tokenIds.length; ) {
            uint256 tokenId = tokenIds[i];
            require(listings[tokenId].active, "ENSFall: not active listing");

            address seller = listings[tokenId].seller;

            // Effects
            listings[tokenId].active = false;
            _removeFromList(tokenId);

            emit EmergencyReturn(tokenId, seller);

            // Interaction
            ENS_REGISTRAR.transferFrom(address(this), seller, tokenId);

            unchecked { ++i; }
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // Internal
    // ═══════════════════════════════════════════════════════════════

    function _removeFromList(uint256 tokenId) internal {
        uint256 idx = _listingIndex[tokenId];
        unchecked {
            uint256 lastIdx = listedTokenIds.length - 1;
            if (idx != lastIdx) {
                uint256 lastToken        = listedTokenIds[lastIdx];
                listedTokenIds[idx]      = lastToken;
                _listingIndex[lastToken] = idx;
            }
        }
        listedTokenIds.pop();
        delete _listingIndex[tokenId];
    }

    // No receive() — reverts on accidental ETH
    // No fallback() — reverts on unknown calls
}