
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; // NEW IMPORT FOR OWNERSHIP

contract APXCOIN is ERC20, Ownable { // NEWLY INHERITS Ownable
    constructor() ERC20("APXCOIN", "APX") Ownable(msg.sender) { // NEWLY SETS OWNER
        // Mint all 2 Billion tokens to the deployer (the owner)
        _mint(owner(), 2000000000 * 10 ** decimals()); 
    }
}