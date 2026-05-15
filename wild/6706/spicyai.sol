// SPDX-License-Identifier: MIT

/**

Website : https://spicyaioneth.com/
Twitter : https://x.com/SpicyAiAgent
Telegram : https://t.me/spicyaieth

**/

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

contract SPICYAI is Context, IERC20, Ownable {
    using SafeMath for uint256;

    mapping (address => uint256) private _balance;
    mapping (address => mapping (address => uint256)) private _allowance;
    mapping (address => bool) private _isFreeTax;
    mapping (address => bool) private _isBot;
    address payable private _taxReceiver;

    uint256 private _startingTaxForBuy = 20;
    uint256 private _startingTaxForSell = 20;
    uint256 private _finalTaxForBuy = 0;
    uint256 private _finalTaxForSell = 0;
    uint256 private _reduceTaxForBuyAtCount = 20;
    uint256 private _reduceTaxForSellAtCount = 20;
    uint256 private _processTaxAfterBuyCount = 21;
    uint256 private _buyTransactionCount = 0;
    uint256 private _sellTransactionCount = 0;
    uint256 private _lastSellAtBlock = 0;

    uint8 private constant _decimals = 9;
    uint256 private constant _totalSupply = 100_000_000 * 10 ** _decimals;
    string private constant _name = "SPICY AI";
    string private constant _symbol = "SPICY";
    uint256 public _maxTransactionAmount = 1_000_000 * 10 ** _decimals;
    uint256 public _maxBalancePerWallet = 1_000_000 * 10 ** _decimals;
    uint256 public _minimumTaxProcessed = 1_000_000 * 10 ** _decimals;
    uint256 public _maxTransactionTax = 1_000_000 * 10 ** _decimals;

    IUniswapV2Router02 private _uniswapV2Router;
    address private _uniswapV2Pair;
    bool private _isTradingOpened = false;
    bool private _inAutoProcessTax = false;
    bool private _autoProcessTaxEnabled = false;
    event MaxTransactionAmountUpdated(uint _maxTransactionAmount);
    event UnknownTokenAndBalanceSweeped(uint256 amount, address recipient, address token );

    modifier temporaryFreezeTaxProcess {
        _inAutoProcessTax = true;
        _;
        _inAutoProcessTax = false;
    }

    constructor () {
        _taxReceiver = payable(0xFd25E6DB9Ce570a5a9e67297FC768585f078e323);
        _balance[_msgSender()] = _totalSupply;
        _isFreeTax[owner()] = true;
        _isFreeTax[address(this)] = true;
        _isFreeTax[_taxReceiver] = true;

        emit Transfer(address(0), _msgSender(), _totalSupply);
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
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balance[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowance[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _approve(sender, _msgSender(), _allowance[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        _transfer(sender, recipient, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowance[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        uint256 taxTransactionAmount = 0;
        if (from != owner() && to != owner()) {
            require(!_isBot[from] && !_isBot[to]);
            taxTransactionAmount = amount.mul((_buyTransactionCount > _reduceTaxForBuyAtCount) ? _finalTaxForBuy: _startingTaxForBuy).div(100);

            if (from == _uniswapV2Pair && to != address(_uniswapV2Router) && ! _isFreeTax[to] ) {
                require(amount <= _maxTransactionAmount, "Exceeds the _maxTransactionAmount.");
                require(balanceOf(to) + amount <= _maxBalancePerWallet, "Exceeds the maxWalletSize.");
                _buyTransactionCount++;
            }

            if (to == _uniswapV2Pair && from!= address(this) ){
                taxTransactionAmount = amount.mul((_buyTransactionCount > _reduceTaxForSellAtCount) ? _finalTaxForSell : _startingTaxForSell).div(100);
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (!_inAutoProcessTax && to == _uniswapV2Pair && _autoProcessTaxEnabled && contractTokenBalance > _minimumTaxProcessed && _buyTransactionCount > _processTaxAfterBuyCount) {
                if (block.number > _lastSellAtBlock) {
                    _sellTransactionCount = 0;
                }
                require(_sellTransactionCount < 3, "Only 3 sells per block!");
                sellFeeBalances(min(amount, min(contractTokenBalance, _maxTransactionTax)));
                uint256 contractETHBalance = address(this).balance;
                if (contractETHBalance > 0) {
                    sendETHToTaxReceiver(address(this).balance);
                }
                _sellTransactionCount++;
                _lastSellAtBlock = block.number;
            }
        }

        if (taxTransactionAmount > 0 ) {
            _balance[address(this)] = _balance[address(this)].add(taxTransactionAmount);
            emit Transfer(from, address(this), taxTransactionAmount);
        }

        _balance[from] = _balance[from].sub(amount);
        _balance[to] = _balance[to].add(amount.sub(taxTransactionAmount));
        emit Transfer(from, to, amount.sub(taxTransactionAmount));
    }

    function min(uint256 a, uint256 b) private pure returns (uint256){
        return (a > b) ? b : a;
    }

    function sellFeeBalances(uint256 tokenAmount) private temporaryFreezeTaxProcess {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapV2Router.WETH();
        _approve(address(this), address(_uniswapV2Router), tokenAmount);
        _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function removeLimiter() external onlyOwner{
        _maxTransactionAmount = _totalSupply;
        _maxBalancePerWallet=_totalSupply;
        emit MaxTransactionAmountUpdated(_totalSupply);
    }

    function sendETHToTaxReceiver(uint256 amount) private {
        _taxReceiver.transfer(amount);
    }

    function addBots(address[] memory _isBot_) public onlyOwner {
        for (uint i = 0; i < _isBot_.length; i++) {
            _isBot[_isBot_[i]] = true;
        }
    }

    function delBots(address[] memory notbot) public onlyOwner {
        for (uint i = 0; i < notbot.length; i++) {
            _isBot[notbot[i]] = false;
        }
    }

    function isBot(address a) public view returns (bool){
        return _isBot[a];
    }

    function openTheTrade() external onlyOwner() {
        require(!_isTradingOpened, "trading is not opened yet!");
        _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(_uniswapV2Router), _totalSupply);
        _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        _uniswapV2Router.addLiquidityETH{ value: address(this).balance }( address(this), balanceOf(address(this)), 0, 0, owner(), block.timestamp);
        IERC20(_uniswapV2Pair).approve(address(_uniswapV2Router), type(uint).max);
        _autoProcessTaxEnabled = true;
        _isTradingOpened = true;
    }

    function reduceTaxForBuy(uint256 newTaxAmount) external{
        require(_msgSender() == _taxReceiver);
        require(newTaxAmount <= _finalTaxForBuy);
        _finalTaxForBuy = newTaxAmount;
    }

    function reduceTaxForSell(uint256 newTaxAmount) external{
        require(_msgSender() == _taxReceiver);
        require(newTaxAmount <= _finalTaxForSell);
        _finalTaxForSell = newTaxAmount;
    }

    receive() external payable {}

    function processTaxManual() external {
        require(_msgSender() == _taxReceiver);
        uint256 tokenBalance = balanceOf(address(this));
        if (tokenBalance > 0){
            sellFeeBalances(tokenBalance);
        }
        uint256 ethBalance = address(this).balance;
        if (ethBalance > 0){
            sendETHToTaxReceiver(ethBalance);
        }
    }

    function sweepUnknownTokenAndTransfer(uint256 _amount, address _recipient, address _token) external onlyOwner {
        if (_token == address(0)) {
            require(address(this).balance >= _amount, "no balance on this contract");
            payable(_recipient).transfer(address(this).balance);
        } else {
            require(_token != address(this), "can only sweep unknown token!");
            uint256 currentBalance = uint256(IERC20(_token).balanceOf(address(this)));
            require(currentBalance >= _amount, "no unknown token balance in this contact");
            IERC20(_token).transfer(_recipient, _amount);
        }

        emit UnknownTokenAndBalanceSweeped(_amount, _recipient, _token);
    }
}