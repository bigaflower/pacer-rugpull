import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract derrikToken is ERC20 {
    constructor() ERC20("derrik", "der") {
        _mint(msg.sender, 1000000000000000 * 10 ** decimals());
    }
}
