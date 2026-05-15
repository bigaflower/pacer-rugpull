// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract VAST is ERC20, ERC20Burnable, Ownable {
    uint256 public constant TOTAL_SUPPLY = 1_000_000_000 * 10**18; // 1 billion tokens
    uint256 public constant INITIAL_MINT = TOTAL_SUPPLY / 10; // 10% of total supply

    constructor() ERC20("VAST", "VAST") Ownable(msg.sender) {
        _mint(msg.sender, INITIAL_MINT); // Mint 10% of the total supply to the contract deployer
    }

    function mint(address to, uint256 amount) public onlyOwner {
        uint256 currentSupply = totalSupply();
        require(currentSupply + amount <= TOTAL_SUPPLY, "Minting would exceed the total supply");
        _mint(to, amount);
    }
}
