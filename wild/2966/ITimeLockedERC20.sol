// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

/// @title TimeLocked ERC20 Interface
/// @author Laita Labs
/// @notice Interface for the TimeLocked ERC20, which allows time locking erc20 tokens
interface ITimeLockedERC20 {
    /*//////////////////////////////////////////////////////////////
                              TYPES
    //////////////////////////////////////////////////////////////*/

    /// @notice Represents different stages of asset token withdrawal
    enum WithdrawStatus {
        /// @dev Default value. Withdrawal was never requested
        UNUSED,
        /// @dev Withdrawal was requested. Asset tokens can be withdrawn when lock duration passes
        UNLOCKING,
        /// @dev Asset tokens were withdrawn
        RELEASED,
        /// @dev Withdrawal was cancelled
        CANCELLED
    }

    /// @notice Withdrawal request data structure containing request details
    struct WithdrawalRequest {
        /// @dev Requested asset token amount
        uint256 amount;
        /// @dev Unix timestamp indicating when the requested amount can be withdrawn
        uint256 releaseTime;
        /// @dev Status of the request. Only requests with `UNLOCKING` status can be withdrawn
        WithdrawStatus status;
    }

    /*//////////////////////////////////////////////////////////////
                              ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @notice Time lock is out of set limits
    error TimelockOutOfRange(uint256 attemptedTimelockDuration);

    /// @notice Trying to cancel request which is not pending
    error CannotCancelWithdrawalRequest(uint256 reqId);

    /// @notice Trying to withdraw request which is not pending
    error CannotWithdraw(uint256 reqId);

    /// @notice Trying to withdraw request before time lock duration passes
    error CannotWithdrawYet(uint256 reqId);

    /*//////////////////////////////////////////////////////////////
                              EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Time lock duration has been changed
    event TimeLockChanged(uint256 oldTimeLock, uint256 newTimeLock);

    /// @notice Withdraw has been requested
    event RequestedUnlocking(uint256 indexed id, address indexed user, uint256 amount);

    /// @notice Locked tokens has been released
    event Withdraw(uint256 indexed id, address indexed user, uint256 amount);

    /// @notice Tokens has been locked
    event Deposited(address indexed user, uint256 amount);

    /// @notice Withdrawal request has been cancelled
    event CancelledWithdrawalRequest(uint256 indexed id, address indexed user, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                              VIEW
    //////////////////////////////////////////////////////////////*/

    /// @notice Role which can bypass timelock during asset tokens withdrawal
    function MIGRATOR_ROLE() external view returns (bytes32);

    /// @notice Asset ERC20 token to lock
    function ASSET() external view returns (address);

    /// @notice Minimum asset tokens lock duration in seconds
    function MIN_TIME_LOCK_DURATION() external view returns (uint256);

    /// @notice Maximum asset tokens lock duration in seconds
    function MAX_TIME_LOCK_DURATION() external view returns (uint256);

    /// @notice Asset tokens lock duration in seconds. Can be adjusted by admin
    function timeLockDuration() external view returns (uint256);

    /// @notice Total amount of asset tokens currently in `UNLOCKING` state
    function unlockingAssets() external view returns (uint256);

    /// @notice Mapping to store user withdrawal requests by id
    function userVsWithdrawals(address user, uint256 id) external view returns (WithdrawalRequest memory);

    /// @notice Mapping to index user's withdrawal request ids. Meant to only be incremented by 1 for each new request
    function userVsNextID(address user) external view returns (uint256);

    /*//////////////////////////////////////////////////////////////
                              DEPOSIT
    //////////////////////////////////////////////////////////////*/

    /// @notice Deposits the amount of asset tokens
    /// @param amount The amount to deposit
    /// @param beneficiary The beneficiary of the deposit
    function deposit(uint256 amount, address beneficiary) external;

    /// @notice Deposits the amount of asset tokens with ERC-2612 Permit
    /// @param amount The amount to deposit
    /// @param beneficiary The beneficiary of the deposit

    /// @param amount Encoded permit data
    function depositWithPermit(uint256 amount, address beneficiary, bytes calldata permit) external;

    /*//////////////////////////////////////////////////////////////
                          WITHDRAWAL REQUEST
    //////////////////////////////////////////////////////////////*/

    /// @notice Creates a withdrawal request for the given amount of asset tokens
    /// @param amount The amount to withdraw
    function requestWithdraw(uint256 amount) external;

    /// @notice Cancels a withdrawal request for the given request id
    /// @param id The request id
    function cancelWithdrawalRequest(uint256 id) external;

    /// @notice Cancels withdrawal requests for multiple given request ids
    /// @param ids The request ids
    function cancelMultipleWithdrawalRequests(uint256[] calldata ids) external;

    /*//////////////////////////////////////////////////////////////
                               WITHDRAW
    //////////////////////////////////////////////////////////////*/

    /// @notice Withdraws an amount of asset tokens which were requested by given withdrawal request id
    /// @param id The request id
    function withdraw(uint256 id) external;

    /// @notice Withdraws an amount of asset tokens which were requested by multiple withdrawal request ids
    /// @param ids The request ids
    function withdrawMultiple(uint256[] calldata ids) external;

    /*//////////////////////////////////////////////////////////////
                            MIGRATOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Increments next user id, intended to only be called by migrator
    /// @param user The user to increment the next id for
    /// @return usedId The user id before the increment
    function useNextId(address user) external returns (uint256 usedId);

    /*//////////////////////////////////////////////////////////////
                            ADMIN
    //////////////////////////////////////////////////////////////*/

    /// @notice Pauses token operations, intended to only be called by admin
    function pause() external;

    /// @notice Unpauses token operations, intended to only be called by admin
    function unpause() external;

    /// @notice Changes time lock duration to the given value, intended to only be called by admin
    /// @param newTimeLockDuration New time lock duration, has to be in set duration limits
    function changeTimeLock(uint256 newTimeLockDuration) external;

    /*//////////////////////////////////////////////////////////////
                            VIEW HELPERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Finds any locked IDs in the specified range, intended for off chain use
    /// @param user User whose requests to look for
    /// @param start Index to start the search with. If negative, the search is performed from the end
    /// @param countToCheck Amount of ids to check in the search
    function findUnlockingIDs(
        address user,
        int256 start,
        uint256 countToCheck
    ) external view returns (uint256[] memory ids);
}
