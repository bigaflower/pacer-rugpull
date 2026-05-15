// SPDX-License-Identifier: MIT

/*
ISHIGO
The oldest Shiba Inu registered by the Japanese Dog Preservation Society.
https://www.nihonken-hozonkai.or.jp/history/

Website: ishigo.org
Telegram: t.me/ishigoportal
X: x.com/ishigoerc20
*/

pragma solidity 0.8.27;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
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

contract ISHIGO is Context, IERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;

    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private _balances;
    
    string private constant _name = "Ishigo";
    string private constant _symbol = "ISHIGO";
    uint8 private constant _decimals = 18;
    uint256 private constant _tTotal = 1000000  * 10**_decimals;

    uint256 public _maxWalletAmount = 15000  * 10**_decimals;
    uint256 public _maxTxAmount = 15000 * 10**_decimals;
    uint256 public _maxSwapAmount = 15000 * 10**_decimals;
    
    address private _taxFeeWallet;

    bool private tradingOpen;
    bool private inSwap = false;

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    event MaxTxAmountUpdated(uint256);
    event RemoveLimit(bool);
    event OpenTrading(bool);

    constructor () {
        uint256 tokenAmount = _tTotal.mul(20).div(100);
        _taxFeeWallet = _msgSender();

        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        _balances[_msgSender()] = _tTotal.sub(tokenAmount);
        _balances[address(this)] = tokenAmount;
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance."));
        return true;
    }

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address.");
        require(spender != address(0), "ERC20: approve to the zero address.");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address.");
        require(to != address(0), "ERC20: transfer to the zero address.");
        require(amount > 0, "_transfer: Transfer amount must be greater than zero.");
        if (from != owner() && to != owner()) {
            require(amount <= _maxTxAmount, "_transfer: Amount of transfer exceeds max transaction amount.");
            if (from == uniswapV2Pair && to != address(uniswapV2Router)) {
                require(tradingOpen,"_transfer: Trade is not yet open.");
                require(balanceOf(to) + amount <= _maxWalletAmount, "_transfer: Amount of transfer exceeds max wallet amount.");
            } else if (to == uniswapV2Pair){
                require(tradingOpen,"_transfer: Trade is not yet open.");
                uint256 contractTokenBalance = balanceOf(address(this));
                if (!inSwap && contractTokenBalance > 1 * 10**_decimals) {
                    uint256 swapAmount = (contractTokenBalance >= amount) ? amount : contractTokenBalance;
                    if (swapAmount > _maxSwapAmount) {
                        swapAmount = _maxSwapAmount;
                    }
                    swapTokensForEth(swapAmount);
                    uint256 contractETHBalance = address(this).balance;
                    if (contractETHBalance > 0.001 ether) {
                        sendETHToFeeWallet(address(this).balance);
                    }
                }
            }
        }
        _balances[from]=_balances[from].sub(amount);
        _balances[to]=_balances[to].add(amount);
        emit Transfer(from, to, amount);
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
            block.timestamp.add(5 minutes)
        );
    }

    function sendETHToFeeWallet(uint256 amount) private {
        payable(_taxFeeWallet).transfer(amount);
    }

    function openTrading() external onlyOwner {
        require(!tradingOpen,"openTrading: Trading is already open.");
        tradingOpen = true;
        emit OpenTrading(tradingOpen);
    }

    function removeLimit() external onlyOwner {
        _maxTxAmount = _tTotal;
        _maxWalletAmount=_tTotal;
        emit MaxTxAmountUpdated(_tTotal);
        emit RemoveLimit(true);
    }

    receive() external payable {}

}