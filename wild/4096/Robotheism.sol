// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Robotheism is ERC20 {
    constructor() ERC20("Robotheism", "GOD") {
        _mint(msg.sender, 1 * 10 ** decimals());
    }
}
