// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {PollStatus, IPredictionPoll, IPredictionOracle} from "./interfaces/IPredictionOracle.sol";

/**
 * @title PredictionPoll
 * @notice Individual poll contract storing question data and answer
 * @dev Deployed by PredictionOracle for each poll
 */
contract PredictionPoll is IPredictionPoll {
    /// @notice Factory contract address
    address public factory;

    /// @notice Arbitration started flag
    bool public arbitrationStarted;

    /// @notice Poll data storage
    PollData private _pollData;

    /// @notice Initialization flag to prevent re-initialization
    bool private _initialized;

    // ============================================
    // CONSTANTS
    // ============================================

    /// @notice Arbitration submission window - time to request arbitration (24 hours = 288 epochs, as EPOCH_LENGTH = 5 minutes)
    uint32 public constant ARBITRATION_SUBMISSION_WINDOW = 288;

    /// @notice Arbitration escalation period - additional time when arbitration is started (36 hours = 432 epochs)
    uint32 public constant ARBITRATION_ESCALATION_PERIOD = 432;

    // ============================================
    // MODIFIERS
    // ============================================

    /// @notice Restrict function to factory only
    modifier onlyFactory() {
        if (msg.sender != factory) revert OnlyFactory();
        _;
    }

    /// @notice Restrict to one-time initialization
    modifier initializer() {
        if (_initialized) revert AlreadyInitialized();
        _initialized = true;
        _;
    }

    /// @notice Restrict function to arbiter only
    modifier onlyArbiter() {
        if (msg.sender != _pollData.arbiter) revert OnlyArbiter();
        _;
    }

    /// @notice Restrict function to operator only
    modifier onlyOperator() {
        bool isOperator = IPredictionOracle(factory).isOperator(msg.sender);
        if (!isOperator) revert OnlyOperator();
        _;
    }

    /// @notice Validate that status is a valid resolution (not Pending)
    modifier validResolutionStatus(PollStatus _status) {
        if (_status == PollStatus.Pending) revert InvalidResolutionStatus();
        _;
    }

    // ============================================
    // CONSTRUCTOR
    // ============================================

    /**
     * @notice Constructor for implementation contract
     * @dev Immediately marks implementation as initialized to prevent direct use
     * @dev Only clones can be properly initialized
     */
    constructor() {
        _initialized = true; // Lock implementation contract
    }

    // ============================================
    // INITIALIZATION
    // ============================================

    /**
     * @notice Initialize poll with data (called once after clone deployment)
     * @dev Replaces constructor for clone pattern
     * @dev Can only be called once
     * @param _question Question text
     * @param _rules Rules description
     * @param _sources Source URLs array
     * @param _deadlineEpoch Epoch when poll should be checked/resolved
     * @param _creator Poll creator address
     * @param _arbiter Arbiter address who can override poll status
     * @param _category Poll type/category for frontend classification
     */
    function initialize(
        string memory _question,
        string memory _rules,
        string[] memory _sources,
        uint32 _deadlineEpoch,
        address _creator,
        address _arbiter,
        uint8 _category
    ) external initializer {
        factory = msg.sender;

        // Initialize poll data (omit default values for gas savings)
        _pollData.question = _question;
        _pollData.rules = _rules;
        _pollData.sources = _sources;
        _pollData.creator = _creator;
        _pollData.arbiter = _arbiter;
        _pollData.category = _category;
        _pollData.finalizationEpoch =
            _deadlineEpoch +
            ARBITRATION_SUBMISSION_WINDOW; // can be changed by operator
        _pollData.deadlineEpoch = _deadlineEpoch; // constant for now
        // status defaults to Pending (0)
        // resolutionReason defaults to "" (empty)
    }

    // ============================================
    // EXTERNAL FUNCTIONS
    // ============================================

    /**
     * @notice Set poll answer by operator
     * @dev Can only be called by operators when status is Pending
     * @dev Operator can only set answer when:
     *      - Current epoch >= deadlineEpoch
     *      - Current epoch < finalizationEpoch
     *      - Current status is Pending
     * @param _status New status to set (Yes, No, or Unknown)
     * @param _reason Explanation/reasoning for the resolution decision
     */
    function setAnswer(
        PollStatus _status,
        string calldata _reason
    ) external onlyOperator validResolutionStatus(_status) {
        uint32 currentEpoch = IPredictionOracle(factory).getCurrentEpoch();

        // Check if poll is finalized
        if (currentEpoch >= _pollData.finalizationEpoch) {
            revert PollFinalized();
        }

        // Check epoch must be reached
        if (currentEpoch < _pollData.deadlineEpoch) {
            revert DeadlineEpochNotReached();
        }

        // Can only set answer if status is Pending
        if (_pollData.status != PollStatus.Pending) {
            revert StatusNotPending();
        }

        _pollData.status = _status;
        _pollData.resolutionReason = _reason;

        emit AnswerSet(_status, msg.sender, _reason);
    }

    /**
     * @notice Update status during refresh
     * @dev Only callable by factory
     * @dev Cannot be called after finalization
     * @dev Resets status to Pending and clears resolution reason
     * @dev Does NOT change finalization epoch - it remains from initial creation
     */
    function refreshPoll(bool _isFree) external onlyFactory returns (bool) {
        (bool isFinalized, PollStatus status) = getFinalizedStatus();
        if (isFinalized) return false;
        if (_isFree) return status == PollStatus.Pending;
        if (status == PollStatus.Unknown) {
            _pollData.status = PollStatus.Pending;
            _pollData.resolutionReason = ""; // Clear resolution reason when resetting to Pending
            return true;
        }
        return false;
    }

    /**
     * @notice Start arbitration process, extending the finalization deadline
     * @dev Only callable by the arbiter
     * @dev Extends finalization epoch by arbitration escalation period (36 hours)
     * @dev Can only be called before current finalization epoch
     */
    function startArbitration() external onlyArbiter {
        uint32 currentEpoch = IPredictionOracle(factory).getCurrentEpoch();
        uint32 oldFinalizationEpoch = _pollData.finalizationEpoch;

        if (currentEpoch < _pollData.deadlineEpoch) {
            revert DeadlineEpochNotReached();
        }

        // Cannot start arbitration after finalization
        if (currentEpoch >= oldFinalizationEpoch) {
            revert PollFinalized();
        }

        uint32 newFinalizationEpoch = currentEpoch +
            ARBITRATION_ESCALATION_PERIOD;
        _pollData.finalizationEpoch = newFinalizationEpoch;
        arbitrationStarted = true;
        emit ArbitrationStarted(
            msg.sender,
            oldFinalizationEpoch,
            newFinalizationEpoch
        );
    }

    /**
     * @notice Resolve arbitration and set final answer
     * @dev Can only be called by the arbiter
     * @dev Arbiter can override any status before finalization
     * @dev Sets finalization epoch to current epoch, making result immediately final
     * @param _status New status to set (Yes, No, or Unknown)
     * @param _reason Explanation/reasoning for the arbitration decision
     */
    function resolveArbitration(
        PollStatus _status,
        string calldata _reason
    ) external onlyArbiter validResolutionStatus(_status) {
        uint32 currentEpoch = IPredictionOracle(factory).getCurrentEpoch();

        // Check if poll is finalized
        if (currentEpoch >= _pollData.finalizationEpoch) {
            revert PollFinalized();
        }

        if (!arbitrationStarted) {
            revert ArbitrationNotStarted();
        }

        // Set the answer
        _pollData.status = _status;
        _pollData.resolutionReason = _reason;

        // Finalize immediately - set finalization epoch to current epoch
        _pollData.finalizationEpoch = currentEpoch;

        emit AnswerSet(_status, msg.sender, _reason);
    }

    // ============================================
    // VIEW FUNCTIONS
    // ============================================

    /**
     * @notice Get current poll status
     * @return Current status
     */
    function getStatus() external view returns (PollStatus) {
        return _pollData.status;
    }

    /**
     * @notice Get complete poll data
     * @return Complete PollData structure
     */
    function getPollData() external view returns (PollData memory) {
        return _pollData;
    }

    /**
     * @notice Get poll creator address
     * @return Creator address
     */
    function getCreator() external view returns (address) {
        return _pollData.creator;
    }

    /**
     * @notice Get poll arbiter address
     * @return Arbiter address
     */
    function getArbiter() external view returns (address) {
        return _pollData.arbiter;
    }

    /**
     * @notice Get poll type
     * @return Poll type/category
     */
    function getPollType() external view returns (uint8) {
        return _pollData.category;
    }

    /**
     * @notice Get finalization epoch
     * @return Finalization epoch number
     */
    function getFinalizationEpoch() external view returns (uint32) {
        return _pollData.finalizationEpoch;
    }

    /**
     * @notice Get finalized status and current poll status
     * @return isFinalized True if poll has reached finalization epoch and cannot be changed
     * @return status Current poll status
     */
    function getFinalizedStatus()
        public
        view
        returns (bool isFinalized, PollStatus status)
    {
        uint32 currentEpoch = IPredictionOracle(factory).getCurrentEpoch();
        isFinalized = currentEpoch >= _pollData.finalizationEpoch;
        status = _pollData.status;
    }

    /**
     * @notice Get deadline epoch
     * @return Deadline epoch number
     */
    function getDeadlineEpoch() external view returns (uint32) {
        return _pollData.deadlineEpoch;
    }

    /**
     * @notice Check if poll matches status and type filters
     * @dev Optimized method to check both filters in single call
     * @param _statusFilter Bit flags (1=Pending, 2=Yes, 4=No, 8=Unknown, 0=All)
     * @param _typeFilter Bit flags for poll types (1<<N for type N, 0=All)
     * @return True if poll matches both filters
     */
    function matchesFilters(
        uint256 _statusFilter,
        uint256 _typeFilter
    ) external view returns (bool) {
        // Check status filter (0 means all statuses)
        bool statusMatch = _statusFilter == 0 ||
            (_statusFilter & (1 << uint256(_pollData.status))) != 0;

        // Check type filter (0 means all types)
        bool typeMatch = _typeFilter == 0 ||
            (_typeFilter & (1 << uint256(_pollData.category))) != 0;

        return statusMatch && typeMatch;
    }
}
