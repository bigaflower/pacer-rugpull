// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
/**
 * @title VOOI
 * @dev Standard ERC20 implementation of the Vooi ($VOOI) token
 *
 * Features:
 * - Standard ERC20 functionality
 * - Fixed supply of 1 billion tokens
 * - All tokens minted to specified recipient on deployment
 * - No additional permissions or restrictions
 * - Permit signing for approval
 */

contract VOOI is ERC20Permit {
    /// @dev Total supply: 1 billion tokens (1e9 * 10^18)
    uint256 private constant TOTAL_SUPPLY = 1_000_000_000 * 10 ** 18;

    /**
     * @dev Constructor that mints all tokens to the specified recipient
     * @param recipient The address that will receive all tokens
     */
    constructor(address recipient) ERC20("VOOI", "VOOI") ERC20Permit("VOOI") {
        require(recipient != address(0), "VOOI: recipient cannot be zero address");
        _mint(recipient, TOTAL_SUPPLY);
    }
}