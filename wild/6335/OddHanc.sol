// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC20Burnable } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

/**
 * @title OddHanc Token Contract
 * @dev ERC20 token with a fixed capped supply minted at deployment and public burning capabilities.
 * Ownership removed for full decentralization from deployment.
 */
contract OddHanc is ERC20, ERC20Burnable {
    /**
     * @notice The maximum and total supply of tokens, immutable and set during contract deployment.
     * This ensures a fixed cap on the token supply for transparency and scarcity.
     */
    uint256 public immutable MAX_SUPPLY;

    // Custom errors for gas efficiency
    error ZeroBurnAmount();

    /**
     * @dev Emitted when tokens are burned by a user.
     * This event allows for better off-chain tracking of burn activities separately from standard Transfer events.
     * @param burner The address of the account that initiated the burn.
     * @param amount The amount of tokens burned (in wei).
     */
    event TokensBurned(address indexed burner, uint256 amount);

    /**
     * @dev Initializes the token, sets the max supply, and mints the entire supply to the deployer (msg.sender).
     * No initialOwner param since no ownership.
     */
    constructor() ERC20("OddHanc", "HANC") {
        MAX_SUPPLY = 520_851_852_113 * 10 ** 18;
        _mint(msg.sender, MAX_SUPPLY);
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * Explicit override for clarity, though it inherits 18 from ERC20.
     */
    function decimals() public pure override returns (uint8) {
        return 18;
    }

    /**
     * @dev Burns tokens from the caller's balance.
     * @param amount Amount to burn (in wei).
     * No reentrancy risk since it doesn’t handle external calls in burn. Safe.
     */
    function burn(uint256 amount) public override {
        if (amount == 0) revert ZeroBurnAmount();
        super.burn(amount);
        emit TokensBurned(msg.sender, amount);
    }
}