// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

/**
 * @title MovieDOMToken
 * @dev ERC20 token
 * - Standard ERC20 implementation
 * - Supports ERC20Permit for gasless approvals
 * - Includes burn and burnFrom functions
 */
contract MovieDOMToken is ERC20, ERC20Permit {
    uint256 public constant INITIAL_SUPPLY = 1000000000 * 10 ** 18; // 1 billion tokens

    /**
     * @dev Constructor initializes the token with standard parameters
     */
    constructor(
        string memory name,
        string memory symbol,
        address owner
    ) ERC20(name, symbol) ERC20Permit(name) {
        _mint(owner, INITIAL_SUPPLY);
    }

    /**
     * @dev Burns a specific amount of the caller's tokens
     * @param amount The amount of tokens to burn
     */
    function burn(uint256 amount) external virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Burns tokens from a specific account
     * @param account The account whose tokens will be burned
     * @param amount The amount of tokens to burn
     */
    function burnFrom(address account, uint256 amount) external virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(
            currentAllowance >= amount,
            "ERC20: burn amount exceeds allowance"
        );
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }
}