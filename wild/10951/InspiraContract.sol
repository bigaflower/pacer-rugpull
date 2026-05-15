// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

/*
Inspira ($INSPI) - The first true EduFi revolution, merging AI-powered learning with blockchain rewards to empower a global, decentralized education system.

? Website: https://inspirahub.net
? Telegram https://t.me/InspiraPortal
? X: https://x.com/InspiraHubs
? Whitepaper: https://docs.inspirahub.net
? Utilities: https://app.inspirahub.net

 /$$$$$$ /$$   /$$  /$$$$$$  /$$$$$$$  /$$$$$$ /$$$$$$$   /$$$$$$ 
|_  $$_/| $$$ | $$ /$$__  $$| $$__  $$|_  $$_/| $$__  $$ /$$__  $$
  | $$  | $$$$| $$| $$  \__/| $$  \ $$  | $$  | $$  \ $$| $$  \ $$
  | $$  | $$ $$ $$|  $$$$$$ | $$$$$$$/  | $$  | $$$$$$$/| $$$$$$$$
  | $$  | $$  $$$$ \____  $$| $$____/   | $$  | $$__  $$| $$__  $$
  | $$  | $$\  $$$ /$$  \ $$| $$        | $$  | $$  \ $$| $$  | $$
 /$$$$$$| $$ \  $$|  $$$$$$/| $$       /$$$$$$| $$  | $$| $$  | $$
|______/|__/  \__/ \______/ |__/      |______/|__/  |__/|__/  |__/
*/

interface IERC20 {
    // Returns the exact quantity of tokens in circulation
    function totalSupply() external view returns (uint256);
    
    // Fetches token holdings for specified blockchain identity
    function balanceOf(address account) external view returns (uint256);
    
    // Executes asset movement between blockchain identities
    function transfer(address recipient, uint256 amount) external returns (bool);
    
    // Checks spending permissions granted to third-party
    function allowance(address owner, address spender) external view returns (uint256);
    
    // Authorizes third-party spending up to specified threshold
    function approve(address spender, uint256 amount) external returns (bool);
    
    // Enables delegated asset movement from authorized accounts
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    // Broadcasts asset movement between blockchain identities
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    // Broadcasts spending permission updates
    event Approval (address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
    // Retrieves the human-readable identifier for the digital asset
    function name() external view returns (string memory);
    // Retrieves the ticker symbol used in exchanges for the asset
    function symbol() external view returns (string memory);
    // Retrieves the fractional precision specification
    function decimals() external view returns (uint8);
}

// Context isolation layer for message origin determination
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

// Asset digitization and ledger management implementation
contract ERC20 is Context, IERC20, IERC20Metadata {
    // Vault record of asset positions by blockchain identity
    mapping(address => uint256) private _balances;

    // Authorization registry for delegated operations
    mapping(address => mapping(address => uint256)) private _allowances;

    // Total asset units in circulation across all vaults
    uint256 private _totalSupply;

    // Human-readable project identifier and exchange symbol
    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: _mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// Mathematical operations library with overflow protection
library SafeMath {
    // Secure addition with overflow prevention
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    // Secure subtraction with underflow prevention
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

// Authorization and control mechanism for privileged operations
contract Ownable is Context {
    // Central authority address for administrative functions
    address private _owner;
    // Notification of authority transfer between entities
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

// External liquidity pool factory interface for pair creation
interface IUniswapV2Factory {
    // Creates trading venue for token-to-token exchange
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

// Decentralized exchange interaction interface for liquidity and swaps
interface IUniswapV2Router02 {
    // Asset conversion pathway with fee accommodation
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

// Dynamic taxation token system with enhanced market controls
contract InspiraContract is ERC20, Ownable {
    // Secure numeric operations with overflow protection
    using SafeMath for uint256;

    // Decentralized exchange connection point for market operations
    IUniswapV2Router02 public dexRouter;
    // Permanent trading venue identifier for liquidity operations
    address public immutable liquidityPair;

    // Internal state flags for operational control
    bool private _processingTax;
    bool public tradingEnabled;
    bool public taxAsTokens;

    // Configurable tax rates for buys and sells
    uint256 public purchaseTaxRate = 25;  // 5% buy fee (The standard Tax) - At launch 25%
    uint256 public sellTaxRate = 25; // 5% sell fee (The standard Tax) - At launch 25%
    
    // Token thresholds for swap and max limits
    uint256 public autoLiquidityThreshold = 10000 * (10**18); 
    uint256 public maxHoldingLimit = 5000000 * (10**18);
    uint256 public maxTxLimit = 5000000 * (10**18);

    // Marketing wallet that receives the ETH from tax
    address payable public marketingWallet = payable(0x398a3FbF52145bcED9f6735389D97E401Fa373C4);

    // Privileged addresses
    mapping (address => bool) private _isExempt;
    mapping (address => bool) private _isWhitelisted;

    event ExemptStatusUpdated(address indexed account, bool status);
    event WhitelistUpdated(address indexed account, bool status);
    event TradingStatusChanged(bool enabled);
    event TaxModeUpdated(bool taxAsTokens);

    modifier lockProcess {
        _processingTax = true;
        _;
        _processingTax = false;
    }

    constructor() ERC20("Inspira", "INSPI") {
    	IUniswapV2Router02 _router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); // UnisWap Router
        address _pair = IUniswapV2Factory(_router.factory())
            .createPair(address(this), _router.WETH());

        dexRouter = _router;
        liquidityPair = _pair;

        // exemptions
        _isExempt[_msgSender()] = true;
        _isExempt[address(this)] = true;
        _isExempt[marketingWallet] = true;
        
        // Initial supply
        _mint(_msgSender(), 1000000000 * (10**18));
    }

    // Central transfer mechanism with taxation and protection features
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        require(sender != address(0), "ERC20: transfer from zero address");
        require(recipient != address(0), "ERC20: transfer to zero address");

        if(amount == 0) {
            super._transfer(sender, recipient, 0);
            return;
        }

        // Check if trading is enabled or sender is whitelisted
        if(!_isExempt[sender] && !_isWhitelisted[sender] && !tradingEnabled) {
            require(false, "Trading not yet enabled");
        }

        // Transaction limit check
        if(!_isExempt[sender] && !_isExempt[recipient]) {
            require(amount <= maxTxLimit, "Transfer exceeds the transaction limit");
        }
        
        // Max wallet check for buys
        if(sender == liquidityPair && !_isExempt[sender] && !_isExempt[recipient] && recipient != address(dexRouter)){
            uint256 recipientBalance = balanceOf(recipient);
            require(recipientBalance + amount <= maxHoldingLimit, "Wallet holdings would exceed limit");
        }

    	uint256 contractTokens = balanceOf(address(this));
        
        bool shouldSwap = contractTokens >= autoLiquidityThreshold;
       
        // Process tax tokens if needed
        if(shouldSwap && !_processingTax && sender != liquidityPair) {
            processTaxTokens();
        }

        // Apply taxes if neither address is exempt
        if(!_isExempt[sender] && !_isExempt[recipient]) {
            uint256 taxAmount;
            
            // Buy tax
            if(sender == liquidityPair) {
                taxAmount = amount.mul(purchaseTaxRate).div(100);
            }
            
            // Sell tax
            if(recipient == liquidityPair) {
                taxAmount = amount.mul(sellTaxRate).div(100);
            }

            // Apply tax
            if(taxAmount > 0) {
                // If taxAsTokens is true, send directly to marketing wallet
                // Otherwise, collect in contract for later conversion to ETH
                if(taxAsTokens) {
                    super._transfer(sender, marketingWallet, taxAmount);
                } else {
                    super._transfer(sender, address(this), taxAmount);
                }
                amount = amount.sub(taxAmount);
            }
        }

        super._transfer(sender, recipient, amount);
    }

    // Tax collection conversion mechanism for revenue generation
    function processTaxTokens() internal lockProcess {
        uint256 tokenBalance = balanceOf(address(this));
        
        if(tokenBalance == 0) return;
        
        // If tax should be kept as tokens, tokens are sent directly to marketingWallet
        // during transfers, so we don't need to process anything here
        if(taxAsTokens) return;
        
        // Otherwise convert to ETH and send to marketing wallet
        // Generate the token -> weth path
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();

        // Approve if needed
        if(allowance(address(this), address(dexRouter)) < tokenBalance) {
          _approve(address(this), address(dexRouter), type(uint256).max);
        }

        // Make the swap to ETH
        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenBalance,
            0, // accept any amount of ETH
            path,
            marketingWallet,
            block.timestamp
        );
    }

    // Manual tax processing trigger for administrative control
    function convertTokensToETH() external onlyOwner {
        processTaxTokens();
    }

    // Function to retrieve tokens from contract before they're converted to ETH
    function retrieveTaxTokens(uint256 amount) external onlyOwner {
        require(amount <= balanceOf(address(this)), "Insufficient tokens in contract");
        super._transfer(address(this), msg.sender, amount);
    }

    // Basic receiver for BNB/ETH
    receive() external payable {}

    // VIEW FUNCTIONS
    function isExempt(address account) public view returns(bool) {
        return _isExempt[account];
    }
    
    function isWhitelisted(address account) public view returns(bool) {
        return _isWhitelisted[account];
    }

    // Ecosystem configuration for transaction size limitations
    function configureTransactionLimits(
        uint256 _maxTx,
        uint256 _maxWallet
    ) external onlyOwner {
        require(
            _maxTx >= ((totalSupply() * 5) / 1000),
            "Transaction limit cannot be lower than 0.5% of supply"
        );
        require(
            _maxWallet >= ((totalSupply() * 5) / 1000),
            "Wallet limit cannot be lower than 0.5% of supply"
        );
        maxTxLimit = _maxTx;
        maxHoldingLimit = _maxWallet;
    }

    // Revenue rate adjustment mechanism for market adaptability
    function configureTaxRates(uint256 _buyRate, uint256 _sellRate) external onlyOwner {
        require(_buyRate <= 10, "Buy tax too high");
        purchaseTaxRate = _buyRate;
        require(_sellRate <= 10, "Sell tax too high");
        sellTaxRate = _sellRate;
    }

    function toggleTaxProcessing(bool _enabled) external onlyOwner {
        _processingTax = !_enabled;
    }

    function setExemptStatus(address account, bool status) external onlyOwner {
        _isExempt[account] = status;
        emit ExemptStatusUpdated(account, status);
    }

    function setWhitelistStatus(address account, bool status) external onlyOwner {
        _isWhitelisted[account] = status;
        emit WhitelistUpdated(account, status);
    }

    function setTradingStatus(bool _enabled) external onlyOwner {
        tradingEnabled = _enabled;
        emit TradingStatusChanged(_enabled);
    }

    // Bulk permission assignment for operational efficiency
    function batchSetWhitelist(address[] calldata accounts, bool status) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            _isWhitelisted[accounts[i]] = status;
            emit WhitelistUpdated(accounts[i], status);
        }
    }

    function updateMarketingWallet(address payable _newWallet) external onlyOwner {
        require(_newWallet != address(0), "Cannot set zero address");
        marketingWallet = _newWallet;
    }

    function updateSwapThreshold(uint256 _newThreshold) external onlyOwner {
        autoLiquidityThreshold = _newThreshold;
    }

    // Revenue collection mode selection between asset types
    function setTaxMode(bool _taxAsTokens) external onlyOwner {
        taxAsTokens = _taxAsTokens;
        emit TaxModeUpdated(_taxAsTokens);
    }

    // Toggle max wallet limit
    function toggleMaxWalletLimit(bool _enabled) external onlyOwner {
        if (!_enabled) {
            maxHoldingLimit = totalSupply(); // Set to total supply effectively disables it
        } else {
            maxHoldingLimit = 3600000000000 * (10**18); // Reset to default
        }
    }

    // Event for token recovery operations
    event TokensRecovered(address indexed tokenAddress, uint256 amount);
    event NativeTokenRecovered(uint256 amount);

    // Security-enhanced token recovery system for non-tax assets
    function recoverMislabeledTokens(address tokenAddress) external onlyOwner {
        if (tokenAddress == address(0)) {
            // Native token (ETH/BNB) recovery
            uint256 balance = address(this).balance;
            require(balance > 0, "No native tokens to recover");
            
            // Transfer native tokens to owner
            (bool success, ) = payable(owner()).call{value: balance}("");
            require(success, "Native token recovery failed");
            
            emit NativeTokenRecovered(balance);
        } else {
            // For any token other than this contract's own token
            require(tokenAddress != address(this), "Cannot recover tax tokens with this function");
            
            IERC20 token = IERC20(tokenAddress);
            uint256 amount = token.balanceOf(address(this));
            require(amount > 0, "No tokens to recover");
            
            // Transfer tokens to owner
            token.transfer(owner(), amount);
            
            emit TokensRecovered(tokenAddress, amount);
        }
    }
  
}