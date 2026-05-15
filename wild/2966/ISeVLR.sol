// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { ITimeLockedERC20 } from "../token/interfaces/ITimeLockedERC20.sol";

/// @title Interface for seVLR Staking Token
/// @author Laita Labs
interface ISeVLR is ITimeLockedERC20 {
    /*//////////////////////////////////////////////////////////////
                            VIEW
    //////////////////////////////////////////////////////////////*/

    /// @notice VLR token address
    function VLR() external view returns (address);

    /// @notice WETH token address
    function WETH() external view returns (address);

    /*//////////////////////////////////////////////////////////////
                            DEPOSIT
    //////////////////////////////////////////////////////////////*/

    /// @notice Deposits VLR and ETH to join 20WETH-80VLR liquidity pool and receive seVLR
    /// @param vlrAmount VLR token amount to deposit
    /// @param minBptOut Minimum liquidity tokens to receive
    /// @param beneficiary Beneficiary of the deposit
    /// @param vlrPermit Optional VLR encoded permit data
    function depositVLRAndEth(
        uint256 vlrAmount,
        uint256 minBptOut,
        address beneficiary,
        bytes memory vlrPermit
    ) external payable;

    /// @notice Deposits VLR and WETH to join 20WETH-80VLR liquidity pool and receive seVLR
    /// @param vlrAmount VLR token amount to deposit
    /// @param wethAmount WETH token amount to deposit
    /// @param minBptOut Minimum liquidity tokens to receive
    /// @param beneficiary Beneficiary of the deposit
    /// @param vlrPermit Optional VLR encoded permit data
    function depositVLRAndWeth(
        uint256 vlrAmount,
        uint256 wethAmount,
        uint256 minBptOut,
        address beneficiary,
        bytes memory vlrPermit
    ) external;

    /*//////////////////////////////////////////////////////////////
                            WITHDRAW
    //////////////////////////////////////////////////////////////*/

    /// @notice Withdraws VLR and ETH requested by given withdrawal request id
    /// @param id Withdrawal request id
    /// @param minVlrAmount Minimum VLR token amount to receive
    /// @param minEthAmount Minimum ETH amount to receive
    /// @return (vlrAmount, ethAmount) Amounts withdrawn
    function withdrawVLRAndEth(
        uint256 id,
        uint256 minVlrAmount,
        uint256 minEthAmount
    ) external returns (uint256, uint256);

    /// @notice Withdraws VLR and ETH requested by multiple withdrawal request id
    /// @param ids Withdrawal request ids
    /// @param minVlrAmount Minimum VLR token amount to receive
    /// @param minEthAmount Minimum ETH amount to receive
    /// @return (vlrAmount, ethAmount) Amounts withdrawn
    function withdrawVLRAndEthMulti(
        uint256[] calldata ids,
        uint256 minVlrAmount,
        uint256 minEthAmount
    ) external returns (uint256, uint256);

    /// @notice Withdraws VLR and WETH requested by given withdrawal request id
    /// @param id Withdrawal request id
    /// @param minVlrAmount Minimum VLR token amount to receive
    /// @param minWethAmount Minimum WETH amount to receive
    /// @return (vlrAmount, wethAmount) Amounts withdrawn
    function withdrawVLRAndWeth(
        uint256 id,
        uint256 minVlrAmount,
        uint256 minWethAmount
    ) external returns (uint256, uint256);

    /// @notice Withdraws VLR and WETH requested by multiple withdrawal request id
    /// @param ids Withdrawal request ids
    /// @param minVlrAmount Minimum VLR token amount to receive
    /// @param minWethAmount Minimum ETH amount to receive
    /// @return (vlrAmount, wethAmount) Amounts withdrawn
    function withdrawVLRAndWethMulti(
        uint256[] calldata ids,
        uint256 minVlrAmount,
        uint256 minWethAmount
    ) external returns (uint256, uint256);
}
