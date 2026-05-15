// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface INode {
        function isNode(address account) external view returns (uint256);
}