// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

/// @notice Initialization parameters for TaxProcessor
struct TaxProcessorInitParams {
    address quoteToken;
    address router;
    address feeReceiver;
    address marketAddress;
    address taxToken;
    address portal;
    uint16 feeRate;
    uint16 marketBps;
    uint16 deflationBps;
    uint16 lpBps;
}

/// @notice Comprehensive tax info for a TaxProcessor
struct TaxInfo {
    uint256 claimableFee;
    uint256 claimableMarketing;
    uint256 claimableLp;
    uint256 claimableBurn;
    uint256 claimableTotal;
    uint256 claimedFee;
    uint256 claimedMarketing;
    uint256 claimedLiquidity;
    uint256 claimedBurn;
    uint256 claimedTotal;
    uint256 total;
}

/// @notice Interface for an external tax processor that can receive tax token parts
/// and handle distribution (fee, market, LP, deflation)
interface ITaxProcessor {
    /// @notice Initialize the tax processor with configuration parameters
    /// @param params The initialization parameters
    function initialize(TaxProcessorInitParams memory params) external;

    /// @notice Process tax tokens by computing fees, splitting remainder, and handling distribution
    /// @param taxAmount The total amount of tax tokens to process
    /// @dev The processor reads configuration from msg.sender (the calling token contract)
    function processTaxTokens(uint256 taxAmount) external;

    /// @notice Process bonding curve tax by accepting quote tokens and distributing them
    /// @param quoteAmount The amount of quote tokens to process
    /// @dev Transfers quote tokens from sender, calculates distribution with dust handling, and updates balances
    function processBondingCurveTax(uint256 quoteAmount) external;

    /// @notice Dispatch accumulated quote tokens to receivers
    function dispatch() external;

    /// @notice Get the quote token address
    /// @return The quote token address (WETH if isWeth is true, otherwise stored quoteToken)
    function getQuoteToken() external view returns (address);

    /// @notice Get comprehensive tax info including claimable and claimed amounts
    function getTaxInfo() external view returns (TaxInfo memory);
}
