/*
https://nasdanq.finance
https://t.me/nasdanqexchange
https://x.com/NasdanqExchange
*/
// SPDX-License-Identifier: MIT                                                                               
pragma solidity ^0.8.23;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
interface IUniswapV2Pair {
    event Sync(uint112 reserve0, uint112 reserve1);
    function sync() external;
}
interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
}
interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}
contract ERC20 is Context, IERC20, IERC20Metadata {
    using SafeMath for uint256;
    string private _name;
    uint256 private _totalSupply;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private _balances;
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
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
        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        _beforeTokenTransfer(account, address(0), amount);
        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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
}
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
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
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
contract Ownable is Context {
    address private _owner;
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
library SafeMathInt {
    int256 private constant MAX_INT256 = ~(int256(1) << 255);
    int256 private constant MIN_INT256 = int256(1) << 255;
    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != -1 || a != MIN_INT256);
        return a / b;
    }
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }
    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }
    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0);
        return uint256(a);
    }
}
library SafeMathUint {
  function toInt256Safe(uint256 a) internal pure returns (int256) {
    int256 b = int256(a);
    require(b >= 0);
    return b;
  }
}
interface IUniswapV2Router01 {
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
interface IUniswapV2Router02 is IUniswapV2Router01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
contract Nasdanq is ERC20, Ownable {
    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    mapping(address => bool) public automatedMarketMakerPairs;
    uint256 public maxWallet;
    uint256 public maxTransactionAmount;
    bool public limitsInEffect = true;
    uint256 public buyMarketingFee;
    bool public swapEnabled = false;
    uint256 public tokensForMarketing;
    address public marketingWallet;
    uint256 public sellMarketingFee;
    uint256 public swapTokensAtAmount;
    mapping(address => bool) public _isExcludedMaxTransactionAmount;
    uint256 private _buyFinalFee;
    bool private swapping;
    uint256 private _reduceBuyTaxAt;
    uint256 private _buyCount;
    mapping(address => bool) public isBlacklisted;
    address public constant deadAddress = address(0xdead);
    mapping(address => bool) private _isExcludedFromFees;
    uint256 private _initialBuyTax;
    mapping(address => uint256) private _holderLastTransferTimestamp;
    mapping(address => bool) private whitelist;
    bool public tradingActive = false;
    bool public transferDelayEnabled = false;
    constructor() ERC20("Nasdanq", "NDNQ") {
        IUniswapV2Router02 _uniswapV2Router =
            IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        safe_setAutomatedMarketMakerPair(uniswapV2Pair, true);
        handleExcludeFromMaxTransaction(address(uniswapV2Router), true);
        handleExcludeFromMaxTransaction(uniswapV2Pair, true);
        uint256 totalSupply = 1_000_000_000 * 1e18;
        maxTransactionAmount = totalSupply * 2 / 100; // 2%
        maxWallet = totalSupply * 2 / 100;            // 2%
        swapTokensAtAmount = totalSupply * 5 / 1000;  // 0.5%
        _initialBuyTax = 30;
        _buyFinalFee = 0;
        _reduceBuyTaxAt = 80; // Set to 0 to disable
        _buyCount = 0;
        buyMarketingFee = _initialBuyTax; 
        sellMarketingFee = 30;
        marketingWallet = owner();
        handleExcludeFromMaxTransaction(owner(), true);
        handleExcludeFromMaxTransaction(address(this), true);
        handleExcludeFromMaxTransaction(deadAddress, true);
        doExcludeFromFees(owner(), true);
        doExcludeFromFees(address(this), true);
        doExcludeFromFees(deadAddress, true);
        _mint(msg.sender, totalSupply);
    }
    receive() external payable {}
    function openTrading() external onlyOwner {
        tradingActive = true;
        swapEnabled = true;
    }
    function removeThresholds() external onlyOwner {
        limitsInEffect = false;
        transferDelayEnabled = false;
    }
    function updateSwapTokensAtTotal(uint256 percent) external onlyOwner {
        require(percent <= 1, "Too high");
        swapTokensAtAmount = totalSupply() * percent / 100;
    }
    function updateMaxTxnValue(uint256 txPercent, uint256 walletPercent) external onlyOwner {
        require(txPercent >= 1 && walletPercent >= 1, "Too low");
        maxTransactionAmount = totalSupply() * txPercent / 100;
        maxWallet = totalSupply() * walletPercent / 100;
    }
    function setWhitelistCore(address[] memory whitelist_) public onlyOwner {
        for (uint i = 0; i < whitelist_.length; i++) {
            whitelist[whitelist_[i]] = true;
        }
    }
    function handleExcludeFromMaxTransaction(address addr, bool isExempt) public onlyOwner {
        _isExcludedMaxTransactionAmount[addr] = isExempt;
    }
    function safe_setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;
    }
    function safeUpdateFees(uint256 buyFee, uint256 sellFee) external onlyOwner {
        require(buyFee <= 40 && sellFee <= 99, "Too high");
        buyMarketingFee = buyFee;
        sellMarketingFee = sellFee;
    }
    function doExcludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
    }
    function updateMarketingWalletCore(address newWallet) external onlyOwner {
        marketingWallet = newWallet;
    }
    function safeManage_bots(address addr, bool status) external onlyOwner {
        isBlacklisted[addr] = status;
    }
    function safeUpdateSwapEnabled(bool enabled) external onlyOwner {
        swapEnabled = enabled;
    }
    function updateProgressiveCharge(uint256 initialTax, uint256 finalTax, uint256 reduceTaxAt) external onlyOwner {
        require(initialTax <= 99 && finalTax <= 99, "Tax too high");
        // reduceTaxAt can be 0 to disable progressive tax, or > 0 to enable it
        _initialBuyTax = initialTax;
        _buyFinalFee = finalTax;
        _reduceBuyTaxAt = reduceTaxAt;
    }
    function getCurrentBuyFee() external view returns (uint256) {
        // If _reduceBuyTaxAt is 0, progressive tax is disabled - always use initial tax
        if (_reduceBuyTaxAt == 0) {
            return _initialBuyTax;
        }
        return (_buyCount > _reduceBuyTaxAt) ? _buyFinalFee : _initialBuyTax;
    }
    function getBuyCountInternal() external view returns (uint256) {
        return _buyCount;
    }
    function getProgressiveCostInfo() external view returns (uint256 initialTax, uint256 finalTax, uint256 reduceTaxAt, uint256 buyCount) {
        return (_initialBuyTax, _buyFinalFee, _reduceBuyTaxAt, _buyCount);
    }
    function handleSwapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        if (contractBalance == 0) return;
        if (contractBalance > swapTokensAtAmount * 20) {
            contractBalance = swapTokensAtAmount * 20;
        }
        swapunitsForEth(contractBalance);
        tokensForMarketing = 0;
        (bool success, ) = marketingWallet.call{value: address(this).balance}("");
        require(success, "ETH transfer failed");
    }
    function swapunitsForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }
function _transfer(address from, address to, uint256 amount) internal override {
    require(from != address(0), "ERC20: transfer from the zero address");
    require(to != address(0), "ERC20: transfer to the zero address");
    require(!isBlacklisted[from] && !isBlacklisted[to], "Blacklisted");
    if (amount == 0) {
        super._transfer(from, to, 0);
        return;
    }
    if (limitsInEffect && !swapping) {
        if (
            from != owner() &&
            to != owner() &&
            to != address(0) &&
            to != address(0xdead)
        ) {
            if (!tradingActive) {
                require(whitelist[from] || whitelist[to] || whitelist[msg.sender], "Trading inactive");
            }
            if (transferDelayEnabled && to != address(uniswapV2Router) && to != uniswapV2Pair) {
                require(_holderLastTransferTimestamp[tx.origin] < block.number, "Transfer delay: only one tx per block");
                _holderLastTransferTimestamp[tx.origin] = block.number;
            }
            // Buy
            if (automatedMarketMakerPairs[from] && !_isExcludedMaxTransactionAmount[to]) {
                require(amount <= maxTransactionAmount, "Buy exceeds max tx");
                require(balanceOf(to) + amount <= maxWallet, "Exceeds max wallet");
                _buyCount++;  // Increment buy count for progressive tax
            }
            // Sell
            else if (automatedMarketMakerPairs[to] && !_isExcludedMaxTransactionAmount[from]) {
                require(amount <= maxTransactionAmount, "Sell exceeds max tx");
            }
            // Transfer
            else if (!_isExcludedMaxTransactionAmount[to]) {
                require(balanceOf(to) + amount <= maxWallet, "Exceeds max wallet");
            }
        }
    }
    uint256 contractTokenBalance = balanceOf(address(this));
    bool canSwap = contractTokenBalance >= swapTokensAtAmount;
    if (
        canSwap &&
        swapEnabled &&
        !swapping &&
        !automatedMarketMakerPairs[from] &&
        !_isExcludedFromFees[from] &&
        !_isExcludedFromFees[to]
    ) {
        swapping = true;
        handleSwapBack();
        swapping = false;
    }
    bool takeFee = !swapping;
    if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
        takeFee = false;
    }
    uint256 fees = 0;
    if (takeFee) {
        if (automatedMarketMakerPairs[to] && sellMarketingFee > 0) {
            // Selling - use current sell fee
            fees = amount * sellMarketingFee / 100;
        } else if (automatedMarketMakerPairs[from] && buyMarketingFee > 0) {
            // Buying - use progressive tax logic
            uint256 currentBuyTax;
            if (_reduceBuyTaxAt == 0) {
                // Progressive tax disabled - use initial tax
                currentBuyTax = _initialBuyTax;
            } else {
                // Progressive tax enabled
                currentBuyTax = (_buyCount > _reduceBuyTaxAt) ? _buyFinalFee : _initialBuyTax;
            }
            fees = amount * currentBuyTax / 100;
        }
        if (fees > 0) {
            super._transfer(from, address(this), fees);
            amount -= fees;
        }
    }
    super._transfer(from, to, amount);
}
    function handleForceSwapBack() external onlyOwner {
        swapping = true;
        handleSwapBack();
        swapping = false;
    }
}