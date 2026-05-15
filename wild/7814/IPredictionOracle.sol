// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

/**
 * @title Poll Status Enum
 * @notice Shared enumeration for poll status
 */
enum PollStatus {
    Pending, // 0 - Initial state, awaiting answer
    Yes, // 1 - Positive answer
    No, // 2 - Negative answer
    Unknown // 3 - Cannot determine answer at check time
}

/**
 * @title PollInfo
 * @notice Complete poll information for backend processing
 */
struct PollInfo {
    address pollAddress;
    string question;
    string rules;
    string[] sources;
    uint32 deadlineEpoch; // target epoch when poll result should be resolved
    uint32 finalizationEpoch; // Epoch when poll result becomes final and immutable
    uint32 checkEpoch; // Epoch when poll should be checked/resolved by oracle operator
    address creator;
    address arbiter; // Arbiter address who can override poll status
    PollStatus status;
    uint8 category; // Poll type/category for classification
    string resolutionReason; // Explanation/reasoning for the resolution decision
}

/**
 * @title IPredictionPoll
 * @notice Interface for PredictionPoll contract
 */
interface IPredictionPoll {
    /// @notice Poll data structure
    struct PollData {
        string question; // Question text (max 200 chars)
        string rules; // Rules description (max 1000 chars)
        string[] sources; // Source URLs (max 3, 200 chars each)
        address creator; // Poll creator address
        address arbiter; // Arbiter address who can override poll status
        PollStatus status; // Current poll status (packed with arbiter and category)
        uint8 category; // Poll type/category (0-255, for frontend classification)
        uint32 finalizationEpoch; // Epoch when poll result becomes final and immutable
        uint32 deadlineEpoch; // target epoch when poll result should be resolved
        string resolutionReason; // Explanation/reasoning for the resolution decision
    }
    // ============================================
    // EVENTS
    // ============================================

    event AnswerSet(PollStatus status, address indexed setter, string reason);

    /// @notice Emitted when arbitration is started
    /// @param arbiter Address of the arbiter who started arbitration
    /// @param oldFinalizationEpoch Previous finalization epoch
    /// @param newFinalizationEpoch New finalization epoch after extension
    event ArbitrationStarted(
        address indexed arbiter,
        uint32 oldFinalizationEpoch,
        uint32 newFinalizationEpoch
    );

    // ============================================
    // ERRORS
    // ============================================

    /// @notice Only factory can call this function
    error OnlyFactory();

    /// @notice Only operator can call this function
    error OnlyOperator();

    /// @notice Deadline epoch not reached yet
    error DeadlineEpochNotReached();

    /// @notice Status is not Pending - operator cannot override
    error StatusNotPending();

    /// @notice Arbitration has not started yet
    error ArbitrationNotStarted();

    /// @notice Poll has been finalized and cannot be changed
    error PollFinalized();

    /// @notice Only arbiter can call this function
    error OnlyArbiter();

    /// @notice Poll already initialized
    error AlreadyInitialized();

    /// @notice Cannot set status to Pending as resolution
    error InvalidResolutionStatus();

    // ============================================
    // FUNCTIONS
    // ============================================

    function factory() external view returns (address);

    function arbitrationStarted() external view returns (bool);

    function ARBITRATION_SUBMISSION_WINDOW() external view returns (uint32);

    function ARBITRATION_ESCALATION_PERIOD() external view returns (uint32);

    function initialize(
        string memory _question,
        string memory _rules,
        string[] memory _sources,
        uint32 _deadlineEpoch,
        address _creator,
        address _arbiter,
        uint8 _category
    ) external;

    function setAnswer(PollStatus _status, string calldata _reason) external;

    function resolveArbitration(
        PollStatus _status,
        string calldata _reason
    ) external;

    function refreshPoll(bool _isFree) external returns (bool);

    function getStatus() external view returns (PollStatus);

    function getPollData() external view returns (PollData memory);

    function getCreator() external view returns (address);

    function getArbiter() external view returns (address);

    function getPollType() external view returns (uint8);

    function getFinalizationEpoch() external view returns (uint32);

    function getDeadlineEpoch() external view returns (uint32);

    function getFinalizedStatus()
        external
        view
        returns (bool isFinalized, PollStatus status);

    function matchesFilters(
        uint256 _statusFilter,
        uint256 _typeFilter
    ) external view returns (bool);

    function startArbitration() external;
}

/**
 * @title IPredictionOracle
 * @notice Interface for PredictionOracle contract
 */
interface IPredictionOracle {
    // ============================================
    // EVENTS
    // ============================================

    /// @notice Emitted when new poll is created
    event PollCreated(
        address indexed pollAddress,
        address indexed creator,
        uint32 deadlineEpoch,
        string question
    );

    /// @notice Emitted when poll check epoch is refreshed
    event PollRefreshed(
        address indexed pollAddress,
        uint32 oldCheckEpoch,
        uint32 newCheckEpoch,
        bool wasFree
    );

    /// @notice Emitted when operator is added
    event OperatorAdded(address indexed operator);

    /// @notice Emitted when operator is removed
    event OperatorRemoved(address indexed operator);

    /// @notice Emitted when operator gas fee is updated
    event OperatorGasFeeUpdated(uint256 newFee);

    /// @notice Emitted when protocol fee is updated
    event ProtocolFeeUpdated(uint256 newFee);

    /// @notice Emitted when poll implementation is updated
    event PollImplementationUpdated(
        address indexed oldImplementation,
        address indexed newImplementation
    );

    /// @notice Emitted when protocol fees are withdrawn
    event ProtocolFeesWithdrawn(address indexed to, uint256 amount);

    // ============================================
    // ERRORS
    // ============================================

    error InvalidQuestionLength();
    error InvalidRulesLength();
    error TooManySources();
    error InvalidSourceLength();
    error InsufficientPayment();
    error NoOperatorsAvailable();
    error OperatorAlreadyExists();
    error OperatorNotFound();
    error CannotRemoveLastOperator();
    error CannotRefreshYet();
    error InvalidAddress();
    error RefreshPaymentRequired();
    error PollNotFound();
    error WithdrawalFailed();
    error InsufficientProtocolFees();
    error InvalidTargetTimestamp();
    error ForbiddenRefresh();
    error ImplementationNotSet();

    // ============================================
    // POLL MANAGEMENT
    // ============================================

    function createPoll(
        string calldata _question,
        string calldata _rules,
        string[] calldata _sources,
        uint256 _targetTimestamp,
        address _arbiter,
        uint8 _category
    ) external payable returns (address pollAddress);

    function refreshPollFree(address _pollAddress) external;

    function refreshPollPaid(address _pollAddress) external payable;

    // ============================================
    // MANAGEMENT
    // ============================================

    function addOperator(address _operator) external;

    function removeOperator(address _operator) external;

    function getOperators() external view returns (address[] memory);

    function getOperatorCount() external view returns (uint256);

    function isOperator(address _addr) external view returns (bool);

    function setOperatorGasFee(uint256 _fee) external;

    function setProtocolFee(uint256 _fee) external;

    function setPollImplementation(address _implementation) external;

    function pause() external;

    function unpause() external;

    function withdrawProtocolFees(address payable _to) external;

    // ============================================
    // VIEW FUNCTIONS
    // ============================================

    function operatorGasFee() external view returns (uint256);

    function protocolFee() external view returns (uint256);

    function accumulatedProtocolFees() external view returns (uint256);

    function pollImplementation() external view returns (address);

    function MAX_QUESTION_LENGTH() external view returns (uint256);

    function MAX_RULES_LENGTH() external view returns (uint256);

    function MAX_SOURCES() external view returns (uint256);

    function MAX_SOURCE_LENGTH() external view returns (uint256);

    function PENDING_TIMEOUT_EPOCHS() external view returns (uint256);

    function EPOCH_LENGTH() external view returns (uint256);

    function getCurrentEpoch() external view returns (uint32);

    function getPollsByEpochRange(
        uint32 _fromEpoch,
        uint32 _toEpoch,
        uint256 _statusFilter,
        uint256 _typeFilter,
        uint256 _maxResults,
        uint256 _startIndex
    )
        external
        view
        returns (PollInfo[] memory polls, uint32 nextEpoch, uint256 nextIndex);

    function getPollsByEpochs(
        uint32[] calldata _epochs,
        uint256 _statusFilter,
        uint256 _typeFilter,
        uint256 _maxResults
    ) external view returns (PollInfo[] memory polls);

    function getPollsByCreator(
        address _creator,
        uint256 _maxResults,
        uint256 _offset
    ) external view returns (PollInfo[] memory polls, bool hasMore);

    function getCurrentCheckEpoch(
        address _pollAddress
    ) external view returns (uint32);

    function verifyPollAddressExists(
        address _pollAddress
    ) external view returns (bool);

    function pollsByCheckEpoch(
        uint32 _epoch,
        uint256 _index
    ) external view returns (address);

    function pollsByCreator(
        address _creator,
        uint256 _index
    ) external view returns (address);
}
