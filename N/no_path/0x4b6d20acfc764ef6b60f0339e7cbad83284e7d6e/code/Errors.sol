// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/// @title Errors
/// @notice This library is used to define custom errors
library Errors {
    /// @notice An error for an invalid proof
    error InvalidProof();

    /// @notice An error for an invalid BTC address
    error InvalidBTCAddress();

    /// @notice An error for an invalid update
    error ZeroTotalSupply();

    /// @notice An error for a zero address
    error ZeroAddress();

    /// @notice An error for an invalid access
    error InvalidAccess();

    /// @notice An error for a zero amount
    error ZeroAmount();

    /// @notice An error for an already claimed address
    error AlreadyClaimed();

    /// @notice An error for an amount that exceeds the limit
    error ExceedsLimit();

    /// @notice An error for an invalid signature
    error InvalidSignature();
}
