// SPDX-License-Identifier: MIT
// Flattened for Remix – Cymatic Song Royalties (no external deps)
pragma solidity ^0.8.20;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

/**
 * Cymatic Song Gallery – royalties by song and creator.
 * - Only contract owner can grant QUINE rewards per song. Creator withdraws all ETH + QUINE in one tx (withdrawAllRoyaltiesAndQuine).
 */
contract CymaticSongs {
    uint256 public constant BASE_DOWNLOAD_PRICE_WEI = 500000000000000;

    address public owner;

    uint256 public pricePerDownloadWei;
    uint256 public songCount;

    mapping(uint256 => address) public songCreator;

    mapping(uint256 => uint256) public songPrice;

    mapping(uint256 => uint256) public songRoyaltyBalance;

    address public quineToken;
    mapping(uint256 => uint256) public songQuineBalance;
    mapping(uint256 => uint256) public songQuineReward;

    event SongCreated(uint256 indexed songId, address indexed creator, string contentCid);
    event SongPriceSet(uint256 indexed songId, address indexed creator, uint256 priceWei);
    event DownloadPurchased(uint256 indexed songId, address indexed buyer, address indexed creator, uint256 amount);
    event AllRoyaltiesAndQuineWithdrawn(address indexed creator, uint256 ethAmount, uint256 quineAmount);
    event QuineTokenSet(address indexed token);
    event QuineRewardGranted(uint256 indexed songId, address indexed creator, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(uint256 pricePerDownloadWei_) {
        owner = msg.sender;
        pricePerDownloadWei = pricePerDownloadWei_;
    }

    function setPricePerDownload(uint256 priceWei) external onlyOwner {
        pricePerDownloadWei = priceWei;
    }

    function createSong(string calldata contentCid) external returns (uint256 songId) {
        songId = ++songCount;
        songCreator[songId] = msg.sender;
        emit SongCreated(songId, msg.sender, contentCid);
        return songId;
    }

    function setSongPrice(uint256 songId, uint256 priceWei) external {
        require(songCreator[songId] != address(0), "Invalid song");
        require(msg.sender == songCreator[songId], "Not song creator");
        songPrice[songId] = priceWei;
        emit SongPriceSet(songId, msg.sender, priceWei);
    }

    function purchaseDownload(uint256 songId) external payable {
        address creator = songCreator[songId];
        require(creator != address(0), "Invalid song");

        uint256 perSongPrice = songPrice[songId];
        uint256 effectivePrice = perSongPrice > 0 ? perSongPrice : pricePerDownloadWei;
        require(effectivePrice > 0, "Price not set");
        require(msg.value >= effectivePrice, "Insufficient payment");

        songRoyaltyBalance[songId] += effectivePrice;

        if (msg.value > effectivePrice) {
            (bool ok,) = msg.sender.call{ value: msg.value - effectivePrice }("");
            require(ok, "Refund failed");
        }

        emit DownloadPurchased(songId, msg.sender, creator, effectivePrice);
    }

    function withdrawAllRoyaltiesAndQuine() external {
        uint256 totalEth = 0;
        uint256 totalQuine = 0;
        for (uint256 id = 1; id <= songCount; id++) {
            if (songCreator[id] != msg.sender) continue;
            if (songRoyaltyBalance[id] > 0) {
                totalEth += songRoyaltyBalance[id];
                songRoyaltyBalance[id] = 0;
            }
            if (songQuineBalance[id] > 0) {
                totalQuine += songQuineBalance[id];
                songQuineBalance[id] = 0;
            }
        }
        require(totalEth > 0 || totalQuine > 0, "No royalties or QUINE");
        if (totalEth > 0) {
            (bool ok,) = msg.sender.call{ value: totalEth }("");
            require(ok, "ETH transfer failed");
        }
        if (totalQuine > 0) {
            require(quineToken != address(0), "QUINE token not set");
            require(IERC20(quineToken).transfer(msg.sender, totalQuine), "QUINE transfer failed");
        }
        emit AllRoyaltiesAndQuineWithdrawn(msg.sender, totalEth, totalQuine);
    }

    function setQuineToken(address token) external onlyOwner {
        quineToken = token;
        emit QuineTokenSet(token);
    }

    function grantQuineReward(uint256 songId, uint256 amountWei) external onlyOwner {
        address creator = songCreator[songId];
        require(creator != address(0), "Invalid song");
        require(quineToken != address(0), "QUINE token not set");
        require(amountWei > 0, "Zero amount");
        IERC20 token = IERC20(quineToken);
        require(token.transferFrom(msg.sender, address(this), amountWei), "Transfer failed");
        songQuineBalance[songId] += amountWei;
        songQuineReward[songId] += amountWei;
        emit QuineRewardGranted(songId, creator, amountWei);
    }

    function getSong(uint256 songId) external view returns (address creator, string memory contentCid) {
        creator = songCreator[songId];
        contentCid = "";
        return (creator, contentCid);
    }

    function getSongRoyaltyBalance(uint256 songId) external view returns (uint256) {
        return songRoyaltyBalance[songId];
    }

    function getRoyaltyBalance(address creator) external view returns (uint256) {
        uint256 total = 0;
        for (uint256 id = 1; id <= songCount; id++) {
            if (songCreator[id] == creator) total += songRoyaltyBalance[id];
        }
        return total;
    }

    function getSongQuineBalance(uint256 songId) external view returns (uint256) {
        return songQuineBalance[songId];
    }

    function getQuineBalance(address creator) external view returns (uint256) {
        uint256 total = 0;
        for (uint256 id = 1; id <= songCount; id++) {
            if (songCreator[id] == creator) total += songQuineBalance[id];
        }
        return total;
    }
}