// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

/// @title IDRISS Token contract
contract IDRISS is ERC20, ERC20Permit, ERC20Votes {
    /**
     * @dev EIP-20 token name for this token
     */
    string public constant TOKEN_NAME = "IDRISS";

    /**
     * @dev EIP-20 token symbol for this token
     */
    string public constant TOKEN_SYMBOL = "IDRISS";


    /// @dev Will mint 1 billion tokens to the dao treasury
    constructor(address treasury) ERC20(TOKEN_NAME, TOKEN_SYMBOL) ERC20Permit(TOKEN_NAME) {
        // "ether" is used here to get 18 decimals
        _mint(treasury, 1_000_000_000 ether);
    }

    // The following functions are overrides required by Solidity.
    
    /// Requirements: This contract cannot be the recipient
    /// @param from The account sending the tokens
    /// @param to The account that should receive the tokens
    /// @param value The amount of tokens to send
    function _update(
        address from,
        address to,
        uint256 value
    ) internal override(ERC20, ERC20Votes) {
        require(to != address(this), "IDRISS: cannot transfer tokens to token contract");
        super._update(from, to, value);
    }

    function nonces(
        address owner
    ) public view override(ERC20Permit, Nonces) returns (uint256) {
        return super.nonces(owner);
    }
}
