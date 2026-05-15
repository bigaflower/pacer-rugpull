// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import "solady/src/utils/SafeTransferLib.sol";
import "src/interfaces/IERC20.sol";
import "src/interfaces/ILiquidityGauge.sol";
import "src/interfaces/ILocker.sol";
import "src/interfaces/ISdToken.sol";
import "src/interfaces/ITokenMinter.sol";
import {IDepositorBase} from "src/interfaces/IDepositorBase.sol";

/// @title DepositorBase
/// @notice Contract that accepts tokens and locks them in the Locker, minting sdToken in return
/// @dev Adapted for veCRV like Locker.
/// @author StakeDAO
/// @custom:contact contact@stakedao.org
abstract contract DepositorBase is IDepositorBase {
    ///////////////////////////////////////////////////////////////
    /// --- STATE VARIABLES & CONSTANTS
    ///////////////////////////////////////////////////////////////

    /// @notice Denominator for fixed point math.
    uint256 public constant DENOMINATOR = 1e18;

    /// @notice Maximum lock duration.
    uint256 public immutable MAX_LOCK_DURATION;

    /// @notice Address of the token to be locked.
    address public immutable token;

    /// @notice Address of the locker contract.
    address public immutable locker;

    /// @notice Address of the sdToken minter contract.
    address public minter;

    /// @notice Address of the governance.
    address public governance;

    /// @notice Address of the future governance contract.
    address public futureGovernance;

    enum STATE {
        UNINITIALIZED, // default state at construction
        ACTIVE,
        CANCELED
    }

    /// @notice The state of the contract.
    /**
     * @dev The contract uses a minimalistic state machine pattern to manage the lifecycle of locked tokens:
     * 1. At construction time, the contract is in the ACTIVE state.
     * 2. The contract can be shutdown by the governance at any time, transitioning the contract to the CANCELED state.
     *    This is a terminal state and cannot be reverted.
     *
     * Here's the State Machine Diagram:
     *
     *  +--------------+
     *  |   ACTIVE     |
     *  +--------------+
     *       |
     *     shutdown
     *       |
     *       ↓
     *  +--------------+
     *  |   CANCELED   |
     *  +--------------+
     *
     * Transitions:
     * - ACTIVE -> CANCELED: via `shutdown()`
     */
    STATE public state;

    ////////////////////////////////////////////////////////////////
    /// --- EVENTS & ERRORS
    ///////////////////////////////////////////////////////////////

    /// @notice Throws if caller is not the governance.
    error GOVERNANCE();

    /// @notice Throws if the deposit amount is zero.
    error AMOUNT_ZERO();

    /// @notice Throws if the address is zero.
    error ADDRESS_ZERO();

    /// @notice Throws if the contract is not active.
    error DEPOSITOR_DISABLED();

    /// @notice Event emitted when the governance update is proposed
    event GovernanceUpdateProposed(address newFutureGovernance);

    /// @notice Event emitted when the governance update is accepted
    event GovernanceUpdateAccepted(address newGovernance);

    /// @notice Event emitted when the state of the contract is updated.
    /// @param newState The new state of the contract.
    event StateUpdated(STATE newState);

    ////////////////////////////////////////////////////////////////
    /// --- MODIFIERS
    ///////////////////////////////////////////////////////////////

    modifier onlyGovernance() {
        if (msg.sender != governance) revert GOVERNANCE();
        _;
    }

    modifier onlyActive() {
        if (state != STATE.ACTIVE) revert DEPOSITOR_DISABLED();
        _;
    }

    constructor(address _token, address _locker, address _minter, uint256 _maxLockDuration) {
        if (_token == address(0) || _locker == address(0) || _minter == address(0)) {
            revert ADDRESS_ZERO();
        }

        governance = msg.sender;

        token = _token;
        minter = _minter;
        locker = _locker;

        MAX_LOCK_DURATION = _maxLockDuration;

        /// Set the state of the contract to ACTIVE
        _setState(STATE.ACTIVE);
    }

    ////////////////////////////////////////////////////////////////
    /// --- DEPOSIT & LOCK
    ///////////////////////////////////////////////////////////////

    function _createLockFrom(address _from, uint256 _amount) internal virtual {
        // Transfer tokens to the locker contract
        SafeTransferLib.safeTransferFrom(token, _from, address(locker), _amount);

        // Can be called only once.
        ILocker(locker).createLock(_amount, block.timestamp + MAX_LOCK_DURATION);
    }

    /// @notice Initiate a lock in the Locker contract and mint the sdTokens to the caller.
    /// @param _amount Amount of tokens to lock.
    function createLock(uint256 _amount) external virtual onlyActive {
        // Transfer caller's tokens to the locker and lock them
        _createLockFrom(msg.sender, _amount);

        /// Mint sdToken to msg.sender.
        ITokenMinter(minter).mint(msg.sender, _amount);
    }

    /// @notice Deposit all tokens held by the contract.
    /// @param _user Address of the user to receive the sdToken.
    function depositAll(address _user) external {
        uint256 tokenBalance = IERC20(token).balanceOf(msg.sender);
        deposit(tokenBalance, _user);
    }

    /// @notice Deposit tokens, and receive sdToken in return.
    /// @param _amount Amount of tokens to deposit.
    /// @param _user Address of the user to receive the sdToken.
    /// @custom:reverts DEPOSITOR_DISABLED if the contract is not active.
    /// @custom:reverts AMOUNT_ZERO if the amount is zero.
    /// @custom:reverts ADDRESS_ZERO if the user address is zero.
    function deposit(uint256 _amount, address _user) public onlyActive {
        if (_amount == 0) revert AMOUNT_ZERO();
        if (_user == address(0)) revert ADDRESS_ZERO();

        /// Transfer tokens to the locker contract.
        SafeTransferLib.safeTransferFrom(token, msg.sender, locker, _amount);

        /// Lock the amount sent.
        _lockToken(_amount);

        /// Mint sdToken to _user.
        ITokenMinter(minter).mint(_user, _amount);
    }

    /// @notice Locks the tokens held by the contract
    /// @dev The contract must have tokens to lock
    function _lockToken(uint256 _amount) internal virtual {
        if (_amount != 0) {
            /// Increase the lock.
            ILocker(locker).increaseLock(_amount, block.timestamp + MAX_LOCK_DURATION);
        }
    }

    ////////////////////////////////////////////////////////////////
    /// --- GOVERNANCE PARAMETERS
    ///////////////////////////////////////////////////////////////

    /// @notice Transfer the governance to a new address.
    /// @param _governance Address of the new governance.
    function transferGovernance(address _governance) external onlyGovernance {
        emit GovernanceUpdateProposed(futureGovernance = _governance);
    }

    /// @notice Accept the governance transfer.
    function acceptGovernance() external {
        if (msg.sender != futureGovernance) revert GOVERNANCE();

        emit GovernanceUpdateAccepted(governance = msg.sender);

        futureGovernance = address(0);
    }

    /// @notice Shutdown the contract and transfer the balance of the contract to the given receiver.
    /// @param receiver Address who will receive the balance of this contract.
    /// @dev This will put the contract in the CANCELED state, preventing any further deposits, or locking of tokens.
    //       Use `shutdown()` to transfer the remaining balance to the governance address.
    /// @custom:reverts ONLY_GOVERNANCE if the caller is not the governance.
    function shutdown(address receiver) public onlyGovernance {
        _setState(STATE.CANCELED);

        // Recover any token left in the contract.
        SafeTransferLib.safeTransfer(token, receiver, IERC20(token).balanceOf(address(this)));
    }

    /// @notice Shutdown the contract and transfer the balance of the contract to the governance.
    /// @custom:reverts ONLY_GOVERNANCE if the caller is not the governance.
    function shutdown() external onlyGovernance {
        shutdown(governance);
    }

    /// @notice Set the new operator for minting sdToken
    /// @param _minter operator minter address
    function setSdTokenMinterOperator(address _minter) external virtual onlyGovernance {
        ISdToken(minter).setOperator(_minter);
    }

    function _setState(STATE _state) internal {
        state = _state;
        emit StateUpdated(_state);
    }

    function name() external view virtual returns (string memory) {
        return string(abi.encodePacked(IERC20(token).symbol(), " Depositor"));
    }

    /// @notice Get the version of the contract
    /// Version follows the Semantic Versioning (https://semver.org/)
    /// Major version is increased when backward compatibility is broken in this base contract.
    /// Minor version is increased when new features are added in this base contract.
    /// Patch version is increased when child contracts are updated.
    function version() external pure virtual returns (string memory) {
        return "4.0.0";
    }
}
