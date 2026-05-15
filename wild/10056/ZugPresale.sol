// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract ZUGPresaleV2 is Ownable, ReentrancyGuard {
    IERC20 public zugToken;
    
    // Price in USD with 18 decimal precision (e.g., $1.50 = 1500000000000000000)
    uint256 public tokenPriceUsd;
    
    // Chainlink Price Feed (ETH/USD or BNB/USD)
    AggregatorV3Interface public priceFeed;
    
    // Commission Configuration
    uint256 public commissionPercentage = 10; // 10%
    uint256 public minPurchaseForCommission = 0.005 ether; // Minimum purchase to trigger commission

    // Events
    event TokenPurchased(address indexed buyer, uint256 paymentAmount, uint256 tokenAmount, uint256 priceUsd);
    event ReferralCommissionPaid(address indexed referrer, address indexed buyer, uint256 commissionAmount);
    event PriceUpdated(uint256 oldPrice, uint256 newPrice);
    event CommissionConfigUpdated(uint256 newPercentage, uint256 newMinPurchase);
    event ETHWithdrawn(address indexed owner, uint256 amount);
    event TokensWithdrawn(address indexed owner, uint256 amount);
    
    constructor(address _zugToken, uint256 _initialPriceUsd, address _priceFeed) Ownable(msg.sender) {
        require(_zugToken != address(0), "Invalid token address");
        require(_priceFeed != address(0), "Invalid price feed address");
        
        zugToken = IERC20(_zugToken);
        tokenPriceUsd = _initialPriceUsd;
        priceFeed = AggregatorV3Interface(_priceFeed);
    }
    
    /**
     * @dev Get latest Coin/USD price from Chainlink (8 decimals)
     */
    function getLatestPrice() public view returns (uint256) {
        (, int256 price,,,) = priceFeed.latestRoundData();
        require(price > 0, "Invalid price from oracle");
        return uint256(price);
    }
    
    /**
     * @dev purchase ZUG with optional Referrer
     */
    function purchaseZUG(address referrer) external payable nonReentrant {
        _processPurchase(referrer);
    }

    /**
     * @dev Backward compatible purchase ZUG (No referrer)
     */
    function purchaseZUG() external payable nonReentrant {
        _processPurchase(address(0));
    }

    function _processPurchase(address referrer) internal {
        require(msg.value > 0, "Must send ETH/BNB");
        require(msg.value >= 0.00001 ether, "Minimum purchase is 0.00001");

        // 1. Calculate Token Amount
        uint256 tokenAmount = calculateTokenAmount(msg.value);
        require(tokenAmount > 0, "Token amount must be greater than 0");
        require(zugToken.balanceOf(address(this)) >= tokenAmount, "Insufficient tokens in contract");

        // 2. Handle Referral Commission
        if (referrer != address(0) && referrer != msg.sender && msg.value >= minPurchaseForCommission) {
            uint256 commission = (msg.value * commissionPercentage) / 100;
            // Transfer commission instantly
            (bool success, ) = payable(referrer).call{value: commission}("");
            if (success) {
                emit ReferralCommissionPaid(referrer, msg.sender, commission);
            }
        }

        // 3. Transfer Tokens to Buyer
        require(zugToken.transfer(msg.sender, tokenAmount), "Token transfer failed");
        
        emit TokenPurchased(msg.sender, msg.value, tokenAmount, tokenPriceUsd);
    }
    
    function calculateTokenAmount(uint256 paymentAmount) public view returns (uint256) {
        uint256 currentPrice = getLatestPrice(); // 8 decimals
        // Value in USD = (Amount * Price) / 1e8
        uint256 valueUsd = (paymentAmount * currentPrice) / 1e8;
        // Tokens = (Value USD * 1e18) / Token Price
        return (valueUsd * 1e18) / tokenPriceUsd;
    }
    
    function setCommissionConfig(uint256 _percentage, uint256 _minPurchase) external onlyOwner {
        require(_percentage <= 20, "Commission too high"); // Safety cap
        commissionPercentage = _percentage;
        minPurchaseForCommission = _minPurchase;
        emit CommissionConfigUpdated(_percentage, _minPurchase);
    }

    function setPrice(uint256 newPriceUsd) external onlyOwner {
        require(newPriceUsd > 0, "Price must be > 0");
        uint256 oldPrice = tokenPriceUsd;
        tokenPriceUsd = newPriceUsd;
        emit PriceUpdated(oldPrice, newPriceUsd);
    }
    
    function withdrawETH() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ETH to withdraw");
        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "Withdrawal failed");
        emit ETHWithdrawn(owner(), balance);
    }
    
    function withdrawTokens() external onlyOwner {
        uint256 balance = zugToken.balanceOf(address(this));
        require(balance > 0, "No tokens to withdraw");
        require(zugToken.transfer(owner(), balance), "Token withdrawal failed");
        emit TokensWithdrawn(owner(), balance);
    }
}
