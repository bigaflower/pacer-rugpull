// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface ITokenSaleFactoryMin {
    function isFinished(address token) external view returns (bool);
    function onTransfer(address from, uint256 amount) external;
}