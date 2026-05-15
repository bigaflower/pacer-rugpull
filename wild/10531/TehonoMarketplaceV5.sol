// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts (last updated v5.4.0) (utils/introspection/IERC165.sol)

pragma solidity >=0.4.16;

/**
 * @dev Interface of the ERC-165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[ERC].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[ERC section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: @openzeppelin/contracts/token/ERC1155/IERC1155.sol


// OpenZeppelin Contracts (last updated v5.4.0) (token/ERC1155/IERC1155.sol)

pragma solidity >=0.6.2;


/**
 * @dev Required interface of an ERC-1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[ERC].
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` amount of tokens of type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the value of tokens of token type `id` owned by `account`.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the zero address.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers a `value` amount of tokens of type `id` from `from` to `to`.
     *
     * WARNING: This function can potentially allow a reentrancy attack when transferring tokens
     * to an untrusted contract, when invoking {IERC1155Receiver-onERC1155Received} on the receiver.
     * Ensure to follow the checks-effects-interactions pattern and consider employing
     * reentrancy guards when interacting with untrusted contracts.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `value` amount.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 value, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * WARNING: This function can potentially allow a reentrancy attack when transferring tokens
     * to an untrusted contract, when invoking {IERC1155Receiver-onERC1155BatchReceived} on the receiver.
     * Ensure to follow the checks-effects-interactions pattern and consider employing
     * reentrancy guards when interacting with untrusted contracts.
     *
     * Emits either a {TransferSingle} or a {TransferBatch} event, depending on the length of the array arguments.
     *
     * Requirements:
     *
     * - `ids` and `values` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external;
}

// File: @openzeppelin/contracts/utils/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v5.1.0) (utils/ReentrancyGuard.sol)

pragma solidity ^0.8.20;

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
 */
abstract contract ReentrancyGuard {
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

    uint256 private _status;

    /**
     * @dev Unauthorized reentrant call.
     */
    error ReentrancyGuardReentrantCall();

    constructor() {
        _status = NOT_ENTERED;
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

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be NOT_ENTERED
        if (_status == ENTERED) {
            revert ReentrancyGuardReentrantCall();
        }

        // Any calls to nonReentrant after this point will fail
        _status = ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == ENTERED;
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;

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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;


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

// File: @openzeppelin/contracts/utils/Pausable.sol


// OpenZeppelin Contracts (last updated v5.3.0) (utils/Pausable.sol)

pragma solidity ^0.8.20;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    bool private _paused;

    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    /**
     * @dev The operation failed because the contract is paused.
     */
    error EnforcedPause();

    /**
     * @dev The operation failed because the contract is not paused.
     */
    error ExpectedPause();

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        if (paused()) {
            revert EnforcedPause();
        }
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        if (!paused()) {
            revert ExpectedPause();
        }
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: contracts/TehonoMarketplaceV5.sol


pragma solidity ^0.8.20;





contract TehonoMarketplaceV5 is ReentrancyGuard, Ownable, Pausable {
    
    uint256 public platformFeeBasisPoints = 150; 
    
    address public feeRecipient = 0x0C0eC963CeA5cE0528E32ab744ee89e279263203; 

    struct Listing {
        address seller;
        uint256 price;
        uint256 quantity;
    }

    struct Offer {
        uint256 pricePerUnit;
        uint256 quantity;
        uint256 totalValueLocked;
    }

    mapping(address => mapping(uint256 => Listing)) public listings;
    mapping(address => mapping(uint256 => mapping(address => Offer))) public offers;
    
    mapping(address => mapping(uint256 => address)) public tokenCreators;
    mapping(address => mapping(uint256 => uint256)) public tokenRoyalties;

    event ItemListed(address indexed seller, address indexed nft, uint256 indexed tokenId, uint256 quantity, uint256 price);
    event ItemSold(address indexed buyer, address indexed seller, address indexed nft, uint256 tokenId, uint256 quantity, uint256 price);
    event ListingCancelled(address indexed seller, address indexed nft, uint256 indexed tokenId);
    event OfferMade(address indexed buyer, address indexed nft, uint256 indexed tokenId, uint256 quantity, uint256 pricePerUnit);
    event OfferCancelled(address indexed buyer, address indexed nft, uint256 indexed tokenId);
    event OfferAccepted(address indexed seller, address indexed buyer, address indexed nft, uint256 tokenId, uint256 quantity, uint256 pricePerUnit);

    constructor() Ownable(msg.sender) {}

    function pauseMarket() external onlyOwner { _pause(); }
    function unpauseMarket() external onlyOwner { _unpause(); }
    
    function setPlatformFee(uint256 _newFee) external onlyOwner { 
        require(_newFee <= 1000, "Frais max 10%"); // Sécurité anti-abus
        platformFeeBasisPoints = _newFee; 
    }
    
    function setFeeRecipient(address _newRecipient) external onlyOwner {
        feeRecipient = _newRecipient;
    }

    function listItem(address _nft, uint256 _tokenId, uint256 _quantity, uint256 _price, uint256 _royaltyPct) external whenNotPaused nonReentrant {
        require(_price > 0, "Prix > 0");
        require(_quantity > 0, "Quantite > 0");
        require(_royaltyPct <= 15, "Royalties max 15%");

        IERC1155 nft = IERC1155(_nft);
        require(nft.balanceOf(msg.sender, _tokenId) >= _quantity, "Pas assez de stock");
        require(nft.isApprovedForAll(msg.sender, address(this)), "Marche non approuve");

        if (tokenCreators[_nft][_tokenId] == address(0)) {
            tokenCreators[_nft][_tokenId] = msg.sender;
            tokenRoyalties[_nft][_tokenId] = _royaltyPct * 100;
        }

        listings[_nft][_tokenId] = Listing(msg.sender, _price, _quantity);
        emit ItemListed(msg.sender, _nft, _tokenId, _quantity, _price);
    }

    function updateListing(address _nft, uint256 _tokenId, uint256 _newPrice) external whenNotPaused nonReentrant {
        Listing storage listing = listings[_nft][_tokenId];
        require(listing.seller == msg.sender, "Pas le vendeur");
        require(_newPrice > 0, "Prix invalide");
        listing.price = _newPrice;
    }

    function cancelListing(address _nft, uint256 _tokenId) external nonReentrant {
        require(listings[_nft][_tokenId].seller == msg.sender, "Pas le vendeur");
        delete listings[_nft][_tokenId];
        emit ListingCancelled(msg.sender, _nft, _tokenId);
    }

    function buyItem(address _nft, uint256 _tokenId, uint256 _buyQty) external payable whenNotPaused nonReentrant {
        Listing storage listing = listings[_nft][_tokenId];
        require(listing.price > 0, "Pas en vente");
        require(listing.quantity >= _buyQty, "Stock insuffisant");

        uint256 totalPrice = listing.price * _buyQty;
        require(msg.value >= totalPrice, "Fonds insuffisants");

        uint256 platformCut = (totalPrice * platformFeeBasisPoints) / 10000;
        uint256 royaltyCut = (totalPrice * tokenRoyalties[_nft][_tokenId]) / 10000;
        uint256 sellerCut = totalPrice - platformCut - royaltyCut;

        if(platformCut > 0) {
            (bool successFee, ) = feeRecipient.call{value: platformCut}("");
            require(successFee, "Echec paiement frais");
        }
        if(royaltyCut > 0) {
            (bool successRoy, ) = tokenCreators[_nft][_tokenId].call{value: royaltyCut}("");
            require(successRoy, "Echec paiement royalties");
        }
        
        (bool successSeller, ) = listing.seller.call{value: sellerCut}("");
        require(successSeller, "Echec paiement vendeur");

        IERC1155(_nft).safeTransferFrom(listing.seller, msg.sender, _tokenId, _buyQty, bytes(""));
        listing.quantity -= _buyQty;
        if (listing.quantity == 0) delete listings[_nft][_tokenId];

        emit ItemSold(msg.sender, listing.seller, _nft, _tokenId, _buyQty, listing.price);
    }

    function makeOffer(address _nft, uint256 _tokenId, uint256 _quantity, uint256 _pricePerUnit) external payable whenNotPaused nonReentrant {
        uint256 totalLocked = _quantity * _pricePerUnit;
        require(msg.value == totalLocked, "Montant ETH invalide");
        require(offers[_nft][_tokenId][msg.sender].totalValueLocked == 0, "Annulez l'ancienne offre");

        offers[_nft][_tokenId][msg.sender] = Offer(_pricePerUnit, _quantity, totalLocked);
        emit OfferMade(msg.sender, _nft, _tokenId, _quantity, _pricePerUnit);
    }

    function cancelOffer(address _nft, uint256 _tokenId) external nonReentrant {
        uint256 refundAmount = offers[_nft][_tokenId][msg.sender].totalValueLocked;
        require(refundAmount > 0, "Aucune offre");

        delete offers[_nft][_tokenId][msg.sender];
        
        (bool success, ) = msg.sender.call{value: refundAmount}("");
        require(success, "Echec remboursement");
        
        emit OfferCancelled(msg.sender, _nft, _tokenId);
    }

    function acceptOffer(address _nft, uint256 _tokenId, address _buyer) external whenNotPaused nonReentrant {
        Offer memory offer = offers[_nft][_tokenId][_buyer];
        require(offer.totalValueLocked > 0, "Offre invalide");

        IERC1155 nft = IERC1155(_nft);
        require(nft.balanceOf(msg.sender, _tokenId) >= offer.quantity, "Stock insuffisant");
        require(nft.isApprovedForAll(msg.sender, address(this)), "Marche non approuve");

        delete offers[_nft][_tokenId][_buyer];

        uint256 platformCut = (offer.totalValueLocked * platformFeeBasisPoints) / 10000;
        uint256 royaltyCut = (offer.totalValueLocked * tokenRoyalties[_nft][_tokenId]) / 10000;
        uint256 sellerCut = offer.totalValueLocked - platformCut - royaltyCut;

        if(platformCut > 0) {
            (bool successFee, ) = feeRecipient.call{value: platformCut}("");
            require(successFee, "Echec paiement frais");
        }
        if(royaltyCut > 0) {
            (bool successRoy, ) = tokenCreators[_nft][_tokenId].call{value: royaltyCut}("");
            require(successRoy, "Echec paiement royalties");
        }
        
        (bool successSeller, ) = msg.sender.call{value: sellerCut}("");
        require(successSeller, "Echec paiement vendeur");

        nft.safeTransferFrom(msg.sender, _buyer, _tokenId, offer.quantity, bytes(""));

        if(listings[_nft][_tokenId].seller == msg.sender) {
            if(listings[_nft][_tokenId].quantity >= offer.quantity) listings[_nft][_tokenId].quantity -= offer.quantity;
            else listings[_nft][_tokenId].quantity = 0;
            if(listings[_nft][_tokenId].quantity == 0) delete listings[_nft][_tokenId];
        }

        emit OfferAccepted(msg.sender, _buyer, _nft, _tokenId, offer.quantity, offer.pricePerUnit);
    }
}