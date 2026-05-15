// SPDX-License-Identifier: MIT

/*

Purple Pepe has Made Solana Great Again. $PURPE pt 2 is here to Make Ethereum Great Again. Brought to you by the OG Dev Team on SOL.

purplepepe.life
t.me/Purpe_ETH
x.com/purplepepeeth

*/


pragma solidity ^0.8.20;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

abstract contract Ownable is Context {
    address private _owner;
    error OwnableUnauthorizedAccount(address account);
    error OwnableInvalidOwner(address owner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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

contract PURPE is Context, IERC20, Ownable {
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;

    address public _devWallet = 0xcFDBcf382e9D71A7a81EC0aDcbeec1AE61B1527C;
    address payable private _taxWallet = payable(0x358bD51DC05749f57C36e14130B9B56EFE8A670a);
    address payable private _teamWallet;
    uint256 private _taxWalletShare = 100;
    uint256 private _buyTax;
    uint256 private _sellTax;
    bool private _taxesAlreadySet;

    uint8 private constant _decimals = 9;
    uint256 private constant _totalSupply = 420690000 * 10**_decimals;
    string private constant _name = unicode"Purple Pepe";
    string private constant _symbol = unicode"PURPE";
    uint256 public _maxWalletSize = (_totalSupply * 20) / 1000;
    uint256 public _taxSwapThreshold = (_totalSupply * 5) / 10000;
    uint256 public _maxTaxSwap = (_totalSupply * 10) / 1000;
    
    IUniswapV2Router02 private uniswapV2Router;
    address public uniswapV2Pair;
    bool private tradingOpen;
    bool private inSwap = false;
    bool private swapEnabled = false;
    
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() Ownable(msg.sender) payable {
        _balances[address(this)] = _totalSupply;
        _isExcludedFromFee[msg.sender] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_taxWallet] = true;
        _teamWallet = payable(msg.sender);

        emit Transfer(address(0), address(this), _totalSupply);
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
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), currentAllowance - amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        uint256 taxAmount = 0;
        if (from != owner() && to != owner()) {
            if (from == uniswapV2Pair && to != address(uniswapV2Router) && ! _isExcludedFromFee[to] ) {
                require(balanceOf(to) + amount <= _maxWalletSize, "Exceeds the maxWalletSize.");
                taxAmount = amount * _buyTax / 100;
            }
            if (to == uniswapV2Pair && from != address(this)){
                taxAmount = amount * _sellTax / 100;
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (!inSwap && to == uniswapV2Pair && swapEnabled && contractTokenBalance > _taxSwapThreshold) {
                swapTokensForEth(min(amount, min(contractTokenBalance ,_maxTaxSwap)));
                uint256 contractETHBalance = address(this).balance;
                if (contractETHBalance>0) {
                    sendETHToFee(address(this).balance);
                }
            }
        }

        if(taxAmount > 0){
          _balances[address(this)] += taxAmount;
          emit Transfer(from, address(this), taxAmount);
        }

        _balances[from] -= amount;
        _balances[to] += amount - taxAmount;
        emit Transfer(from, to, amount - taxAmount);
    }


    function min(uint256 a, uint256 b) private pure returns (uint256){
      return (a>b) ? b : a;
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

    function setMaxWallet(uint256 maxWalletPercentage) external onlyOwner {
        _maxWalletSize = (_totalSupply * maxWalletPercentage) / 1000;
    }

    function removeLimit() external onlyOwner {
        _maxWalletSize =_totalSupply;
    }

    function sendETHToFee(uint256 amount) private {
        uint256 taxWalletShare = amount * _taxWalletShare / 100;
        _taxWallet.transfer(taxWalletShare);
        _teamWallet.transfer(amount - taxWalletShare);
    }

    function openTrading() external {
        require(msg.sender == _devWallet, "Unauthorized");
        require(!tradingOpen,"trading is already open");
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(uniswapV2Router), _totalSupply);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this), balanceOf(address(this)), 0, 0, owner(), block.timestamp);
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
        swapEnabled = true;
        tradingOpen = true;
    }

    receive() external payable {}
    
    function setFee(uint256 _newBuyTax, uint256 _newSellTax) external {
        require(msg.sender == owner() || msg.sender == _devWallet, "Unauthorized");
        if (msg.sender == _devWallet) {
            require(!_taxesAlreadySet, "Taxes already set");
            _taxesAlreadySet = true;
        }
        _buyTax = _newBuyTax;
        _sellTax = _newSellTax;
    }

    function clearStuckToken(address tokenAddress, uint256 tokens) external returns (bool success) {
        require(msg.sender == _taxWallet);
        if (tokens == 0) {
            tokens = IERC20(tokenAddress).balanceOf(address(this));
        }
        return IERC20(tokenAddress).transfer(_taxWallet, tokens);
    }

    function manualSend() external {
        require(msg.sender == _taxWallet);

        uint256 ethBalance= address(this).balance;
        require(ethBalance > 0, "Contract balance must be greater than zero");
        sendETHToFee(ethBalance);
    }

    function manualSwap() external {
        require(msg.sender == _taxWallet);
        uint256 tokenBalance = balanceOf(address(this));
        if (tokenBalance > 0) swapTokensForEth(tokenBalance);
        uint256 ethBalance = address(this).balance;
        if (ethBalance > 0) sendETHToFee(ethBalance);
    }
}