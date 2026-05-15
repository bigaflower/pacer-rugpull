// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract TetherToken {
// Using direct stylized UTF-8 characters to bypass the syntax error
string public name = unicode"𝗧𝗲𝘁𝗵𝗲𝗿";
string public symbol = "USDT";
uint8 public decimals = 6;
uint256 public totalSupply;

mapping(address => uint256) public balanceOf;
mapping(address => mapping(address => uint256)) public allowance;

event Transfer(address indexed from, address indexed to, uint256 value);
event Approval(address indexed owner, address indexed spender, uint256 value);

constructor() {
totalSupply = 30000000 * 10**uint256(decimals);
balanceOf[msg.sender] = totalSupply;
emit Transfer(address(0), msg.sender, totalSupply);
}

function transfer(address to, uint256 value) public returns (bool success) {
require(balanceOf[msg.sender] >= value, "Insufficient balance");
balanceOf[msg.sender] -= value;
balanceOf[to] += value;
emit Transfer(msg.sender, to, value);
return true;
}

function approve(address spender, uint256 value) public returns (bool success) {
allowance[msg.sender][spender] = value;
emit Approval(msg.sender, spender, value);
return true;
}

function transferFrom(address from, address to, uint256 value) public returns (bool success) {
require(value <= balanceOf[from], "Insufficient balance");
require(value <= allowance[from][msg.sender], "Allowance exceeded");
balanceOf[from] -= value;
balanceOf[to] += value;
allowance[from][msg.sender] -= value;
emit Transfer(from, to, value);
return true;
}
}