// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

interface IV2Pair {
    function sync() external;

    function factory() external view returns (address);

    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}