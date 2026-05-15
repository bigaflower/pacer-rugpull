// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
Treasury USD (USDT)
ERC-20 Stable Token
Decimals: 6
Fixed Supply
*/

interface IERC20 {
function totalSupply() external view returns (uint256);
function balanceOf(address account) external view returns (uint256);
function transfer(address recipient, uint256 amount) external returns (bool);
function allowance(address owner, address spender) external view returns (uint256);
function approve(address spender, uint256 amount) external returns (bool);
function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

event Transfer(address indexed from, address indexed to, uint256 value);
event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract TreasuryUSD is IERC20 {

string public constant name = "Treasury USD";
string public constant symbol = "USDT";
uint8 public constant decimals = 6;

uint256 private constant _totalSupply = 100_000_000 * 10**6; // 100 million

mapping(address => uint256) private _balances;
mapping(address => mapping(address => uint256)) private _allowances;

constructor() {
_balances[msg.sender] = _totalSupply;
emit Transfer(address(0), msg.sender, _totalSupply);
}

function totalSupply() external pure override returns (uint256) {
return _totalSupply;
}

function balanceOf(address account) external view override returns (uint256) {
return _balances[account];
}

function transfer(address recipient, uint256 amount) external override returns (bool) {
_transfer(msg.sender, recipient, amount);
return true;
}

function allowance(address owner, address spender) external view override returns (uint256) {
return _allowances[owner][spender];
}

function approve(address spender, uint256 amount) external override returns (bool) {
_allowances[msg.sender][spender] = amount;
emit Approval(msg.sender, spender, amount);
return true;
}

function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
uint256 currentAllowance = _allowances[sender][msg.sender];
require(currentAllowance >= amount, "Allowance exceeded");
_allowances[sender][msg.sender] = currentAllowance - amount;
_transfer(sender, recipient, amount);
return true;
}

function _transfer(address from, address to, uint256 amount) internal {
require(from != address(0) && to != address(0), "Zero address");
require(_balances[from] >= amount, "Balance too low");

_balances[from] -= amount;
_balances[to] += amount;

emit Transfer(from, to, amount);
}
}