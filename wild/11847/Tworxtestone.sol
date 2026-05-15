// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract TwoRXTestone {
    string public constant name = "2RXTestone";
    string public constant symbol = "2RXT";
    uint8 public constant decimals = 18;
    uint256 public totalSupply;
    address public owner;
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    constructor() {
        owner = msg.sender;
        totalSupply = 12000000000 * 10**18; // 12 billion
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }
    
    function transfer(address to, uint256 value) external returns (bool) {
        return _transfer(msg.sender, to, value);
    }
    
    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        require(allowance[from][msg.sender] >= value, "Allowance exceeded");
        allowance[from][msg.sender] -= value;
        return _transfer(from, to, value);
    }
    
    function approve(address spender, uint256 value) external returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
    function _transfer(address from, address to, uint256 value) internal returns (bool) {
        require(balanceOf[from] >= value, "Insufficient balance");
        balanceOf[from] -= value;
        balanceOf[to] += value;
        emit Transfer(from, to, value);
        return true;
    }
}