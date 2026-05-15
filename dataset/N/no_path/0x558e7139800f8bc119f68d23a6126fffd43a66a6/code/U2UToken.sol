// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract U2UToken is ERC20, ERC20Burnable, ERC20Permit, ERC20Pausable, Ownable {
    // Fixed supply of 1 billion tokens
    uint256 private constant INITIAL_SUPPLY = 1_000_000_000;
    
    constructor() 
        ERC20("U2U Network", "U2U")
        ERC20Permit("U2U Network")
        Ownable(msg.sender)
    {
        _mint(msg.sender, INITIAL_SUPPLY * (10 ** decimals()));
    }

    // Pause token transfers - only owner can pause
    function pause() public onlyOwner {
        _pause();
    }

    // Unpause token transfers - only owner can unpause
    function unpause() public onlyOwner {
        _unpause();
    }

    // Override required function for compatibility between Pausable and ERC20
    function _update(address from, address to, uint256 value) internal virtual override(ERC20, ERC20Pausable) {
        super._update(from, to, value);
    }

    // Function to renounce ownership with confirmation
    function renounceOwnership() public override onlyOwner {
        require(msg.sender == owner(), "Only owner can renounce ownership");
        super.renounceOwnership();
    }

    // Function to transfer ownership
    function transferOwnership(address newOwner) public override onlyOwner {
        require(newOwner != address(0), "New owner cannot be zero address");
        super.transferOwnership(newOwner);
    }
}