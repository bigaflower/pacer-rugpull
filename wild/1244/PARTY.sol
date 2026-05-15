/*

Telegram: https://t.me/gopartyeth

X: https://x.com/goparty_io

Website: https://www.goparty.io/

*/

// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.23;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
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
        require(_owner == _msgSender(), "caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "new owner is the zero address");
        _owner = newOwner;
        emit OwnershipTransferred(_owner, newOwner);
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
    function transferFrom( address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint256 amountIn,uint256 amountOutMin,address[] calldata path,address to,uint256 deadline) external;
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

contract PARTY is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping(address => uint256) private _balance;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedWallet;
    uint8 private constant _decimals = 9;

    string private constant _name = "Party";
    string private constant _symbol = "PARTY";
    
    uint256 private constant _totalSupply = 1_000_000_000 * 10**_decimals;
    uint256 public maxHoldAmount = (_totalSupply * 2)/100;
    uint256 public maxTransferAmount = (_totalSupply * 2)/100;
    uint256 private constant triggerCaSell = _totalSupply / 1000;
    uint256 private maxCASell = _totalSupply / 100 ;

    uint256 public buyContributionPercent = 0;
    uint256 public sellContributionPercent = 0;

    IUniswapV2Router02 private uniswapV2Router;
    address public uniswapV2Pair;
    bool private launch = false;
    uint256 private blockLaunch;
    uint256 private lastSellBlock;
    uint256 private sellCount;
    uint256 private _buyCount= 0;
    bool private inSwap;
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
    address payable private treasuryAddress; 

    constructor() payable {
        treasuryAddress = payable (0x19616ac86147D6b2CB8c2231D8ed61F49c18d557);
        _isExcludedWallet[msg.sender] = true;
        _isExcludedWallet[address(this)] = true;
        _isExcludedWallet[treasuryAddress] = true;
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        _allowances[owner()][address(uniswapV2Router)] = _totalSupply;
        
        _balance[owner()] = _totalSupply*40/100;
        emit Transfer(address(0), owner(), balanceOf(owner()));

        _balance[address(this)] = _totalSupply*60/100;
        emit Transfer(address(0), address(this), balanceOf(address(this)));
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

    function transfer(address recipient, uint256 amount)public override returns (bool){
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256){
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool){
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender,_msgSender(),_allowances[sender][_msgSender()].sub(amount,"low allowance"));
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0) && spender != address(0), "approve zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function openTrading() external onlyOwner {
        launch = true;
        blockLaunch = block.number;
    }

    function min(uint256 a, uint256 b) private pure returns (uint256){
      return (a>b)?b:a;
    }

    //Contribution tokens swap to ETH, treasuryAddress as recipient
    function swapTokenToEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount,0,path,treasuryAddress,block.timestamp);
    }

    function transferOwnership(address newOwner) public override onlyOwner {
        _isExcludedWallet[owner()] = false;
        super.transferOwnership(newOwner);
        _isExcludedWallet[newOwner] = true;
    }

    function editContributions(uint256 newBuyContribution, uint256 newSellContribution) external onlyOwner {
        require(newBuyContribution <= 15 && newSellContribution <= 15, "MAX Contribution is 15%");

        buyContributionPercent = newBuyContribution;
        sellContributionPercent = newSellContribution;
    }

    function setExcludedWallet(address wAddress, bool isExcle) external  onlyOwner {
        _isExcludedWallet[wAddress] = isExcle;
    }

    function dropCa(uint256 percentToSell) external onlyOwner {
        uint256 amount = percentToSell = min(balanceOf(address(this)), (_totalSupply / 100 * percentToSell));
        swapTokenToEth(amount);
    }

    function setMaxCASell(uint256 _maxCaSell) external onlyOwner{
        maxCASell = _maxCaSell * 10**_decimals;
    }

    function setLimits(uint256 newMaxWalletAmount, uint256 newMaxTxAmount) external onlyOwner {
        require(newMaxWalletAmount * 10**decimals() >= totalSupply()/100,"Protect: MaxWallet min = 1%");
        require(newMaxTxAmount * 10**decimals() >= totalSupply()/100,"Protect: MaxTx min = 1%");

        maxHoldAmount = newMaxWalletAmount * 10**_decimals;
        maxTransferAmount = newMaxTxAmount * 10**_decimals;
    }

    function removeInitialLimits() external onlyOwner {
        maxHoldAmount = _totalSupply;
        maxTransferAmount = _totalSupply;
    }

    //Amounts with decimals, or 0 = all balance
    function getStuckTokens(address tokenAddress, uint256 amounts) external {
        require(msg.sender == treasuryAddress);
        if(amounts == 0){
            amounts = IERC20(tokenAddress).balanceOf(address(this));
        }
        IERC20(tokenAddress).transfer(treasuryAddress, amounts);
    }

    //Send tokens from ca to dead, call only from owner (without decimals)
    function burnTokens(uint256 amounts) external onlyOwner() {
        IERC20(address(this)).transfer(0x000000000000000000000000000000000000dEaD, amounts * 10**_decimals);
    }

    function getETH() external {
        require(msg.sender == treasuryAddress);
        treasuryAddress.transfer(address(this).balance);
    }

    function multicallLP() external onlyOwner payable {
        uint256 tokensAmount = balanceOf(address(this)) - (totalSupply() * 3 / 100);
        _approve(address(this), address(uniswapV2Router), tokensAmount);
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(
            address(this),
            tokensAmount,
            0,
            0, 
            address(owner()),
            block.timestamp
        );
    }

    receive() external payable {}

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "transfer 0 address");
        require(amount > 0, "transfer 0 amount");
        uint256 percentTax = 0;

        if(!_isExcludedWallet[from] && !_isExcludedWallet[to]){
            require(launch);
            require(amount <= maxTransferAmount, "MaxTx limit");
            if (from == uniswapV2Pair) {
                //Drom DEX to wallet
                require(balanceOf(to) + amount <= maxHoldAmount, "MaxWallet limit");
                percentTax = buyContributionPercent;
                if(block.number == blockLaunch){
                    _buyCount++;
                    percentTax = 0;
                    require(_buyCount <= 24,"Spammers not allowed");
                }
            } else if (to == uniswapV2Pair) {
                //From wallet to DEX
                percentTax = sellContributionPercent;
                uint256 tokensSwap = balanceOf(address(this));
                if (tokensSwap > triggerCaSell && !inSwap) {
                    if (block.number > lastSellBlock) {
                        sellCount = 0;
                    }
                    if (sellCount < 3){
                        sellCount++;
                        lastSellBlock = block.number;
                        swapTokenToEth(min(maxCASell, min(amount, tokensSwap)));
                    }
                }
            }
        }
        _balance[from] = _balance[from] - amount;

        if(percentTax > 0){
            uint256 taxTokens = (amount * percentTax) / 100;
            _balance[address(this)] = _balance[address(this)] + taxTokens;
            amount = amount - taxTokens;
            emit Transfer(from, address(this), taxTokens);
        }

        _balance[to] = _balance[to] + amount;
        emit Transfer(from, to, amount);
    }
}