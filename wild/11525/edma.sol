// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.1.0) (token/ERC20/IERC20.sol)

pragma solidity 0.8.20;

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

// File: Mainnet/EDMANew.sol

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = payable(address(0));
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract EDMA is IERC20, Ownable {
    struct VestingSchedule {
        uint256 totalLocked;
        uint256 totalReleased;
        bool isFirstReleased;
    }
    uint256 public constant VESTING_INTERVAL = 90 days;  // 7776000;

    string private constant _NAME = "EDMA";
    string private constant _SYMBOL = "EDM";
    uint8 private constant _DECIMALS = 18;
    uint256 private _totalSupply = 500_000_000 * 10 ** _DECIMALS;

    bool public  presaleActive = true;
    uint256 public  presaleEndTime;
    address public presaleAddress;

    modifier onlyPresale() {
        require(presaleAddress == _msgSender(), "EDMA: caller is not the presale");
        _;
    }

    modifier activePresale() {
        require(presaleActive, "EDMA: presale already ended.");
        _;
    }

    modifier validAddress(address addressToCheck) {
        require(addressToCheck != address(0), "EDMA: Address must not be zero");
        _;
    }


    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => VestingSchedule) public vesting;
    mapping(address => bool) public excludedFromVesting;
    
    
    

    event Burned(address indexed from, uint256 amount);
    event TokensRecovered(address token, address recipient, uint256 amount);
    event ETHRecovered(address recipient, uint256 amount);
    event TokensVested(address indexed beneficiary, uint256 amount);
    event Received(address sender, uint256 value);
    event PresaleAddressUpdated(address oldAddress, address newAddress);
    event PresaleEnded(uint256 presaleEndTime);
    event ExclusionFromVestingUpdated(address addr, bool value);
    

    constructor() {
        _balances[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    // Fallback to receive ETH
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    // Token Information
    function name() public pure returns (string memory) {
        return _NAME;
    }

    function symbol() public pure returns (string memory) {
        return _SYMBOL;
    }

    function decimals() public pure returns (uint8) {
        return _DECIMALS;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function burn(uint256 amount) external {
        require(amount > 0 && _balances[msg.sender] >= amount, "Invalid token amount");
        checkIfCanSpend(msg.sender, amount);
        _balances[msg.sender] -= amount;
        _totalSupply -= amount;
        emit Burned(msg.sender, amount);
    }

    function transferAndVest(address recipient, uint256 amount) external onlyPresale activePresale validAddress(recipient) returns (bool) {
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");
        if(vesting[recipient].totalLocked == 0) {
            vesting[recipient] = VestingSchedule(amount, 0, false);
        } else {
            vesting[recipient].totalLocked =  vesting[recipient].totalLocked + amount;
        }
        emit TokensVested(recipient, amount);
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function calculateUnlockableAmount(address sender) public view  returns (uint256 toUnlockAmount) {
        // presale active so no tokens unlockable
        if(presaleActive) {
            return  0;
        }

        // if presale ended, check vesting details
        VestingSchedule storage vs = vesting[sender];
        if(vs.totalLocked == 0 || vs.totalLocked <= vs.totalReleased) {
            return 0;
        }
        if(vs.isFirstReleased && block.timestamp < presaleEndTime + VESTING_INTERVAL) {
            return  0;
        }
        uint256 intervalPassed = ((block.timestamp - presaleEndTime) / VESTING_INTERVAL);

        if(!vs.isFirstReleased && intervalPassed == 0) {
            intervalPassed = 1; // released 20% with presale end date even if 90day didn't passed.
        } else if(intervalPassed >= 1) {
            intervalPassed = intervalPassed+1; // considering intial release for 1st interval.
        }
        if(intervalPassed > 5) { intervalPassed = 5; }  // max 5 (5x20% = 100%)

        // total amount that must have release by now from presale end time.
        uint256 totalReleasable  = (vs.totalLocked * (intervalPassed * 20)) / 100;
        uint256 currentReleasable = totalReleasable - vs.totalReleased;
        if(currentReleasable == 0) {
            return 0;
        }
        if(currentReleasable > vs.totalLocked - vs.totalReleased) {
            return vs.totalLocked - vs.totalReleased;
        }
        return currentReleasable;
    }

    // set Presale address control
    function setPresale(address newPresaleAddress) external onlyOwner activePresale validAddress(newPresaleAddress) {
        emit PresaleAddressUpdated(presaleAddress, newPresaleAddress);
        presaleAddress = newPresaleAddress;
    }

    // mark presale end
    function endPresale() external onlyOwner activePresale returns (bool){
        presaleActive = false;
        presaleEndTime = block.timestamp;
        emit PresaleEnded(presaleEndTime);
        return true;
    }

    // Method to setVesting exlusion
    function setExcludedFromVesting(address addr, bool excluded) external onlyOwner {
        excludedFromVesting[addr] = excluded;
        emit ExclusionFromVestingUpdated(addr, excluded);
    }

    // ERC20 functions
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] - subtractedValue
        );
        return true;
    }

    // Utility functions
    function recoverStuckTokens(address token, address recipient, uint256 amount) external onlyOwner validAddress(recipient) {
        require(IERC20(token).transfer(recipient, amount), "EDMA: Token recovery failed");
        emit TokensRecovered(token, recipient, amount);
    }

    function recoverStuckETH(address recipient) external onlyOwner validAddress(recipient) {
        uint256 balnce = address(this).balance;
        require(balnce > 0, "EDMA: No ETH to recover");
        payable(recipient).transfer(balnce);
        emit ETHRecovered(recipient, balnce);
    }

    function checkIfCanSpend(address sender, uint256 amount) internal {
        uint256 toRelease = calculateUnlockableAmount(sender);
        if (toRelease > 0) {
            vesting[sender].totalReleased = vesting[sender].totalReleased + toRelease;
        }
        
        uint256 lockedBalance = vesting[sender].totalLocked - vesting[sender].totalReleased;
        if(lockedBalance > 0) {
            require(amount <= balanceOf(sender) - lockedBalance, "Amount exceeds unlocked balance");
            if(!vesting[sender].isFirstReleased && !presaleActive) {
                vesting[sender].isFirstReleased = true;
            }
        }
    }

    // Internal functions
    function _transfer(address sender, address recipient, uint256 amount) internal validAddress(recipient) validAddress(sender) {
        uint256 totalVestingPeriod = (5 * VESTING_INTERVAL) + 60 ; //1 minute extra for precaution; 

        // only check locked balance if presale active or the vesting period is ongoing.
        if(presaleActive || block.timestamp <=  totalVestingPeriod + presaleEndTime) {
            if(amount > 0 && !excludedFromVesting[sender]) {
                checkIfCanSpend(sender, amount);
            }
        }

        _balances[sender] -= amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal validAddress(owner) validAddress(spender) {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}