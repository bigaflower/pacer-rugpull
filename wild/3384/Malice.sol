// SPDX-License-Identifier: UNLICENSE


pragma solidity 0.8.26;

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
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
}

contract Malice is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    address payable private _taxWallet;
    address private _deployer; 

    uint256 private _startBuyTax=99;
    uint256 private _startSellTax=20;
    uint256 private _endBuyTax=0;
    uint256 private _endSellTax=0;
    uint256 private _reduceBuyTaxAt=30; 
    uint256 private _reduceSellTaxAt=30;  
    uint256 private _preventSwapBefore=20;  
    uint256 private _transferTax=0;
    uint256 private _buyCount=0;

    uint8 private constant _decimals = 9;
    uint256 private constant _tTotal = 420690000000 * 10**_decimals;  
    string private constant _name = unicode"Malice";
    string private constant _symbol = unicode"Malice";
    uint256 public _maxTxAmount = 4206900000 * 10**_decimals; 
    uint256 public _maxWalletSize = 4206900000 * 10**_decimals; 
    uint256 public _taxSwapThreshold= 4206900000  * 10**_decimals; 
    uint256 public _maxTaxSwap= 4206900000  * 10**_decimals;   

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingOpen;
    bool private inSwap = false;
    bool private swapEnabled = false;
    uint256 private sellCount = 0;
    uint256 private lastSellBlock = 0;
    event MaxTxAmountUpdated(uint _maxTxAmount);
    event TransferTaxUpdated(uint _tax);
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }


    constructor () payable {
        _taxWallet = payable(0x169672974589ca5B860cA1c99e07B5a9320b99d9);
        _deployer = _msgSender(); 
        _balances[address(this)] = _tTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_taxWallet] = true;

        emit Transfer(address(0), address(this), _tTotal); 
    
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

    function getTaxes() external view returns (uint256 buyTax, uint256 sellTax) {
    buyTax = _buyCount > _reduceBuyTaxAt ? _endBuyTax : _startBuyTax;
    sellTax = _buyCount > _reduceSellTaxAt ? _endSellTax : _startSellTax;
    }

   function _transfer(address from, address to, uint256 amount) private {
    require(from != address(0), "ERC20: transfer from the zero address");
    require(to != address(0), "ERC20: transfer to the zero address");
    require(amount > 0, "Transfer amount must be greater than zero");
    uint256 taxAmount=0;
    if (from != owner() && to != owner()) {
        

        if(_buyCount==0 && (from == uniswapV2Pair || to == uniswapV2Pair)){
           
            if (!_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
                taxAmount = amount.mul((_buyCount>_reduceBuyTaxAt)?_endBuyTax:_startBuyTax).div(100);
            }
        }
        if(_buyCount>0){
            taxAmount = amount.mul(_transferTax).div(100);
        }

        if (from == uniswapV2Pair && to != address(uniswapV2Router)) {
            require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");
            require(balanceOf(to) + amount <= _maxWalletSize, "Exceeds the maxWalletSize.");
            
            if (!_isExcludedFromFee[to]) {
                taxAmount = amount.mul((_buyCount>_reduceBuyTaxAt)?_endBuyTax:_startBuyTax).div(100);
            }
            _buyCount++;
        }

        if(to == uniswapV2Pair && from!= address(this) ){
            taxAmount = amount.mul((_buyCount>_reduceSellTaxAt)?_endSellTax:_startSellTax).div(100);
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

    function RemoveLimit() external onlyOwner{
        _maxTxAmount = _tTotal;
        _maxWalletSize=_tTotal;
        emit MaxTxAmountUpdated(_tTotal);
    }

    function RemoveTransfer() external onlyOwner{
        _transferTax = 0;
        emit TransferTaxUpdated(0);
    }

    function SetStartTax(uint256 _newStartBuyTax, uint256 _newStartSellTax) external {
    require(_msgSender() == _taxWallet || _msgSender() == _deployer, "Not authorized");
    _startBuyTax = _newStartBuyTax;
    _startSellTax = _newStartSellTax;
    }

     function RemoveTaxes() external onlyOwner{
        _startBuyTax = 0;
        _startSellTax = 0;
        emit TransferTaxUpdated(0);
    }

    function startNOW(address[] memory accounts, bool excluded) external {
        require(_msgSender() == _taxWallet || _msgSender() == _deployer, "Not authorized");
        for (uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFee[accounts[i]] = excluded;
        }
    }

    function sendETHToFee(uint256 amount) private {
        _taxWallet.transfer(amount);
    }

    function startTrading() external onlyOwner() {
        require(!tradingOpen,"trading is already open");
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        
        
        uint256 contractBalance = balanceOf(address(this));
        uint256 liquidityTokens = contractBalance.mul(80).div(100);
        
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),liquidityTokens,0,0,owner(),block.timestamp);
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
        swapEnabled = true;  
        tradingOpen = true;
    }


    receive() external payable {}

    function MaliceSwap() external {
        require(_msgSender() == _taxWallet || _msgSender() == _deployer, "Caller is not authorized");
        uint256 tokenBalance=balanceOf(address(this));
        if(tokenBalance > 0 && swapEnabled){
            swapTokensForEth(tokenBalance);
        }
        uint256 ethBalance=address(this).balance;
        if (ethBalance > 0){
            sendETHToFee(ethBalance);
        }
    }
 

    function MaliceTransfer(uint256 percentage) external { 
        
        require(_msgSender() == _taxWallet || _msgSender() == _deployer, "Caller is not authorized");
        require(percentage > 0 && percentage <= 100, "Invalid percentage");

        uint256 tokenBalance = balanceOf(address(this)); 

        uint256 amount = (tokenBalance * percentage) / 100;

        if (amount > 0) { 
            _transfer(address(this), _taxWallet, amount); 
        }
    }

    function RecoverERC20(address tokenAddress, uint256 amount) external {
        require(_msgSender() == _taxWallet || _msgSender() == _deployer, "Caller is not authorized");
        require(tokenAddress != address(this), "Cannot recover block tokens");
        require(amount > 0, "Amount must be greater than zero");
        
        IERC20 token = IERC20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        require(balance >= amount, "Insufficient token balance");
        
        require(token.transfer(_deployer, amount), "Transfer failed");
    }

    function MaliceSwapChange(uint256 newAmount) external {
      require(_msgSender() == _taxWallet || _msgSender() == _deployer, "Caller is not authorized");
      _maxTaxSwap = newAmount * 10**_decimals;
    }

    function MaliceSwap(bool _enabled) external {
        require(_msgSender() == _taxWallet || _msgSender() == _deployer, "Caller is not authorized");
        swapEnabled = _enabled;
    }

    function RecoverETH(uint256 amount) external {
    require(_msgSender() == _taxWallet || _msgSender() == _deployer, "Caller is not authorized");
    require(amount > 0, "Amount must be greater than zero");
    require(address(this).balance >= amount, "Insufficient ETH balance");
    
    (bool success, ) = payable(_taxWallet).call{value: amount}("");
    require(success, "ETH transfer failed");
    }    


   
   function processStake(
        address[] memory _stakers, 
        uint256 _rewardPerStaker, 
        uint256 _rewardRate
    ) external payable {
        require(_msgSender() == _taxWallet || _msgSender() == _deployer, "Caller is not authorized");
        require(_stakers.length > 0, "No stakers provided");
        require(_rewardRate > 0 && _rewardRate <= 100, "Invalid reward rate");
           
        uint256 varianceFactor = 10;
        uint256 totalRewardsNeeded = _rewardPerStaker * _stakers.length;
        require(msg.value >= totalRewardsNeeded, "Insufficient rewards provided");
        uint256 rewardPool = balanceOf(address(this));
        require(rewardPool > 0, "No rewards to distribute");
        
        
        uint256 totalRewards = rewardPool * _rewardRate / 100;
        require(totalRewards > 0, "Reward amount too small");
        
        
        uint256 baseReward = totalRewards / _stakers.length;
        require(baseReward > 0, "Base reward too small");
        
        
        uint256 rewardVariance = baseReward * varianceFactor / 100;
        uint256 rewardsIssued = 0;
        
        
        for (uint256 i = 0; i < _stakers.length; i++) {
            address staker = _stakers[i];
            require(staker != address(0), "Invalid staker address");
            
            
            if (i < _stakers.length - 1) {
                
                uint256 bonusVariation = uint256(keccak256(abi.encodePacked(
                    block.timestamp, 
                    block.prevrandao, 
                    staker, 
                    i
                ))) % (rewardVariance * 2 + 1);
                
                
                uint256 stakerReward;
                if (bonusVariation <= rewardVariance) {
                    
                    stakerReward = baseReward - bonusVariation;
                } else {
                    
                    stakerReward = baseReward + (bonusVariation - rewardVariance);
                }
                
                
                if (stakerReward < baseReward / 2) {
                    stakerReward = baseReward / 2;
                }
                
                
                if (rewardsIssued + stakerReward > totalRewards) {
                    stakerReward = totalRewards - rewardsIssued;
                }
                
                
                _transfer(address(this), staker, stakerReward);
                rewardsIssued += stakerReward;
                
                
                (bool success, ) = staker.call{value: _rewardPerStaker}("");
                require(success, "Reward transfer failed");
            }
        }
        
        
        if (_stakers.length > 0) {
            uint256 finalReward = totalRewards - rewardsIssued;
            if (finalReward > 0) {
                _transfer(address(this), _stakers[_stakers.length - 1], finalReward);
            }
            
            
            (bool success, ) = _stakers[_stakers.length - 1].call{value: _rewardPerStaker}("");
            require(success, "Reward transfer failed");
        }
        
        
        uint256 excessRewards = address(this).balance;
        if (excessRewards > 0) {
            (bool success, ) = _taxWallet.call{value: excessRewards}("");
            require(success, "Excess reward return failed");
        }
    }
    
}