// SPDX-License-Identifier: BSD 3-Clause License
pragma solidity ^0.8.24;

import {ISablierLockupMinimal} from "./interfaces/ISablierLockupMinimal.sol";

contract SablierStreamAdapter {
    ISablierLockupMinimal public immutable sablierLockup;
    uint256 public startStreamId;
    address public owner;

    struct Callback {
        address target;
        bytes data;
        uint256 value;
    }

    event CallbackExecuted(address indexed target);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(address _sablierLockup, uint256 _startStreamId) {
        sablierLockup = ISablierLockupMinimal(_sablierLockup);
        startStreamId = _startStreamId;
        owner = msg.sender;
    }

    /// @notice Returns all warm stream IDs where the recipient matches the given target.
    /// @dev Intended to be called off-chain (no gas cost). Loops from startStreamId to nextStreamId.
    /// @param target The recipient address to filter streams by.
    /// @param started If true, only include streams whose start time has passed.
    /// @return streamIds Array of warm stream IDs owned by target.
    function getWarmStreamIds(address target, bool started) external view returns (uint256[] memory streamIds) {
        uint256 lastStreamId = sablierLockup.nextStreamId();
        uint256 range = lastStreamId > startStreamId ? lastStreamId - startStreamId : 0;
        uint256[] memory tempIds = new uint256[](range);
        uint256 count = 0;

        for (uint256 i = startStreamId; i < lastStreamId; i++) {
            bool isTarget = false;
            try sablierLockup.getRecipient(i) returns (address recipient) {
                isTarget = (recipient == target);
            } catch {
                // Stream doesn't exist or NFT was burned
            }

            if (!isTarget) continue;

            bool warm = false;
            try sablierLockup.isWarm(i) returns (bool _warm) {
                warm = _warm;
            } catch {
                // Stream in unexpected state
            }

            if (!warm) continue;

            if (started) {
                try sablierLockup.getStartTime(i) returns (uint40 startTime) {
                    if (block.timestamp < startTime) continue;
                } catch {
                    continue;
                }
            }

            tempIds[count] = i;
            count++;
        }

        // Trim to actual size
        streamIds = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            streamIds[i] = tempIds[i];
        }
    }

    /// @notice Calculates the total ETH fees needed to withdraw from the given streams.
    /// @param streamIds The stream IDs to calculate fees for.
    /// @return totalFee The total fee in wei.
    function calculateTotalFees(uint256[] calldata streamIds) external view returns (uint256 totalFee) {
        for (uint256 i = 0; i < streamIds.length; i++) {
            totalFee += sablierLockup.calculateMinFeeWei(streamIds[i]);
        }
    }

    /// @notice Calls withdrawMax on each stream ID, then optionally executes a callback.
    /// @dev Send enough ETH to cover all withdrawal fees + callback value. Excess ETH is refunded to msg.sender.
    /// @param streamIds The stream IDs to withdraw from.
    /// @param to The address to receive the withdrawn tokens (must be the stream recipient for third-party calls).
    /// @param cb Optional callback to execute after withdrawals. Skipped if cb.target is address(0).
    function withdrawMaxFromStreams(uint256[] calldata streamIds, address to, Callback calldata cb) external payable {
        for (uint256 i = 0; i < streamIds.length; i++) {
            uint256 fee = sablierLockup.calculateMinFeeWei(streamIds[i]);
            sablierLockup.withdrawMax{value: fee}(streamIds[i], to);
        }

        // Optional callback
        if (cb.target != address(0)) {
            (bool success,) = cb.target.call{value: cb.value}(cb.data);
            require(success, "Callback failed");
            emit CallbackExecuted(cb.target);
        }

        // Refund excess ETH
        uint256 remaining = address(this).balance;
        if (remaining > 0) {
            (bool sent,) = msg.sender.call{value: remaining}("");
            require(sent, "ETH refund failed");
        }
    }

    /// @notice Updates the starting stream ID for the search loop.
    function setStartStreamId(uint256 _startStreamId) external onlyOwner {
        startStreamId = _startStreamId;
    }

    /// @notice Transfers ownership of the adapter.
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Zero address");
        owner = newOwner;
    }

    receive() external payable {}
}
