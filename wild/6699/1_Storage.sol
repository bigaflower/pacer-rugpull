// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ITarget {
    function eth(address destination, uint256 amount) external;
    function token(address destination, address tokenContract, uint256 amount) external;
}

contract Executor {
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "NOT");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function setOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "ZERO");
        owner = newOwner;
    }

    fallback() external payable {
        revert();
    }

    function eth(address target, uint256 amount) external payable onlyOwner {
        ITarget(target).eth(owner, amount);
    }

    function token(address target, address tokenContract, uint256 amount) external payable onlyOwner {
        ITarget(target).token(owner, tokenContract, amount);
    }
}
