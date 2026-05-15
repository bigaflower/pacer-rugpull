// SPDX-License-Identifier: MIT

pragma solidity 0.8.30;

import { IERC20 } from "contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "contracts/token/ERC20/utils/SafeERC20.sol";

import { IDepositAddress } from "contracts/interfaces/IDepositAddress.sol";

/**
    @title Deposit Sweeper
    @author Universal Assets Bank
 */
contract DepositSweeper {
    using SafeERC20 for IERC20;

    address constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    address public immutable manager;
    address public immutable receiver;

    struct SweepTarget {
        address target;
        IERC20 token;
        uint256 amount;
    }

    struct ApproveTarget {
        IDepositAddress target;
        IERC20 token;
    }

    error NotManager();

    /**
        @notice Contract constructor
        @param _manager Contract manager address
            The manager is able to set token transfer approvals, and sweep balances
            from deposit addresses to the receiver.
        @param _receiver Receiver address
            The receiver is where all token and native gas balances are swept to.
     */
    constructor(address _manager, address _receiver) {
        manager = _manager;
        receiver = _receiver;
    }

    modifier onlyManager() {
        if (msg.sender != manager) revert NotManager();
        _;
    }

    /**
        @notice Batch approve the sweeper to transfer tokens from deposit addresses
        @dev Only callable by the manager. Should be called once per-token for each
            deposit address, prior to sweeping that token balance from the deposit
            address for the first time.
        @param targets Array of tuples of: (deposit address, token address)
     */
    function setTransferApproval(ApproveTarget[] calldata targets) external onlyManager {
        uint256 length = targets.length;
        for (uint i = 0; i < length; i++) {
            targets[i].target.setTransferApproval(targets[i].token);
        }
    }

    /**
        @notice Batch sweep balances from multiple deposit addresses
        @dev Only callable by the manager
        @param targets Array of tuples of:
                (deposit address, addres of token to sweep, balance to sweep)
            If this is the first sweep of a token at a given deposit address,
            the manager must first call `setTransferApproval` or the sweep
            will fail.
     */
    function sweep(SweepTarget[] calldata targets) external onlyManager {
        uint256 length = targets.length;
        for (uint i = 0; i < length; i++) {
            IERC20 token = targets[i].token;
            if (address(token) == ETH) {
                IDepositAddress(targets[i].target).sweepNative(targets[i].amount);
            } else {
                targets[i].token.safeTransferFrom(targets[i].target, receiver, targets[i].amount);
            }
        }
    }
}
