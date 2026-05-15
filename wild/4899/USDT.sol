// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract USDT is ERC20, Ownable {

    constructor() ERC20("USDT", "USDT") Ownable(msg.sender) {
        uint256 initialSupply = 1_000_000_000 * 10**decimals();
        _mint(msg.sender, initialSupply);
    }
}
