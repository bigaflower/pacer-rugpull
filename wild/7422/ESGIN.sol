// File: contract/contract/com/IERC20.sol


// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC-20 standard as defined in the ERC.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// File: contract/contract/com/Context.sol


// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// File: contract/contract/com/Ownable.sol


// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contract/contract/com/ReentrancyGuard.sol


pragma solidity ^0.8.20;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 */
abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

// File: contract/contract/token/ESGIN_V2.sol


pragma solidity ^0.8.20;





contract ESGIN is Context, IERC20, Ownable, ReentrancyGuard {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private constant _decimals = 18;

    uint256 public constant MAX_LOCKS_PER_ADDRESS = 100;
    uint256 public constant MAX_LOCK_DURATION = 1460 days; 
    uint256 public constant MAX_COOLDOWN_PERIOD = 7 days;

    struct LockInfo {
        uint256 releaseTime;
        uint256 amount;
    }
    
    mapping(address => LockInfo[]) public timelockList;
    mapping(address => uint256) public lockedAmount;
    mapping(address => uint256) public lastLockTime;
    uint256 public lockCooldownPeriod;

    mapping(address => bool) public approved;
    address[] private _approvedList;
    mapping(address => uint256) private _approvedIndex;

    modifier onlyApproved() {
        require(owner() == _msgSender() || approved[_msgSender()], "ESGIN: caller not approved");
        _;
    }

    // --- Events ---
    event Locked(address indexed user, uint256 amount, uint256 releaseTime);
    event Unlocked(address indexed user, uint256 amount);
    event Claimed(address indexed holder, uint256 totalAmount, uint256 count);
    event ApprovedAdded(address indexed addr);
    event ApprovedRemoved(address indexed addr);
    event CooldownUpdated(uint256 oldPeriod, uint256 newPeriod);

    constructor(
        string memory name_,
        string memory symbol_,
        address initialOwner_
    ) Ownable(initialOwner_) {
        _name = name_;
        _symbol = symbol_;
        _totalSupply = 1_000_000_000 * 10 ** _decimals;
        _balances[initialOwner_] = _totalSupply;
        emit Transfer(address(0), initialOwner_, _totalSupply);
        lockCooldownPeriod = 1 hours;
    }

    // --- ERC20 Standard Functions ---
    function name() public view virtual returns (string memory) { return _name; }
    function symbol() public view virtual returns (string memory) { return _symbol; }
    function decimals() public view virtual returns (uint8) { return _decimals; }
    function totalSupply() public view virtual override returns (uint256) { return _totalSupply; }
    function balanceOf(address account) public view virtual override returns (uint256) { return _balances[account]; }

    function transfer(address to, uint256 value) public virtual override returns (bool) {
        address sender = _msgSender();
        if (timelockList[sender].length > 0) {
            _autoUnlock(sender);
        }
        _transfer(sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public virtual override returns (bool) {
        _autoUnlock(from);
        _spendAllowance(from, _msgSender(), value);
        _transfer(from, to, value);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 value) public virtual override returns (bool) {
        _approve(_msgSender(), spender, value);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 requestedDecrease) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= requestedDecrease, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - requestedDecrease);
        }
        return true;
    }

    // --- Core Logic ---
    function _transfer(address from, address to, uint256 value) internal virtual {
        require(from != address(0), "ERC20: transfer from zero");
        require(to != address(0), "ERC20: transfer to zero");
        uint256 fromBalance = _balances[from];
        require(fromBalance >= value, "ERC20: insufficient balance");
        require(fromBalance - lockedAmount[from] >= value, "ERC20: exceeds unlocked balance");

        unchecked {
            _balances[from] = fromBalance - value;
            _balances[to] += value;
        }
        emit Transfer(from, to, value);
    }

    function transferWithLock(address holder, uint256 value, uint256 releaseTime) public onlyApproved nonReentrant returns (bool) {
        address sender = _msgSender();
        _autoUnlock(sender); 
        
        _transfer(sender, holder, value);
        _lock(holder, value, releaseTime);
        return true;
    }

    function _lock(address holder, uint256 value, uint256 releaseTime) internal {
        require(holder != address(0), "Lock: zero address");
        require(value > 0, "Lock: amount zero");
        require(releaseTime > block.timestamp, "Lock: release time in past");
        require(releaseTime <= block.timestamp + MAX_LOCK_DURATION, "Lock: exceeds max duration");
        require(_balances[holder] - lockedAmount[holder] >= value, "Lock: insufficient unlocked");
        require(timelockList[holder].length < MAX_LOCKS_PER_ADDRESS, "Lock: limit reached");

        if (msg.sender != holder && lockCooldownPeriod > 0) {
            require(block.timestamp >= lastLockTime[holder] + lockCooldownPeriod, "Lock: cooldown active");
        }

        lockedAmount[holder] += value;
        lastLockTime[holder] = block.timestamp;
        
        // Optimized sorted insert: reserve space first, then insert at sorted position
        _sortedInsert(holder, releaseTime, value);

        emit Locked(holder, value, releaseTime);
    }

    /**
     * @dev Reserves an empty slot first, then finds the sorted position and inserts.
     * Avoids redundant storage allocation and improves readability.
     */
    function _sortedInsert(address holder, uint256 releaseTime, uint256 amount) internal {
        LockInfo[] storage locks = timelockList[holder];
        locks.push(); // Reserve empty slot by extending length (Storage SSTORE optimization)
        
        uint256 i = locks.length - 1;
        // Shift existing elements right until insertion position is found
        while (i > 0 && locks[i - 1].releaseTime > releaseTime) {
            locks[i] = locks[i - 1];
            i--;
        }
        // Insert data at the final determined position 'i'
        locks[i] = LockInfo(releaseTime, amount);
    }

    function _removeLock(address holder, uint256 idx) internal {
        uint256 amount = timelockList[holder][idx].amount;
        // Shifting to preserve sort order
        for (uint256 i = idx; i < timelockList[holder].length - 1; i++) {
            timelockList[holder][i] = timelockList[holder][i + 1];
        }
        timelockList[holder].pop();
        lockedAmount[holder] -= amount;
        
        emit Unlocked(holder, amount);
    }

    function _autoUnlock(address holder) internal returns (uint256 totalUnlocked, uint256 count) {
        while (timelockList[holder].length > 0 && block.timestamp >= timelockList[holder][0].releaseTime) {
            totalUnlocked += timelockList[holder][0].amount;
            _removeLock(holder, 0);
            count++;
        }
        return (totalUnlocked, count);
    }

    function claim() external nonReentrant returns (uint256) {
        (uint256 totalAmount, uint256 count) = _autoUnlock(_msgSender());
        if (count > 0) {
            emit Claimed(_msgSender(), totalAmount, count);
        }
        return totalAmount;
    }

    // --- Admin Functions ---
    function addApproved(address _addr) external onlyOwner {
        require(_addr != address(0), "Auth: zero address");
        require(!approved[_addr], "Auth: already approved");
        approved[_addr] = true;
        _approvedIndex[_addr] = _approvedList.length;
        _approvedList.push(_addr);
        emit ApprovedAdded(_addr);
    }

    function removeApproved(address _addr) external onlyOwner {
        require(approved[_addr], "Auth: not approved");
        approved[_addr] = false;
        uint256 index = _approvedIndex[_addr];
        uint256 lastIndex = _approvedList.length - 1;
        if (index != lastIndex) {
            address lastAddr = _approvedList[lastIndex];
            _approvedList[index] = lastAddr;
            _approvedIndex[lastAddr] = index;
        }
        _approvedList.pop();
        delete _approvedIndex[_addr];
        emit ApprovedRemoved(_addr);
    }

    function setLockCooldownPeriod(uint256 _period) external onlyOwner {
        require(_period <= MAX_COOLDOWN_PERIOD, "Config: exceeds max cooldown");
        emit CooldownUpdated(lockCooldownPeriod, _period);
        lockCooldownPeriod = _period;
    }

    // --- Helper Functions ---
    function getApprovedList() external view returns (address[] memory) { return _approvedList; }
    function getLockCount(address holder) public view returns (uint256) { return timelockList[holder].length; }
    
    function getClaimableAmount(address holder) external view returns (uint256) {
        uint256 claimable = 0;
        for (uint256 i = 0; i < timelockList[holder].length; i++) {
            if (block.timestamp >= timelockList[holder][i].releaseTime) {
                claimable += timelockList[holder][i].amount;
            } else {
                break;
            }
        }
        return claimable;
    }

    function _approve(address owner, address spender, uint256 value) internal virtual {
        require(owner != address(0), "ERC20: approve from zero");
        require(spender != address(0), "ERC20: approve to zero");
        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _spendAllowance(address owner, address spender, uint256 value) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= value, "ERC20: insufficient allowance");
            unchecked { _approve(owner, spender, currentAllowance - value); }
        }
    }
}