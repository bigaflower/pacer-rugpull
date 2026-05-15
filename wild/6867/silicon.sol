// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
    Silicon (SILI)
    Total Supply: 21,000,000
    Decimals: 18
    Extras (2025-friendly):
      - EIP-2612 Permit (ERC20Permit)
      - Burnable (ERC20Burnable)
      - Ownable with renounceOwnership
*/

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Silicon is ERC20, ERC20Permit, ERC20Burnable, Ownable {
    constructor()
        ERC20("Silicon", "SILI")
        ERC20Permit("Silicon")
        Ownable(msg.sender)
    {
        _mint(msg.sender, 21_000_000 * 10 ** decimals());
    }

    // renounceOwnership() exists via Ownable (OpenZeppelin)
}
