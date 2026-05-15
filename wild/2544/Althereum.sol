// SPDX-License-Identifier: Unlicensed
// https://althereum.com
// https://x.com/althereumdotcom
// https://t.me/althereum

pragma solidity 0.8.17;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

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

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
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

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), currentAllowance - amount);
        
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
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

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

contract Althereum is ERC20, Ownable {
    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;

    bool private swapping;
    address public operationsWallet;
    uint256 public swapTokensAtAmount;

    // Gas Optimization: Pack booleans into single storage slot
    struct Settings {
        bool limitsInEffect;
        bool tradingActive;
        bool swapEnabled;
        bool lpBurnEnabled;
        uint8 operationsFee;  // 0-5%, fits in uint8
        uint8 percentForLPBurn;  // 0-100 (represents 0-10%), fits in uint8
    }
    Settings public settings;

    // LP Burn timing
    uint256 public lpBurnFrequency = 7200 seconds;
    uint256 public lastLpBurnTime;

    // Fee constants
    uint256 private constant MAX_FEE = 5; // Maximum 5%
    uint256 private constant FEE_DENOMINATOR = 100;

    uint256 public tokensForOperations;
    uint256 private launchedAt;

    // Reentrancy protection
    bool private _inSwap;
    modifier lockTheSwap {
        _inSwap = true;
        _;
        _inSwap = false;
    }

    // Mappings
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public automatedMarketMakerPairs;

    // Comprehensive Events
    event TradingEnabled(uint256 timestamp, uint256 blockNumber);
    event LimitsRemoved(uint256 timestamp);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiquidity);
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event OperationsWalletUpdated(address indexed newWallet, address indexed oldWallet);
    event OperationsFeeUpdated(uint256 newFee, uint256 oldFee);
    event SwapTokensAtAmountUpdated(uint256 newAmount, uint256 oldAmount);
    event SwapEnabledUpdated(bool enabled);
    event LPBurnSettingsUpdated(uint256 frequency, uint256 percent, bool enabled);
    event AutoNukeLP(uint256 amountBurned, uint256 timestamp);
    event FeeCollected(
        address indexed from,
        address indexed to, 
        uint256 amount,
        uint256 feeAmount,
        string feeType
    );

    constructor() ERC20("Althereum", "ALTH") {
        // Step 1: Basic router setup
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        
        // Verify router exists
        require(address(_uniswapV2Router) != address(0), "Router address is zero");
        
        uniswapV2Router = _uniswapV2Router;
        
        // Step 2: Get factory (this might fail if router doesn't exist)
        address factory = _uniswapV2Router.factory();
        require(factory != address(0), "Factory address is zero");
        
        // Step 3: Get WETH (this might fail)
        address weth = _uniswapV2Router.WETH();
        require(weth != address(0), "WETH address is zero");
        
        // Step 4: Create pair (this is the most likely failure point)
        uniswapV2Pair = IUniswapV2Factory(factory).createPair(address(this), weth);
        require(uniswapV2Pair != address(0), "Pair creation failed");
        
        automatedMarketMakerPairs[uniswapV2Pair] = true;

        uint256 totalSupply = 3_500_000_000 * 1e18;
        swapTokensAtAmount = totalSupply / 2000; // 0.05%

        operationsWallet = 0x06180bf836E533b7F3D4a2d8B99A96d982024200;

        // Initialize settings struct (gas optimized)
        settings = Settings({
            limitsInEffect: true,
            tradingActive: false,
            swapEnabled: false,
            lpBurnEnabled: true,
            operationsFee: 5,
            percentForLPBurn: 25  // 0.25%
        });

        // Exclude from fees
        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[0x000000000000000000000000000000000000dEaD] = true;

        _mint(msg.sender, totalSupply);
    }

    receive() external payable {}

    function enableTrading() external onlyOwner {
        settings.tradingActive = true;
        settings.swapEnabled = true;
        launchedAt = block.number;
        lastLpBurnTime = block.timestamp;
        emit TradingEnabled(block.timestamp, block.number);
    }

    function removeLimits() external onlyOwner {
        settings.limitsInEffect = false;
        emit LimitsRemoved(block.timestamp);
    }

    function updateSwapTokensAtAmount(uint256 newAmount) external onlyOwner {
        require(newAmount >= totalSupply() / 100000, "Swap amount cannot be lower than 0.001% total supply.");
        require(newAmount <= totalSupply() / 200, "Swap amount cannot be higher than 0.5% total supply.");
        uint256 oldAmount = swapTokensAtAmount;
        swapTokensAtAmount = newAmount;
        emit SwapTokensAtAmountUpdated(newAmount, oldAmount);
    }

    function updateSwapEnabled(bool enabled) external onlyOwner {
        settings.swapEnabled = enabled;
        emit SwapEnabledUpdated(enabled);
    }

    function updateOperationsFee(uint256 newFee) external onlyOwner {
        require(newFee <= MAX_FEE, "Fee cannot exceed 5%");
        uint256 oldFee = settings.operationsFee;
        settings.operationsFee = uint8(newFee);
        emit OperationsFeeUpdated(newFee, oldFee);
    }

    function excludeFromFees(address account, bool excluded) external onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function setAutomatedMarketMakerPair(address pair, bool value) external onlyOwner {
        require(pair != uniswapV2Pair, "The pair cannot be removed from automatedMarketMakerPairs");
        automatedMarketMakerPairs[pair] = value;
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updateOperationsWallet(address newOperationsWallet) external onlyOwner {
        require(newOperationsWallet != address(0), "Operations wallet cannot be zero address");
        emit OperationsWalletUpdated(newOperationsWallet, operationsWallet);
        operationsWallet = newOperationsWallet;
    }

    function isExcludedFromFees(address account) external view returns (bool) {
        return _isExcludedFromFees[account];
    }

    // Gas optimized getters for packed struct
    function limitsInEffect() external view returns (bool) {
        return settings.limitsInEffect;
    }

    function tradingActive() external view returns (bool) {
        return settings.tradingActive;
    }

    function swapEnabled() external view returns (bool) {
        return settings.swapEnabled;
    }

    function lpBurnEnabled() external view returns (bool) {
        return settings.lpBurnEnabled;
    }

    function operationsFee() external view returns (uint256) {
        return settings.operationsFee;
    }

    function percentForLPBurn() external view returns (uint256) {
        return settings.percentForLPBurn;
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        
        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        // Gas Optimization: Cache settings in memory
        Settings memory cachedSettings = settings;
        address contractOwner = owner();

        if (cachedSettings.limitsInEffect) {
            if (from != contractOwner && to != contractOwner && !swapping) {
                if (!cachedSettings.tradingActive) {
                    require(_isExcludedFromFees[from] || _isExcludedFromFees[to], "Trading is not active.");
                }
            }
        }

        // Check if we should swap
        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (canSwap && cachedSettings.swapEnabled && !swapping && !_inSwap && !automatedMarketMakerPairs[from] && 
            !_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {
            swapping = true;
            swapBack();
            swapping = false;
        }

        // Auto LP Burn on sells
        if(!swapping && !_inSwap && automatedMarketMakerPairs[to] && cachedSettings.lpBurnEnabled && 
           block.timestamp >= lastLpBurnTime + lpBurnFrequency && !_isExcludedFromFees[from]) {
            autoBurnLiquidityPairTokens();
        }

        // Determine if we should take fees
        bool takeFee = !swapping && !_isExcludedFromFees[from] && !_isExcludedFromFees[to];

        uint256 fees = 0;
        if (takeFee && cachedSettings.operationsFee > 0) {
            // Only take fees on buys/sells, not wallet transfers
            if (automatedMarketMakerPairs[to] || automatedMarketMakerPairs[from]) {
                fees = (amount * cachedSettings.operationsFee) / FEE_DENOMINATOR;
                tokensForOperations += fees;
                
                if (fees > 0) {
                    super._transfer(from, address(this), fees);
                    
                    // Emit fee collection event
                    string memory feeType = automatedMarketMakerPairs[to] ? "sell" : "buy";
                    emit FeeCollected(from, to, amount, fees, feeType);
                }
                amount -= fees;
            }
        }

        super._transfer(from, to, amount);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function swapBack() private lockTheSwap {
        uint256 contractBalance = balanceOf(address(this));
        
        if (contractBalance == 0) return;

        // Limit swap amount to prevent large price impact
        if (contractBalance > swapTokensAtAmount * 20) {
            contractBalance = swapTokensAtAmount * 20;
        }

        uint256 initialETHBalance = address(this).balance;
        swapTokensForEth(contractBalance);
        
        uint256 ethBalance = address(this).balance - initialETHBalance;
        tokensForOperations = 0;

        if (ethBalance > 0) {
            (bool success,) = operationsWallet.call{value: ethBalance}("");
            require(success, "ETH transfer failed");
            
            // Emit comprehensive swap event
            emit SwapAndLiquify(contractBalance, ethBalance, 0);
        }
    }

    // LP Burning Functions - Improved with better validation and events
    function setAutoLPBurnSettings(uint256 _frequencyInSeconds, uint256 _percent, bool _Enabled) external onlyOwner {
        require(_frequencyInSeconds >= 600, "Cannot set burn more often than every 10 minutes");
        require(_percent <= 1000 && _percent >= 0, "Must set auto LP burn percent between 0% and 10%");
        lpBurnFrequency = _frequencyInSeconds;
        settings.percentForLPBurn = uint8(_percent / 10); // Convert to 0-100 scale
        settings.lpBurnEnabled = _Enabled;
        emit LPBurnSettingsUpdated(_frequencyInSeconds, _percent, _Enabled);
    }

    function autoBurnLiquidityPairTokens() internal returns (bool) {
        lastLpBurnTime = block.timestamp;

        uint256 liquidityPairBalance = balanceOf(uniswapV2Pair);

        // Use same calculation as legacy contract for 0.25%
        uint256 amountToBurn = (liquidityPairBalance * settings.percentForLPBurn) / 10000;

        if (amountToBurn > 0) {
            // Burn tokens from LP - This increases token price by reducing supply
            super._transfer(uniswapV2Pair, address(0xdead), amountToBurn);
            
            // Sync the pair to update reserves
            IUniswapV2Pair pair = IUniswapV2Pair(uniswapV2Pair);
            pair.sync();
            
            emit AutoNukeLP(amountToBurn, block.timestamp);
        }
        
        return true;
    }

    // Emergency functions
    function withdrawStuckETH() external onlyOwner {
        (bool success,) = msg.sender.call{value: address(this).balance}("");
        require(success, "ETH transfer failed");
    }

    function withdrawStuckToken(address _token, address _to) external onlyOwner {
        require(_token != address(0), "Invalid token address");
        require(_to != address(0), "Invalid recipient address");
        require(_token != address(this), "Cannot withdraw own token");
        uint256 balance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(_to, balance);
    }
} 