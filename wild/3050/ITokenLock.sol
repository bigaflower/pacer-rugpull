// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ITokenLock {
    function setERC20(address tokenAddress) external ;
    function unLock() external;
    function getReceiverIndex() external view returns (uint256);
}
