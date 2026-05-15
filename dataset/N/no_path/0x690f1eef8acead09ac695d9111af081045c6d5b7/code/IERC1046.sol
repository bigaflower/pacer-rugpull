// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.28;

/// @title  ERC-1046: tokenURI Interoperability
interface IERC1046 {
    /// @notice     Gets an ERC-721-like token URI
    /// @dev        The resolved data MUST be in JSON format and support ERC-1046's ERC-20 Token Metadata Schema
    function tokenURI() external view returns (string memory);
}
