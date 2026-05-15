// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract ETH {
    string public name = "Ethereum";
    string public symbol = "ETH";
    uint8 public decimals = 18;
    uint256 public totalSupply;

    address public owner;

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Mint(address indexed to, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
        uint256 initialSupply = 1_000_000_000 * 10 ** uint256(decimals); // 1 billion ETH with 18 decimals
        totalSupply = initialSupply;
        balances[owner] = initialSupply;
        emit Transfer(address(0), owner, initialSupply);
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        balances[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function allowance(address _owner, address spender) public view returns (uint256) {
        return allowances[_owner][spender];
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        require(balances[sender] >= amount, "Insufficient balance");
        require(allowances[sender][msg.sender] >= amount, "Allowance exceeded");
        balances[sender] -= amount;
        balances[recipient] += amount;
        allowances[sender][msg.sender] -= amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function mint(address to, uint256 amount) public onlyOwner returns (bool) {
        uint256 mintAmount = amount * 10 ** uint256(decimals);
        totalSupply += mintAmount;
        balances[to] += mintAmount;
        emit Transfer(address(0), to, mintAmount);
        emit Mint(to, mintAmount);
        return true;
    }
}