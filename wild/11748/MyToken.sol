// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol"; // Add ReentrancyGuard import

contract PAIRS is ERC20, ERC20Burnable, ERC20Pausable, Ownable, ERC20Permit, ReentrancyGuard {
    // Mapping to keep track of frozen accounts
    mapping(address => bool) private _frozenAccounts;

    // Events for freeze, unfreeze, and token withdrawal
    event Frozen(address indexed account);
    event Unfrozen(address indexed account);
    event TokensWithdrawn(address indexed token, address indexed to, uint256 amount);

    constructor(address initialOwner)
        ERC20("PAIRS", "PAIRS")
        Ownable(initialOwner)
        ERC20Permit("PAIRS")
    {
        // Mint 8,000,000,000 tokens (considering decimals, typically 18)
        _mint(initialOwner, 8000000000 * 10 ** decimals());
    }

    // Function to allow owner to withdraw any ERC20 tokens sent to the contract
    function withdrawTokens(address tokenAddress) public onlyOwner nonReentrant {
        require(tokenAddress != address(0), "Invalid token address");
        IERC20 token = IERC20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "No tokens to withdraw");
        token.transfer(owner(), balance);
        emit TokensWithdrawn(tokenAddress, owner(), balance);
    }

    // Freeze an account, preventing it from transferring tokens
    function freeze(address account) public onlyOwner {
        require(account != address(0), "Invalid address");
        require(!_frozenAccounts[account], "Account already frozen");
        _frozenAccounts[account] = true;
        emit Frozen(account);
    }

    // Unfreeze an account, restoring its ability to transfer tokens
    function unfreeze(address account) public onlyOwner {
        require(account != address(0), "Invalid address");
        require(_frozenAccounts[account], "Account not frozen");
        _frozenAccounts[account] = false;
        emit Unfrozen(account);
    }

    // Check if an account is frozen
    function isFrozen(address account) public view returns (bool) {
        return _frozenAccounts[account];
    }

    // Pause the contract (only owner)
    function pause() public onlyOwner {
        _pause();
    }

    // Unpause the contract (only owner)
    function unpause() public onlyOwner {
        _unpause();
    }

    // Override _update to include freeze and pausable checks
    function _update(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Pausable)
    {
        require(!_frozenAccounts[from], "Sender account is frozen");
        super._update(from, to, amount);
    }
}