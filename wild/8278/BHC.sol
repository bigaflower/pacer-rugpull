// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract BHC {
    string public constant name = "Block Hub Coin";
    string public constant symbol = "BHC";
    uint8  public constant decimals = 18;
    uint256 public constant totalSupply = 19_000_000 * 10**18;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function transfer(address to, uint256 value) external returns (bool) {
        require(balanceOf[msg.sender] >= value, "insufficient balance");
        unchecked {
            balanceOf[msg.sender] -= value;
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
        require(balanceOf[from] >= value, "insufficient balance");
        uint256 allowed = allowance[from][msg.sender];
        require(allowed >= value, "insufficient allowance");
        unchecked {
            balanceOf[from] -= value;
            allowance[from][msg.sender] = allowed - value;
            balanceOf[to] += value;
        }
        emit Transfer(from, to, value);
        return true;
    }
}