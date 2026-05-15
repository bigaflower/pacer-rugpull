// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract ManualSwitch {

    address public owner;
    bool public enabled;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    modifier isEnabled() {
        require(enabled, "contract not enabled");
        _;
    }

    // вручную включить
    function enable() external onlyOwner {
        enabled = true;
    }

    // вручную выключить
    function disable() external onlyOwner {
        enabled = false;
    }

    // функция которая работает только если включено
    function doSomething(uint256 x) external isEnabled returns (uint256) {
        return x * 2;
    }
}