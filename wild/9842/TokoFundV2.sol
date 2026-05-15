// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * ------------------------------------------------------------------------
 *  Minimal inline OpenZeppelin utilities
 * ------------------------------------------------------------------------
 */

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/** Context */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

/** Ownable (simplified) */
abstract contract Ownable is Context {
    address public _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "New owner is zero");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address old = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(old, newOwner);
    }
}

abstract contract BlackList is Ownable {
    
    /////// Getters to allow the same blacklist to be used also by other contracts (including upgraded Tokoin) ///////
    function getBlackListStatus(address _maker) external view returns (bool) {
        return isBlackListed[_maker];
    }

    function getOwner() external view returns (address) {
        return _owner;
    }

    mapping(address => bool) public isBlackListed;

    function addBlackList(address _evilUser) public onlyOwner {
        isBlackListed[_evilUser] = true;
        emit AddedBlackList(_evilUser);
    }

    function removeBlackList(address _clearedUser) public onlyOwner {
        isBlackListed[_clearedUser] = false;
        emit RemovedBlackList(_clearedUser);
    }

    event AddedBlackList(address _user);
    event RemovedBlackList(address _user);
}

/** ReentrancyGuard */
abstract contract ReentrancyGuard {
    uint256 private _status;
    constructor() {
        _status = 1;
    }
    modifier nonReentrant() {
        require(_status != 2, "ReentrancyGuard: reentrant call");
        _status = 2;
        _;
        _status = 1;
    }
}

/** Pausable */
abstract contract Pausable is Context {
    bool private _paused;
    event Paused(address account);
    event Unpaused(address account);

    constructor() {
        _paused = false;
    }

    function paused() public view virtual returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

/** SafeERC20 (minimal version) */
library SafeERC20 {
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        require(token.transfer(to, value), "SafeERC20: transfer failed");
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        require(token.transferFrom(from, to, value), "SafeERC20: transferFrom failed");
    }
}

/**
 * ------------------------------------------------------------------------
 *  TokoFundV2 Contract
 * ------------------------------------------------------------------------
 */
contract TokoFundV2 is Ownable, Pausable, ReentrancyGuard, BlackList {
    using SafeERC20 for IERC20;

    IERC20 public token;
    uint256 public totalDeposit;

    mapping(bytes32 => bool) public processedTransfer;

    uint256 public feeRate; // basis points (100 = 1%)
    address public feeCollector;

    uint256 public minDepositAmount;
    uint256 public maxDepositAmount;

    event Deposit(address indexed from, address indexed target, uint256 amount, bytes32 offchainId);
    event Withdraw(address indexed to, uint256 amount);
    event Transfer(address indexed to, uint256 netAmount, uint256 fee, bytes32 offchainId);
    event FeeUpdated(uint256 newFeeRate, address indexed collector);
    event TokenUpdated(address indexed newToken);

    constructor(address _token, uint256 _minDeposit, uint256 _maxDeposit) {
        require(_token != address(0), "Invalid token address");
        token = IERC20(_token);
        
        feeCollector = address(this);
        minDepositAmount = _minDeposit;
        maxDepositAmount = _maxDeposit;
    }

    /// @notice Update token address (only owner)
    function setToken(address _token) external onlyOwner {
        require(_token != address(0), "Invalid token address");
        token = IERC20(_token);
        emit TokenUpdated(_token);
    }

    /// @notice Get current token balance held by this contract
    function getBalance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function setMinDepositAmount(uint256 _minDepositAmount) external whenNotPaused onlyOwner {
        require(_minDepositAmount > 0, "Min must be > 0");
        minDepositAmount = _minDepositAmount;
    }

    function setMaxDepositAmount(uint256 _maxDepositAmount) external whenNotPaused onlyOwner {
        require(_maxDepositAmount > minDepositAmount, "Max must be > min");
        maxDepositAmount = _maxDepositAmount;
    }

    function deposit(uint256 amount, address target, bytes32 offchainId) external whenNotPaused nonReentrant {
        require(amount > 0, "Amount must be > 0");
        require(amount >= minDepositAmount, "Below min deposit");
        require(amount <= maxDepositAmount, "Above max deposit");
        require(target != address(0), "Invalid target");
        require(!isBlackListed[target], "Address blacklisted");

        token.safeTransferFrom(msg.sender, address(this), amount);
        totalDeposit += amount;

        // bytes32 offchainId = keccak256(abi.encodePacked(msg.sender,target,amount,block.number,block.timestamp,totalDeposit));
        emit Deposit(msg.sender, target, amount, offchainId);
    }

    /// @notice Withdraw tokens (only owner)
    function withdraw(address to, uint256 amount) external onlyOwner whenNotPaused nonReentrant {
        require(to != address(0), "Invalid address");
        require(amount <= getBalance(), "Insufficient balance");
        require(!isBlackListed[to], "Address blacklisted");
        token.safeTransfer(to, amount);
        totalDeposit -= amount;
        emit Withdraw(to, amount);
    }

    /// @notice Transfer tokens from this contract (only owner)
    /// Fee (if any) will be deducted and sent to the feeCollector
    function transfer(address to, uint256 amount, bytes32 offchainId) external onlyOwner whenNotPaused nonReentrant {
        require(!processedTransfer[offchainId], "Already processed Offchain ID");
        require(to != address(0), "Invalid address");
        require(!isBlackListed[to], "Address blacklisted");
        require(amount <= getBalance(), "Insufficient balance");

        processedTransfer[offchainId] = true;

        uint256 fee = (amount * feeRate) / 10000;
        uint256 netAmount = amount - fee;

        token.safeTransfer(to, netAmount);
        if (fee > 0 && feeCollector != address(0)) {
            token.safeTransfer(feeCollector, fee);
        }

        emit Transfer(to, netAmount, fee, offchainId);
    }
    
    /// @notice isProcessed function to check if and Id is already processed or not
    function isProcessed(bytes32 offchainId) external view returns (bool) {
        return processedTransfer[offchainId];
    }

    /// @notice Pause contract (only owner)
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpause contract (only owner)
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Set transfer fee rate and fee collector (only owner)
    function setFee(uint256 _feeRate, address _collector) external onlyOwner {
        require(_collector != address(0), "Invalid collector");
        feeRate = _feeRate;
        feeCollector = _collector;
        emit FeeUpdated(_feeRate, _collector);
    }
}