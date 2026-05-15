
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ISwapPair {
    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function totalSupply() external view returns (uint256);

    function kLast() external view returns (uint256);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
    
    function sync() external;
}