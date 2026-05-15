// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ERC1155} from "solady/tokens/ERC1155.sol";
import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";

import {BaseStrategy} from "./BaseStrategy.sol";

/// @title ERC1155Strategy - An ERC20 token that constantly churns NFTs from a collection
/// @author TokenWorks (https://token.works/)
/// @notice This contract implements an ERC20 token backed by another token.
///         Users can trade the token on Uniswap V4, and the contract uses trading fees to buy bags of the underlying token.
/// @dev Uses ERC1967 proxy pattern with immutable args for gas-efficient upgrades
contract ERC1155Strategy is BaseStrategy {
    /* ™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™                ™™™™™™™™™™™                ™™™™™™™™™™™ */
    /* ™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™               ™™™™™™™™™™™™™              ™™™™™™™™™™  */
    /* ™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™              ™™™™™™™™™™™™™              ™™™™™™™™™™™  */
    /* ™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™             ™™™™™™™™™™™™™™            ™™™™™™™™™™™   */
    /* ™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™            ™™™™™™™™™™™™™™™            ™™™™™™™™™™™   */
    /*                ™™™™™™™™™™™            ™™™™™™™™™™™           ™™™™™™™™™™™™™™™           ™™™™™™™™™™™    */
    /*                ™™™™™™™™™™™             ™™™™™™™™™™          ™™™™™™™™™™™™™™™™™          ™™™™™™™™™™™    */
    /*                ™™™™™™™™™™™             ™™™™™™™™™™          ™™™™™™™™™™™™™™™™™          ™™™™™™™™™™     */
    /*                ™™™™™™™™™™™              ™™™™™™™™™™        ™™™™™™™™™™™™™™™™™™™        ™™™™™™™™™™™     */
    /*                ™™™™™™™™™™™              ™™™™™™™™™™™       ™™™™™™™™™ ™™™™™™™™™       ™™™™™™™™™™™      */
    /*                ™™™™™™™™™™™               ™™™™™™™™™™      ™™™™™™™™™™ ™™™™™™™™™™      ™™™™™™™™™™™      */
    /*                ™™™™™™™™™™™               ™™™™™™™™™™      ™™™™™™™™™   ™™™™™™™™™      ™™™™™™™™™™       */
    /*                ™™™™™™™™™™™                ™™™™™™™™™™    ™™™™™™™™™™    ™™™™™™™™™    ™™™™™™™™™™        */
    /*                ™™™™™™™™™™™                 ™™™™™™™™™™   ™™™™™™™™™     ™™™™™™™™™™  ™™™™™™™™™™™        */
    /*                ™™™™™™™™™™™                 ™™™™™™™™™™  ™™™™™™™™™™     ™™™™™™™™™™  ™™™™™™™™™™         */
    /*                ™™™™™™™™™™™                  ™™™™™™™™™™™™™™™™™™™™       ™™™™™™™™™™™™™™™™™™™™          */
    /*                ™™™™™™™™™™™                   ™™™™™™™™™™™™™™™™™™         ™™™™™™™™™™™™™™™™™™           */
    /*                ™™™™™™™™™™™                   ™™™™™™™™™™™™™™™™™™         ™™™™™™™™™™™™™™™™™™           */
    /*                ™™™™™™™™™™™                    ™™™™™™™™™™™™™™™™           ™™™™™™™™™™™™™™™™            */
    /*                ™™™™™™™™™™™                     ™™™™™™™™™™™™™™             ™™™™™™™™™™™™™™             */
    /*                ™™™™™™™™™™™                     ™™™™™™™™™™™™™™             ™™™™™™™™™™™™™™             */
    /*                ™™™™™™™™™™™                      ™™™™™™™™™™™™               ™™™™™™™™™™™™              */

    struct StrategyRange {
        uint256 start;
        uint256 end;
    }

    enum StrategyType {
        Range,
        List,
        All
    }

    struct Listing {
        uint256 price;
        uint256 tokenId;
    }

    /* ™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™ */
    /*                     CONSTANTS                       */
    /* ™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™ */

    /// @notice The collection this strategy is tied to
    ERC1155 public collection;

    /// @notice the range of ids, only if strategyType == StrategyType.Range
    StrategyRange public range;

    /// @notice the list of ids this strategy focuses on, only if strategyType == StrategyType.List
    mapping(uint256 => bool) acceptedIds;

    /// @notice the strategy type
    StrategyType public strategyType;

    /* ™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™ */
    /*                   STATE VARIABLES                   */
    /* ™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™ */

    /// @notice Mapping of listingId => Listing
    mapping(uint256 => Listing) public listings;

    /// @notice Counter for listings
    uint256 lastListingId;

    /// @notice Storage gap for future upgrades (prevents storage collisions)
    uint256[50] private __gap;

    /* ™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™ */
    /*                   CUSTOM EVENTS                     */
    /* ™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™ */

    /// @notice Emitted when the protocol buys from the collection
    event ERC1155BoughtByProtocol(
        uint256 indexed listingId,
        uint256 indexed tokenId,
        uint256 purchasePrice,
        uint256 listPrice
    );

    /// @notice Emitted when the protocol buys from the collection
    event ERC1155SoldByProtocol(
        uint256 indexed listingId,
        uint256 indexed tokenId,
        uint256 price,
        address buyer
    );

    /* ™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™ */
    /*                    CUSTOM ERRORS                    */
    /* ™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™ */

    /// @notice given sale id is not currently for sale
    error NotForSale();
    /// @notice Sent ETH amount is less than the bag sale price
    error PriceTooLow();
    /// @notice Call didn't result in buying the right amount of the token
    error NeedToBuyNFT();
    /// @notice triggered when trying to buy tokens for 0
    error NoZeroBuys();
    /// @notice triggered when there is an error in inputs
    error InputsError();
    /// @notice triggered when target is collection
    error InvalidTarget();
    /// @notice triggered when trying to buy a token not in the list (or range)
    error InvalidTokenId();
    /// @notice triggered when the external call fails when buying an NFT
    error ExternalCallFailed(bytes reason);
    /// @notice triggered when the given ids are not in the right order
    error InvalidIds();
    /// @notice triggered when receiving ERC1155 items from a wrong collection
    error InvalidCollection();
    /// @notice triggered when receiving too many items
    error InvalidAmount();

    /* ™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™ */
    /*                    CONSTRUCTOR                      */
    /* ™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™ */

    /// @notice Constructor calls BaseStrategy() to disable initializers
    /// @dev This is required for the proxy pattern to work correctly
    constructor() BaseStrategy() {}

    /// @notice Initializes the contract with required addresses and permissions
    /// @param _collection Address of the underlying ERC20 contract
    /// @param _strategyType type of ERC1155Strategy: Range|List
    /// @param _ids ids to initialize the type (list must be in ascending order)
    /// @param _hook Address of the StrategyHook contract
    /// @param _tokenName Name of the token
    /// @param _tokenSymbol Symbol of the token
    /// @param _buyIncrement Buy increment for the token
    /// @param _owner Owner of the contract
    function initialize(
        address _collection,
        StrategyType _strategyType,
        uint256[] memory _ids,
        address _hook,
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _buyIncrement,
        address _owner
    ) external initializer {
        require(_collection != address(0), "Invalid collection");

        collection = ERC1155(_collection);
        strategyType = _strategyType;

        _initializeIds(_strategyType, _ids);

        __BaseStrategy_init(
            _hook,
            _tokenName,
            _tokenSymbol,
            _buyIncrement,
            _owner
        );
    }

    /* ™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™ */
    /*                 GETTERS                             */
    /* ™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™ */

    /// @dev this must be incremented whenever there is any change in BaseStrategy or this strategy
    function VERSION() public pure override returns (uint256) {
        return 2;
    }

    /* ™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™ */
    /*                 MECHANISM FUNCTIONS                 */
    /* ™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™ */

    /// @notice Buys a specific NFT using accumulated fees
    /// @param value Amount of ETH to spend on the NFT purchase
    /// @param data Calldata for the external marketplace call
    /// @param tokenId The token ID expected to be acquired
    /// @param target The marketplace contract to call
    /// @dev Protected against reentrancy, validates NFT acquisition
    function buyTargetNFT(
        uint256 value,
        bytes calldata data,
        uint256 tokenId,
        address target
    ) external nonReentrant {
        if (target == address(collection)) revert InvalidTarget();

        // checking tokenId validity here instead of in onERC1155Received
        // because some implementations of ERC1155 do not call onERC1155Received
        if (strategyType == StrategyType.Range) {
            if (tokenId < range.start || tokenId > range.end) {
                revert InvalidTokenId();
            }
        } else if (strategyType == StrategyType.List) {
            if (!acceptedIds[tokenId]) {
                revert InvalidTokenId();
            }
        }

        uint256 ethBalanceBefore = address(this).balance;
        uint256 funds = availableFunds();

        // this prevents tokens from being locked in contract because if salePrice == 0
        // tokens would be seen as not on sale
        if (funds == 0) {
            revert NoZeroBuys();
        }

        // ensure the users doesn't ask for too much value
        if (value > funds) {
            revert NotEnoughEth();
        }

        uint256 listingId = (++lastListingId);

        uint256 tokenBalanceBefore = collection.balanceOf(
            address(this),
            tokenId
        );

        // Call external
        (bool success, bytes memory reason) = target.call{value: value}(data);
        if (!success) {
            revert ExternalCallFailed(reason);
        }

        if (
            collection.balanceOf(address(this), tokenId) !=
            tokenBalanceBefore + 1
        ) {
            revert NeedToBuyNFT();
        }

        // Calculate actual cost of the NFT to base new price on
        uint256 cost = ethBalanceBefore - address(this).balance;
        currentFees -= cost;

        uint256 listPrice = (cost * priceMultiplier) / 1000;
        listings[listingId] = Listing({price: listPrice, tokenId: tokenId});

        // Update last buy block to reset max price calculation
        lastBuyBlock = block.number;

        emit ERC1155BoughtByProtocol(listingId, tokenId, cost, listPrice);
    }

    /// @notice Sell an NFT that was previously bought and listed
    /// @param listingId The ID of the bag to sell
    function sellListing(uint256 listingId) external payable nonReentrant {
        Listing memory listing = listings[listingId];

        uint256 salePrice = listing.price;
        uint256 tokenId = listing.tokenId;

        // Verify listing is for sale
        if (salePrice == 0) revert NotForSale();

        // Verify sent ETH matches sale price
        if (msg.value != salePrice) revert PriceTooLow();

        // Remove from listings
        delete listings[listingId];

        // Transfer token to buyer
        collection.safeTransferFrom(address(this), msg.sender, tokenId, 1, "");

        // Add sale price to fees
        ethToTwap += salePrice;

        emit ERC1155SoldByProtocol(listingId, tokenId, salePrice, msg.sender);
    }

    /* ™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™ */
    /*                  GETTER FUNCTIONS                   */
    /* ™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™ */

    /// @notice Returns all listings from id 0 to {lastListingId} included
    /// @dev switch to list(start, end) if this function ever revert because too much gas
    /// @return all listing from id 0 to {lastListingId}
    function list() external view returns (Listing[] memory) {
        return list(0, lastListingId);
    }

    /// @notice Returns all listings from id {startId} to {endId} included
    /// @param startId the id of the first bag
    /// @param endId the id of the last bag
    /// @return _listings all listings from id {startId} to {endId}
    function list(
        uint256 startId,
        uint256 endId
    ) public view returns (Listing[] memory _listings) {
        if (endId < startId) {
            revert InputsError();
        }

        uint256 length = endId - startId + 1;
        _listings = new Listing[](length);

        for (uint256 i; i < length; i++) {
            _listings[i] = listings[startId + i];
        }
    }

    /* ™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™ */
    /*                  Internal FUNCTIONS                 */
    /* ™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™ */

    /// @dev initialize the strategy with type and ids
    /// @dev if type == Range, ids.length must be 2, in ascending order
    /// @dev if type == List, any number of ids, in ascending order
    /// @dev if type == All, ids must be empty
    /// @param _strategyType the strategy type (Range|List|All)
    /// @param ids the list of ids (must be in ascending order)
    function _initializeIds(
        StrategyType _strategyType,
        uint256[] memory ids
    ) internal {
        // initialize the range or the list
        if (_strategyType == StrategyType.All) {
            if (ids.length != 0) {
                revert InvalidIds();
            }
        } else if (_strategyType == StrategyType.Range) {
            if (ids.length != 2) {
                revert InvalidIds();
            }

            uint256 start = ids[0];
            uint256 end = ids[1];

            if (end < start) {
                revert InvalidIds();
            }

            range = StrategyRange(start, end);
        } else if (_strategyType == StrategyType.List) {
            uint256 length = ids.length;
            if (length == 0) {
                revert InvalidIds();
            }

            uint256 previousId;
            uint256 id;
            for (uint256 i; i < length; i++) {
                id = ids[i];
                if (i > 0) {
                    if (id <= previousId) {
                        revert InvalidIds();
                    }
                }
                acceptedIds[id] = true;
                previousId = id;
            }
        }
    }

    /* ™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™ */
    /*                      Callbacks                      */
    /* ™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™ */

    /// @notice Handles the receipt of items from the collection
    function onERC1155Received(
        address,
        address,
        uint256 tokenId,
        uint256 amount,
        bytes calldata
    ) external returns (bytes4) {
        if (msg.sender != address(collection)) {
            revert InvalidCollection();
        }

        if (amount != 1) {
            revert InvalidAmount();
        }

        return this.onERC1155Received.selector;
    }
}
