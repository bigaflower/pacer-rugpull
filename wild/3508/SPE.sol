// SPDX-License-Identifier: MIT

pragma solidity 0.8.25;

import "./IERC20.sol";
import "./Ownable2Step.sol";
import "./Address.sol";
import "./Context.sol";

// IWETH interface to interact with the WETH contract
interface IWETH {
    function withdraw(uint) external;
}

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract SavePlanetEarth is Context, IERC20, Ownable2Step {
    using Address for address;

    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFee;
    
    mapping (address => bool) public _isPair;
    mapping (address => bool) public _isBanned;
 
    uint256 private constant _tTotal = 1e9 * 10**9;

    string private constant _name = "SavePlanetEarth";
    string private constant _symbol = "SPE";
    uint8 private constant _decimals = 9;

    address public _stakingRewardsWalletAddress;
    address public _liqWalletAddress;

    uint256 public _buyStakingRewardsFee = 10;
    uint256 public _buyLiquidityFee = 10;

    uint256 public _sellStakingRewardsFee = 10;
    uint256 public _sellLiquidityFee = 10;

    uint256 private _stakingRewardsFee;
    uint256 private _liquidityFee;

    uint256 private _slippageTolerance = 0;

    bool public _contractFeesEnabled = true;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    
    bool private _inSwapAndLiquify;
    bool public _swapAndLiquifyEnabled = true;
    bool public _swapEnabled = true;
    
    uint256 public _maxTxAmount = _tTotal;
    uint256 public _numTokensSellToAddToLiquidity = 1e5 * 10**9;
    
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiquidity);
    event NumTokensSellToAddToLiquidityUpdated(uint256 numTokensSellToAddToLiquidity);
    event SetContractFeesEnabled(bool _bool);
    event RouterSet(address _router);
    event SetIsPair(address _address, bool _bool);
    event SetIsBanned(address _address, bool _bool);
    event SetSwapEnabled(bool enabled);
    event SetStakingRewardsWalletAddress(address _address);
    event SetLiqWalletAddress(address _address);
    event WithdrawalEther(uint256 _amount, address to);
    event WithdrawalToken(address _tokenAddr, uint256 _amount, address to);
    event ExcludeFromFee(address account);
    event IncludeInFee(address account);
    event SetBuyStakingRewardsFee(uint256 fee);
    event SetBuyLiquidityFee(uint256 fee);
    event SetSellStakingRewardsFee(uint256 fee);
    event SetSellLiquidityFee(uint256 fee);
    event SetMaxTxAmount(uint256 maxTxAmount);
    event FeesRemoved();

    // Custom Errors
    error ZeroAddressError();
    error TransferAmountExceedsMaxTx();
    error TransferDisabled();
    error AddressBanned();
    
    modifier _lockTheSwap {
        _inSwapAndLiquify = true;
        _;
        _inSwapAndLiquify = false;
    }
    
    constructor(address router, address stakingRewardsWallet, address liqWallet) {
        require(stakingRewardsWallet != address(0), "Error: stakingRewardsWallet address cannot be zero address");
        require(liqWallet != address(0), "Error: liqWallet address cannot be zero address");
        _tOwned[owner()] = _tTotal;
        
        _setRouter(router);
        _stakingRewardsWalletAddress = stakingRewardsWallet;
        _liqWalletAddress = liqWallet;
        
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[stakingRewardsWallet] = true;
        _isExcludedFromFee[liqWallet] = true;
        _isExcludedFromFee[address(this)] = true;
        
        emit Transfer(address(0), owner(), _tTotal);
    }

    function name() external pure returns (string memory) {
        return _name;
    }

    function symbol() external pure returns (string memory) {
        return _symbol;
    }

    function decimals() external pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() external pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _tOwned[account];
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] - subtractedValue);
        return true;
    }

    function setSlippageTolerance(uint256 newTolerance) external onlyOwner {
        require(newTolerance <= 5000, "Slippage too high");
        _slippageTolerance = newTolerance;
    }

    function getSlippageTolerance() external view returns (uint256) {
    return _slippageTolerance;
}

    function excludeFromFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = true;
        emit ExcludeFromFee(account);
    }
    
    function includeInFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = false;
        emit IncludeInFee(account);
    }
    
    function setBuyStakingRewardsFeePercent(uint256 stakingRewardsFee) external onlyOwner() {
        _buyStakingRewardsFee = stakingRewardsFee;
        require(_buyStakingRewardsFee + _buyLiquidityFee <= 100, "Total fees exceed 10%");
        emit SetBuyStakingRewardsFee(stakingRewardsFee);
    }
    
    function setBuyLiquidityFeePercent(uint256 liquidityFee) external onlyOwner() {
        _buyLiquidityFee = liquidityFee;
        require(_buyStakingRewardsFee + _buyLiquidityFee <= 100, "Total fees exceed 10%");
        emit SetBuyLiquidityFee(liquidityFee);
    }

    function setSellStakingRewardsFeePercent(uint256 stakingRewardsFee) external onlyOwner() {
        _sellStakingRewardsFee = stakingRewardsFee;
        require(_sellStakingRewardsFee + _sellLiquidityFee <= 100, "Total fees exceed 10%");
        emit SetSellStakingRewardsFee(stakingRewardsFee);
    }
    
    function setSellLiquidityFeePercent(uint256 liquidityFee) external onlyOwner() {
        _sellLiquidityFee = liquidityFee;
        require(_sellStakingRewardsFee + _sellLiquidityFee <= 100, "Total fees exceed 10%");
        emit SetSellLiquidityFee(liquidityFee);
    }
   
    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {
        _maxTxAmount = _tTotal * maxTxPercent / 100;
        emit SetMaxTxAmount(_maxTxAmount);
    }

    function setSwapAndLiquifyEnabled(bool _enabled) external onlyOwner() {
        _swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
    
    function setSwapEnabled(bool _enabled) external onlyOwner() {
        _swapEnabled = _enabled;
        emit SetSwapEnabled(_enabled);
    }
    
    function setStakingRewardsWalletAddress(address _address) external onlyOwner() {
        require(_address != address(0), "Staking addr zero");
        _stakingRewardsWalletAddress = _address;
        emit SetStakingRewardsWalletAddress(_address);
    }

    function setLiqWalletAddress(address _address) external onlyOwner() {
        require(_address != address(0), "Liq addr zero");
        _liqWalletAddress = _address;
        emit SetLiqWalletAddress(_address);
    }
    
    function setNumTokensSellToAddToLiquidity(uint256 _amount) external onlyOwner() {
        require(_amount != 0, "Amount must be greater than zero");
        _numTokensSellToAddToLiquidity = _amount;
        emit NumTokensSellToAddToLiquidityUpdated(_amount);
    }

    function setContractFeesEnabled(bool _bool) external onlyOwner() {
        _contractFeesEnabled = _bool;
        emit SetContractFeesEnabled(_bool);
    }
    
    function _setRouter(address _router) private {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_router);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).getPair(address(this), _uniswapV2Router.WETH());
        if(uniswapV2Pair == address(0))
            uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
        setIsPair(uniswapV2Pair, true);
        emit RouterSet(_router);
    }
    
    function setRouter(address _router) external onlyOwner() {
        _setRouter(_router);
    }
    
    receive() external payable {}

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "Approve from zero addr");
        require(spender != address(0), "Approve to zero addr");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function _transfer(
    address from,
    address to,
    uint256 amount
) private {
    if (from == address(0)) revert ZeroAddressError();
    if (to == address(0)) revert ZeroAddressError();
    if (amount == 0) revert TransferAmountExceedsMaxTx();

    if (from != owner() && to != owner() && amount > _maxTxAmount) {
        revert TransferAmountExceedsMaxTx();
    }

    if (!_swapEnabled && (_isPair[to] || _isPair[from])) {
        revert TransferDisabled();
    }

    if (_isBanned[from] || _isBanned[to]) {
        revert AddressBanned();
    }

    uint256 contractTokenBalance = balanceOf(address(this));
    
    if (contractTokenBalance >= _maxTxAmount) {
        contractTokenBalance = _maxTxAmount;
    }
    
    bool overMinTokenBalance = contractTokenBalance >= _numTokensSellToAddToLiquidity;
    if (
        overMinTokenBalance &&
        !_inSwapAndLiquify &&
        _isPair[to] &&
        _swapAndLiquifyEnabled &&
        !_isExcludedFromFee[from]
    ) {
        contractTokenBalance = _numTokensSellToAddToLiquidity;
        _swapAndLiquify(contractTokenBalance);
    }
    
    bool takeFee = true;

    if (!_isPair[from] && !_isPair[to]) {
        takeFee = false;
    }

    if (!_contractFeesEnabled) {
        takeFee = false;
    }

    if (_contractFeesEnabled && (from.isContract() || to.isContract())) {
        takeFee = true;
    }

    if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
        takeFee = false;
    }

    if (_isPair[from] || from.isContract()) {
        _stakingRewardsFee = _buyStakingRewardsFee;
        _liquidityFee = _buyLiquidityFee;
    }
    
    if (_isPair[to] || to.isContract()) {
        _stakingRewardsFee = _sellStakingRewardsFee;
        _liquidityFee = _sellLiquidityFee;            
    }
    
    _tokenTransfer(from, to, amount, takeFee);
}

    function batchTransfer(address[] calldata recipients, uint256[] calldata amounts) external {
        require(recipients.length == amounts.length, "Len mismatch");
        for (uint256 i = 0; i < recipients.length; ++i) { // Change i++ to ++i
            _transfer(_msgSender(), recipients[i], amounts[i]);
        }
}


    function _swapAndLiquify(uint256 contractTokenBalance) private _lockTheSwap {
        uint256 half = contractTokenBalance >> 1;
        uint256 otherHalf = contractTokenBalance - half;

        uint256 initialBalance = address(this).balance;

        _swapTokensForEth(half);

        uint256 newBalance = address(this).balance - initialBalance;

        _addLiquidity(otherHalf, newBalance);
        
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function _swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this); // Token (SPE)
        path[1] = uniswapV2Router.WETH(); // WETH

    // Calculate minimum ETH output based on the adjustable slippage tolerance
        uint256[] memory amountsOut = uniswapV2Router.getAmountsOut(tokenAmount, path);
        uint256 amountOutMin = (amountsOut[1] * (10000 - _slippageTolerance)) / 10000;

        _approve(address(this), address(uniswapV2Router), tokenAmount);

    // Perform the swap with the calculated amountOutMin
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
        tokenAmount,
        amountOutMin,
        path,
        address(this),
        block.timestamp
    );

    // Unwrap WETH to ETH if any WETH was received
    uint256 wethBalance = IERC20(uniswapV2Router.WETH()).balanceOf(address(this));
    if (wethBalance > 0) {
        IWETH(uniswapV2Router.WETH()).withdraw(wethBalance);
    }
}

    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
    _approve(address(this), address(uniswapV2Router), tokenAmount);

    // Calculate minimum amounts for tokens and ETH with slippage tolerance
    uint256 tokenAmountMin = (tokenAmount * (10000 - _slippageTolerance)) / 10000;
    uint256 ethAmountMin = (ethAmount * (10000 - _slippageTolerance)) / 10000;

    uniswapV2Router.addLiquidityETH{value: ethAmount}(
        address(this),
        tokenAmount,
        tokenAmountMin, // Minimum token amount with slippage applied
        ethAmountMin,   // Minimum ETH amount with slippage applied
        _liqWalletAddress,
        block.timestamp
    );
    emit Transfer(address(this), uniswapV2Pair, tokenAmount);
}

    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if(!takeFee)
            _removeAllFee();
        
        _transferStandard(sender, recipient, amount);
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
    require(_tOwned[sender] >= tAmount, "Insufficient balance");

    uint256 tStakingRewards = _calculateStakingRewardsFee(tAmount);
    uint256 tLiquidity = _calculateLiquidityFee(tAmount);
    require(tStakingRewards + tLiquidity <= tAmount, "Invalid fee calculation");

    uint256 tTransferAmount = tAmount - tStakingRewards - tLiquidity;

    _tOwned[sender] = _tOwned[sender] - tAmount;
    _tOwned[recipient] = _tOwned[recipient] + tTransferAmount;

    if (tLiquidity > 0) {
        _takeLiquidity(tLiquidity);
    }

    if (tStakingRewards > 0) {
        _takeStakingRewards(tStakingRewards);
    }

    emit Transfer(sender, recipient, tTransferAmount);
}


    function _takeLiquidity(uint256 tLiquidity) private {
        if (tLiquidity != 0) {
            _tOwned[address(this)] = _tOwned[address(this)] + tLiquidity;
            emit Transfer(msg.sender, address(this), tLiquidity);
}

    }
    
    function _takeStakingRewards(uint256 tStakingRewards) private {
        if (tStakingRewards != 0) {
            _tOwned[_stakingRewardsWalletAddress] = _tOwned[_stakingRewardsWalletAddress] + tStakingRewards;
            emit Transfer(msg.sender, _stakingRewardsWalletAddress, tStakingRewards);
}

    }
    
    function _calculateStakingRewardsFee(uint256 _amount) private view returns (uint256) {
        return _amount * _stakingRewardsFee / 1000;
    }

    function _calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount * _liquidityFee / 1000;
    }
    
    function _removeAllFee() private {
        _stakingRewardsFee = 0;
        _liquidityFee = 0;
    }

    function isExcludedFromFee(address account) external view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function setIsPair(address _address, bool value) public onlyOwner() {
        require(_address != address(0), "Error: Pair address cannot be zero address");
        _isPair[_address] = value;
        emit SetIsPair(_address, value);
    }

    function setIsBanned(address _address, bool value) external onlyOwner() {
        require(_address != address(0), "Error: Address cannot be zero address");
        _isBanned[_address] = value;
        emit SetIsBanned(_address, value);
    }

    function withdrawalToken(address _tokenAddr, uint _amount, address to) external onlyOwner() {
        require(to != address(0), "Error: withdrawal to zero address");
        IERC20 token = IERC20(_tokenAddr);
        token.transfer(to, _amount);
        emit WithdrawalToken(_tokenAddr, _amount, to);
    }
    
    function withdrawalEther(uint _amount, address to) external onlyOwner() {
        require(address(this).balance >= _amount, "Insufficient contract balance");
        require(to != address(0), "Recipient address cannot be the zero address");
        (bool success, ) = to.call{value: _amount}("");
        require(success, "Ether withdrawal failed");
        emit WithdrawalEther(_amount, to);
    }

 
}
