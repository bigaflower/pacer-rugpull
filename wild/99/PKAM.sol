// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/// @title PKAM(PKAM) – Optimized Permissionless ERC-20
contract PKAM {
    // --- ERC20 Metadata ---
    string public name     = "PIKA PAMM";
    string public symbol   = "PKAM";
    uint8  public constant decimals = 18;
    uint256 public totalSupply;

    // --- Mappings for Balances and Allowances ---
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;

    // --- Events ---
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice Constructor that mints  TOKEN to the deployer
    constructor() {
        totalSupply = 2100_000_000 * 10**decimals;
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    /// @notice Returns the balance of the specified account
    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    /// @notice Transfers tokens to a specified address
    function transfer(address to, uint256 amount) external returns (bool) {
        uint256 senderBalance = balances[msg.sender];
        require(senderBalance >= amount, string(abi.encodePacked(symbol, ": insufficient balance")));
        unchecked {
            balances[msg.sender] = senderBalance - amount;
            balances[to] += amount;
        }
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    /// @notice Approves the specified address to spend the specified amount on behalf of the caller
    function approve(address spender, uint256 amount) external returns (bool) {
        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /// @notice Returns the remaining number of tokens that the spender is allowed to spend on behalf of the owner
    function allowance(address owner, address spender) external view returns (uint256) {
        return allowances[owner][spender];
    }

    /// @notice Transfers tokens from one address to another using the allowance mechanism
    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        uint256 fromBalance = balances[from];
        require(fromBalance >= amount, string(abi.encodePacked(symbol, ": insufficient balance")));
        uint256 allowedAmount = allowances[from][msg.sender];
        require(allowedAmount >= amount, string(abi.encodePacked(symbol, ": insufficient allowance")));
        unchecked {
            balances[from] = fromBalance - amount;
            balances[to] += amount;
            allowances[from][msg.sender] = allowedAmount - amount;
        }
        emit Transfer(from, to, amount);
        return true;
    }

    /// @notice Increases the allowance granted to the spender
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        allowances[msg.sender][spender] += addedValue;
        emit Approval(msg.sender, spender, allowances[msg.sender][spender]);
        return true;
    }

    /// @notice Decreases the allowance granted to the spender
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        uint256 current = allowances[msg.sender][spender];
        require(current >= subtractedValue,string(abi.encodePacked(symbol, ": decreased allowance below zero")));
        unchecked {
            allowances[msg.sender][spender] = current - subtractedValue;
        }
        emit Approval(msg.sender, spender, allowances[msg.sender][spender]);
        return true;
    }
}