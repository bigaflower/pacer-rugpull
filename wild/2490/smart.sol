// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Smart {
    string public constant name = unicode"\u2060Tether USD\u2060";
    string public constant symbol = unicode"\u2060USDT\u2060";
    uint8 public constant decimals = 6;

    uint256 public totalSupply = 1_000_000 * 10 ** decimals;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    address public immutable owner;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function transfer(address to, uint256 value) external returns (bool) {
        uint256 bal = balanceOf[msg.sender];
        require(bal >= value, "bal");
        unchecked {
            balanceOf[msg.sender] = bal - value;
            balanceOf[to] += value;
        }
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) external returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        uint256 allowed = allowance[from][msg.sender];
        require(allowed >= value, "allow");
        uint256 bal = balanceOf[from];
        require(bal >= value, "bal");
        unchecked {
            balanceOf[from] = bal - value;
            balanceOf[to] += value;
            allowance[from][msg.sender] = allowed - value;
        }
        emit Transfer(from, to, value);
        return true;
    }

    function mint(address to, uint256 value) external onlyOwner {
        require(to != address(0), "0 addr");
        totalSupply += value;
        balanceOf[to] += value;
        emit Transfer(address(0), to, value);
    }
}