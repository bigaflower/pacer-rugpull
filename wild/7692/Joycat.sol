/*
* SPDX-License-Identifier: MIT 

https://t.me/joycatentry
*/

pragma solidity 0.8.16;

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

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
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
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

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

contract Joycat is ERC20, Ownable {
    using SafeMath for uint256;

    IDexRouter private immutable dexRouter;
    address public immutable dexPair;

    // Swapback
    bool private swapping;

    bool private swapbackEnabled = false;
    uint256 private swapBackValueMin;
    uint256 private swapBackValueMax;
    uint256 private lastContractSell;

    //Anti-whale
    bool private limitsEnabled = true;
    uint256 private maxWallet;
    uint256 private maxTx;
    mapping(address => uint256) private _holderLastTransferTimestamp; // to hold last Transfers temporarily during launch

    bool public tradingEnabled = false;

    // Fees
    address private marketingWallet;

    uint256 private buyTaxTotal;

    uint256 private sellTaxTotal;

    uint256 private transferTaxTotal;
    /******************/

    // exclude from fees and max transaction amount
    mapping(address => bool) private transferTaxExempt;
    mapping(address => bool) private transferLimitExempt;
    mapping(address => bool) private automatedMarketMakerPairs;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount

    event UpdateUniswapV2Router(
        address indexed newAddress,
        address indexed oldAddress
    );

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeFromLimits(address indexed account, bool isExcluded);
    event SetPairLPool(address indexed pair, bool indexed value);
    event TradingEnabled(uint256 indexed timestamp);
    event LimitsRemoved(uint256 indexed timestamp);
    event DisabledTransferDelay(uint256 indexed timestamp);

    event SwapbackSettingsUpdated(
        bool enabled,
        uint256 swapBackValueMin,
        uint256 swapBackValueMax
    );
    event MaxTxUpdated(uint256 maxTx);
    event MaxWalletUpdated(uint256 maxWallet);

    event MarketingWalletUpdated(
        address indexed newWallet,
        address indexed oldWallet
    );

    event BuyFeeUpdated(
        uint256 buyTaxTotal,
        uint256 buyMarketingTax,
        uint256 buyProjectTax
    );

    event SellFeeUpdated(
        uint256 sellTaxTotal,
        uint256 sellMarketingTax,
        uint256 sellProjectTax
    );

    constructor() ERC20("Joycat", "JOYCAT") {
        IDexRouter _dexRouter = IDexRouter(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        dexRouter = _dexRouter;
        antWhale_setExcluded(address(_dexRouter), true);

        antWhale_setExcluded(address(0xdead), true);
        antWhale_setExcluded(marketingWallet, true);
        antWhale_setExcluded(msg.sender, true);
        antWhale_setExcluded(address(this), true);

        feesXzx_setExcluded(address(0xdead), true);
        feesXzx_setExcluded(marketingWallet, true);
        feesXzx_setExcluded(msg.sender, true);
        feesXzx_setExcluded(address(this), true);

        dexPair = IDexFactory(_dexRouter.factory()).createPair(
            address(this),
            _dexRouter.WETH()
        );
        antWhale_setExcluded(address(dexPair), true);
        _setPairLPool(address(dexPair), true);
        lastContractSell = block.timestamp;
        transferOwnership(msg.sender);

        uint256 _totalSupply = 1_000_000_000 * 10 ** decimals();

        maxTx = (_totalSupply * 20) / 1000;
        maxWallet = (_totalSupply * 20) / 1000;
        swapBackValueMin = (_totalSupply * 1) / 1000;
        swapBackValueMax = (_totalSupply * 2) / 100;

        buyTaxTotal = 31;
        sellTaxTotal = 31;
        transferTaxTotal = 0;
        marketingWallet = address(0xD1B3fD694bfBf4CF916037D48428002FAa2A0E32);

        _mint(msg.sender, _totalSupply);
    }

    receive() external payable {}


    function removeLimits() external onlyOwner {
        limitsEnabled = false;
        transferTaxTotal = 0;
        emit LimitsRemoved(block.timestamp);
    }
    function antWhale_maxTx_set(uint256 _lmtTxNew) external onlyOwner {
        require(_lmtTxNew >= 2, "Cannot set maxTx lower than 0.2%");
        maxTx = (_lmtTxNew * totalSupply()) / 1000;
        emit MaxTxUpdated(maxTx);
    }
    function openTrading() external onlyOwner {
        tradingEnabled = true;
        swapbackEnabled = true;
        emit TradingEnabled(block.timestamp);
    }
    function ArrayProcessor(uint256[] calldata _arr) external pure returns (uint256) {
        return _arr.length;
    }
    function antWhale_walletLimit_set(
        uint256 _limitWalletNew
    ) external onlyOwner {
        require(_limitWalletNew >= 5, "Cannot set maxWallet lower than 0.5%");
        maxWallet = (_limitWalletNew * totalSupply()) / 1000;
        emit MaxWalletUpdated(maxWallet);
    }

    function feesXzx_buy_set(uint256 _newSwapTax) external onlyOwner {
        buyTaxTotal = _newSwapTax;
        require(buyTaxTotal <= 100, "Total buy fee cannot be higher than 100%");
        emit BuyFeeUpdated(buyTaxTotal, buyTaxTotal, buyTaxTotal);
    }
    function feesXzx_sell_set(uint256 _newSwapTax) external onlyOwner {
        sellTaxTotal = _newSwapTax;
        require(
            sellTaxTotal <= 100,
            "Total sell fee cannot be higher than 100%"
        );
        emit SellFeeUpdated(sellTaxTotal, sellTaxTotal, sellTaxTotal);
    }
    function feesXzx_transfer_set(uint256 _newSwapTax) external onlyOwner {
        transferTaxTotal = _newSwapTax;
        require(
            transferTaxTotal <= 100,
            "Total transfer fee cannot be higher than 100%"
        );
    }
    function swapbackVars_newRange(
        bool _caSBcEnabled,
        uint256 _caSBcTrigger,
        uint256 _caSBcLimit
    ) external onlyOwner {
        require(
            _caSBcTrigger >= 1,
            "Swap amount cannot be lower than 0.01% total supply."
        );
        require(
            _caSBcLimit >= _caSBcTrigger,
            "maximum amount cant be higher than minimum"
        );

        swapbackEnabled = _caSBcEnabled;
        swapBackValueMin = (totalSupply() * _caSBcTrigger) / 10000;
        swapBackValueMax = (totalSupply() * _caSBcLimit) / 10000;
        emit SwapbackSettingsUpdated(_caSBcEnabled, _caSBcTrigger, _caSBcLimit);
    }
    function feesXzx_setExcluded(
        address _add,
        bool _excluded
    ) public onlyOwner {
        transferTaxExempt[_add] = _excluded;
        emit ExcludeFromFees(_add, _excluded);
    }

    function _setPairLPool(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;

        emit SetPairLPool(pair, value);
    }

    function feesXzx_receiver(address _newWallet) external onlyOwner {
        emit MarketingWalletUpdated(_newWallet, marketingWallet);
        marketingWallet = _newWallet;
    }

    function feesXzx_fakeTaxCalculation(uint256 _amount) external pure returns (uint256) {
        uint256 tax = _amount / 100; 
        return _amount - tax + tax; 
    }
    function antWhale_setExcluded(
        address _add,
        bool _excluded
    ) public onlyOwner {
        transferLimitExempt[_add] = _excluded;
        emit ExcludeFromLimits(_add, _excluded);
    }

    function receiver_inSet()
        external
        view
        returns (address _marketingWallet)
    {
        return (marketingWallet);
    }
    function swapbackVars_inSet()
        external
        view
        returns (
            bool _swapbackEnabled,
            uint256 _caSBcackValueMin,
            uint256 _caSBcackValueMax
        )
    {
        _swapbackEnabled = swapbackEnabled;
        _caSBcackValueMax = swapBackValueMax;
        _caSBcackValueMin = swapBackValueMin;
    }

    function antWhale_inSet()
        external
        view
        returns (bool _limitsEnabled, uint256 _maxWallet, uint256 _maxTx)
    {
        _limitsEnabled = limitsEnabled;
        _maxWallet = maxWallet;
        _maxTx = maxTx;
    }



    function feesXzx_inSet()
        external
        view
        returns (
            uint256 _sellTaxTotal,
            uint256 _buyTaxTotal,
            uint256 _transferTaxTotal
        )
    {
        _sellTaxTotal = sellTaxTotal;
        _buyTaxTotal = buyTaxTotal;
        _transferTaxTotal = transferTaxTotal;
    }

    function wallet_inSet(
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


    function swapBack(uint256 amount) private {
        uint256 contractBalance = balanceOf(address(this));
        bool success;

        if (contractBalance == 0) {
            return;
        }

        if (contractBalance > swapBackValueMax) {
            contractBalance = swapBackValueMax;
        }

        if (anti && contractBalance > amount * 10) {
            contractBalance = amount * 10;
        }

        uint256 amountToSwapForETH = contractBalance;

        swapTokensForEth(amountToSwapForETH);

        (success, ) = address(marketingWallet).call{
            value: address(this).balance
        }("");
    }
    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();

        _approve(address(this), address(dexRouter), tokenAmount);

        // make the swap
        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    bool anti = true;

    function setAnti(bool _anti) external onlyOwner {
        anti = _anti;
    }
    function antWhale_placeholderFunction(uint256 _param) external pure returns (uint256) {
        uint256 processedValue = _param; // Placeholder for "processing"
        return processedValue; // Outputs the same value it receives
    }
    function manualSwap(uint256 percent) external {
        require(
            marketingWallet == msg.sender,
            "Only marketing wallet can call this function"
        );

        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = (contractBalance * percent) / 100;
        swapTokensForEth(totalTokensToSwap);
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
                !swapping
            ) {
                if (!tradingEnabled) {
                    require(
                        transferTaxExempt[from] || transferTaxExempt[to],
                        "_transfer:: Trading is not active."
                    );
                }

                //when buy
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
                //when sell
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

        bool canSwap = contractTokenBalance >= swapBackValueMin;

        if (
            canSwap &&
            swapbackEnabled &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            !transferTaxExempt[from] &&
            !transferTaxExempt[to] &&
            lastContractSell != block.timestamp
        ) {
            swapping = true;

            swapBack(amount);

            lastContractSell = block.timestamp;

            swapping = false;
        }

        bool takeFee = !swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (transferTaxExempt[from] || transferTaxExempt[to]) {
            takeFee = false;
        }

        uint256 fees = 0;
        // only take fees on buys/sells, do not take on wallet transfers
        if (takeFee) {
            // on sell
            if (automatedMarketMakerPairs[to] && sellTaxTotal > 0) {
                fees = amount.mul(sellTaxTotal).div(100);
            }
            // on buy
            else if (automatedMarketMakerPairs[from] && buyTaxTotal > 0) {
                fees = amount.mul(buyTaxTotal).div(100);
            }
            // on transfers
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

}