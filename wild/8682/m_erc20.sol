// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimplestERC20 {
    string  public name       = "USD Coin";
    string  public symbol     = "USDC";
    uint8   public decimals   = 6;
    uint256 public totalSupply = 1_000_000 * 10**6;

    event Transfer(address indexed from, address indexed to, uint256 value);

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        emit Transfer(from, to, amount);
        return true;
    }
}