// SPDX-License-Identifier: MIT

/**

Website: https://DemCoin.us

*/

pragma solidity ^0.8.20;

import "./ERC20.sol";

contract DEMOCRAT is ERC20 {
    address public taxAddress; // Address where taxes are collected

    constructor(address _taxAddress) ERC20("DEMOCRAT", "DEM") {
        taxAddress = _taxAddress;
        _mint(msg.sender, 50000000 * (10 ** uint256(decimals()))); // 100M tokens
    }

    function totalSupply() public view override returns (uint256) {
        return super.totalSupply();
    }

    function balanceOf(address tokenOwner) public view override returns (uint256 balance) {
        return super.balanceOf(tokenOwner);
    }

    function allowance(address tokenOwner, address spender) public view override returns (uint256 remaining) {
        return super.allowance(tokenOwner, spender);
    }

    function approve(address spender, uint256 tokens) public override returns (bool success) {
        return super.approve(spender, tokens);
    }

    function transfer(address to, uint256 tokens) public override returns (bool success) {
        uint256 tax = calculateTax(tokens);
        uint256 tokensAfterTax = tokens - tax;
        super.transfer(to, tokensAfterTax);
        super.transfer(taxAddress, tax);
        return true;
    }

    function transferFrom(address from, address to, uint256 tokens) public override returns (bool success) {
        uint256 tax = calculateTax(tokens);
        uint256 tokensAfterTax = tokens - tax;
        super.transferFrom(from, to, tokensAfterTax);
        super.transferFrom(from, taxAddress, tax);
        return true;
    }

    function calculateTax(uint256 tokens) private pure returns (uint256) {
        uint256 taxPercentage = 2; // Set your tax percentage here
        uint256 tax = tokens * taxPercentage / 100;
        return tax;
    }
}
