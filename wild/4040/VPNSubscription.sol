// SPDX-License-Identifier: MIT


pragma solidity ^0.8.20;



interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
}

interface AggregatorV3Interface {
    function latestRoundData() external view returns (
        uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound
    );
}

contract VPNSubscription {
    // Immutable variables save gas on every 'buy' call
    AggregatorV3Interface internal immutable priceFeed;
    IERC20 public immutable loyaltyToken;
    address public owner;
    
    bool public paused;
    bool private locked; 

    
    uint256 public constant TOKEN_REWARD = 4 * 10**18; 
    uint256 public constant STALE_PRICE_DELAY = 3600; 

    event TokensPurchased(address indexed buyer, uint256 ethSpent, uint256 usdValue);

    constructor(address _loyaltyToken) {
        require(_loyaltyToken != address(0), "Invalid token address");
        priceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
        loyaltyToken = IERC20(_loyaltyToken);
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier nonReentrant() {
        require(!locked, "Reentrancy protection");
        locked = true;
        _;
        locked = false;
    }


    function buy() external payable nonReentrant {
        require(!paused, "Contract is paused");
        
        ( , int256 price, , uint256 updatedAt, ) = priceFeed.latestRoundData();
        require(price > 0, "Invalid Oracle Price");
        require(block.timestamp - updatedAt <= STALE_PRICE_DELAY, "Price data too old");

        
        uint256 usdValue = (msg.value * uint256(price)) / 1e8;

        
        require(usdValue >= 395 * 10**16, "Sent less than $3.95");
        require(usdValue <= 405 * 10**16, "Sent more than $4.05");

        
        require(loyaltyToken.balanceOf(address(this)) >= TOKEN_REWARD, "Contract out of tokens");
        require(loyaltyToken.transfer(msg.sender, TOKEN_REWARD), "Transfer failed");

        emit TokensPurchased(msg.sender, msg.value, usdValue);
    }


    function withdrawEth() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        (bool success, ) = payable(owner).call{value: balance}("");
        require(success, "ETH Withdraw failed");
    }

    function withdrawAnyToken(address _token) external onlyOwner nonReentrant {
        uint256 balance = IERC20(_token).balanceOf(address(this));
        require(balance > 0, "No balance to withdraw");
        require(IERC20(_token).transfer(owner, balance), "Token Rescue failed");
    }


    function setPaused(bool _state) external onlyOwner {
        paused = _state;
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Invalid address");
        owner = _newOwner;
    }

    function getRequiredEth() public view returns (uint256) {
        ( , int256 price, , , ) = priceFeed.latestRoundData();
        return (4 * 10**26) / uint256(price);
    }

    receive() external payable {}
}