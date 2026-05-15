/**

PEACE - $PEACE

Telegram: https://t.me/PeaceERC

*/

// SPDX-License-Identifier: MIT

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
        require(_owner == _msgSender(), "Not authorized");
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

contract PEACE is Context, IERC20, Ownable {
    mapping (address => uint256) private _tokenBalances;
    mapping (address => mapping (address => uint256)) private _tokenAllowances;
    mapping (address => bool) private _feeExempt;
    mapping (address => bool) private _blacklisted;
    address payable private _feeReceiver;

    uint256 private _startBuyFee=20;
    uint256 private _startSellFee=20;
    uint256 private _endBuyFee=0;
    uint256 private _endSellFee=0;
    uint256 private _buyFeeDropAt=19;
    uint256 private _sellFeeDropAt=19;
    uint256 private _minTxBeforeSwap=20;
    uint256 private _sendFee=0;
    uint256 private _totalBuys=0;

    uint8 private constant _tokenDecimals = 9;
    uint256 private constant _totalTokens = 1_000_000_000 * 10**_tokenDecimals;
    string private constant _tokenName = unicode"PEACE";
    string private constant _tokenSymbol = unicode"PEACE";
    uint256 public _maxTx =  2 * (_totalTokens/100);
    uint256 public _maxHolding =  2 * (_totalTokens/100);
    uint256 public _swapMin =  1 * (_totalTokens/1000);
    uint256 public _swapMax = 5 * (_totalTokens/1000);

    uint256 private constant _variant = 2;
    uint256 private constant _iteration = 8174;
    uint256 private constant _compiled = 20260226;
    
    IUniswapV2Router02 private _router;
    address private _pair;
    bool private _tradingLive;
    bool private _swapping = false;
    bool private _swapActive = false;
    uint256 private _sellsThisBlock = 0;
    uint256 private _lastBlockSold = 0;
    event MaxTxAmountUpdated(uint _maxTx);
    event TransferTaxUpdated(uint _tax);
    modifier swapGuard {
        _swapping = true;
        _;
        _swapping = false;
    }

    constructor () {
        _feeReceiver = payable(0xC31Cd0f56e8106eE8fF6FE7353CADf6ca7fa16D8);
        _tokenBalances[_msgSender()] = _totalTokens;
        _feeExempt[owner()] = true;
        _feeExempt[address(this)] = true;
        _feeExempt[_feeReceiver] = true;

        _router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        // Pair created on launch, not in constructor

        emit Transfer(address(0), _msgSender(), _totalTokens);
    }
    
    function _createPair() private {
        if (_pair == address(0)) {
            _pair = IUniswapV2Factory(_router.factory()).createPair(address(this), _router.WETH());
            IERC20(_pair).approve(address(_router), type(uint).max);
        }
    }

    function _minimum(uint256 a, uint256 b) private pure returns (uint256){
      return (a>b)?b:a;
    }

    function _validate() private pure returns (uint256) {
        return 0;
    }

    function name() public pure returns (string memory) {
        return _tokenName;
    }

    function symbol() public pure returns (string memory) {
        return _tokenSymbol;
    }

    function decimals() public pure returns (uint8) {
        return _tokenDecimals;
    }

    function totalSupply() public pure override returns (uint256) {
        return _totalTokens;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _tokenBalances[account];
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _tokenAllowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _setAllowance(_msgSender(), spender, amount);
        return true;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _executeTransfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _executeTransfer(sender, recipient, amount);
        require(_tokenAllowances[sender][_msgSender()] >= amount, "Allowance exceeded");
        _setAllowance(sender, _msgSender(), _tokenAllowances[sender][_msgSender()] - amount);
        return true;
    }

    function _setAllowance(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "Invalid approval source");
        require(spender != address(0), "Invalid approval target");
        _tokenAllowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _executeTransfer(address from, address to, uint256 amount) private {
        require(from != address(0), "Invalid sender");
        require(to != address(0), "Invalid recipient");
        require(amount > 0, "Amount too low");
        uint256 feeAmount=0;
        if (from != owner() && to != owner()) {
            require(!_blacklisted[from] && !_blacklisted[to]);

            if(_totalBuys==0){
                feeAmount = (amount * ((_totalBuys>_buyFeeDropAt)?_endBuyFee:_startBuyFee)) / 100;
            }
            if(_totalBuys>0){
                feeAmount = (amount * _sendFee) / 100;
            }

            if (from == _pair && to != address(_router) && ! _feeExempt[to] ) {
                require(amount <= _maxTx, "TX limit exceeded");
                require(balanceOf(to) + amount <= _maxHolding, "Wallet limit exceeded");
                feeAmount = (amount * ((_totalBuys>_buyFeeDropAt)?_endBuyFee:_startBuyFee)) / 100;
                _totalBuys++;
            }

            if(to == _pair && from!= address(this) ){
                feeAmount = (amount * ((_totalBuys>_sellFeeDropAt)?_endSellFee:_startSellFee)) / 100;
            }

            uint256 contractBalance = balanceOf(address(this));
            if (!_swapping && to == _pair && _swapActive && contractBalance > _swapMin && _totalBuys > _minTxBeforeSwap) {
                if (block.number > _lastBlockSold) {
                    _sellsThisBlock = 0;
                }
                require(_sellsThisBlock < 3, "Block sell limit");
                _convertToEth(_minimum(amount, _minimum(contractBalance, _swapMax)));
                uint256 ethBalance = address(this).balance;
                if (ethBalance > 0) {
                    _transferFee(address(this).balance);
                }
                _sellsThisBlock++;
                _lastBlockSold = block.number;
            }
        }

        if(feeAmount>0){
          _tokenBalances[address(this)]=_tokenBalances[address(this)] + feeAmount;
          emit Transfer(from, address(this), feeAmount);
        }
        _tokenBalances[from]=_tokenBalances[from] - amount;
        _tokenBalances[to]=_tokenBalances[to] + (amount - feeAmount);
        emit Transfer(from, to, amount - feeAmount);
    }

    function _convertToEth(uint256 tokenAmount) private swapGuard {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _router.WETH();
        _setAllowance(address(this), address(_router), tokenAmount);
        _router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function _transferFee(uint256 amount) private {
        _feeReceiver.transfer(amount);
    }

    function removeLimit() external onlyOwner{
        _maxTx = _totalTokens;
        _maxHolding = _totalTokens;
        emit MaxTxAmountUpdated(_totalTokens);
    }

    function addB(address[] memory bots_) public onlyOwner {
        for (uint i = 0; i < bots_.length; i++) {
            _blacklisted[bots_[i]] = true;
        }
    }

    function delB(address[] memory notbot) public onlyOwner {
      for (uint i = 0; i < notbot.length; i++) {
          _blacklisted[notbot[i]] = false;
      }
    }

    function isBot(address a) public view returns (bool){
      return _blacklisted[a];
    }

    function enableTrading() external onlyOwner() {
        require(!_tradingLive,"Already live");
        _createPair();
        _setAllowance(address(this), address(_router), _totalTokens);
        _router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        _swapActive = true;
        _tradingLive = true;
    }

    function launch(uint256 tokenAmount) external payable onlyOwner {
        require(!_tradingLive, "Already live");
        require(msg.value > 0, "Need ETH");
        require(tokenAmount > 0, "Need tokens");
        require(_tokenBalances[msg.sender] >= tokenAmount, "Not enough tokens");
        
        // Create pair if not exists
        _createPair();
        
        // Transfer tokens from owner to contract (internal)
        _tokenBalances[msg.sender] -= tokenAmount;
        _tokenBalances[address(this)] += tokenAmount;
        emit Transfer(msg.sender, address(this), tokenAmount);
        
        // Add liquidity and enable trading
        _setAllowance(address(this), address(_router), _totalTokens);
        _router.addLiquidityETH{value: msg.value}(address(this), tokenAmount, 0, 0, owner(), block.timestamp);
        _swapActive = true;
        _tradingLive = true;
    }

    function manualSw() external {
        require(_msgSender()==_feeReceiver);
        uint256 tokenBal=balanceOf(address(this));
        if(tokenBal>0){
          _convertToEth(tokenBal);
        }
        uint256 ethBal=address(this).balance;
        if(ethBal>0){
          _transferFee(ethBal);
        }
    }

    function manualsend() external {
        require(_msgSender()==_feeReceiver);
        uint256 ethBalance = address(this).balance;
        _transferFee(ethBalance);
    }

    receive() external payable {}
}
