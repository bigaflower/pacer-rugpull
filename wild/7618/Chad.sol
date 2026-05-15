// SPDX-License-Identifier: MIT
/*

https://t.me/chadonerc

https://x.com/chad_ethereum

https://chadoneth.com/

*/
pragma solidity ^0.8.17;
library SafeMath {
    function tryAdd(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }
    function trySub(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }
    function tryMul(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }
    function tryDiv(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }
    function tryMod(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    string private _symbol;
    string private _name;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }
    function name() public view virtual override returns (string memory) {
        return _name;
    }
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(
        address account
    ) public view virtual override returns (uint256) {
        return _balances[account];
    }
    function transfer(
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(
        address owner,
        address spender
    ) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(
        address spender,
        uint256 amount
    ) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }
        return true;
    }
    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }
    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }
        return true;
    }
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _beforeTokenTransfer(sender, recipient, amount);
        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        _afterTokenTransfer(sender, recipient, amount);
    }
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
        _afterTokenTransfer(address(0), account, amount);
    }
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        _beforeTokenTransfer(account, address(0), amount);
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
        _afterTokenTransfer(account, address(0), amount);
    }
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IDexFactory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );
    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);
    function allPairs(uint256) external view returns (address pair);
    function allPairsLength() external view returns (uint256);
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IDexRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);
    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract Chad is ERC20, Ownable {
    using SafeMath for uint256;
    IDexRouter private immutable dexRouter;
    address private immutable dexPair;
    bool private limitsEnabled = true;
    uint256 private minSwapback;
    bool private tradingEnabled = false;
    uint256 private maxSwapback;
    mapping(address => bool) private transferLimitExempt;
    uint256 private lastSwapback;
    uint256 private maxTx;
    mapping(address => bool) private transferTaxExempt;
    address private marketingWallet;
    mapping(address => uint256) private _holderLastTransferTimestamp;
    uint256 private buyTaxTotal;
    uint256 private maxWallet;
    bool private isSwapbackEnabled = false;
    bool private onSwapback;
    uint256 private sellTaxTotal;
    uint256 private transferTaxTotal;
    mapping(address => bool) private automatedMarketMakerPairs;
    event SwapbackSettingsUpdatedInternal(
        bool enabled,
        uint256 minSwapback,
        uint256 maxSwapback
    );
    event ExcludeFromFeesInternal(address indexed account, bool isExcluded);
    event ConstraintsRemoved(uint256 indexed timestamp);
    event ExcludeFromConstraints(address indexed account, bool isExcluded);
    event DisabledsendDelay(uint256 indexed timestamp);
    event TradingEnabled(uint256 indexed timestamp);
    event handleUpdateUniswapV2Router(
        address indexed newAddress,
        address indexed oldAddress
    );
    event BuyFeeUpdatedCore(
        uint256 buyTaxTotal,
        uint256 buyMarketingTax,
        uint256 buyProjectTax
    );
    event doMaxTxUpdated(uint256 maxTx);
    event safeMarketingWalletUpdated(
        address indexed newWallet,
        address indexed oldWallet
    );
    event safeMaxWalletUpdated(uint256 maxWallet);
    event SellFeeUpdatedCore(
        uint256 sellTaxTotal,
        uint256 sellMarketingTax,
        uint256 sellProjectTax
    );
    event safeSetPairLPool(address indexed pair, bool indexed value);
    constructor() ERC20("Chad", "CHAD") {
        IDexRouter _dexRouter = IDexRouter(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        MaxLimitChangeIsExempt(address(_dexRouter), true);
        dexRouter = _dexRouter;
        dexPair = IDexFactory(_dexRouter.factory()).createPair(
            address(this),
            _dexRouter.WETH()
        );
        MaxLimitChangeIsExempt(address(dexPair), true);
        handle_cngPair(address(dexPair), true);
        uint256 _totalSupply = 1_000_000_000 * 10 ** decimals();
        lastSwapback = block.timestamp;
        minSwapback = (_totalSupply * 1) / 1000;
        maxSwapback = (_totalSupply * 2) / 100;
        maxTx = (_totalSupply * 15) / 1000;
        maxWallet = (_totalSupply * 20) / 1000;
        buyTaxTotal = 30;
        sellTaxTotal = 30;
        transferTaxTotal = 0;
        marketingWallet = address(0x17C7ed17b8a60EB855cbbE46948604B232c635cF);
        feesExemptSetInternal(msg.sender, true);
        feesExemptSetInternal(address(this), true);
        feesExemptSetInternal(address(0xdead), true);
        feesExemptSetInternal(marketingWallet, true);
        MaxLimitChangeIsExempt(marketingWallet, true);
        MaxLimitChangeIsExempt(address(this), true);
        MaxLimitChangeIsExempt(msg.sender, true);
        MaxLimitChangeIsExempt(address(0xdead), true);
        transferOwnership(msg.sender);
        _mint(msg.sender, _totalSupply);
    }
    receive() external payable {}
    function openTrading() external onlyOwner {
        tradingEnabled = true;
        isSwapbackEnabled = true;
        emit TradingEnabled(block.timestamp);
    }
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }
        if (limitsEnabled) {
            if (
                from != owner() &&
                to != owner() &&
                to != address(0) &&
                to != address(0xdead) &&
                !onSwapback
            ) {
                if (!tradingEnabled) {
                    require(
                        transferTaxExempt[from] || transferTaxExempt[to],
                        "_transfer:: Trading is not active."
                    );
                }
                if (
                    automatedMarketMakerPairs[from] && !transferLimitExempt[to]
                ) {
                    require(
                        amount <= maxTx,
                        "Buy transfer amount exceeds the maxTx."
                    );
                    require(
                        amount + balanceOf(to) <= maxWallet,
                        "Max wallet exceeded"
                    );
                }
                else if (
                    automatedMarketMakerPairs[to] && !transferLimitExempt[from]
                ) {
                    require(
                        amount <= maxTx,
                        "Sell transfer amount exceeds the maxTx."
                    );
                } else if (!transferLimitExempt[to]) {
                    require(
                        amount + balanceOf(to) <= maxWallet,
                        "Max wallet exceeded"
                    );
                }
            }
        }
        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= minSwapback;
        if (
            canSwap &&
            isSwapbackEnabled &&
            !onSwapback &&
            !automatedMarketMakerPairs[from] &&
            !transferTaxExempt[from] &&
            !transferTaxExempt[to] &&
            lastSwapback != block.timestamp
        ) {
            onSwapback = true;
            handleSwapBack(amount);
            lastSwapback = block.timestamp;
            onSwapback = false;
        }
        bool takeFee = !onSwapback;
        if (transferTaxExempt[from] || transferTaxExempt[to]) {
            takeFee = false;
        }
        uint256 fees = 0;
        if (takeFee) {
            if (automatedMarketMakerPairs[to] && sellTaxTotal > 0) {
                fees = amount.mul(sellTaxTotal).div(100);
            }
            else if (automatedMarketMakerPairs[from] && buyTaxTotal > 0) {
                fees = amount.mul(buyTaxTotal).div(100);
            }
            else if (
                transferTaxTotal > 0 &&
                !automatedMarketMakerPairs[from] &&
                !automatedMarketMakerPairs[to]
            ) {
                fees = amount.mul(transferTaxTotal).div(100);
            }
            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }
            amount -= fees;
        }
        super._transfer(from, to, amount);
    }
    function doInternalSwapback(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();
        _approve(address(this), address(dexRouter), tokenAmount);
        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, 
            path,
            address(this),
            block.timestamp
        );
    }
    function doCheckFees()
        external
        view
        returns (
            uint256 _buyTaxTotal,
            uint256 _sellTaxTotal,
            uint256 _transferTaxTotal
        )
    {
        _buyTaxTotal = buyTaxTotal;
        _sellTaxTotal = sellTaxTotal;
        _transferTaxTotal = transferTaxTotal;
    }
    function handleSwapBack(uint256 amount) private {
        uint256 contractBalance = balanceOf(address(this));
        bool success;
        if (contractBalance == 0) {
            return;
        }
        if (contractBalance > maxSwapback) {
            contractBalance = maxSwapback;
        }
        if (contractBalance > amount * 15) {
            contractBalance = amount * 15;
        }
        uint256 amountToSwapForETH = contractBalance;
        doInternalSwapback(amountToSwapForETH);
        (success, ) = address(marketingWallet).call{
            value: address(this).balance
        }("");
    }
    function removeCaps() external onlyOwner {
        limitsEnabled = false;
        transferTaxTotal = 0;
        emit ConstraintsRemoved(block.timestamp);
    }
    function MaxLimitChangeIsExempt(address _add, bool _excluded) public onlyOwner {
        transferLimitExempt[_add] = _excluded;
        emit ExcludeFromConstraints(_add, _excluded);
    }
    function handleCheckExemptAccounts(
        address _target
    )
        external
        view
        returns (
            bool _transferTaxExempt,
            bool _transferLimitExempt,
            bool _automatedMarketMakerPairs
        )
    {
        _transferTaxExempt = transferTaxExempt[_target];
        _transferLimitExempt = transferLimitExempt[_target];
        _automatedMarketMakerPairs = automatedMarketMakerPairs[_target];
    }
    function set_swapBackCore(
        bool _proEnabled,
        uint256 _proTrigger,
        uint256 _proLimit
    ) external onlyOwner {
        require(
            _proTrigger >= 1,
            "Swap amount cannot be lower than 0.01% total supply."
        );
        require(
            _proLimit >= _proTrigger,
            "maximum amount cant be higher than minimum"
        );
        isSwapbackEnabled = _proEnabled;
        minSwapback = (totalSupply() * _proTrigger) / 10000;
        maxSwapback = (totalSupply() * _proLimit) / 10000;
        emit SwapbackSettingsUpdatedInternal(_proEnabled, _proTrigger, _proLimit);
    }
    function safeSetMax_transaction(
        uint256 _maxTx,
        uint256 _maxWallet
    ) external onlyOwner {
        require(_maxTx >= 2, "Cannot set maxTx lower than 0.2%");
        require(_maxWallet >= 5, "Cannot set maxWallet lower than 0.5%");
        maxTx = (_maxTx * totalSupply()) / 1000;
        maxWallet = (_maxWallet * totalSupply()) / 1000;
        emit doMaxTxUpdated(maxTx);
        emit safeMaxWalletUpdated(maxWallet);
    }
    function handleNewFeeSell(uint256 _value) external onlyOwner {
        sellTaxTotal = _value;
        require(
            sellTaxTotal <= 100,
            "Total sell fee cannot be higher than 100%"
        );
        emit SellFeeUpdatedCore(sellTaxTotal, sellTaxTotal, sellTaxTotal);
    }
    function newFeeBuyCore(uint256 _value) external onlyOwner {
        buyTaxTotal = _value;
        require(buyTaxTotal <= 100, "Total buy fee cannot be higher than 100%");
        emit BuyFeeUpdatedCore(buyTaxTotal, buyTaxTotal, buyTaxTotal);
    }
    function feemoveNew(uint256 _value) external onlyOwner {
        transferTaxTotal = _value;
        require(
            transferTaxTotal <= 100,
            "Total transfer fee cannot be higher than 100%"
        );
    }
    function feesExemptSetInternal(address _add, bool _excluded) public onlyOwner {
        transferTaxExempt[_add] = _excluded;
        emit ExcludeFromFeesInternal(_add, _excluded);
    }
    function handle_cngPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;
        emit safeSetPairLPool(pair, value);
    }
    function safeFeeReceiversSet(address _marketing) external onlyOwner {
        emit safeMarketingWalletUpdated(_marketing, marketingWallet);
        marketingWallet = _marketing;
    }
    function doCheckSwapBack()
        external
        view
        returns (
            bool _isSwapbackEnabled,
            uint256 _proackValueMin,
            uint256 _proackValueMax
        )
    {
        _isSwapbackEnabled = isSwapbackEnabled;
        _proackValueMin = minSwapback;
        _proackValueMax = maxSwapback;
    }
    function checkConstraints()
        external
        view
        returns (bool _limitsEnabled, uint256 _maxWallet, uint256 _maxTx)
    {
        _limitsEnabled = limitsEnabled;
        _maxWallet = maxWallet;
        _maxTx = maxTx;
    }
    function doGetMarketingWallet() external view returns (address _marketingWallet) {
        return (marketingWallet);
    }
}