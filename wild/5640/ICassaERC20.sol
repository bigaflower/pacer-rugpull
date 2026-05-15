// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IERC20} from "./IERC20.sol";

/// @title Cassa ERC20 Token Interface
/// @notice Extended ERC20 interface for Cassa tokens with mint/burn capabilities.
interface ICassaERC20 is IERC20 {
    /// @notice Mints new tokens to a specified address
    /// @dev Only callable by the parent `ICassaITUT` contract
    /// @param to The address that will receive the minted tokens
    /// @param amount The amount of tokens to mint
    function mint(address to, uint256 amount) external;

    /// @notice Burns tokens from a specified address
    /// @dev Only callable by the parent `ICassaITUT` contract
    /// @param from The address from which tokens will be burned
    /// @param amount The amount of tokens to burn
    function burn(address from, uint256 amount) external;

    /// @notice Spends allowance from an owner on behalf of a spender
    /// @dev Only callable by the parent `ICassaITUT` contract
    /// @param owner The address of the token owner
    /// @param spender The address of the spender
    /// @param amount The amount of allowance to spend
    function spendAllowance(address owner, address spender, uint256 amount) external;
}
