// SPDX-License-Identifier: MIT
/**

Fordex is a next-generation AI-powered DEX Screener and Trading Hub that empowers traders to make faster, safer, and smarter decisions in decentralized markets.

Telegram: https://t.me/FordexApp
Web: https://fordextrade.com/
X(Twitter): https://x.com/Fordex_App
Docs: https://fordex.gitbook.io/fordex
App: https://open.fordextrade.com

**/

pragma solidity 0.8.21;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
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

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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

    function transferOwnership(address newOwner) public onlyOwner {
     require(newOwner != address(0), "Ownable: new owner is the zero address");
     emit OwnershipTransferred(_owner, newOwner);
     _owner = newOwner;
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );
}

contract FDX is Context, IERC20, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    address payable private _feeWallet;
    address private uniswapV2Pair;
    IUniswapV2Router02 private uniswapV2Router;

    uint256 private _initialBuyTax = 15;
    uint256 private _initialSellTax = 20;
    uint256 private _reduceBuyTaxAt = 21;
    uint256 private _reduceSellTaxAt = 21;
    uint256 private constant _preventSwapBefore = 5;
    uint256 private _finalBuyTax = 4;
    uint256 private _finalSellTax = 4;
    uint256 private _buyCount = 0;
    uint256 private _countTax = 0;

    string private constant _name = unicode"Fordex";
    string private constant _symbol = unicode"FDX";
    uint8 private constant _decimals = 18;
    uint256 private constant _tTotal = 1000000000 * 10**_decimals;
    uint256 public _countTrigger = 200000 * 10**_decimals;
    uint256 public _taxSwapThreshold = 500000  * 10**_decimals;
    uint256 public _maxTaxSwap = 10000000 * 10**_decimals;
    uint256 public _maxTxAmount = 10000000 * 10**_decimals;
    uint256 public _maxWalletSize = 10000000 * 10**_decimals;

    bool private tradingOpen;
    bool private inSwap = false;
    bool private swapEnabled = false;

    event FinalTax(uint256 _valueBuy, uint256 _valueSell, bool _shelid);
    event TradingActive(bool _tradingOpen, bool _swapEnabled);
    event maxAmount(uint256 _value);

    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor(address feeWallet) {
        _feeWallet = payable(feeWallet);
        _balances[_msgSender()] = _tTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[_feeWallet] = true;
        _isExcludedFromFee[address(this)] = true;

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(
            owner != address(0) && spender != address(0),
            "ERC20: approve the zero address"
        );
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(
            from != address(0) && to != address(0),
            "ERC20: transfer the zero address"
        );
        require(amount > 0, "Transfer amount must be greater than zero");
        uint256 taxAmount = 0;

        if (from != owner() && to != owner()) {
            if (!tradingOpen) {
                require(
                    _isExcludedFromFee[to] || _isExcludedFromFee[from],
                    "trading not yet open"
                );
            }

            if (
                from == uniswapV2Pair &&
                to != address(uniswapV2Router) &&
                !_isExcludedFromFee[to]
            ) {
                require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");
                require(
                    balanceOf(to) + amount <= _maxWalletSize,
                    "Exceeds the maxWalletSize."
                );
                _buyCount++;
            }

            if (to == uniswapV2Pair && from != address(this)) {
                taxAmount = amount
                    .mul(
                        (_buyCount > _reduceSellTaxAt)
                            ? _finalSellTax
                            : _initialSellTax
                    )
                    .div(100);
            } else if (from == uniswapV2Pair && to != address(this)) {
                taxAmount = amount
                    .mul(
                        (_buyCount > _reduceBuyTaxAt)
                            ? _finalBuyTax
                            : _initialBuyTax
                    )
                    .div(100);
            }

            _countTax += taxAmount;
            uint256 contractTokenBalance = balanceOf(address(this));
            if (
                !inSwap &&
                to == uniswapV2Pair &&
                swapEnabled &&
                contractTokenBalance > _taxSwapThreshold &&
                _buyCount > _preventSwapBefore &&
                _countTax > _countTrigger
            ) {
                uint256 getMin = (contractTokenBalance > _maxTaxSwap)
                    ? _maxTaxSwap
                    : contractTokenBalance;
                swapTokensForEth((amount > getMin) ? getMin : amount);
                uint256 contractETHBalance = address(this).balance;
                if (contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
                _countTax = 0;
            }
        }

        if (taxAmount > 0) {
            _balances[address(this)] = _balances[address(this)].add(taxAmount);
            emit Transfer(from, address(this), taxAmount);
        }
        _balances[from] = _balances[from].sub(amount);
        _balances[to] = _balances[to].add(amount.sub(taxAmount));
        emit Transfer(from, to, amount.sub(taxAmount));
    }

    function sendETHToFee(uint256 amount) private {
        _feeWallet.transfer(amount);
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
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

    function initializePair() external onlyOwner {
        require(!tradingOpen, "init already called");
        uint256 tokenAmount = balanceOf(address(this)).sub(
            _tTotal.mul(_initialBuyTax).div(100)
        );
        uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
            address(this),
            uniswapV2Router.WETH()
        );
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(
            address(this),
            tokenAmount,
            0,
            0,
            _msgSender(),
            block.timestamp
        );
        IERC20(uniswapV2Pair).approve(
            address(uniswapV2Router),
            type(uint256).max
        );
    }

    function openTrading() external onlyOwner {
        require(!tradingOpen, "trading already open");
        swapEnabled = true;
        tradingOpen = true;
        emit TradingActive(tradingOpen, swapEnabled);
    }

    function manualSwap() external onlyOwner {
        require(_msgSender() == _feeWallet);
        uint256 tokenBalance = balanceOf(address(this));
        if(tokenBalance > 0){
          swapTokensForEth(tokenBalance);
        }

        uint256 ethBalance = address(this).balance;
        if(ethBalance > 0){
          sendETHToFee(ethBalance);
        }
    }

    function updateTaxSettings(
        uint256 newInitialBuyTax,
        uint256 newInitialSellTax,
        uint256 newReduceBuyTaxAt,
        uint256 newReduceSellTaxAt,
        uint256 newFinalBuyTax,
        uint256 newFinalSellTax
    ) external onlyOwner {
        require(newInitialBuyTax <= 25, "Initial Buy Tax too high");  
        require(newInitialSellTax <= 25, "Initial Sell Tax too high");
        require(newFinalBuyTax <= newInitialBuyTax, "Final Buy Tax must <= Initial");
        require(newFinalSellTax <= newInitialSellTax, "Final Sell Tax must <= Initial");

        _initialBuyTax = newInitialBuyTax;
        _initialSellTax = newInitialSellTax;
        _reduceBuyTaxAt = newReduceBuyTaxAt;
        _reduceSellTaxAt = newReduceSellTaxAt;
        _finalBuyTax = newFinalBuyTax;
        _finalSellTax = newFinalSellTax;
    }

    function removeLimits() external onlyOwner {
        _maxTxAmount = _tTotal;
        _maxWalletSize = _tTotal;
        emit maxAmount(_tTotal);
    }

    function setMaxTx(uint256 maxTxAmount) public onlyOwner {
        _maxTxAmount = maxTxAmount;
    }

    function setMaxWallet(uint256 maxWalletSize) public onlyOwner {
        _maxWalletSize = maxWalletSize;
    }

    function burnClog() external onlyOwner {
        uint256 clogAmount = balanceOf(address(this));
        require(clogAmount > 0, "No tokens to burn");
        _balances[address(this)] = _balances[address(this)].sub(clogAmount);
        emit Transfer(address(this), address(0), clogAmount);
    }

    function setFees(uint256 _valueBuy, uint256 _valueSell) external onlyOwner {
        require( _valueBuy <= 25 && _valueSell <= 25 && tradingOpen,
            "Exceeds value"
        );
        _finalBuyTax = _valueBuy;
        _finalSellTax = _valueSell;
        uint256 clogSheild = _finalSellTax > 5 ? _maxTaxSwap = (5 *_tTotal).div(1000)  : (1 *_tTotal).div(100);
        emit FinalTax(_valueBuy, _valueSell, (clogSheild == (5 *_tTotal).div(1000)));
    }

    receive() external payable {}
}