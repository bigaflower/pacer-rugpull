// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Import OpenZeppelin ERC20 from GitHub (works directly in Remix)
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.6/contracts/token/ERC20/ERC20.sol";

contract StormToken is ERC20 {
    constructor(address initialHolder) ERC20("Storm Token", "STORM") {
        // Mint exactly 1,000,000,000 STORM (18 decimals) to your treasury Safe
        _mint(initialHolder, 1_000_000_000 * 10 ** decimals());
    }
}
