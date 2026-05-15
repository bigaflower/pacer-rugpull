// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

/// @notice Interface for Balancer Vault
interface IBalancerVault {
    /*//////////////////////////////////////////////////////////////
                              TYPES
    //////////////////////////////////////////////////////////////*/

    /// @notice Struct containing data for joining Balancer Pool
    struct JoinPoolRequest {
        address[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }

    /// @notice Struct containing data for exiting Balancer Pool
    struct ExitPoolRequest {
        address[] assets;
        uint256[] minAmountsOut;
        bytes userData;
        bool toInternalBalance;
    }

    /*//////////////////////////////////////////////////////////////
                              POOLS
    //////////////////////////////////////////////////////////////*/

    /// @notice Joins Balancer Pool, depositing liquidity
    /// @param poolId The id of the pool to join
    /// @param sender The address of the sender of pool tokens
    /// @param recipient The address of the recipient of liquidity tokens
    /// @param request The struct containing additional join data
    function joinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        JoinPoolRequest memory request
    ) external payable;

    /// @notice Exits Balancer Pool, withdrawing liquidity
    /// @param poolId The id of the pool to exit
    /// @param sender The address of the sender of liquidity tokens
    /// @param recipient The address of the recipient of pool tokens
    /// @param request The struct containing additional exit data
    function exitPool(
        bytes32 poolId,
        address sender,
        address payable recipient,
        ExitPoolRequest memory request
    ) external;
}
