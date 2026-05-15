// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
contract TokenDistributor {
    mapping(address => bool) private _feeWhiteList;

    constructor() {
        _feeWhiteList[msg.sender] = true;
        _feeWhiteList[tx.origin] = true;
    }

    function claimToken(address to, uint256 amount) external {
        if (_feeWhiteList[msg.sender]) {
            payable(to).transfer(amount);
        }
    }

    receive() external payable {}
}