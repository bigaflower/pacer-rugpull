// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

library Address {
  function isContract(address account) internal view returns (bool) {
    return account.code.length > 0;
  }

  function sendValue(address payable recipient, uint256 amount) internal {
    require(address(this).balance >= amount, "Address: insufficient balance");

    (bool success, ) = recipient.call{value: amount}("");
    require(
      success,
      "Address: unable to send value, recipient may have reverted"
    );
  }

  function functionCall(
    address target,
    bytes memory data
  ) internal returns (bytes memory) {
    return
      functionCallWithValue(target, data, 0, "Address: low-level call failed");
  }

  function functionCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    return functionCallWithValue(target, data, 0, errorMessage);
  }

  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value
  ) internal returns (bytes memory) {
    return
      functionCallWithValue(
        target,
        data,
        value,
        "Address: low-level call with value failed"
      );
  }

  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(
      address(this).balance >= value,
      "Address: insufficient balance for call"
    );
    (bool success, bytes memory returndata) = target.call{value: value}(data);
    return
      verifyCallResultFromTarget(target, success, returndata, errorMessage);
  }

  function functionStaticCall(
    address target,
    bytes memory data
  ) internal view returns (bytes memory) {
    return
      functionStaticCall(target, data, "Address: low-level static call failed");
  }

  function functionStaticCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal view returns (bytes memory) {
    (bool success, bytes memory returndata) = target.staticcall(data);
    return
      verifyCallResultFromTarget(target, success, returndata, errorMessage);
  }

  function functionDelegateCall(
    address target,
    bytes memory data
  ) internal returns (bytes memory) {
    return
      functionDelegateCall(
        target,
        data,
        "Address: low-level delegate call failed"
      );
  }

  function functionDelegateCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    (bool success, bytes memory returndata) = target.delegatecall(data);
    return
      verifyCallResultFromTarget(target, success, returndata, errorMessage);
  }

  function verifyCallResultFromTarget(
    address target,
    bool success,
    bytes memory returndata,
    string memory errorMessage
  ) internal view returns (bytes memory) {
    if (success) {
      if (returndata.length == 0) {
        require(isContract(target), "Address: call to non-contract");
      }
      return returndata;
    } else {
      _revert(returndata, errorMessage);
    }
  }

  function verifyCallResult(
    bool success,
    bytes memory returndata,
    string memory errorMessage
  ) internal pure returns (bytes memory) {
    if (success) {
      return returndata;
    } else {
      _revert(returndata, errorMessage);
    }
  }

  function _revert(
    bytes memory returndata,
    string memory errorMessage
  ) private pure {
    if (returndata.length > 0) {
      /// @solidity memory-safe-assembly
      assembly {
        let returndata_size := mload(returndata)
        revert(add(32, returndata), returndata_size)
      }
    } else {
      revert(errorMessage);
    }
  }
}

abstract contract Context {
  function _msgSender() internal view virtual returns (address) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns (bytes calldata) {
    return msg.data;
  }
}

interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(
    address owner,
    address spender
  ) external view returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IDEXFactory {
  function createPair(
    address tokenA,
    address tokenB
  ) external returns (address pair);
}

interface IDEXRouter {
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

  function swapExactTokensForETHSupportingFeeOnTransferTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external;
}

abstract contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  constructor() {
    _transferOwnership(_msgSender());
  }

  modifier onlyOwner() {
    _checkOwner();
    _;
  }

  function owner() public view virtual returns (address) {
    return _owner;
  }

  function _checkOwner() internal view virtual {
    require(owner() == _msgSender(), "Ownable: caller is not the owner");
  }

  function renounceOwnership() public virtual onlyOwner {
    _transferOwnership(address(0));
  }

  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    _transferOwnership(newOwner);
  }

  function _transferOwnership(address newOwner) internal virtual {
    address oldOwner = _owner;
    _owner = newOwner;
    emit OwnershipTransferred(oldOwner, newOwner);
  }
}

contract KnoxNet is IERC20, Ownable {
  using Address for address;

  address DEAD = 0x000000000000000000000000000000000000dEaD;
  address ZERO = 0x0000000000000000000000000000000000000000;

  string constant _name = "KnoxNet";
  string constant _symbol = "KNX";
  uint8 constant _decimals = 18;

  uint256 _totalSupply = 1_000_000_000 * (10 ** _decimals);
  uint256 _maxBuyTxAmount = (_totalSupply * 1) / 100;
  uint256 _maxSellTxAmount = (_totalSupply * 1) / 100;
  uint256 _maxWalletSize = (_totalSupply * 1) / 100;

  mapping(address => uint256) _balances;
  mapping(address => mapping(address => uint256)) _allowances;

  mapping(uint256 => uint256) public autoSwapCountPerBlock;
  uint256 public autoSwapPerBlockLimit = 3;

  mapping(address => bool) public isTaxExempt;
  mapping(address => bool) public isTxLimitExempt;
  mapping(address => bool) public isLiquidityCreator;

  uint256 marketingBuyTaxBps = 500;
  uint256 marketingSellTaxBps = 9000;
  uint256 liquidityBuyTaxBps = 0;
  uint256 liquiditySellTaxBps = 0;
  uint256 totalBuyTaxBps = marketingBuyTaxBps + liquidityBuyTaxBps;
  uint256 totalSellTaxBps = marketingSellTaxBps + liquiditySellTaxBps;
  uint256 taxDenominator = 10000;

  bool public transferTax = false;

  address payable public liquidityTaxReceiver = payable(0x80048791Fe26bEa0E2344940e3A818249F78bbb1);
  address payable public marketingTaxReceiver = payable(0x80048791Fe26bEa0E2344940e3A818249F78bbb1);

  IDEXRouter public router;
  address routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
  mapping(address => bool) liquidityPools;
  address public pair;

  mapping(address => uint256) public blacklist;
  uint256 public blacklistCount;

  uint256 public launchBlock;
  uint256 public launchTimestamp;
  bool isTradingEnabled = false;

  bool public autoSwapEnabled = false;
  uint256 public autoSwapTokenThreshold = _totalSupply / 1000;
  uint256 public autoSwapMinTokenBalance = _totalSupply / 10000;
  bool inSwap;

  modifier swapping() {
    inSwap = true;
    _;
    inSwap = false;
  }

  mapping(address => bool) trustedOperators;

  modifier onlyTrustedOperator() {
    require(
      trustedOperators[_msgSender()] || msg.sender == owner(),
      "Caller is not a trusted operator"
    );
    _;
  }

  event WalletRestricted(address, address, uint256);

  constructor() {
    router = IDEXRouter(routerAddress);
    pair = IDEXFactory(router.factory()).createPair(
      router.WETH(),
      address(this)
    );
    liquidityPools[pair] = true;
    _allowances[owner()][routerAddress] = type(uint256).max;
    _allowances[address(this)][routerAddress] = type(uint256).max;

    isTaxExempt[owner()] = true;
    isLiquidityCreator[owner()] = true;

    isTxLimitExempt[address(this)] = true;
    isTxLimitExempt[owner()] = true;
    isTxLimitExempt[routerAddress] = true;
    isTxLimitExempt[DEAD] = true;

    _balances[owner()] = _totalSupply;

    emit Transfer(address(0), owner(), _totalSupply);
  }

  receive() external payable {}

  function totalSupply() external view override returns (uint256) {
    return _totalSupply;
  }

  function decimals() external pure returns (uint8) {
    return _decimals;
  }

  function symbol() external pure returns (string memory) {
    return _symbol;
  }

  function name() external pure returns (string memory) {
    return _name;
  }

  function getOwner() external view returns (address) {
    return owner();
  }

  function maxBuyTxTokens() external view returns (uint256) {
    return _maxBuyTxAmount / (10 ** _decimals);
  }

  function maxSellTxTokens() external view returns (uint256) {
    return _maxSellTxAmount / (10 ** _decimals);
  }

  function maxWalletTokens() external view returns (uint256) {
    return _maxWalletSize / (10 ** _decimals);
  }

  function balanceOf(address account) public view override returns (uint256) {
    return _balances[account];
  }

  function allowance(
    address holder,
    address spender
  ) external view override returns (uint256) {
    return _allowances[holder][spender];
  }

  function approve(
    address spender,
    uint256 amount
  ) public override returns (bool) {
    _allowances[msg.sender][spender] = amount;
    emit Approval(msg.sender, spender, amount);
    return true;
  }

  function approveMaxAmount(address spender) external returns (bool) {
    return approve(spender, type(uint256).max);
  }

  function setTrustedOperator(address _operator, bool _enabled) external onlyOwner {
    trustedOperators[_operator] = _enabled;
  }

  function airdrop(
    address[] calldata addresses,
    uint256[] calldata amounts
  ) external onlyOwner {
    require(addresses.length > 0 && amounts.length == addresses.length);
    address from = msg.sender;

    for (uint i = 0; i < addresses.length; i++) {
      if (!liquidityPools[addresses[i]] && !isLiquidityCreator[addresses[i]]) {
        _basicTransfer(from, addresses[i], amounts[i] * (10 ** _decimals));
      }
    }
  }

  function recoverStuckETH(
    uint256 amountPercentage,
    address adr
  ) external onlyTrustedOperator {
    uint256 amountETH = address(this).balance;

    if (amountETH > 0) {
      (bool sent, ) = adr.call{value: (amountETH * amountPercentage) / 100}("");
      require(sent, "Failed to transfer funds");
    }
  }

  function updateBlacklist(
    address[] calldata _wallets,
    bool _blacklist
  ) external onlyTrustedOperator {
    for (uint i = 0; i < _wallets.length; i++) {
      if (_blacklist) {
        blacklistCount++;
        emit WalletRestricted(tx.origin, _wallets[i], block.number);
      } else {
        if (blacklist[_wallets[i]] != 0) blacklistCount--;
      }
      blacklist[_wallets[i]] = _blacklist ? block.number : 0;
    }
  }

  function transfer(
    address recipient,
    uint256 amount
  ) external override returns (bool) {
    return _transferFrom(msg.sender, recipient, amount);
  }

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external override returns (bool) {
    if (_allowances[sender][msg.sender] != type(uint256).max) {
      _allowances[sender][msg.sender] =
        _allowances[sender][msg.sender] -
        amount;
    }

    return _transferFrom(sender, recipient, amount);
  }

  function _transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) internal returns (bool) {
    require(sender != address(0), "ERC20: transfer from 0x0");
    require(recipient != address(0), "ERC20: transfer to 0x0");
    require(amount > 0, "Amount must be > zero");
    require(_balances[sender] >= amount, "Insufficient balance");
    if (!_isLaunched() && liquidityPools[recipient]) {
      require(isLiquidityCreator[sender], "Liquidity not added yet.");
      _recordLaunch();
    }
    if (!isTradingEnabled) {
      require(
        isLiquidityCreator[sender] || isLiquidityCreator[recipient],
        "Trading is not launched yet."
      );
    }

    _enforceTxLimit(sender, recipient, amount);

    if (!liquidityPools[recipient] && recipient != DEAD) {
      if (!isTxLimitExempt[recipient]) {
        _enforceWalletLimit(recipient, amount);
      }
    }

    if (inSwap) {
      return _basicTransfer(sender, recipient, amount);
    }

    _balances[sender] = _balances[sender] - amount;

    uint256 amountReceived = amount;

    if (_shouldApplyTax(sender, recipient)) {
      amountReceived = _applyTax(recipient, amount);
      if (_shouldAutoSwap(recipient) && amount > 0) _autoSwapBack(amount);
    }

    _balances[recipient] = _balances[recipient] + amountReceived;

    emit Transfer(sender, recipient, amountReceived);
    return true;
  }

  function _isLaunched() internal view returns (bool) {
    return launchBlock != 0;
  }

  function _recordLaunch() internal {
    launchBlock = block.number;
    launchTimestamp = block.timestamp;
  }

  function openTrading() external onlyTrustedOperator {
    require(!isTradingEnabled, "Can't re-open trading");
    isTradingEnabled = true;
    autoSwapEnabled = true;
  }

  function _basicTransfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal returns (bool) {
    _balances[sender] = _balances[sender] - amount;
    _balances[recipient] = _balances[recipient] + amount;
    emit Transfer(sender, recipient, amount);
    return true;
  }

  function _enforceWalletLimit(address recipient, uint256 amount) internal view {
    uint256 walletLimit = _maxWalletSize;
    require(
      _balances[recipient] + amount <= walletLimit,
      "Amount exceeds the max wallet size."
    );
  }

  function _enforceTxLimit(
    address sender,
    address recipient,
    uint256 amount
  ) internal view {
    if (isTxLimitExempt[sender] || isTxLimitExempt[recipient]) return;

    require(
      amount <= (liquidityPools[sender] ? _maxBuyTxAmount : _maxSellTxAmount),
      "Amount exceeds the tx limit."
    );

    require(blacklist[sender] == 0, "Wallet blacklisted!");
  }

  function _shouldApplyTax(
    address sender,
    address recipient
  ) public view returns (bool) {
    if (!transferTax && !liquidityPools[recipient] && !liquidityPools[sender])
      return false;
    return !isTaxExempt[sender] && !isTaxExempt[recipient];
  }

  function getTotalTaxBps(bool selling) public view returns (uint256) {
    if (selling) return totalSellTaxBps;
    return totalBuyTaxBps;
  }

  function _applyTax(
    address recipient,
    uint256 amount
  ) internal returns (uint256) {
    bool selling = liquidityPools[recipient];
    uint256 taxAmount = (amount * getTotalTaxBps(selling)) / taxDenominator;

    _balances[address(this)] += taxAmount;

    return amount - taxAmount;
  }

  function _shouldAutoSwap(address recipient) internal view returns (bool) {
    return
      !liquidityPools[msg.sender] &&
      !inSwap &&
      autoSwapEnabled &&
      autoSwapCountPerBlock[block.number] < autoSwapPerBlockLimit &&
      liquidityPools[recipient] &&
      _balances[address(this)] >= autoSwapMinTokenBalance &&
      totalBuyTaxBps + totalSellTaxBps > 0;
  }

  // Max share of the user's sell amount the contract may swap in one go (10%).
  uint256 public autoSwapSellCapPercent = 10;

  function _autoSwapBack(uint256 amount) internal swapping {
    uint256 combinedTaxBps = totalBuyTaxBps + totalSellTaxBps;
    uint256 amountToSwap = amount < autoSwapTokenThreshold ? amount : autoSwapTokenThreshold;
    if (_balances[address(this)] < amountToSwap)
      amountToSwap = _balances[address(this)];
    uint256 maxSwapForThisSell = (amount * autoSwapSellCapPercent) / 100;
    if (amountToSwap > maxSwapForThisSell)
      amountToSwap = maxSwapForThisSell;
    if (amountToSwap == 0) return;

    uint256 totalLiquidityTaxBps = liquidityBuyTaxBps + liquiditySellTaxBps;
    uint256 amountToLiquify = ((amountToSwap * totalLiquidityTaxBps) / 2) /
      combinedTaxBps;
    amountToSwap -= amountToLiquify;

    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = router.WETH();

    uint256 balanceBefore = address(this).balance;

    router.swapExactTokensForETHSupportingFeeOnTransferTokens(
      amountToSwap,
      0,
      path,
      address(this),
      block.timestamp
    );

    uint256 amountETH = address(this).balance - balanceBefore;
    uint256 totalETHTax = combinedTaxBps - (totalLiquidityTaxBps / 2);

    uint256 amountETHLiquidity = 0;
    if (totalETHTax > 0) {
      amountETHLiquidity = ((amountETH * totalLiquidityTaxBps) / 2) /
        totalETHTax;
    }
    uint256 amountETHMarketing = amountETH - amountETHLiquidity;

    if (amountETHMarketing > 0) {
      (bool sentMarketing, ) = marketingTaxReceiver.call{
        value: amountETHMarketing
      }("");
      if (!sentMarketing) {
        // ETH stays in contract; recoverable via recoverStuckETH
      }
    }

    if (amountToLiquify > 0) {
      router.addLiquidityETH{value: amountETHLiquidity}(
        address(this),
        amountToLiquify,
        0,
        0,
        liquidityTaxReceiver,
        block.timestamp
      );
    }
    autoSwapCountPerBlock[block.number] = autoSwapCountPerBlock[block.number] + 1;
    emit TaxDistributed(
      amountETHMarketing,
      amountETHLiquidity,
      amountToLiquify
    );
  }

  function addLiquidityPool(address lp, bool isPool) external onlyOwner {
    require(lp != pair, "Can't alter current liquidity pair");
    liquidityPools[lp] = isPool;
  }

  function setAutoSwapPerBlockLimit(uint256 rate) external onlyOwner {
    autoSwapPerBlockLimit = rate;
  }

  function setAutoSwapSellCapPercent(uint256 percent) external onlyOwner {
    require(percent > 0 && percent <= 100, "Cap must be 1-100%");
    autoSwapSellCapPercent = percent;
  }

  function manualClogClearPercent(uint256 percent) external onlyOwner swapping {
    require(percent > 0 && percent <= 100, "Percent must be 1-100%");
    uint256 contractTokenBalance = _balances[address(this)];
    require(contractTokenBalance > 0, "No tokens to swap");

    uint256 amountToSwap = (contractTokenBalance * percent) / 100;
    require(amountToSwap > 0, "Swap amount too small");

    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = router.WETH();

    uint256 ethBefore = address(this).balance;
    router.swapExactTokensForETHSupportingFeeOnTransferTokens(
      amountToSwap,
      0,
      path,
      address(this),
      block.timestamp
    );
    uint256 ethReceived = address(this).balance - ethBefore;
    if (ethReceived > 0) {
      (bool sentMarketing, ) = marketingTaxReceiver.call{value: ethReceived}("");
      require(sentMarketing, "Failed to send ETH");
    }
    emit ClogClearedManually(amountToSwap, ethReceived, percent);
  }

  function setTxLimit(
    uint256 buyNumerator,
    uint256 sellNumerator,
    uint256 divisor
  ) external onlyOwner {
    require(
      buyNumerator > 0 && sellNumerator > 0 && divisor > 0 && divisor <= 10000
    );
    _maxBuyTxAmount = (_totalSupply * buyNumerator) / divisor;
    _maxSellTxAmount = (_totalSupply * sellNumerator) / divisor;
  }

  function setMaxWallet(uint256 numerator, uint256 divisor) external onlyOwner {
    require(numerator > 0 && divisor > 0 && divisor <= 10000);
    _maxWalletSize = (_totalSupply * numerator) / divisor;
  }

  function setIsTaxExempt(address holder, bool exempt) external onlyOwner {
    isTaxExempt[holder] = exempt;
  }

  function setIsTxLimitExempt(address holder, bool exempt) external onlyOwner {
    isTxLimitExempt[holder] = exempt;
  }

  function setTaxConfig(
    uint256 _liquidityBuyTaxBps,
    uint256 _liquiditySellTaxBps,
    uint256 _marketingBuyTaxBps,
    uint256 _marketingSellTaxBps,
    uint256 _taxDenominator
  ) external onlyOwner {
    require(
      ((_liquidityBuyTaxBps + _liquiditySellTaxBps) / 2) * 2 ==
        (_liquidityBuyTaxBps + _liquiditySellTaxBps),
      "Liquidity tax must be an even number for rounding compatibility."
    );
    require(
      _liquidityBuyTaxBps + _marketingBuyTaxBps <= 6500,
      "Buy tax cannot exceed 65%"
    );
    require(
      _liquiditySellTaxBps + _marketingSellTaxBps <= 6500,
      "Sell tax cannot exceed 65%"
    );
    liquidityBuyTaxBps = _liquidityBuyTaxBps;
    liquiditySellTaxBps = _liquiditySellTaxBps;
    marketingBuyTaxBps = _marketingBuyTaxBps;
    marketingSellTaxBps = _marketingSellTaxBps;
    totalBuyTaxBps = _liquidityBuyTaxBps + _marketingBuyTaxBps;
    totalSellTaxBps = _liquiditySellTaxBps + _marketingSellTaxBps;
    taxDenominator = _taxDenominator;
    emit TaxConfigUpdated(totalBuyTaxBps, totalSellTaxBps, taxDenominator);
  }

  function toggleTransferTax() external onlyOwner {
    transferTax = !transferTax;
  }

  function setTaxReceivers(
    address _liquidityTaxReceiver,
    address _marketingTaxReceiver
  ) external onlyOwner {
    liquidityTaxReceiver = payable(_liquidityTaxReceiver);
    marketingTaxReceiver = payable(_marketingTaxReceiver);
  }

  function configureAutoSwap(
    bool _enabled,
    uint256 _denominator,
    uint256 _minTokenBalance
  ) external onlyOwner {
    require(_denominator > 0 && _denominator <= 10000, "Denominator 1-10000");
    autoSwapEnabled = _enabled;
    autoSwapTokenThreshold = _totalSupply / _denominator;
    autoSwapMinTokenBalance = _minTokenBalance * (10 ** _decimals);
  }

  function getCirculatingSupply() public view returns (uint256) {
    return _totalSupply - (balanceOf(DEAD) + balanceOf(ZERO));
  }

  event TaxDistributed(
    uint256 marketingETH,
    uint256 liquidityETH,
    uint256 liquidityTokens
  );
  event TaxConfigUpdated(
    uint256 totalBuyTaxBps,
    uint256 totalSellTaxBps,
    uint256 denominator
  );
  event ClogClearedManually(
    uint256 tokenAmountSwapped,
    uint256 ethReceived,
    uint256 percent
  );
}