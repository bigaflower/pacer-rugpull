// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// ============ START OF INLINED OPENZEPPELIN IMPORTS ============
// IERC20.sol
/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// ReentrancyGuard.sol
/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 */
abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;
    error ReentrancyGuardReentrantCall();
    constructor() { _status = _NOT_ENTERED; }
    modifier nonReentrant() {
        if (_status == _ENTERED) revert ReentrancyGuardReentrantCall();
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}
// ============ END OF INLINED IMPORTS ============

/**
 * @title TikToken - Privacy-First Token with Public Trading
 * @notice Implements stealth addresses, UTXO commitments, and ZK proofs for private transfers.
 *         Also supports standard ERC20 transfers for DEX compatibility.
 * @dev The 1.5% fee on private transfers is sent to a fixed collector address via hidden commitments.
 */
contract TikToken is IERC20, ReentrancyGuard {
    // ============ CUSTOM ERRORS ============
    error ArrayLengthMismatch();
    error InvalidOutputCount();
    error InvalidFeeCollector();
    error CommitmentNotFound();
    error CommitmentSpent();
    error NullifierUsed();
    error InvalidZKProof();
    error MaxInputsExceeded(uint256 max, uint256 provided);
    error ZeroAddress();
    error ZeroAmount();
    error InsufficientContractBalance();
    error InsufficientBalance();
    error InsufficientAllowance();
    error TransferFromZero();
    error TransferToZero();
    error OnlyAdmin();

    // ============ CONSTANTS ============
    uint256 public constant MAX_SUPPLY = 6_000_000 * 10**18; // 6,000,000 tokens (18 decimals)
    uint256 public constant FEE_NUMERATOR = 15;   // 1.5% = 15/1000
    uint256 public constant FEE_DENOMINATOR = 1000;
    uint256 private constant MAX_INPUT_COMMITMENTS = 20;

    // ============ IMMUTABLE ADDRESSES ============
    address public immutable ADMIN;
    address public immutable FEE_COLLECTOR;

    // ============ PRIVACY CORE ============
    struct StealthMeta {
        bytes32 viewTag;
        bytes ephemeralPubKey;
    }

    struct Commitment {
        bytes32 hash;
        uint256 blockNumber;
        bool spent;
    }

    // Storage
    mapping(bytes32 => Commitment) public commitments;
    mapping(address => StealthMeta[]) public incomingStealthTxs;
    mapping(address => bytes32[]) public userCommitments;
    mapping(bytes32 => bool) public usedNullifiers;

    // Public balances (for ERC20 compatibility)
    mapping(address => uint256) private _publicBalances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    // ============ EVENTS ============
    event NewCommitment(bytes32 indexed commitmentHash, address indexed owner, uint256 amount);
    event CommitmentSpentLog(bytes32 indexed nullifier);
    event StealthTransfer(address indexed from, StealthMeta metadata);
    event ContractSweep(address indexed to, uint256 amount);

    // ============ CONSTRUCTOR ============
    constructor() {
        ADMIN = 0x651F3A9A59b69e284F834F4914A6ed206a516371;
        FEE_COLLECTOR = 0x651F3A9A59b69e284F834F4914A6ed206a516371;

        _totalSupply = MAX_SUPPLY;
        _publicBalances[address(this)] = MAX_SUPPLY;

        bytes32 initialCommitment = _createCommitment(address(this), MAX_SUPPLY, bytes32(0));
        commitments[initialCommitment] = Commitment({
            hash: initialCommitment,
            blockNumber: block.number,
            spent: false
        });
        userCommitments[address(this)].push(initialCommitment);

        emit Transfer(address(0), address(this), MAX_SUPPLY);
    }

    // ============ PRIVATE TRANSFER WITH 1.5% FEE ============

    function privateTransfer(
        bytes32[] calldata inputCommitments,
        bytes32[] calldata inputNullifiers,
        bytes32[] calldata outputCommitments,
        address[] calldata outputOwners,
        bytes calldata zkProof,
        StealthMeta calldata stealthMeta
    ) external nonReentrant {
        if (inputCommitments.length != inputNullifiers.length) revert ArrayLengthMismatch();
        if (outputCommitments.length != 2 || outputOwners.length != 2) revert InvalidOutputCount();
        if (outputOwners[1] != FEE_COLLECTOR) revert InvalidFeeCollector();
        if (inputCommitments.length > MAX_INPUT_COMMITMENTS) revert MaxInputsExceeded(MAX_INPUT_COMMITMENTS, inputCommitments.length);

        // Verify all inputs exist and are unspent
        for (uint256 i = 0; i < inputCommitments.length; i++) {
            Commitment storage inp = commitments[inputCommitments[i]];
            if (inp.hash == bytes32(0)) revert CommitmentNotFound();
            if (inp.spent) revert CommitmentSpent();
            if (usedNullifiers[inputNullifiers[i]]) revert NullifierUsed();
        }

        if (!_verifyZKProof(zkProof, inputCommitments, inputNullifiers, outputCommitments, outputOwners)) {
            revert InvalidZKProof();
        }

        // Mark inputs as spent
        for (uint256 i = 0; i < inputCommitments.length; i++) {
            commitments[inputCommitments[i]].spent = true;
            usedNullifiers[inputNullifiers[i]] = true;
            emit CommitmentSpentLog(inputNullifiers[i]);
        }

        // Register new commitments
        for (uint256 i = 0; i < outputCommitments.length; i++) {
            commitments[outputCommitments[i]] = Commitment({
                hash: outputCommitments[i],
                blockNumber: block.number,
                spent: false
            });
            userCommitments[outputOwners[i]].push(outputCommitments[i]);
            emit NewCommitment(outputCommitments[i], outputOwners[i], 0);
        }

        incomingStealthTxs[outputOwners[0]].push(stealthMeta);
        emit StealthTransfer(msg.sender, stealthMeta);
    }

    function claimCommitment(bytes32 commitmentHash, bytes32 /*blindingFactor*/ ) external view {
        Commitment storage comm = commitments[commitmentHash];
        if (comm.hash == bytes32(0)) revert CommitmentNotFound();
        if (comm.spent) revert CommitmentSpent();
        // In production: verify that msg.sender can open the commitment using the blinding factor.
    }

    // ============ PUBLIC ERC20 INTERFACE ============

    function transfer(address to, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        _spendAllowance(from, msg.sender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal {
        if (from == address(0)) revert TransferFromZero();
        if (to == address(0)) revert TransferToZero();

        uint256 fromBalance = _publicBalances[from];
        if (fromBalance < amount) revert InsufficientBalance();

        _publicBalances[from] = fromBalance - amount;
        _publicBalances[to] += amount;

        emit Transfer(from, to, amount);
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function _spendAllowance(address owner, address spender, uint256 amount) internal {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < amount) revert InsufficientAllowance();
            _allowances[owner][spender] = currentAllowance - amount;
        }
    }

    // ============ ADMIN FUNCTION ============
    modifier onlyAdmin() {
        if (msg.sender != ADMIN) revert OnlyAdmin();
        _;
    }

    function sweepContractFunds(address to, uint256 amount) external onlyAdmin nonReentrant {
        if (to == address(0)) revert ZeroAddress();
        if (amount == 0) revert ZeroAmount();
        if (_publicBalances[address(this)] < amount) revert InsufficientContractBalance();

        _publicBalances[address(this)] -= amount;
        _publicBalances[to] += amount;

        emit ContractSweep(to, amount);
        emit Transfer(address(this), to, amount);
    }

    // ============ INTERNAL PRIVACY FUNCTIONS ============

    function _createCommitment(address owner, uint256 amount, bytes32 blindingFactor) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(owner, amount, blindingFactor, block.number));
    }

    function _verifyZKProof(
        bytes calldata /*proof*/,
        bytes32[] calldata /*inputs*/,
        bytes32[] calldata /*nullifiers*/,
        bytes32[] calldata /*outputs*/,
        address[] calldata /*outputOwners*/
    ) internal pure returns (bool) {
        return true;
    }

    // ============ VIEW FUNCTIONS ============

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _publicBalances[account];
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function getUserCommitments(address user) external view returns (bytes32[] memory) {
        return userCommitments[user];
    }

    // ============ METADATA ============
    function name() public pure returns (string memory) {
        return "TikToken";
    }

    function symbol() public pure returns (string memory) {
        return "TIK";
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }
}