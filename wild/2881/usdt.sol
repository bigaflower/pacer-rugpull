// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract USDT {

    string public name = "USDT";
    string public symbol = "Tether";
    uint8 public decimals = 18;

    uint256 public totalSupply;
    uint256 public expiryTime;

    address public owner;

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    modifier notExpired() {
        require(block.timestamp < expiryTime, "Token expired");
        _;
    }

    constructor(uint256 initialSupplyWholeTokens) {
        owner = msg.sender;

        // 90 days expiry
        expiryTime = block.timestamp + 90 days;

        totalSupply = initialSupplyWholeTokens * 10 ** decimals;
        balances[msg.sender] = totalSupply;

        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    function transfer(address to, uint256 amount) public notExpired returns (bool) {
        require(balances[msg.sender] >= amount, "Insufficient balance");

        balances[msg.sender] -= amount;
        balances[to] += amount;

        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public notExpired returns (bool) {
        allowances[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function allowance(address owner_, address spender) public view returns (uint256) {
        return allowances[owner_][spender];
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public notExpired returns (bool) {

        require(balances[from] >= amount, "Balance too low");
        require(allowances[from][msg.sender] >= amount, "Allowance exceeded");

        allowances[from][msg.sender] -= amount;
        balances[from] -= amount;
        balances[to] += amount;

        emit Transfer(from, to, amount);
        return true;
    }

    // Helper: kitne seconds baqi hain
    function secondsUntilExpiry() external view returns (uint256) {
        if (block.timestamp >= expiryTime) return 0;
        return expiryTime - block.timestamp;
    }
}
