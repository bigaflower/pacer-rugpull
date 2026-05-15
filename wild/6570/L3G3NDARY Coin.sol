// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract L3G3NDARYCoin is ERC20, ERC20Permit, Ownable {
    constructor(address initialOwner)
        ERC20("L3G3NDARY Coin", "LGND")
        ERC20Permit("L3G3NDARY Coin")
        Ownable(initialOwner)
    {
        _mint(msg.sender, 1000000000 * 10 ** decimals());
    }
}
