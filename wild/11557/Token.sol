// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract Token {
    string public name = "XLM";
    string public symbol = "XLM";
    uint8 public decimals = 18;
    uint256 private _totalSupply = 1_500_000_000_000 * 10 ** 18;

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address owner) public view returns (uint256) {
        return balances[owner];
    }

    function transfer(address to, uint256 value) public returns (bool) {
        require(to != address(0), "Invalid recipient");
        require(balances[msg.sender] >= value, "Balance too low");

        balances[msg.sender] -= value;
        balances[to] += value;

        emit Transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(to != address(0), "Invalid recipient");
        require(balances[from] >= value, "Balance too low");
        require(allowance[from][msg.sender] >= value, "Allowance too low");

        balances[from] -= value;
        balances[to] += value;
        allowance[from][msg.sender] -= value;

        emit Transfer(from, to, value);
        emit Approval(from, msg.sender, allowance[from][msg.sender]);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        allowance[msg.sender][spender] += addedValue;
        emit Approval(msg.sender, spender, allowance[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(allowance[msg.sender][spender] >= subtractedValue, "Decreased allowance below zero");
        allowance[msg.sender][spender] -= subtractedValue;
        emit Approval(msg.sender, spender, allowance[msg.sender][spender]);
        return true;
    }
}