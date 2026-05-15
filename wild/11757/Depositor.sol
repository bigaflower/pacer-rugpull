// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import "solady/src/utils/SafeTransferLib.sol";
import "src/DepositorBase.sol";
import {IERC20} from "src/interfaces/IERC20.sol";
import {SafeModule} from "src/utils/SafeModule.sol";
import {IVeToken} from "src/interfaces/IVeToken.sol";
import {ITokenMinter} from "src/interfaces/ITokenMinter.sol";

import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

/// @title YieldBasisDepositor
/// @notice Contract that accepts tokens and locks them in the Yield Basis Voting Escrow via a Safe module
/// @author StakeDAO
/// @custom:contact contact@stakedao.org
contract YieldBasisDepositor is DepositorBase, SafeModule {

    ///////////////////////////////////////////////////////////////
    /// --- IMMUTABLES
    ///////////////////////////////////////////////////////////////

    /// @notice Address of the Yield Basis voting escrow contract.
    address public immutable VE_YB;

    ////////////////////////////////////////////////////////////////
    /// --- STATE
    ////////////////////////////////////////////////////////////////

    /// @notice Address of the fallback handler contract.
    address public fallbackHandler;

    /// @notice Amount of tokens sitting in the Safe but not yet locked due to ve rounding.
    uint256 public lockBuffer;

    /// @notice Snapshot of the locker's ve balance used to compute incremental gains.
    uint256 public lastSyncedLockAmount;


    /// @notice Throws when the caller is not the fallback handler.
    error NotFallbackHandler();

    /// @notice Throws when attempting to create the lock more than once.
    error LockAlreadyInitialized();

    /// @notice Throws when attempting to operate before the locker position exists.
    error LockNotInitialized();

    /// @notice Throws when there is no lockable amount available for a `createLock` call.
    error InsufficientLockableAmount();

    /// @notice Throws when the locker is expected to be in infinite mode but is not.
    error LockerNotInfinite();

    /// @notice Throws when amounts observed during a transfer do not match expectations.
    error AmountMismatch();

    event VePositionReceived(address indexed from, uint256 amount);
    event FallbackHandlerUpdated(address indexed handler);

    modifier onlyFallbackHandler() {
        require(msg.sender == fallbackHandler, NotFallbackHandler());
        _;
    }

    ////////////////////////////////////////////////////////////////
    /// --- CONSTRUCTOR
    ///////////////////////////////////////////////////////////////

    /// @notice Constructor
    /// @param _token Address of the token to lock
    /// @param _locker Address of the Safe wallet that owns the lock
    /// @param _minter Address of the sdToken minter
    /// @param _gateway Address of the Safe module gateway
    /// @param _veToken Address of the Yield Basis voting escrow contract
    constructor(address _token, address _locker, address _minter, address _gateway, address _veToken)
        DepositorBase(_token, _locker, _minter, 4 * 365 days)
        SafeModule(_gateway)
    {
        if (_veToken == address(0)) revert ADDRESS_ZERO();
        VE_YB = _veToken;
    }

    /// @notice Creates the initial lock by calling the ve contract through the Safe module
    function createLock(uint256 _amount) external override onlyActive {
        if (_amount == 0) revert AMOUNT_ZERO();
        if (_lockedAmount(locker) != 0) revert LockAlreadyInitialized();

        SafeTransferLib.safeTransferFrom(token, msg.sender, locker, _amount);

        uint256 _lockable = _getLockableAmount(_amount);
        if (_lockable == 0) revert InsufficientLockableAmount();

        uint256 _unlockTime = _roundedUnlockTime(block.timestamp + MAX_LOCK_DURATION);

        _execute_approveToken(type(uint256).max);
        _execute_createLock(_lockable, _unlockTime);

        _execute_infiniteLockToggle();
        require(IVeToken(VE_YB).locked__end(locker) == type(uint256).max, LockerNotInfinite());

        _syncLockerAmount();

        ITokenMinter(minter).mint(msg.sender, _amount);
    }

    /// @notice Locks (or relocks) the tokens held by the locker in the voting escrow
    /// @dev Uses Safe module execution to call the Yield Basis voting escrow contract
    function _lockToken(uint256 _amount) internal override {
        uint256 _lockable = _getLockableAmount(_amount);
        if (_lockable != 0) {
            _execute_increaseAmount(_lockable);
        }

        _syncLockerAmount();
    }

    /// @notice Callback used by the Safe fallback handler when the locker receives a veNFT.
    /// @param owner The address that previously owned the veNFT.
    function onYieldBasisVeReceived(address owner) external onlyFallbackHandler {
        uint256 previous = lastSyncedLockAmount;
        uint256 current = _lockedAmount(locker);

        require(current > previous, AmountMismatch());

        lastSyncedLockAmount = current;

        uint256 gained = current - previous;
        ITokenMinter(minter).mint(owner, gained);

        emit VePositionReceived(owner, gained);
    }

    /// @notice Creates the lock in the Yield Basis voting escrow
    /// @param amount Amount of tokens to lock
    /// @param unlockTime Lock end timestamp
    function _execute_createLock(uint256 amount, uint256 unlockTime) internal virtual {
        _executeTransaction(VE_YB, abi.encodeWithSelector(IVeToken.create_lock.selector, amount, unlockTime));
    }

    /// @notice Approves the voting escrow to pull tokens from the Safe wallet
    /// @param amount Amount to approve
    function _execute_approveToken(uint256 amount) internal virtual {
        _executeTransaction(token, abi.encodeWithSelector(IERC20.approve.selector, VE_YB, amount));
    }

    /// @notice Increases the locked amount for the Safe wallet
    /// @param amount Amount of tokens to add to the lock
    function _execute_increaseAmount(uint256 amount) internal virtual {
        _executeTransaction(VE_YB, abi.encodeWithSelector(IVeToken.increase_amount.selector, amount));
    }

    /// @notice Toggle the locker lock between finite and infinite mode.
    function _execute_infiniteLockToggle() internal virtual {
        _executeTransaction(VE_YB, abi.encodeWithSelector(IVeToken.infinite_lock_toggle.selector));
    }

    /// @notice Refresh the cached locker amount from the voting escrow.
    function _syncLockerAmount() internal {
        lastSyncedLockAmount = _lockedAmount(locker);
    }

    /// @notice Fetch the current locked amount for an account.
    function _lockedAmount(address account) internal view returns (uint256) {
        IVeToken.LockedBalance memory lockInfo = IVeToken(VE_YB).locked(account);
        if (lockInfo.amount <= 0) return 0;
        return SafeCast.toUint256(lockInfo.amount);
    }

    /// @notice Aggregates deposits until the ve contract rounding allows locking them.
    /// @param addedAmount Newly deposited amount to account for.
    /// @return _lockable Portion of the buffer that can be sent to the ve contract.
    function _getLockableAmount(uint256 addedAmount) internal returns (uint256 _lockable) {
        if (addedAmount != 0) lockBuffer += addedAmount;

        uint256 buffer = lockBuffer;
        if (buffer < MAX_LOCK_DURATION) return 0;

        _lockable = buffer / MAX_LOCK_DURATION * MAX_LOCK_DURATION;

        lockBuffer = buffer - _lockable;
    }

    function _roundedUnlockTime(uint256 timestamp) internal pure returns (uint256) {
        return (timestamp / 1 weeks) * 1 weeks;
    }

    function _getLocker() internal view override returns (address) {
        return locker;
    }

    ///////////////////////////////////////////////////////////////
    /// --- GETTERS
    ///////////////////////////////////////////////////////////////

    function version() external pure virtual override returns (string memory) {
        return "1.1.0";
    }

    function name() external view virtual override returns (string memory) {
        return type(YieldBasisDepositor).name;
    }

    function setFallbackHandler(address _fallbackHandler) external onlyGovernance {
        require(_fallbackHandler != address(0), ADDRESS_ZERO());
        fallbackHandler = _fallbackHandler;
        emit FallbackHandlerUpdated(_fallbackHandler);
    }
}
