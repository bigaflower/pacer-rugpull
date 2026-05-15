// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IFeeRate {
    /// @notice Returns the fee rate
    /// @return _feeRate The fee rate by 1e18 (1e18 = 100%)
    function feeRate() external returns (uint256 _feeRate);

    /// @notice Returns the fee receiver address
    /// @return _feeReceiver The fee receiver address
    function feeReceiver() external returns (address _feeReceiver);

    /// @notice Set the fee rate
    /// @param newFeeRate The fee rate by 1e18 (1e18 = 100%)
    function setFeeRate(uint256 newFeeRate) external;

    /// @notice Set the fee receiver address
    /// @param newFeeReceiver The fee receiver address
    function setFeeReceiver(address newFeeReceiver) external;
}
