// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ICassaERC20} from "./ICassaERC20.sol";
import {ICassaPolicy} from "./ICassaPolicy.sol";

/// @title Cassa ITUT Interface
/// @notice Cassa IT/UT vault interface.
interface ICassaITUT {
    /// @notice Returns the IT (Insured Token) contract
    /// @return _it The ICassaERC20 contract for the IT token
    function IT() external view returns (ICassaERC20 _it);

    /// @notice Returns the UT (Underwriting Token) contract
    /// @return _ut The ICassaERC20 contract for the UT token
    function UT() external view returns (ICassaERC20 _ut);

    /// @notice Returns the underlying asset token
    /// @return _asset The address for the underlying asset
    function asset() external view returns (address _asset);

    /// @notice Returns the policy contract
    /// @return _policy The ICassaPolicy contract governing this ITUT
    function policy() external view returns (ICassaPolicy _policy);

    /// @notice Returns the name of the vault
    /// @return _name The name string
    function name() external view returns (string memory _name);

    /// @notice Returns the maximum amount of assets that can be deposited for a receiver
    /// @param receiver The address to check deposit limits for
    /// @return max The maximum deposit amount
    function maxDeposit(address receiver) external view returns (uint256 max);

    /// @notice Returns the maximum amount of IT/UT pairs that can be deposited from a whitelisted `ICassaITUT` contract
    /// @param vault The address of the whitelisted `ICassaITUT` contract whose IT/UT tokens will be deposited
    /// @param receiver The address to check deposit limits for
    /// @return max The maximum deposit amount in IT/UT pairs
    function maxDepositITUT(address vault, address receiver) external view returns (uint256 max);

    /// @notice Returns the maximum amount of tokens that can be redeemed by an owner
    /// @param owner The address of the token owner
    /// @return max The maximum redeemable token amount
    function maxRedeem(address owner) external view returns (uint256 max);

    /// @notice Returns the maximum amount of IT tokens that can be redeemed by an owner
    /// @param owner The address of the IT token owner
    /// @return max The maximum redeemable IT token amount
    function maxRedeemIT(address owner) external view returns (uint256 max);

    /// @notice Returns the maximum amount of UT tokens that can be redeemed by an owner
    /// @param owner The address of the UT token owner
    /// @return max The maximum redeemable UT token amount
    function maxRedeemUT(address owner) external view returns (uint256 max);

    /// @notice Previews the amount of IT and UT tokens that would be minted for a given asset deposit
    /// @param assets The amount of assets to simulate depositing
    /// @return tokens The total amount of token pairs that would be minted
    function previewDeposit(uint256 assets) external view returns (uint256 tokens);

    /// @notice Previews the amount of IT and UT tokens that would be minted for depositing IT/UT pairs from a whitelisted `ICassaITUT` contract
    /// @param vault The address of the whitelisted `ICassaITUT` contract whose IT/UT tokens will be deposited
    /// @param amount The amount of IT/UT pairs to simulate depositing
    /// @return tokens The total amount of token pairs that would be minted
    function previewDepositITUT(address vault, uint256 amount) external view returns (uint256 tokens);

    /// @notice Previews the amount of assets that would be returned for redeeming a given amount of tokens
    /// @param tokens The amount of tokens to simulate redeeming
    /// @return assets The amount of assets that would be returned
    function previewRedeem(uint256 tokens) external view returns (uint256 assets);

    /// @notice Previews the amount of assets that would be returned for redeeming IT tokens
    /// @param tokens The amount of IT tokens to simulate redeeming
    /// @return assets The amount of assets that would be returned
    function previewRedeemIT(uint256 tokens) external view returns (uint256 assets);

    /// @notice Previews the amount of assets that would be returned for redeeming UT tokens
    /// @param tokens The amount of UT tokens to simulate redeeming
    /// @return assets The amount of assets that would be returned
    function previewRedeemUT(uint256 tokens) external view returns (uint256 assets);

    /// @notice Deposits assets and mints IT and UT tokens to a receiver
    /// @param assets The amount of assets to deposit
    /// @param receiver The address that will receive the minted tokens
    /// @return tokens The total amount of token pairs minted
    function deposit(uint256 assets, address receiver) external returns (uint256 tokens);

    /// @notice Deposits IT/UT pairs from a whitelisted `ICassaITUT` contract and mints new IT and UT tokens
    /// @dev The deposited IT/UT pairs must be backed by the same underlying asset
    /// @param vault The address of the whitelisted `ICassaITUT` contract whose IT/UT tokens will be deposited
    /// @param amount The amount of IT/UT pairs to deposit
    /// @param receiver The address that will receive the minted tokens
    /// @return tokens The total amount of token pairs minted
    function depositITUT(address vault, uint256 amount, address receiver) external returns (uint256 tokens);

    /// @notice Redeems tokens and returns assets to a receiver
    /// @param tokens The amount of tokens to redeem
    /// @param receiver The address that will receive the assets
    /// @param owner The address of the token owner
    /// @return assets The amount of assets returned
    function redeem(uint256 tokens, address receiver, address owner) external returns (uint256 assets);

    /// @notice Redeems IT tokens and returns assets to a receiver
    /// @param tokens The amount of IT tokens to redeem
    /// @param receiver The address that will receive the assets
    /// @param owner The address of the IT token owner
    /// @return assets The amount of assets returned
    function redeemIT(uint256 tokens, address receiver, address owner) external returns (uint256 assets);

    /// @notice Redeems UT tokens and returns assets to a receiver
    /// @param tokens The amount of UT tokens to redeem
    /// @param receiver The address that will receive the assets
    /// @param owner The address of the UT token owner
    /// @return assets The amount of assets returned
    function redeemUT(uint256 tokens, address receiver, address owner) external returns (uint256 assets);

    /// @notice Settles the policy and fixes the settlement ratio
    function settle() external;

    /// @notice Returns the settlement ratio and whether the policy has been settled
    /// @return ratio The settlement ratio value scaled by 1e18 (1e18 = 100%)
    /// @return isSettled Whether the policy has been settled
    function settlementRatio() external view returns (uint256 ratio, bool isSettled);
}
