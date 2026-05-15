// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract SCAM is ERC20Permit {
    uint256 private constant TOTAL_SUPPLY = 1_000_000_000 * 10 ** 18;

    constructor(address recipient) ERC20("Scam", "SCAM") ERC20Permit("Scam") {
        require(recipient != address(0), "SCAM: recipient cannot be zero address");
        _mint(recipient, TOTAL_SUPPLY);
    }
}