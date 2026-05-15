// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title BitBarter Token
 * @dev ERC20 token with tax system, bridge functionality, and owner controls
 * @notice This contract includes burn mechanism and configurable tax rates
 */
contract BitBarter {
    // ERC20 Events
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    // Custom Events
    event BridgeTransfer(address indexed from, address indexed to, uint256 amount);
    event RouterUpdated(address indexed router);
    event PairUpdated(address indexed pair);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OwnershipRenounced(address indexed previousOwner);
    event Paused(address indexed account);
    event Unpaused(address indexed account);
    event TaxRateUpdated(uint256 oldRate, uint256 newRate);
    event TaxSplitUpdated(uint256 marketing, uint256 liquidity, uint256 burn);

    // Token Information
    string public constant name = "Bit-Barter";
    string public constant symbol = "BT77";
    uint8 public constant decimals = 18;
    
    // Supply Management
    uint256 private _totalSupply;
    uint256 public constant MAX_SUPPLY = 777_000_000 * 10**decimals; // 777M max cap
    
    // Tax Configuration
    uint256 public taxRate = 30; // 3.0% (base 1000)
    uint256 public constant MAX_TAX_RATE = 100; // 10% maximum
    
    // Wallets
    address public marketingWallet;
    address public liquidityWallet;
    address public owner;
    
    // Contract State
    bool public paused = false;
    bool public ownershipRenounced = false;

    // Mappings
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;
    mapping(address => bool) public isExcludedFromTax;
    mapping(address => bool) public isBridgeWhitelisted;

    // DEX Integration
    address public dexRouter;
    address public dexPair;

    // Tax Distribution Structure
    struct TaxSplit {
        uint256 marketing;
        uint256 liquidity;
        uint256 burnAmount;
    }

    TaxSplit public taxSplit = TaxSplit({
        marketing: 500, // 50%
        liquidity: 300, // 30%
        burnAmount: 200 // 20%
    });

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner && !ownershipRenounced, "Caller is not the owner or ownership renounced");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier validAddress(address _addr) {
        require(_addr != address(0), "Invalid address: zero address");
        _;
    }

    /**
     * @dev Constructor that sets up the token with initial parameters
     * @param _marketingWallet Address for marketing tax collection
     * @param _liquidityWallet Address for liquidity tax collection
     */
    constructor(
        address _marketingWallet, 
        address _liquidityWallet
    ) {
        require(_marketingWallet != address(0), "Invalid marketing wallet");
        require(_liquidityWallet != address(0), "Invalid liquidity wallet");
        
        marketingWallet = _marketingWallet;
        liquidityWallet = _liquidityWallet;
        owner = msg.sender;

        // FIXED: Properly initialize total supply
        uint256 cap = 77_000_000 * 10**decimals;
        _totalSupply = cap; // FIXED: Actually assign the value
        balances[msg.sender] = cap;

        // Exclude key addresses from tax
        isExcludedFromTax[msg.sender] = true;
        isExcludedFromTax[_marketingWallet] = true;
        isExcludedFromTax[_liquidityWallet] = true;
        isExcludedFromTax[address(this)] = true;

        emit Transfer(address(0), msg.sender, cap);
    }

    // ===== ERC20 STANDARD FUNCTIONS =====

    /**
     * @dev Returns the total supply of tokens
     */
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Returns the balance of the specified address
     */
    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    /**
     * @dev Returns the allowance amount
     */
    function allowance(address owner_, address spender) public view returns (uint256) {
        return allowances[owner_][spender];
    }

    /**
     * @dev Transfer tokens to specified address
     */
    function transfer(address recipient, uint256 amount) 
        external 
        whenNotPaused 
        returns (bool) 
    {
        require(recipient != address(0), "Invalid address: zero address");
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev Approve spender to spend tokens
     */
    function approve(address spender, uint256 amount) 
        external 
        whenNotPaused 
        returns (bool) 
    {
        require(spender != address(0), "Invalid address: zero address");
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another using allowance
     */
    function transferFrom(address sender, address recipient, uint256 amount) 
        external 
        whenNotPaused 
        returns (bool) 
    {
        require(sender != address(0), "Invalid sender address");
        require(recipient != address(0), "Invalid recipient address");
        
        uint256 currentAllowance = allowances[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, currentAllowance - amount);
        
        return true;
    }

    // ===== INTERNAL FUNCTIONS =====

    /**
     * @dev Internal transfer function with tax logic
     * FIXED: Corrected tax deduction logic
     */
    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(balances[from] >= amount, "ERC20: transfer amount exceeds balance");

        uint256 transferAmount = amount;
        uint256 totalFee = 0;

        // Apply tax if conditions are met
        if (
            taxRate > 0 &&
            !isExcludedFromTax[from] &&
            !isExcludedFromTax[to] &&
            (from == dexPair || to == dexPair) // Only tax DEX transactions
        ) {
            totalFee = (amount * taxRate) / 1000;
            
            uint256 marketingShare = (totalFee * taxSplit.marketing) / 1000;
            uint256 liquidityShare = (totalFee * taxSplit.liquidity) / 1000;
            uint256 burnShare = (totalFee * taxSplit.burnAmount) / 1000;

            // Distribute tax portions
            if (marketingShare > 0) {
                balances[marketingWallet] += marketingShare;
                emit Transfer(from, marketingWallet, marketingShare);
            }
            
            if (liquidityShare > 0) {
                balances[liquidityWallet] += liquidityShare;
                emit Transfer(from, liquidityWallet, liquidityShare);
            }
            
            if (burnShare > 0) {
                _totalSupply -= burnShare; // Burn tokens by reducing supply
                emit Transfer(from, address(0), burnShare);
            }

            transferAmount = amount - totalFee; // FIXED: Correct calculation
        }

        // Execute the transfer
        balances[from] -= amount; // FIXED: Deduct full amount from sender
        balances[to] += transferAmount; // Credit net amount to recipient
        
        emit Transfer(from, to, transferAmount);
    }

    /**
     * @dev Internal approve function
     */
    function _approve(address owner_, address spender, uint256 amount) internal {
        require(owner_ != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        allowances[owner_][spender] = amount;
        emit Approval(owner_, spender, amount);
    }

    // ===== PUBLIC FUNCTIONS =====

    /**
     * @dev Burn tokens from caller's balance
     */
    function burn(uint256 amount) external whenNotPaused {
        require(balances[msg.sender] >= amount, "ERC20: burn amount exceeds balance");
        
        balances[msg.sender] -= amount;
        _totalSupply -= amount;
        
        emit Transfer(msg.sender, address(0), amount);
    }

    /**
     * @dev Bridge transfer function with proper validation
     * FIXED: Added address validation and better error handling
     */
    function bridgeTransfer(address to, uint256 amount) 
        external 
        whenNotPaused 
    {
        require(to != address(0), "Invalid address: zero address");
        require(isBridgeWhitelisted[msg.sender], "Not whitelisted for bridge transfers");
        require(balances[msg.sender] >= amount, "Insufficient balance for bridge transfer");
        require(amount > 0, "Bridge amount must be greater than zero");
        
        balances[msg.sender] -= amount;
        _totalSupply -= amount; // Burn tokens for bridge
        
        emit Transfer(msg.sender, address(0), amount);
        emit BridgeTransfer(msg.sender, to, amount);
    }

    // ===== OWNER FUNCTIONS =====

    /**
     * @dev Set tax rate with proper validation
     */
    function setTaxRate(uint256 _rate) external onlyOwner {
        require(_rate <= MAX_TAX_RATE, "Tax rate exceeds maximum");
        
        uint256 oldRate = taxRate;
        taxRate = _rate;
        
        emit TaxRateUpdated(oldRate, _rate);
    }

    /**
     * @dev Set tax distribution split
     */
    function setTaxSplit(uint256 marketingPercent, uint256 liquidityPercent, uint256 burnPercent) external onlyOwner {
        require(marketingPercent + liquidityPercent + burnPercent == 1000, "Split must sum to 1000 (100%)");
        
        taxSplit = TaxSplit(marketingPercent, liquidityPercent, burnPercent);
        emit TaxSplitUpdated(marketingPercent, liquidityPercent, burnPercent);
    }

    /**
     * @dev Update marketing wallet
     */
    function setMarketingWallet(address _wallet) external onlyOwner {
        require(_wallet != address(0), "Invalid address");
        
        // Remove tax exclusion from old wallet
        isExcludedFromTax[marketingWallet] = false;
        
        marketingWallet = _wallet;
        
        // Add tax exclusion to new wallet
        isExcludedFromTax[_wallet] = true;
    }

    /**
     * @dev Update liquidity wallet
     */
    function setLiquidityWallet(address _wallet) external onlyOwner {
        require(_wallet != address(0), "Invalid address");
        
        // Remove tax exclusion from old wallet
        isExcludedFromTax[liquidityWallet] = false;
        
        liquidityWallet = _wallet;
        
        // Add tax exclusion to new wallet
        isExcludedFromTax[_wallet] = true;
    }

    /**
     * @dev Exclude or include address from tax
     */
    function excludeFromTax(address account, bool excluded) external onlyOwner {
        require(account != address(0), "Invalid address");
        isExcludedFromTax[account] = excluded;
    }

    /**
     * @dev Set bridge whitelist status
     */
    function setBridgeWhitelist(address account, bool whitelisted) external onlyOwner {
        require(account != address(0), "Invalid address");
        isBridgeWhitelisted[account] = whitelisted;
    }

    /**
     * @dev Set DEX router address
     */
    function setDexRouter(address _router) external onlyOwner {
        require(_router != address(0), "Invalid router");
        dexRouter = _router;
        emit RouterUpdated(_router);
    }

    /**
     * @dev Set DEX pair address
     */
    function setDexPair(address _pair) external onlyOwner {
        require(_pair != address(0), "Invalid pair");
        dexPair = _pair;
        emit PairUpdated(_pair);
    }

    /**
     * @dev Transfer ownership to new owner
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid new owner");
        require(!ownershipRenounced, "Ownership has been renounced");
        
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Renounce ownership permanently
     * ADDED: Ability to make contract fully decentralized
     */
    function renounceOwnership() external onlyOwner {
        require(!ownershipRenounced, "Ownership already renounced");
        
        ownershipRenounced = true;
        emit OwnershipRenounced(owner);
        owner = address(0);
    }

    /**
     * @dev Pause contract in emergency
     * ADDED: Emergency pause functionality
     */
    function pause() external onlyOwner {
        require(!paused, "Contract is already paused");
        paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Unpause contract
     */
    function unpause() external onlyOwner {
        require(paused, "Contract is not paused");
        paused = false;
        emit Unpaused(msg.sender);
    }

    /**
     * @dev Emergency function to recover accidentally sent ERC20 tokens
     * ADDED: Token recovery for emergency situations
     */
    function recoverToken(address tokenAddress, uint256 amount) external onlyOwner {
        require(tokenAddress != address(this), "Cannot recover own tokens");
        require(tokenAddress != address(0), "Invalid token address");
        
        // Simple transfer call - compatible with most ERC20 tokens
        (bool success, ) = tokenAddress.call(
            abi.encodeWithSignature("transfer(address,uint256)", owner, amount)
        );
        require(success, "Token recovery failed");
    }

    /**
     * @dev Get contract information
     */
    function getContractInfo() external view returns (
        uint256 currentSupply,
        uint256 maxSupply,
        uint256 currentTaxRate,
        bool isPaused,
        bool isOwnershipRenounced
    ) {
        return (
            _totalSupply,
            MAX_SUPPLY,
            taxRate,
            paused,
            ownershipRenounced
        );
    }

    /**
     * @dev Get tax split information
     */
    function getTaxSplit() external view returns (
        uint256 marketingPercent,
        uint256 liquidityPercent,
        uint256 burnPercent
    ) {
        return (
            taxSplit.marketing,
            taxSplit.liquidity,
            taxSplit.burnAmount
        );
    }

    /**
     * @dev Check if address is excluded from tax
     */
    function isAddressExcludedFromTax(address account) external view returns (bool) {
        return isExcludedFromTax[account];
    }

    /**
     * @dev Check if address is whitelisted for bridge
     */
    function isAddressBridgeWhitelisted(address account) external view returns (bool) {
        return isBridgeWhitelisted[account];
    }
}