// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.5.0
pragma solidity ^0.8.33;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract GoldenPoolCoin is ERC20, ERC20Permit {
    constructor(address recipient)
        ERC20("Golden Pool Coin", "GPC")
        ERC20Permit("Golden Pool Coin")
    {
        _mint(recipient, 100000000 * 10 ** decimals());
    }
}