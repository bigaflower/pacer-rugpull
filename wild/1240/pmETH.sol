// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

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

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

interface IReth {
    function getExchangeRate() external view returns (uint256);
}

contract RebasingStakingToken is IERC20Metadata {
    // ============ State Variables ============
    
    mapping(address => uint256) private _shares;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private allowlist;
    mapping(address => uint256) private pending;
    
    uint256 private _totalShares;
    uint256 private lastRatio;
    uint256 private rebaseIndex;
    uint256 public multiplier;

    uint256 public lastRebaseTime;

    IReth rethToken;
    
    // Custodian management
    address public custodian;
    address public pendingCustodian;
    uint256 public custodianChangeDeadline;
    uint256 public constant CUSTODIAN_GRACE_PERIOD = 1 hours;
    uint256 public constant COOLDOWN_WINDOW = 1 days;
    
    // ERC20 Metadata
    string public override name;
    string public override symbol;
    uint8 public constant override decimals = 18;
    
    // Constants for calculations (all using 18 decimals)
    uint256 private constant WAD = 1e18;
    uint256 private constant SECONDS_PER_YEAR = 365 days;

    // ============ Events ============
    
    event MultiplierUpdated(
        uint256 newMultiplier, 
        uint256 time,
        address updatedBy
    );
    event WithdrawalRequsted(address indexed staker, uint256 amount, uint256 time);
    event Rebase(uint256 newIndex, uint256 secondsElapsed);
    event AllowlistUpdated(address indexed account, bool status);
    event CustodianChanged(address indexed oldCustodian, address indexed newCustodian);
    event CustodianChangeProposed(address indexed currentCustodian, address indexed proposedCustodian, uint256 deadline);
    event CustodianChangeCancelled(address indexed currentCustodian, address indexed cancelledCustodian);
    
    // ============ Modifiers ============
    
    modifier onlyCustodian() {
        require(msg.sender == custodian, "pmETH: caller is not the custodian");
        _;
    }
    
    modifier checkAllowlist(address from, address to) {
        require(
            allowlist[from] && allowlist[to],
            "pmETH: transfer not allowed - addresses not in allowlist"
        );
        _;
    }

    // ============ Constructor ============  
    
    constructor(
        string memory _name,
        string memory _symbol,
        address _custodian,
        uint256 _initialSupply,
        uint256 _initialMultiplier,
        address _rethTokenAddress
    ) {
        require(_custodian != address(0), "pmETH: custodian is zero address");
        
        name = _name;
        symbol = _symbol;
        custodian = _custodian;
        rebaseIndex = WAD;
        lastRebaseTime = block.timestamp;
        multiplier = _initialMultiplier;
        require(_rethTokenAddress != address(0), "Invalid address");
        rethToken = IReth(_rethTokenAddress);
        lastRatio = rethToken.getExchangeRate();
        
        if (_initialSupply > 0) {
            _totalShares = _initialSupply;
            _shares[msg.sender] = _initialSupply;
            emit Transfer(address(0), msg.sender, _initialSupply);
        }

        allowlist[msg.sender] = true;
        allowlist[_custodian] = true;
        emit AllowlistUpdated(msg.sender, true);
        emit AllowlistUpdated(_custodian, true);
    }
    
    // ============ Optimized Math Functions ============
    
    function fastWadPow(uint256 a, uint256 b, uint256 c, uint256 d) public pure returns (uint256 result) {
        assembly {
            let wadValue := 0xde0b6b3a7640000 // 1e18

            if iszero(c) { revert(0, 0) }

            let ratio := div(mul(b, wadValue), c)
            if lt(ratio, wadValue) { revert(0, 0) }
            let epsilon := sub(ratio, wadValue)

            let d_minus_1 := sub(d, wadValue)
            let tmp := mul(epsilon, d_minus_1)         // eps * (d-1)
            tmp := div(tmp, wadValue)                  // scale down
            tmp := div(tmp, 2)                         // divide by 2
            tmp := add(tmp, wadValue)                  // 1 + ...

            let d_eps_scaled := div(mul(d, epsilon), wadValue) // (d * eps) / WAD
            let res := div(mul(d_eps_scaled, tmp), wadValue) // ((d * eps)/WAD * tmp)/WAD
            let powerVal := add(wadValue, res)

            result := div(mul(a, powerVal), wadValue)
        }
    }

    // ============ Rebase Function ============

    function rebase() public {
        if (block.timestamp > lastRebaseTime + COOLDOWN_WINDOW) {
            uint256 _newRatio = rethToken.getExchangeRate();
            if (_newRatio > lastRatio) {
                uint256 timeElapsed = block.timestamp - lastRebaseTime;
            
                rebaseIndex = fastWadPow(rebaseIndex, _newRatio, lastRatio, multiplier);
                lastRebaseTime = block.timestamp;
                lastRatio = _newRatio;

                emit Rebase(rebaseIndex, timeElapsed);
            }
        }
    }

    // ============ Internal Functions ============

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal checkAllowlist(sender, recipient) {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        
        rebase();
        
        uint256 senderBalance = (_shares[sender] * rebaseIndex) / WAD;
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        
        uint256 sharesToTransfer = tokensToShares(amount);
        require(sharesToTransfer > 0, "pmETH: cannot transfer 0 shares");
        
        _shares[sender] -= sharesToTransfer;
        _shares[recipient] += sharesToTransfer;
        
        emit Transfer(sender, recipient, amount);
    }
    
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function getCurrentRebaseIndex() private view returns (uint256) {
        uint256 _currentRebaseIndex = rebaseIndex;

        uint256 _newRatio = rethToken.getExchangeRate();
        if (_newRatio > lastRatio) {
            _currentRebaseIndex = fastWadPow(rebaseIndex, _newRatio, lastRatio, multiplier);
        }

        return _currentRebaseIndex;
    }

    function tokensToShares(uint256 amount) public view returns (uint256) {
        return (amount * WAD) / rebaseIndex;
    }
    
    function sharesToTokens(uint256 sharesAmount) public view returns (uint256) {
        return (sharesAmount * rebaseIndex) / WAD;
    }

    // ============ ERC20 Functions ============
    
    function totalSupply() public view override returns (uint256) {
        return (_totalShares * getCurrentRebaseIndex()) / WAD;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_shares[account] == 0) return 0;
        
        return (_shares[account] * getCurrentRebaseIndex()) / WAD;
    }
    
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }
    
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        
        _transfer(sender, recipient, amount);
        
        if (currentAllowance != type(uint256).max) {
            _approve(sender, msg.sender, currentAllowance - amount);
        }
        
        return true;
    }

    // ============ Deposit/Withdraw Functions ============

    function deposit() external payable {
        require(allowlist[msg.sender], "pmETH: deposit not allowed - address not in allowlist");
        require(msg.value > 0, "pmETH: cannot deposit 0 ether");

        rebase();

        uint256 sharesToDeposit = tokensToShares(msg.value);
        _shares[msg.sender] += sharesToDeposit;
        _totalShares += sharesToDeposit;

        (bool success, ) = payable(custodian).call{value: msg.value}("");
        require(success, "Failed to send Ether");

        emit Transfer(address(0), msg.sender, msg.value);
    }

    function depositOnBehalf(address _beneficiary) external payable {
        require(allowlist[_beneficiary], "pmETH: deposit not allowed - beneficiary address not in allowlist");
        require(msg.value > 0, "pmETH: cannot deposit 0 ether");

        rebase();

        uint256 sharesToDeposit = tokensToShares(msg.value);
        _shares[_beneficiary] += sharesToDeposit;
        _totalShares += sharesToDeposit;

        (bool success, ) = payable(custodian).call{value: msg.value}("");
        require(success, "Failed to send Ether");
        
        emit Transfer(address(0), _beneficiary, msg.value);
    }

    function requestWithdrawal(uint256 _amount) external {
        require(allowlist[msg.sender], "pmETH: withdrawal not allowed - address not in allowlist");
        require(_amount > 0, "pmETH: cannot withdraw 0 ether");

        rebase();

        require(sharesToTokens(_shares[msg.sender]) - pending[msg.sender] >= _amount, "pmETH: insufficient balance to withdraw");

        pending[msg.sender] += _amount;

        emit WithdrawalRequsted(msg.sender, _amount, block.timestamp);
    }

    function fulfillWithdrawal(address _address) external payable onlyCustodian {
        require(msg.value > 0, "pmETH: cannot redeem 0 ether");
        require(pending[_address] > 0, "pmETH: no pending withdrawal for this address");
        require(msg.value <= pending[_address], "pmETH: cannot fulfill more than requested");

        rebase();

        pending[_address] -= msg.value;
        uint256 sharesToRedeem = tokensToShares(msg.value);
        _shares[_address] -= sharesToRedeem;
        _totalShares -= sharesToRedeem;

        (bool success, ) = payable(_address).call{value: msg.value}("");
        require(success, "Failed to send Ether");

        emit Transfer(_address, address(0), msg.value);
    }

    // ============ Custodian Mint/Burn Functions ============
    
    function mint(address account, uint256 amount) external onlyCustodian {
        require(account != address(0), "pmETH: mint to zero address");
        require(amount > 0, "pmETH: cannot mint 0 tokens");
        
        rebase();
        
        uint256 sharesToMint = tokensToShares(amount);
        _totalShares += sharesToMint;
        _shares[account] += sharesToMint;
        
        emit Transfer(address(0), account, amount);
    }
    
    function burn(address account, uint256 amount) external onlyCustodian {
        require(account != address(0), "pmETH: burn from zero address");
        
        rebase();
        
        uint256 accountBalance = balanceOf(account);
        require(accountBalance >= amount, "pmETH: burn amount exceeds balance");
        
        uint256 sharesToBurn = tokensToShares(amount);
        _shares[account] -= sharesToBurn;
        _totalShares -= sharesToBurn;
        
        emit Transfer(account, address(0), amount);
    }

    // ============ Other Custodian Functions ============

    function setRethAddress(address _newAddress) external onlyCustodian {
        require(_newAddress != address(0), "Invalid address");
        rebase();

        rethToken = IReth(_newAddress);
        lastRatio = rethToken.getExchangeRate();
    }
    
    function setMultiplier(uint256 _newMultiplier) external onlyCustodian {
        require(5*1e17 < _newMultiplier && _newMultiplier < 2*1e18, "pmETH: Multiplier out of range");
        rebase();
        multiplier = _newMultiplier;        
        emit MultiplierUpdated(_newMultiplier, block.timestamp, msg.sender);
    }

    function setAllowlist(address account, bool status) external onlyCustodian {
        require(account != address(0), "pmETH: cannot allowlist zero address");
        allowlist[account] = status;
        emit AllowlistUpdated(account, status);
    }

    function setAllowlistBatch(address[] calldata accounts, bool status) external onlyCustodian {
        for (uint256 i = 0; i < accounts.length; i++) {
            require(accounts[i] != address(0), "pmETH: cannot allowlist zero address");
            allowlist[accounts[i]] = status;
            emit AllowlistUpdated(accounts[i], status);
        }
    }
    
    function proposeCustodianChange(address newCustodian) external onlyCustodian {
        require(newCustodian != address(0), "pmETH: new custodian is zero address");
        require(newCustodian != custodian, "pmETH: new custodian same as current");
        require(newCustodian != pendingCustodian, "pmETH: custodian already proposed");
        
        pendingCustodian = newCustodian;
        custodianChangeDeadline = block.timestamp + CUSTODIAN_GRACE_PERIOD;
        
        emit CustodianChangeProposed(custodian, newCustodian, custodianChangeDeadline);
    }
    
    function acceptCustodianship() external {
        require(msg.sender == pendingCustodian, "pmETH: caller is not pending custodian");
        require(pendingCustodian != address(0), "pmETH: no pending custodian");
        require(block.timestamp <= custodianChangeDeadline, "pmETH: acceptance period expired");
        
        address oldCustodian = custodian;
        custodian = pendingCustodian;
        pendingCustodian = address(0);
        custodianChangeDeadline = 0;

        allowlist[msg.sender] = true;

        emit AllowlistUpdated(msg.sender, true);
        emit CustodianChanged(oldCustodian, custodian);
    }

    function cancelCustodianChange() external onlyCustodian {
        require(pendingCustodian != address(0), "pmETH: no pending custodian change");
        
        address cancelledCustodian = pendingCustodian;
        pendingCustodian = address(0);
        custodianChangeDeadline = 0;
        
        emit CustodianChangeCancelled(custodian, cancelledCustodian);
    }
    
    function clearExpiredCustodianChange() external {
        require(pendingCustodian != address(0), "pmETH: no pending custodian change");
        require(block.timestamp > custodianChangeDeadline, "pmETH: deadline not yet passed");
        
        address expiredCustodian = pendingCustodian;
        pendingCustodian = address(0);
        custodianChangeDeadline = 0;
        
        emit CustodianChangeCancelled(custodian, expiredCustodian);
    }
    
    // ============ Additional View Functions ============
    
    function sharesOf(address account) public view returns (uint256) {
        return _shares[account];
    }

    function pendingOf(address account) public view returns (uint256) {
        return pending[account];
    }
    
    function totalShares() public view returns (uint256) {
        return _totalShares;
    }
    
    function getRebaseIndex() public view returns (uint256) {
        return rebaseIndex;
    }

    function isAllowlisted(address account) external view returns (bool) {
        return allowlist[account];
    }

    function isTransferAllowed(address from, address to) external view returns (bool) {
        return allowlist[from] && allowlist[to];
    }
    
    function custodianChangeTimeRemaining() external view returns (uint256) {
        if (pendingCustodian == address(0) || block.timestamp > custodianChangeDeadline) {
            return 0;
        }
        return custodianChangeDeadline - block.timestamp;
    }

    function hasPendingCustodianChange() external view returns (bool) {
        return pendingCustodian != address(0) && block.timestamp <= custodianChangeDeadline;
    }
}