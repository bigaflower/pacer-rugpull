// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract UERC {
    // Публичные параметры токена
    string public name = "UERC";
    string public symbol = "UERC";
    uint8 public decimals = 18;

    // Общее количество токенов
    uint256 public totalSupply;

    // Балансы и allowance
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    // События ERC-20
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        // 49 000 000 000 * 10^18
        uint256 initialSupply = 49_000_000_000 * 10 ** uint256(decimals);

        totalSupply = initialSupply;
        balanceOf[msg.sender] = initialSupply;

        emit Transfer(address(0), msg.sender, initialSupply);
    }

    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 fromBalance = balanceOf[from];
        require(fromBalance >= value, "ERC20: transfer amount exceeds balance");

        unchecked {
            balanceOf[from] = fromBalance - value;
        }
        balanceOf[to] += value;

        emit Transfer(from, to, value);
    }

    function transfer(address to, uint256 value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) external returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        uint256 currentAllowance = allowance[from][msg.sender];
        require(currentAllowance >= value, "ERC20: insufficient allowance");

        unchecked {
            allowance[from][msg.sender] = currentAllowance - value;
        }

        _transfer(from, to, value);
        return true;
    }
}