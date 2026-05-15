// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
 * Minimal ERC20 (18 decimals), fixed supply minted to deployer.
 * No imports = tiny bytecode = cheap deploy.
 */
contract JEFF07 {
    string public name;
    string public symbol;
    uint8 public constant decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(string memory name_, string memory symbol_, uint256 initialSupplyTokens) {
        name = name_;
        symbol = symbol_;
        uint256 amount = initialSupplyTokens * 1e18; // 18 decimals
        totalSupply = amount;
        balanceOf[msg.sender] = amount;
        emit Transfer(address(0), msg.sender, amount);
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        _transfer(msg.sender, to, amount); return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount); return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        uint256 allowed = allowance[from][msg.sender];
        require(allowed >= amount, "allowance");
        allowance[from][msg.sender] = allowed - amount;
        _transfer(from, to, amount); return true;
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(to != address(0), "zero addr");
        uint256 bal = balanceOf[from];
        require(bal >= amount, "balance");
        unchecked { balanceOf[from] = bal - amount; }
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
    }
}