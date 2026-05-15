// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Simple ERC-20 token mimicking USDT
contract Tether {
    string public name = "Tether"; // Token name displayed in wallets
    string public symbol = "USDT"; // Token symbol displayed in wallets
    uint8 public decimals = 6; // USDT uses 6 decimals
    uint256 public totalSupply; // Total token supply
    mapping(address => uint256) public balanceOf; // Tracks balances
    mapping(address => mapping(address => uint256)) public allowance; // Tracks approvals

    address public owner; // Deployer’s address

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        owner = msg.sender;
        totalSupply = 1000000000 * 10 ** decimals; // 1B tokens
        balanceOf[msg.sender] = totalSupply; // Mint to deployer
    }

    function transfer(address to, uint256 value) public returns (bool) {
        require(balanceOf[msg.sender] >= value, "Insufficient balance");
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(balanceOf[from] >= value, "Insufficient balance");
        require(allowance[from][msg.sender] >= value, "Insufficient allowance");
        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true;
    }
}