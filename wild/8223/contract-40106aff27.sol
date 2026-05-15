// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.4.0
pragma solidity ^0.8.27;

/*
 ╔══════════════════════════════════════════════════════════════════════════════════════════╗
 ║                                                                                          ║
 ║          ██████   ██    ██   █████   ███    ██  ████████  ██████   ██  ██   ██           ║
 ║         ██    ██  ██    ██  ██   ██  ████   ██     ██     ██   ██  ██   ██ ██            ║
 ║         ██    ██  ██    ██  ███████  ██ ██  ██     ██     ██████   ██    ███             ║
 ║         ██ ▄▄ ██  ██    ██  ██   ██  ██  ██ ██     ██     ██   ██  ██   ██ ██            ║
 ║          ██████    ██████   ██   ██  ██   ████     ██     ██   ██  ██  ██   ██           ║
 ║              ▀▀                                                                          ║
 ║                                                                                          ║
 ║                        The Keymaker of Prediction Markets                                ║
 ║                                                                                          ║
 ╚══════════════════════════════════════════════════════════════════════════════════════════╝
*/

import {ERC20} from "@openzeppelin/contracts@5.4.0/token/ERC20/ERC20.sol";
import {ERC20Permit} from "@openzeppelin/contracts@5.4.0/token/ERC20/extensions/ERC20Permit.sol";

contract Quantrix is ERC20, ERC20Permit {
    constructor(address recipient)
        ERC20("Quantrix", "QTRX")
        ERC20Permit("Quantrix")
    {
        _mint(recipient, 1000000000 * 10 ** decimals());
    }
}
