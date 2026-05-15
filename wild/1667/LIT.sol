// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Lighter is ERC20, ERC20Permit {
    string private constant NAME = "Lighter";
    string private constant SYMBOL = "LIT";
    uint256 private constant MAX_TOTAL_SUPPLY = 1_000_000_000 * (10 ** 18);

    constructor(address recipient) ERC20(NAME, SYMBOL) ERC20Permit(NAME) {
        _mint(recipient, MAX_TOTAL_SUPPLY);
    }
}
