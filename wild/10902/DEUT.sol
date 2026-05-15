// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DEUT is ERC20 {
    constructor() ERC20("DENeon Utility Token", "DEUT") {
        _mint(msg.sender, 50_000_000 * 10 ** decimals());
    }
}