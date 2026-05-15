// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @notice Interface for Balancer Weighted Pool
interface IWeightedPool is IERC20 {
    // @notice Returns the Pool's id
    function getPoolId() external returns (bytes32);
}
