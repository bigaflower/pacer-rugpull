// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract HytopiaNFTStrategy is ERC20Burnable, ERC20Permit {
    uint256 public constant MAX_SUPPLY = 10_000_000 * 1e18; // 10 million tokens with 18 decimals

    constructor() ERC20("HYSTRATEGY", "HYST") ERC20Permit("HYSTRATEGY") {
        _mint(msg.sender, MAX_SUPPLY);
    }
}