// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

// Contracts
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC20Permit } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

// Interfaces
import { ITimeLockedERC20 } from "./interfaces/ITimeLockedERC20.sol";

// Libraries
import { SafeTransferLib } from "solady/src/utils/SafeTransferLib.sol";
import { ERC20UtilsLib } from "../libraries/ERC20UtilsLib.sol";

/// @title Time Locked ERC20
/// @author Laita Labs
/// @notice ERC20 extension that allows time locking tokens for a certain periods of time
contract TimeLockedERC20 is ITimeLockedERC20, ERC20Permit, Pausable, AccessControl {
    /*//////////////////////////////////////////////////////////////
                             LIBRARIES
    //////////////////////////////////////////////////////////////*/

    using SafeTransferLib for address;
    using ERC20UtilsLib for address;

    /*//////////////////////////////////////////////////////////////
                            CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Role which can bypass timelock during asset tokens withdrawal
    bytes32 public constant MIGRATOR_ROLE = keccak256("MIGRATOR_ROLE");

    /// @notice Asset ERC20 token to lock
    address public immutable ASSET;

    /// @notice Minimum asset tokens lock duration in seconds
    uint256 public immutable MIN_TIME_LOCK_DURATION;

    /// @notice Maximum asset tokens lock duration in seconds
    uint256 public immutable MAX_TIME_LOCK_DURATION;

    /*//////////////////////////////////////////////////////////////
                            VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice Asset tokens lock duration in seconds. Can be adjusted by admin
    uint256 public timeLockDuration;

    /// @notice Total amount of asset tokens currently in `UNLOCKING` state
    uint256 public unlockingAssets;

    /// @notice Mapping to store user withdrawal requests by id
    mapping(address user => mapping(uint256 id => WithdrawalRequest)) private _userVsWithdrawals;

    /// @notice Mapping to index user's withdrawal request ids. Meant to only be incremented by 1 for each new request
    mapping(address user => uint256 nextID) private _userVsNextID;

    /*//////////////////////////////////////////////////////////////
                          CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @param name Token name
    /// @param symbol Token symbol
    /// @param asset Asset token to lock
    /// @param _timeLockDuration Lock duration for token deposits in seconds
    /// @param minTimeLockDuration Minimum lock duration for token deposits
    /// @param maxTimeLockDuration Maximum lock duration for token deposits
    /// @param admin Address to grant the admin role to
    constructor(
        string memory name,
        string memory symbol,
        address asset,
        uint256 _timeLockDuration,
        uint256 minTimeLockDuration,
        uint256 maxTimeLockDuration,
        address admin
    ) ERC20Permit(name) ERC20(name, symbol) {
        if (_timeLockDuration < minTimeLockDuration || _timeLockDuration > maxTimeLockDuration) {
            revert TimelockOutOfRange(_timeLockDuration);
        }

        _grantRole(DEFAULT_ADMIN_ROLE, admin);

        ASSET = asset;
        timeLockDuration = _timeLockDuration;
        MIN_TIME_LOCK_DURATION = minTimeLockDuration;
        MAX_TIME_LOCK_DURATION = maxTimeLockDuration;
    }

    /*//////////////////////////////////////////////////////////////
                             DEPOSIT
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ITimeLockedERC20
    function deposit(uint256 amount, address beneficiary) external {
        ASSET.safeTransferFrom(msg.sender, address(this), amount);

        if (beneficiary == address(0)) {
            beneficiary = msg.sender;
        }

        _deposit(amount, beneficiary);
    }

    /// @inheritdoc ITimeLockedERC20
    function depositWithPermit(uint256 amount, address beneficiary, bytes calldata permit) external {
        ASSET.permit(permit);

        ASSET.safeTransferFrom(msg.sender, address(this), amount);

        if (beneficiary == address(0)) {
            beneficiary = msg.sender;
        }

        _deposit(amount, beneficiary);
    }

    /*//////////////////////////////////////////////////////////////
                         WITHDRAW REQUEST
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ITimeLockedERC20
    function requestWithdraw(uint256 amount) external {
        uint256 id = _userVsNextID[msg.sender]++;

        _burn(msg.sender, amount);

        WithdrawalRequest storage request = _userVsWithdrawals[msg.sender][id];

        request.amount = amount;
        request.releaseTime = block.timestamp + timeLockDuration;
        request.status = WithdrawStatus.UNLOCKING;

        unlockingAssets += amount;

        emit RequestedUnlocking(id, msg.sender, amount);
    }

    /// @inheritdoc ITimeLockedERC20
    function cancelWithdrawalRequest(uint256 id) external {
        _cancelWithdrawalRequest(id);
    }

    /// @inheritdoc ITimeLockedERC20
    function cancelMultipleWithdrawalRequests(uint256[] calldata ids) external {
        for (uint256 i = 0; i < ids.length; i++) {
            _cancelWithdrawalRequest(ids[i]);
        }
    }

    /*//////////////////////////////////////////////////////////////
                             WITHDRAW
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ITimeLockedERC20
    function withdraw(uint256 id) external {
        uint256 amount = _withdraw(id);
        ASSET.safeTransfer(msg.sender, amount);
    }

    /// @inheritdoc ITimeLockedERC20
    function withdrawMultiple(uint256[] calldata ids) external {
        uint256 amount;

        for (uint256 i = 0; i < ids.length; i++) {
            amount += _withdraw(ids[i]);
        }

        ASSET.safeTransfer(msg.sender, amount);
    }

    /*//////////////////////////////////////////////////////////////
                            MIGRATOR
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ITimeLockedERC20
    function useNextId(address user) external onlyRole(MIGRATOR_ROLE) returns (uint256) {
        return _userVsNextID[user]++;
    }

    /*//////////////////////////////////////////////////////////////
                              ADMIN
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ITimeLockedERC20
    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /// @inheritdoc ITimeLockedERC20
    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /// @inheritdoc ITimeLockedERC20
    function changeTimeLock(uint256 newTimeLockDuration) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (newTimeLockDuration < MIN_TIME_LOCK_DURATION || newTimeLockDuration > MAX_TIME_LOCK_DURATION) {
            revert TimelockOutOfRange(newTimeLockDuration);
        }

        emit TimeLockChanged(timeLockDuration, newTimeLockDuration);

        timeLockDuration = newTimeLockDuration;
    }

    /*//////////////////////////////////////////////////////////////
                            VIEW HELPERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Getter for _userVsNextID
    function userVsNextID(address user) external view returns (uint256) {
        return _userVsNextID[user];
    }

    /// @notice Getter for _userVsWithdrawals
    function userVsWithdrawals(address user, uint256 id) external view returns (WithdrawalRequest memory) {
        return _userVsWithdrawals[user][id];
    }

    /// @inheritdoc ITimeLockedERC20
    function findUnlockingIDs(
        address user,
        int256 _start,
        uint256 countToCheck
    ) external view returns (uint256[] memory ids) {
        int256 nextID = int256(_userVsNextID[user]);

        if (_start >= nextID) return ids;
        if (_start < 0) _start += nextID;
        int256 _end = _start + int256(countToCheck);
        if (_end <= 0) return ids;
        if (_end > nextID) _end = nextID;
        if (_start < 0) _start = 0;

        mapping(uint256 => WithdrawalRequest) storage withdrawals = _userVsWithdrawals[user];

        ids = new uint256[](uint256(_end - _start));
        uint256 length = 0;
        uint256 end = uint256(_end);
        uint256 start = uint256(_start);

        // Nothing in here can overflow so disable the checks for the loop
        unchecked {
            for (uint256 id = start; id < end; ++id) {
                if (withdrawals[id].status == WithdrawStatus.UNLOCKING) {
                    ids[length++] = id;
                }
            }
        }

        // Need to force the array length to the correct value using assembly
        assembly {
            mstore(ids, length)
        }
    }

    /*//////////////////////////////////////////////////////////////
                              INTERNAL
    //////////////////////////////////////////////////////////////*/

    /// @notice Internal function which is used during deposit. Mints given amount and emits `Deposited` event
    /// @param amount Amount of tokens to mint
    function _deposit(uint256 amount, address beneficiary) internal {
        _mint(beneficiary, amount);

        emit Deposited(beneficiary, amount);
    }

    /// @notice Internal function which is used during withdrawal.
    ///         Checks if given withdrawal request can be withdrawn and emits `Withdraw` event
    /// @param id The id of withdrawal request
    /// @return amount Amount of asset tokens to withdraw
    function _withdraw(uint256 id) internal returns (uint256) {
        WithdrawalRequest storage request = _userVsWithdrawals[msg.sender][id];

        if (request.status != WithdrawStatus.UNLOCKING) {
            revert CannotWithdraw(id);
        }

        // Skip time lock check if sender is has `MIGRATOR` role
        if (!hasRole(MIGRATOR_ROLE, msg.sender)) {
            if (request.releaseTime > block.timestamp) {
                revert CannotWithdrawYet(id);
            }
        }

        request.status = WithdrawStatus.RELEASED;

        uint256 amount = request.amount;

        unlockingAssets -= amount;

        emit Withdraw(id, msg.sender, amount);

        return amount;
    }

    /// @notice Internal function which is used during withdrawal cancellation.
    ///         Checks if given withdrawal request can be cancelled and emits `CancelledWithdrawalRequest` event
    /// @param id The id of withdrawal request
    function _cancelWithdrawalRequest(uint256 id) internal {
        WithdrawalRequest storage request = _userVsWithdrawals[msg.sender][id];
        if (request.status != WithdrawStatus.UNLOCKING) {
            revert CannotCancelWithdrawalRequest(id);
        }

        request.status = WithdrawStatus.CANCELLED;

        uint256 amount = request.amount;

        _mint(msg.sender, amount);

        unlockingAssets -= amount;

        emit CancelledWithdrawalRequest(id, msg.sender, amount);
    }

    /// @notice Override to allow withdrawals during contract pause
    function _update(address from, address to, uint256 value) internal virtual override(ERC20) {
        // Only allow burn if paused
        if (to != address(0)) {
            _requireNotPaused();
        }

        super._update(from, to, value);
    }
}
