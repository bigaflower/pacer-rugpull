// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * ═══════════════════════════════════════════════════════════════════════════
 * CMTDE V3 - GOLD-BACKED TOKEN (IMMUTABLE CORE)
 * ═══════════════════════════════════════════════════════════════════════════
 * 
 * @title CMTDE_V3
 * @dev Immutable ERC-20 token with modular architecture
 * @notice Deploy with NO constructor parameters
 * 
 * Security Features:
 * - 24-hour timelock for TradingModule & ConfigRegistry changes
 * - Instant MEVProtection updates (defensive - needs fast response)
 * - Immutable mint caps (1B per tx, 10B daily)
 * - Module interface verification
 * - Emergency bypass mode
 * - 2-step ownership transfer
 * - Pool restrictions via MEVProtection
 * 
 * Pool Protection (via MEVProtection module):
 * - Owner/LPs can send to ANY contract
 * - Users can send to APPROVED pools only
 * - Global pool cooldown toggle (OFF by default, enable if attacked)
 * - When global cooldown ON: only 1 tx per pool per block
 * 
 * Recommended: Transfer ownership to Gnosis Safe (2-of-4 multi-sig)
 * ═══════════════════════════════════════════════════════════════════════════
 */

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

interface ICMTDE_V3_MEVProtection {
    function checkTransfer(address from, address to, uint256 amount) external;
    function isBlacklisted(address account) external view returns (bool);
    function isLiquidityProvider(address account) external view returns (bool);
    function isApprovedPool(address pool) external view returns (bool);
    function coreToken() external view returns (address);
}

interface ICMTDE_V3_TradingModule {
    function coreToken() external view returns (address);
}

interface ICMTDE_V3_ConfigRegistry {
    function coreToken() external view returns (address);
}

contract CMTDE_V3 is IERC20, IERC20Metadata {
    
    // ═══════════════════════════════════════════════════════════════════
    //                         STATE VARIABLES
    // ═══════════════════════════════════════════════════════════════════
    
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public approvedPools;
    
    uint256 private _totalSupply;
    uint256 private _goldReserves;
    
    address public owner;
    address public pendingOwner;
    address public tradingModule;
    address public mevProtection;
    address public configRegistry;
    
    bool public paused;
    
    // ═══════════════════════════════════════════════════════════════════
    //                    IMMUTABLE SECURITY CONSTANTS
    // ═══════════════════════════════════════════════════════════════════
    
    uint256 public constant CONTRACT_SIZE_THRESHOLD = 100;
    uint256 public constant TIMELOCK_DURATION = 24 hours;
    uint256 public constant MAX_MINT_PER_TX = 1_000_000_000 * 10**18;      // 1B tokens (~$450M)
    uint256 public constant MAX_DAILY_MINT = 10_000_000_000 * 10**18;     // 10B tokens (~$4.5B)
    
    string private constant _name = "CMTDE V3 Token";
    string private constant _symbol = "CMTDE_V3";
    uint8 private constant _decimals = 18;
    
    // ═══════════════════════════════════════════════════════════════════
    //                      MINT CAP TRACKING
    // ═══════════════════════════════════════════════════════════════════
    
    uint256 public dailyMintedAmount;
    uint256 public lastMintResetTime;
    
    // ═══════════════════════════════════════════════════════════════════
    //                      TIMELOCK STRUCTURES
    // ═══════════════════════════════════════════════════════════════════
    
    struct PendingModuleChange {
        address newAddress;
        uint256 executeTime;
        bool exists;
    }
    
    mapping(bytes32 => PendingModuleChange) public pendingChanges;
    
    bytes32 public constant TRADING_MODULE_KEY = keccak256("TradingModule");
    bytes32 public constant CONFIG_REGISTRY_KEY = keccak256("ConfigRegistry");
    
    // ═══════════════════════════════════════════════════════════════════
    //                      EMERGENCY BYPASS
    // ═══════════════════════════════════════════════════════════════════
    
    bool public emergencyBypassEnabled;

    // ═══════════════════════════════════════════════════════════════════
    //                           EVENTS
    // ═══════════════════════════════════════════════════════════════════

    event Mint(address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    event Paused();
    event Unpaused();
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OwnershipTransferPending(address indexed currentOwner, address indexed pendingOwner);
    event ModuleUpdated(string indexed moduleName, address indexed oldModule, address indexed newModule);
    event PoolApprovalUpdated(address indexed pool, bool approved);
    event BatchPoolsApproved(uint256 count, bool approved);
    
    // Timelock events
    event ModuleChangeQueued(string moduleName, address newAddress, uint256 executeTime);
    event ModuleChangeExecuted(string moduleName, address newAddress);
    event ModuleChangeCancelled(string moduleName);
    
    // Emergency events
    event EmergencyBypassEnabled(address indexed enabledBy);
    event EmergencyBypassDisabled(address indexed disabledBy);

    // ═══════════════════════════════════════════════════════════════════
    //                          MODIFIERS
    // ═══════════════════════════════════════════════════════════════════

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    
    modifier onlyOwnerOrModule() {
        require(
            msg.sender == owner || 
            msg.sender == tradingModule ||
            msg.sender == mevProtection ||
            msg.sender == configRegistry,
            "Not authorized"
        );
        _;
    }
    
    modifier whenNotPaused() {
        require(!paused, "Paused");
        _;
    }
    
    modifier validAddress(address addr) {
        require(addr != address(0), "Zero address");
        _;
    }

    // ═══════════════════════════════════════════════════════════════════
    //                         CONSTRUCTOR
    // ═══════════════════════════════════════════════════════════════════

    constructor() {
        owner = msg.sender;
        lastMintResetTime = block.timestamp;
        
        uint256 initialSupply = 20_000_000_000 * 10**18; // 20 billion tokens
        _totalSupply = initialSupply;
        _balances[owner] = initialSupply;
        emit Transfer(address(0), owner, initialSupply);
    }

    // ═══════════════════════════════════════════════════════════════════
    //                      ERC-20 VIEW FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════

    function name() public pure override returns (string memory) { return _name; }
    function symbol() public pure override returns (string memory) { return _symbol; }
    function decimals() public pure override returns (uint8) { return _decimals; }
    function totalSupply() public view override returns (uint256) { return _totalSupply; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address tokenOwner, address spender) public view override returns (uint256) { return _allowances[tokenOwner][spender]; }
    function goldReserves() public view returns (uint256) { return _goldReserves; }

    // ═══════════════════════════════════════════════════════════════════
    //                    ERC-20 TRANSFER FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════

    function transfer(address to, uint256 amount) public override whenNotPaused returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public override whenNotPaused returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public override whenNotPaused returns (bool) {
        uint256 currentAllowance = _allowances[from][msg.sender];
        require(currentAllowance >= amount, "Insufficient allowance");
        _transfer(from, to, amount);
        if (currentAllowance != type(uint256).max) {
            _approve(from, msg.sender, currentAllowance - amount);
        }
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public whenNotPaused returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public whenNotPaused returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "Allowance below zero");
        _approve(msg.sender, spender, currentAllowance - subtractedValue);
        return true;
    }

    // ═══════════════════════════════════════════════════════════════════
    //                      INTERNAL FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════

    function _isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > CONTRACT_SIZE_THRESHOLD;
    }

    function _transfer(address from, address to, uint256 amount) internal validAddress(to) {
        require(from != address(0), "Transfer from zero");
        
        // Check balance once at the start
        uint256 senderBalance = _balances[from];
        require(senderBalance >= amount, "Insufficient balance");
        
        // Emergency bypass - skip all module checks for basic transfers
        if (!emergencyBypassEnabled) {
            // Normal flow with module checks
            if (mevProtection != address(0)) {
                ICMTDE_V3_MEVProtection protection = ICMTDE_V3_MEVProtection(mevProtection);
                require(!protection.isBlacklisted(from), "Sender blacklisted");
                require(!protection.isBlacklisted(to), "Recipient blacklisted");
                
                // POOL PROTECTION: 
                // - Owner and LPs can send to ANY contract
                // - Anyone can send to APPROVED pools (checked via MEVProtection)
                // - Non-approved contracts blocked for regular users
                if (_isContract(to)) {
                    bool isLP = protection.isLiquidityProvider(from);
                    bool isPoolApproved = protection.isApprovedPool(to);
                    
                    require(
                        isLP || from == owner || isPoolApproved,
                        "Only owner/LPs or approved pools"
                    );
                }
                protection.checkTransfer(from, to, amount);
            } else {
                // Fallback when MEVProtection not set: only owner can send to contracts
                if (_isContract(to)) {
                    require(from == owner, "Only owner can send to pools");
                }
            }
        }
        
        // Execute transfer
        _balances[from] = senderBalance - amount;
        _balances[to] += amount;
        emit Transfer(from, to, amount);
    }

    function _approve(address tokenOwner, address spender, uint256 amount) internal {
        require(tokenOwner != address(0) && spender != address(0), "Zero address");
        _allowances[tokenOwner][spender] = amount;
        emit Approval(tokenOwner, spender, amount);
    }

    // ═══════════════════════════════════════════════════════════════════
    //                    MINT/BURN WITH CAPS
    // ═══════════════════════════════════════════════════════════════════

    function mint(address to, uint256 amount) external onlyOwnerOrModule validAddress(to) whenNotPaused {
        require(amount > 0, "Amount must be positive");
        require(amount <= MAX_MINT_PER_TX, "Exceeds max mint per tx");
        
        // Reset daily counter if 24 hours passed
        if (block.timestamp - lastMintResetTime >= 1 days) {
            dailyMintedAmount = 0;
            lastMintResetTime = block.timestamp;
        }
        
        require(dailyMintedAmount + amount <= MAX_DAILY_MINT, "Exceeds daily mint cap");
        dailyMintedAmount += amount;
        
        _balances[to] += amount;
        _totalSupply += amount;
        emit Mint(to, amount);
        emit Transfer(address(0), to, amount);
    }

    function burn(uint256 amount) public whenNotPaused {
        require(_balances[msg.sender] >= amount, "Burn exceeds balance");
        _balances[msg.sender] -= amount;
        _totalSupply -= amount;
        emit Burn(msg.sender, amount);
        emit Transfer(msg.sender, address(0), amount);
    }

    function burnFrom(address account, uint256 amount) public whenNotPaused {
        uint256 currentAllowance = _allowances[account][msg.sender];
        require(currentAllowance >= amount, "Burn exceeds allowance");
        _approve(account, msg.sender, currentAllowance - amount);
        require(_balances[account] >= amount, "Burn exceeds balance");
        _balances[account] -= amount;
        _totalSupply -= amount;
        emit Burn(account, amount);
        emit Transfer(account, address(0), amount);
    }
    
    function moduleBurn(address account, uint256 amount) external onlyOwnerOrModule whenNotPaused {
        require(_balances[account] >= amount, "Burn exceeds balance");
        _balances[account] -= amount;
        _totalSupply -= amount;
        emit Burn(account, amount);
        emit Transfer(account, address(0), amount);
    }

    // ═══════════════════════════════════════════════════════════════════
    //                 TIMELOCK MODULE MANAGEMENT
    // ═══════════════════════════════════════════════════════════════════

    /**
     * @dev Queue a TradingModule change (24-hour delay)
     */
    function queueTradingModule(address _newModule) external onlyOwner validAddress(_newModule) {
        require(_verifyTradingModuleInterface(_newModule), "Invalid TradingModule interface");
        
        pendingChanges[TRADING_MODULE_KEY] = PendingModuleChange({
            newAddress: _newModule,
            executeTime: block.timestamp + TIMELOCK_DURATION,
            exists: true
        });
        
        emit ModuleChangeQueued("TradingModule", _newModule, block.timestamp + TIMELOCK_DURATION);
    }
    
    function executeTradingModule() external onlyOwner {
        PendingModuleChange storage pending = pendingChanges[TRADING_MODULE_KEY];
        require(pending.exists, "No pending change");
        require(block.timestamp >= pending.executeTime, "Timelock not expired");
        
        address oldModule = tradingModule;
        tradingModule = pending.newAddress;
        
        delete pendingChanges[TRADING_MODULE_KEY];
        
        emit ModuleChangeExecuted("TradingModule", pending.newAddress);
        emit ModuleUpdated("TradingModule", oldModule, tradingModule);
    }
    
    function cancelTradingModuleChange() external onlyOwner {
        delete pendingChanges[TRADING_MODULE_KEY];
        emit ModuleChangeCancelled("TradingModule");
    }

    /**
     * @dev Queue a ConfigRegistry change (24-hour delay)
     */
    function queueConfigRegistry(address _newModule) external onlyOwner validAddress(_newModule) {
        require(_verifyConfigRegistryInterface(_newModule), "Invalid ConfigRegistry interface");
        
        pendingChanges[CONFIG_REGISTRY_KEY] = PendingModuleChange({
            newAddress: _newModule,
            executeTime: block.timestamp + TIMELOCK_DURATION,
            exists: true
        });
        
        emit ModuleChangeQueued("ConfigRegistry", _newModule, block.timestamp + TIMELOCK_DURATION);
    }
    
    function executeConfigRegistry() external onlyOwner {
        PendingModuleChange storage pending = pendingChanges[CONFIG_REGISTRY_KEY];
        require(pending.exists, "No pending change");
        require(block.timestamp >= pending.executeTime, "Timelock not expired");
        
        address oldModule = configRegistry;
        configRegistry = pending.newAddress;
        
        delete pendingChanges[CONFIG_REGISTRY_KEY];
        
        emit ModuleChangeExecuted("ConfigRegistry", pending.newAddress);
        emit ModuleUpdated("ConfigRegistry", oldModule, configRegistry);
    }
    
    function cancelConfigRegistryChange() external onlyOwner {
        delete pendingChanges[CONFIG_REGISTRY_KEY];
        emit ModuleChangeCancelled("ConfigRegistry");
    }

    // ═══════════════════════════════════════════════════════════════════
    //                 INITIAL MODULE SETUP (NO TIMELOCK)
    // ═══════════════════════════════════════════════════════════════════
    
    /**
     * @dev Set TradingModule for the first time (no timelock)
     * @notice Can only be used when module is not yet set (address(0))
     */
    function setTradingModule(address _tradingModule) external onlyOwner validAddress(_tradingModule) {
        require(tradingModule == address(0), "Use queueTradingModule for updates");
        require(_verifyTradingModuleInterface(_tradingModule), "Invalid interface");
        tradingModule = _tradingModule;
        emit ModuleUpdated("TradingModule", address(0), _tradingModule);
    }
    
    /**
     * @dev Set MEVProtection module (INSTANT - no timelock)
     * @notice MEVProtection is defensive and may need immediate updates during attacks
     */
    function setMEVProtection(address _mevProtection) external onlyOwner validAddress(_mevProtection) {
        require(_verifyMEVProtectionInterface(_mevProtection), "Invalid interface");
        address oldModule = mevProtection;
        mevProtection = _mevProtection;
        emit ModuleUpdated("MEVProtection", oldModule, _mevProtection);
    }
    
    /**
     * @dev Set ConfigRegistry for the first time (no timelock)
     * @notice Can only be used when module is not yet set (address(0))
     */
    function setConfigRegistry(address _configRegistry) external onlyOwner validAddress(_configRegistry) {
        require(configRegistry == address(0), "Use queueConfigRegistry for updates");
        require(_verifyConfigRegistryInterface(_configRegistry), "Invalid interface");
        configRegistry = _configRegistry;
        emit ModuleUpdated("ConfigRegistry", address(0), _configRegistry);
    }

    // ═══════════════════════════════════════════════════════════════════
    //                  INTERFACE VERIFICATION
    // ═══════════════════════════════════════════════════════════════════

    function _verifyTradingModuleInterface(address _module) internal view returns (bool) {
        try ICMTDE_V3_TradingModule(_module).coreToken() returns (address) {
            return true;
        } catch {
            return false;
        }
    }
    
    function _verifyMEVProtectionInterface(address _module) internal view returns (bool) {
        try ICMTDE_V3_MEVProtection(_module).coreToken() returns (address) {
            return true;
        } catch {
            return false;
        }
    }
    
    function _verifyConfigRegistryInterface(address _module) internal view returns (bool) {
        try ICMTDE_V3_ConfigRegistry(_module).coreToken() returns (address) {
            return true;
        } catch {
            return false;
        }
    }

    // ═══════════════════════════════════════════════════════════════════
    //                      EMERGENCY BYPASS
    // ═══════════════════════════════════════════════════════════════════

    /**
     * @dev Enable emergency bypass - allows basic transfers without module checks
     * @notice Use only if modules are compromised/malfunctioning
     */
    function enableEmergencyBypass() external onlyOwner {
        emergencyBypassEnabled = true;
        emit EmergencyBypassEnabled(msg.sender);
    }
    
    /**
     * @dev Disable emergency bypass - re-enable module checks
     */
    function disableEmergencyBypass() external onlyOwner {
        emergencyBypassEnabled = false;
        emit EmergencyBypassDisabled(msg.sender);
    }

    // ═══════════════════════════════════════════════════════════════════
    //                      POOL APPROVAL MANAGEMENT
    // ═══════════════════════════════════════════════════════════════════
    // 
    // NOTE: _transfer() checks MEVProtection.isApprovedPool() - use that!
    //       MEVProtection.setApprovedPool() is the authoritative source
    //       MEVProtection also has global pool cooldown toggle
    //
    // These local functions kept for backward compatibility / emergencies
    // but are NOT checked in _transfer() flow
    // ═══════════════════════════════════════════════════════════════════

    /// @notice Local pool approval (NOT checked in _transfer - use MEVProtection instead)
    function setApprovedPool(address pool, bool approved) external onlyOwner validAddress(pool) {
        approvedPools[pool] = approved;
        emit PoolApprovalUpdated(pool, approved);
    }
    
    /// @notice Local batch approval (NOT checked in _transfer - use MEVProtection instead)
    function batchApprovePools(address[] calldata pools) external onlyOwner {
        uint256 length = pools.length;
        require(length > 0 && length <= 50, "Invalid array length");
        for (uint256 i = 0; i < length;) {
            if (pools[i] != address(0)) approvedPools[pools[i]] = true;
            unchecked { ++i; }
        }
        emit BatchPoolsApproved(length, true);
    }
    
    /// @notice Local batch revoke (NOT checked in _transfer - use MEVProtection instead)
    function batchRevokePools(address[] calldata pools) external onlyOwner {
        uint256 length = pools.length;
        require(length > 0 && length <= 50, "Invalid array length");
        for (uint256 i = 0; i < length;) {
            approvedPools[pools[i]] = false;
            unchecked { ++i; }
        }
        emit BatchPoolsApproved(length, false);
    }
    
    /// @notice Returns LOCAL approval status (MEVProtection is what's actually enforced)
    function isApprovedPool(address pool) external view returns (bool) { return approvedPools[pool]; }
    function isContract(address account) external view returns (bool) { return _isContract(account); }

    // ═══════════════════════════════════════════════════════════════════
    //                      ADMIN FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════

    function pause() external onlyOwner { paused = true; emit Paused(); }
    function unpause() external onlyOwner { paused = false; emit Unpaused(); }
    function auditGoldReserves(uint256 auditedAmount) external onlyOwner { _goldReserves = auditedAmount; }

    // ═══════════════════════════════════════════════════════════════════
    //                      VIEW FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════

    /**
     * @dev Get pending module change details
     */
    function getPendingChange(bytes32 moduleKey) external view returns (
        address newAddress,
        uint256 executeTime,
        bool exists,
        uint256 timeRemaining
    ) {
        PendingModuleChange storage pending = pendingChanges[moduleKey];
        newAddress = pending.newAddress;
        executeTime = pending.executeTime;
        exists = pending.exists;
        
        if (exists && block.timestamp < executeTime) {
            timeRemaining = executeTime - block.timestamp;
        }
    }
    
    /**
     * @dev Get mint cap status
     */
    function getMintCapStatus() external view returns (
        uint256 dailyMinted,
        uint256 dailyRemaining,
        uint256 maxPerTx,
        uint256 maxDaily,
        uint256 resetTime
    ) {
        dailyMinted = dailyMintedAmount;
        maxPerTx = MAX_MINT_PER_TX;
        maxDaily = MAX_DAILY_MINT;
        
        if (block.timestamp - lastMintResetTime >= 1 days) {
            dailyRemaining = MAX_DAILY_MINT;
            resetTime = 0;
        } else {
            dailyRemaining = MAX_DAILY_MINT - dailyMintedAmount;
            resetTime = lastMintResetTime + 1 days - block.timestamp;
        }
    }

    // ═══════════════════════════════════════════════════════════════════
    //                   OWNERSHIP TRANSFER (2-STEP)
    // ═══════════════════════════════════════════════════════════════════

    function transferOwnership(address newOwner) external onlyOwner validAddress(newOwner) {
        pendingOwner = newOwner;
        emit OwnershipTransferPending(owner, newOwner);
    }
    
    function acceptOwnership() external {
        require(msg.sender == pendingOwner, "Not pending owner");
        address oldOwner = owner;
        owner = pendingOwner;
        pendingOwner = address(0);
        emit OwnershipTransferred(oldOwner, owner);
    }
    
    function cancelOwnershipTransfer() external onlyOwner { pendingOwner = address(0); }
    
    function renounceOwnership() external onlyOwner {
        address oldOwner = owner;
        owner = address(0);
        pendingOwner = address(0);
        emit OwnershipTransferred(oldOwner, address(0));
    }
}