/*----------------------------------------------------------*|
|*          ███    ██ ██ ███    ██ ███████  █████           *|
|*          ████   ██ ██ ████   ██ ██      ██   ██          *|
|*          ██ ██  ██ ██ ██ ██  ██ █████   ███████          *|
|*          ██  ██ ██ ██ ██  ██ ██ ██      ██   ██          *|
|*          ██   ████ ██ ██   ████ ██      ██   ██          *|
|*----------------------------------------------------------*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./utils/Counters.sol";
import "./access/Ownable.sol";

/**
 * @title NinfaCollections
 */

contract NinfaCollections is Ownable {

  using Counters for Counters.Counter;
  /// @notice Listings counter
  Counters.Counter private _listingCount;
  /// @notice Auctions counter
  Counters.Counter private _auctionCount;

  address private _feeRecipient;

  uint256 private _primaryFixedPriceFee;

  uint256 private _primaryAuctionsFee;

  ///@notice constant 10,000 BPS = 100% shares sale price
  uint256 private constant _BPS_DENOMINATOR = 10_000;

  /// @notice `_listingCount` counter to `_Order` struct mapping
  mapping(uint256 => _Listing) private _listings;
  /// @notice `_auctionCount` counter to `_Auction` struct mapping
  mapping(uint256 => _Auction) private _auctions;

  mapping(address => uint256) private _listedCollections;

  uint256 private constant _EXTENSION_DURATION = 15 minutes;

  uint256 private constant _MIN_BID_RAISE = 20;

  enum ListingType {
    FixedPrice,
    Auction
  }

  /**
   * @notice Represents a listing of an entire collection at a fixed price or reserve price
   * buyers will be able to buy or bid on any token in the collection owned by the seller
   * All the sales made are primary sales.
   */
  struct _Listing {
    address collection;
    address seller;
    uint256 price;
    uint256 start;
    uint256 end;
    uint256 auctionDuration;
    uint256[] commissionBps;
    address[] commissionReceivers;
    ListingType listingType;
  }

  /**
   * @notice Represents an auction that started. Independent from listings
   * the listing from which the auction was created can be cancelled or updated without affecting the auction
   */
  struct _Auction {
    address collection;
    address seller;
    address bidder;
    uint256 bidPrice;
    uint256 tokenId;
    uint256 end;
    uint256 auctionDuration;
    uint256[] commissionBps;
    address[] commissionReceivers;
  }

  event ListingCreated(uint256 listingId);

  event ListingCancelled(uint256 listingId);

  event ListingUpdated(uint256 listingId);

  /**
   * @notice Emitted when a fixed price order is executed
   */
  event Trade(uint256 listingId, uint256 tokenId, address buyer);

  /**
   * @notice Emitted when a bid is placed on an auction listing
   */
  event Bid(uint256 auctionId);

  /**
   * @notice Emitted when an auction is finalized
   */
  event AuctionFinalized(uint256 auctionId);

  function onERC721Received(
    address _operator,
    address _from,
    uint256 _tokenId,
    bytes calldata _data
  )
      external
      returns (bytes4)
  {
    // do nothing
    return 0x150b7a02;
  }

  function createListing(
    uint256 _price,
    address _collection,
    uint256 _start,
    uint256 _end,
    uint256 _auctionDuration,
    uint256[] memory _commissionBps,
    address[] memory _commissionReceivers,
    ListingType _listingType
  ) external {
    require(_start < _end && _end > block.timestamp && _listedCollections[_collection] == 0);

    if(_listingType == ListingType.Auction) {
      require(_auctionDuration >= 1 days);
    }

    (bool success, bytes memory balanceData) = 
      _collection.call(abi.encodeWithSelector(0x70a08231, msg.sender)); // balanceOf

    uint256 balance = abi.decode(balanceData, (uint256));
    require(success && balance > 0);
    _listingCount.increment();
    uint256 _listingId = _listingCount.current();
    _listings[_listingId] = _Listing(
      _collection,
      msg.sender, // seller
      _price,
      _start,
      _end,
      _auctionDuration,
      _commissionBps,
      _commissionReceivers,
      _listingType
    );
    _listedCollections[_collection] = _listingId;
    emit ListingCreated(_listingId);
  }

  function cancelListing(uint256 _listingId) external {
    _Listing memory listing = _listings[_listingId];
    require(listing.seller == msg.sender);
    delete _listedCollections[listing.collection];
    delete _listings[_listingId];
    emit ListingCancelled(_listingId);
  }

  function updateListing(
    uint256 _listingId,
    uint256 _price,
    uint256 _start,
    uint256 _end,
    uint256 _auctionDuration,
    uint256[] memory _commissionBps,
    address[] memory _commissionReceivers
  ) external {
    _Listing storage listing = _listings[_listingId];
    require(listing.seller == msg.sender && _start < _end && _end > block.timestamp);

    if(listing.listingType == ListingType.Auction) {
      require(_auctionDuration >= 1 days);
    }

    listing.price = _price;
    listing.start = _start;
    listing.end = _end;
    listing.auctionDuration = _auctionDuration;
    listing.commissionBps = _commissionBps;
    listing.commissionReceivers = _commissionReceivers;
    emit ListingUpdated(_listingId);
  }

  function buy(
    uint256 _listingId,
    uint256 _tokenId,
    address _buyer
  ) external payable {
    _Listing memory listing = _listings[_listingId];
    require(
      listing.listingType == ListingType.FixedPrice && 
      listing.price == msg.value &&
      listing.start <= block.timestamp &&
      listing.end >= block.timestamp
    );
    // Transfers the NFT to the buyer. The contract must be approved by the seller. 
    // Will fail if the seller does not own the NFT
    _handlePayment(
      listing.price,
      _primaryFixedPriceFee,
      listing.seller,
      listing.commissionBps,
      listing.commissionReceivers
    );
    _transferNFT(listing.collection, listing.seller, _buyer, _tokenId);
    emit Trade(_listingId, _tokenId, _buyer);
  }

  function firstBid(
    uint256 _listingId,
    uint256 _tokenId
  ) external payable {
    _Listing memory listing = _listings[_listingId];

    require(
      listing.listingType == ListingType.Auction && 
      msg.value >= listing.price &&
      listing.start <= block.timestamp && 
      listing.end >= block.timestamp
    );

    _auctionCount.increment();
    uint256 _auctionId = _auctionCount.current();

    _auctions[_auctionId] = _Auction(
      listing.collection,
      listing.seller, // seller
      msg.sender, // bidder
      msg.value, // bidPrice
      _tokenId,
      block.timestamp + listing.auctionDuration,
      listing.auctionDuration,
      listing.commissionBps,
      listing.commissionReceivers
    );

    // Escrows the NFT. Must be approved by the seller.
    // Will fail if the seller does not own the NFT 
    // (either because the auction already started or because the seller already sold the NFT)
    _transferNFT(listing.collection, listing.seller, address(this), _tokenId);

    emit Bid(_auctionId);
  }

  function bid(uint256 _auctionId) external payable {
    _Auction storage auction = _auctions[_auctionId];

    require(
      block.timestamp <= auction.end &&
      msg.value - auction.bidPrice >= auction.bidPrice / _MIN_BID_RAISE
    );

    // extend the auction if the bid is placed in the last 15 minutes
    if (block.timestamp + _EXTENSION_DURATION > auction.end) {
      unchecked {
        auction.end += _EXTENSION_DURATION;
      }
    }

    // refund the last bidder
    _sendValue(auction.bidder, auction.bidPrice);

    // update the auction
    auction.bidPrice = msg.value; // new highest bid
    auction.bidder = msg.sender; // new highest bidder

    emit Bid(_auctionId);
  }

  function finalize(uint256 _auctionId) external {
    _Auction memory auction = _auctions[_auctionId];

    require(block.timestamp > auction.end);

    delete _auctions[_auctionId];

    // Transfers the NFT to the bidder.
    _handlePayment(
      auction.bidPrice,
      _primaryAuctionsFee,
      auction.seller,
      auction.commissionBps,
      auction.commissionReceivers
    );
    _transferNFT(auction.collection, address(this), auction.bidder, auction.tokenId);
    emit AuctionFinalized(_auctionId);
  }

  function _handlePayment(
    uint256 _price,
    uint256 _feeBps,
    address _seller,
    uint256[] memory _commissionBps,
    address[] memory _commissionReceivers
  ) private {      
    uint256 marketplaceAmount = (_price * _feeBps) / _BPS_DENOMINATOR;
    uint256 sellerAmount = _price - marketplaceAmount;

    uint256 commissionReceiversLength = _commissionReceivers.length;

    if (commissionReceiversLength > 0) {
      do {
        commissionReceiversLength--;
        if(_commissionBps[commissionReceiversLength] > 0){
          uint256 commissionAmount = (_commissionBps[commissionReceiversLength] * _price) / _BPS_DENOMINATOR; // calculate

          sellerAmount -= commissionAmount; // subtract before external

          _sendValue(_commissionReceivers[commissionReceiversLength], commissionAmount);
        }
      } while (commissionReceiversLength > 0);
    }

    _sendValue(_feeRecipient, marketplaceAmount);
    _sendValue(_seller, sellerAmount);
  }

  function _transferNFT(
    address _collection,
    address _from,
    address _to,
    uint256 _tokenId
  )
    private
  {
    (bool success,) = _collection.call(abi.encodeWithSelector(0x42842e0e, _from, _to, _tokenId));
    require(success);
  }

  function _sendValue(address _receiver, uint256 _amount) private {
    // solhint-disable-next-line avoid-low-level-calls
    (bool success,) = payable(_receiver).call{ value: _amount }("");
    require(success);
  }

  function listings(uint256 _listingId) external view returns (_Listing memory) {
    return _listings[_listingId];
  }

  function getCollectionListing(address _collection) external view returns (_Listing memory) {
    return _listings[_listedCollections[_collection]];
  }

  function auctions(uint256 _auctionId) external view returns (_Auction memory) {
    return _auctions[_auctionId];
  }

  // owner functions

  function setFeeRecipient(address feeRecipient) external onlyOwner {
    _feeRecipient = feeRecipient;
  }

  function setPrimaryOrdersFee(uint256 primaryFixedPriceFee) external onlyOwner {
    _primaryFixedPriceFee = primaryFixedPriceFee;
  }

  function setPrimaryAuctionsFee(uint256 primaryAuctionsFee) external onlyOwner {
    _primaryAuctionsFee = primaryAuctionsFee;
  }

  function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
    return interfaceId == 0x01ffc9a7 || interfaceId == 0x150b7a02;
  }

  constructor(
    address feeRecipient, 
    uint256 primaryOrdersFee, 
    uint256 primaryAuctionsFee
  ) {
    _feeRecipient = feeRecipient;
    _primaryFixedPriceFee = primaryOrdersFee;
    _primaryAuctionsFee = primaryAuctionsFee;
  }
}