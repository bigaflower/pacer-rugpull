// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract MAZZE is ERC20, ERC20Burnable, ERC20Permit {
        
        /**
        * The total supply of the token is set to 5,000,000,000. This establishes the upper limit 
        * of tokens that will ever be in circulation on Ethereum network.
        */
        uint256 private _totalSupply = 5000000000 * (10 ** 18);

        /**
        *
        * Allocating 20% to the "Ecosystem Development Fund" is crucial for funding ongoing 
        * development, research, and innovation within the token's ecosystem.
        */
        uint256 private _ecosystemDevelopment = _totalSupply * 20 / 100;
        
        /**
        * Allocating 12% of the total supply to the "Team Growth Fund" supports the team's 
        * long-term commitment and incentivizes their continuous contribution to the project's 
        * success.
        */
        uint256 private _teamGrowth = _totalSupply * 12 / 100;

        /**
        * Allocating 8% for the "Community Engagement Fund" fosters a strong, interactive 
        * community. This fund can be used for community rewards or other engagement 
        * initiatives.
        */
        uint256 private _communityEngagement = _totalSupply * 8 / 100;

        /**
        * Allocating 8% for the "Marketing and Promotion Fund" ensures ample resources are available 
        * for advertising, partnerships, and other promotional activities to increase the token's 
        * visibility and adoption.
        */
        uint256 private _marketingPromotion = _totalSupply * 8 / 100;

        /**
        * The remaining 52% of the tokens, referred to as _remainingTokens, are allocated to the 
        * Deployer for purposes such as public sale and ensuring liquidity post-listing. This large 
        * allocation allows for significant market penetration and liquidity provision.
        */
        uint256 private _remainingTokens = _totalSupply - (_teamGrowth + _communityEngagement + _marketingPromotion + _ecosystemDevelopment); 
    
    constructor() ERC20("MAZZE", "MAZZE") ERC20Permit("MAZZE") {
        _mint(0xA043BC356A11f548f77F716e8d3c31b1e8beDf7a, _ecosystemDevelopment);
        _mint(0xa81AA52EA19ef26739B0762C03381f9a84c8b05d, _teamGrowth);
        _mint(0x49d125cA46997e3C90ebB0cc9940e033487F8FA4, _communityEngagement);
        _mint(0x8126A70a57B44d32e6eB9F41c8DF4A2A47Ff4Be7, _marketingPromotion);
        _mint(msg.sender, _remainingTokens);
    }
}
