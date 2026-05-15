// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.22;

import {ERC20} from "@openzeppelin/contracts@5.2.0/token/ERC20/ERC20.sol";

contract Endemic is ERC20 {
    constructor(address recipient) ERC20("Endemic", "END") {
        _mint(recipient, 50000000 * 10 ** decimals());
    }
}
