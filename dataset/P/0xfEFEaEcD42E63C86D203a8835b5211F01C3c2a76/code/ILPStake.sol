// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ILPStake {
        function _balances(address account) external view returns (uint256);
}