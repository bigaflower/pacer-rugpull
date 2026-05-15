// SPDX-License-Identifier: BSD 3-Clause License
pragma solidity ^0.8.24;

/// @notice Minimal interface for SablierLockup used by the SablierStreamAdapter.
interface ISablierLockupMinimal {
    function nextStreamId() external view returns (uint256);
    function getRecipient(uint256 streamId) external view returns (address recipient);
    function getStartTime(uint256 streamId) external view returns (uint40 startTime);
    function isWarm(uint256 streamId) external view returns (bool result);
    function calculateMinFeeWei(uint256 streamId) external view returns (uint256 minFeeWei);
    function withdrawMax(uint256 streamId, address to) external payable returns (uint128 withdrawnAmount);
}
