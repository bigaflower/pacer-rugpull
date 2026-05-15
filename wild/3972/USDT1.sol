// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract USDT1 {
    string public name = "USDT1";
    string public symbol = "USDT1";
    uint8 public decimals = 6;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowed;
    address public owner;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 value);

    constructor() {
        owner = msg.sender;
        totalSupply = 900_000_000 * 10**6;
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        require(to != address(0), "Invalid address");
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        require(spender != address(0), "Invalid spender");
        allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        require(from != address(0), "Invalid from address");
        require(to != address(0), "Invalid to address");
        require(balanceOf[from] >= amount, "Insufficient balance");
        require(allowed[from][msg.sender] >= amount, "Insufficient allowance");
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        allowed[from][msg.sender] -= amount;
        emit Transfer(from, to, amount);
        return true;
    }

    function allowance(address tokenOwner, address spender) public view returns (uint256) {
        return allowed[tokenOwner][spender];
    }

    function mint(address to, uint256 amount) public {
        require(msg.sender == owner, "Only owner can mint");
        require(to != address(0), "Invalid address");
        totalSupply += amount;
        balanceOf[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    function burn(uint256 amount) public {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }
}