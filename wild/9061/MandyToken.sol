//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MandyToken is ERC20 {
    constructor() ERC20("Mandy Token", "MANDY") {
        _mint(msg.sender, 1000000 * (10 ** uint256(decimals())));
    }
}
