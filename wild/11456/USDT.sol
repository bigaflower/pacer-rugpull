// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.27;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @custom:security-contact support@artablockchain.com
contract TethorUSDT is ERC20, ERC20Burnable, ERC20Permit, Ownable {
    constructor(address recipient, address initialOwner)
        ERC20("Tether USDT ", "USDT.a")
        ERC20Permit("Tether USDT")
        Ownable(initialOwner)
    {
        _mint(recipient, 100000000000 * 10 ** decimals());
    }
}
