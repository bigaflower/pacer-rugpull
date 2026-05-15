// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.27;

import {ERC20} from "@openzeppelin/contracts@5.3.0/token/ERC20/ERC20.sol";
import {ERC20Permit} from "@openzeppelin/contracts@5.3.0/token/ERC20/extensions/ERC20Permit.sol";

contract GAILToken is ERC20, ERC20Permit {
    constructor() ERC20("GAIL Token", "GAIL") ERC20Permit("GAIL Token") {
        _mint(msg.sender, 1000000000 * 10 ** decimals());
    }
}
