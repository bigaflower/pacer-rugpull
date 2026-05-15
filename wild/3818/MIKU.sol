/*
* SPDX-License-Identifier: MIT

https://hatsunemiku.money
https://t.me/hatsunemikumoney
https://x.com/HatsuneMikuETHok

*/

pragma solidity 0.8.21;

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

contract MIKU is ERC20, Ownable {
    using SafeMath for uint256;

    IDexRouter private immutable uniRouter;
    address private immutable uniPair;

    bool private onSwapback;

    bool private contractSwapBackEnabled = false;
    uint256 private triggerSwapBack;
    uint256 private limitSwapBack;
    uint256 private lastSwapBack;

    bool private limitsEnabled = true;
    uint256 private maxWalletLimit;
    uint256 private maxTransactionLimit;

    bool private tradingOpen = false;

    address private marketingReceiver;

    uint256 private buyTax;

    uint256 private sellTax;

    uint256 private transferTax;

    mapping(address => bool) private exemptFromFees;
    mapping(address => bool) private exemptFromLimits;
    mapping(address => bool) private DEXPair;

    event ExemptFromFee(address indexed account, bool isExcluded);
    event ExemptFromLimit(address indexed account, bool isExcluded);
    event SetPairLPool(address indexed pair, bool indexed value);
    event TradingEnabled(uint256 indexed timestamp);
    event LimitsRemoved(uint256 indexed timestamp);

    event SwapbackSettingsUpdated(
        bool enabled,
        uint256 triggerSwapBack,
        uint256 limitSwapBack
    );
    event MaxLimitTxChanged(uint256 maxTransactionLimit);
    event MaxLimitWalletChanged(uint256 maxWalletLimit);

    event MarketingWalletUpdated(
        address indexed newWallet,
        address indexed oldWallet
    );

    event BuyFeeUpdated(
        uint256 buyTax,
        uint256 buyMarketingTax,
        uint256 buyProjectTax
    );

    event SellFeeUpdated(
        uint256 sellTax,
        uint256 sellMarketingTax,
        uint256 sellProjectTax
    );

    constructor() ERC20("Hatsune Miku", "MIKU") {
        IDexRouter _uniRouter = IDexRouter(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );

        exemptFromLimits[address(_uniRouter)] = true;
        uniRouter = _uniRouter;

        uniPair = IDexFactory(_uniRouter.factory()).createPair(
            address(this),
            _uniRouter.WETH()
        );
        exemptFromLimits[address(uniPair)] = true;
        _inSetUniPair(address(uniPair), true);

        uint256 _totalSupply = 1_000_000_000 * 10 ** decimals();

        lastSwapBack = block.timestamp;
        
        buyTax = 30;
        sellTax = 30;
        transferTax = 0;
        
        triggerSwapBack = (_totalSupply * 1) / 1000;
        limitSwapBack = (_totalSupply * 2) / 100;
        maxWalletLimit = (_totalSupply * 15) / 1000;
        maxTransactionLimit = (_totalSupply * 15) / 1000;



        marketingReceiver = address(0xdB4bA7caB44A7cf1240BcfD083fd12403Fb11C9D);

        exemptFromFees[msg.sender] = true;
        exemptFromFees[address(this)] = true;
        exemptFromFees[address(0xdead)] = true;
        exemptFromFees[marketingReceiver] = true;
        
        exemptFromLimits[msg.sender] = true;
        exemptFromLimits[address(this)] = true;
        exemptFromLimits[address(0xdead)] = true;
        exemptFromLimits[marketingReceiver] = true;

        transferOwnership(msg.sender);

        _mint(msg.sender, _totalSupply);
    }

    receive() external payable {}

    function openTrading() external onlyOwner {
        tradingOpen = true;
        contractSwapBackEnabled = true;
        emit TradingEnabled(block.timestamp);
    }

    function set_WalletLimit(
        uint256 _maxWalletLimit
    ) external onlyOwner {
        require(_maxWalletLimit >= 5, "Cannot set maxWalletLimit lower than 0.5%");
        maxWalletLimit = (_maxWalletLimit * totalSupply()) / 1000;
        emit MaxLimitWalletChanged(maxWalletLimit);
    }

    function configureThSwapbackSettings(
        bool _caSwapBackcEnabled,
        uint256 _caSwapBackcTrigger,
        uint256 _caSwapBackcLimit
    ) external onlyOwner {
        require(
            _caSwapBackcTrigger >= 1,
            "Swap amount cannot be lower than 0.01% total supply."
        );
        require(
            _caSwapBackcLimit >= _caSwapBackcTrigger,
            "maximum amount cant be higher than minimum"
        );

        contractSwapBackEnabled = _caSwapBackcEnabled;
        triggerSwapBack = (totalSupply() * _caSwapBackcTrigger) / 10000;
        limitSwapBack = (totalSupply() * _caSwapBackcLimit) / 10000;
        emit SwapbackSettingsUpdated(_caSwapBackcEnabled, _caSwapBackcTrigger, _caSwapBackcLimit);
    }

    function changeThTransactionLimit(uint256 _maxTransactionLimit) external onlyOwner {
        require(_maxTransactionLimit >= 2, "Cannot set maxTransactionLimit lower than 0.2%");
        maxTransactionLimit = (_maxTransactionLimit * totalSupply()) / 1000;
        emit MaxLimitTxChanged(maxTransactionLimit);
    }

    function removeLimitsNow() external onlyOwner {
        limitsEnabled = false;
        transferTax = 0;
        emit LimitsRemoved(block.timestamp);
    }

    function setTax_Sell(uint256 _value) external onlyOwner {
        sellTax = _value;
        require(
            sellTax <= 100,
            "Total sell fee cannot be higher than 100%"
        );
        emit SellFeeUpdated(sellTax, sellTax, sellTax);
    }


    function changeThAddressLimitExemption(
        address _add,
        bool _excluded
    ) public onlyOwner {
        exemptFromLimits[_add] = _excluded;
        emit ExemptFromLimit(_add, _excluded);
    }

    function setTax_Buy(uint256 _value) external onlyOwner {
        buyTax = _value;
        require(buyTax <= 100, "Total buy fee cannot be higher than 100%");
        emit BuyFeeUpdated(buyTax, buyTax, buyTax);
    }

    function setTax_Transfer(uint256 _value) external onlyOwner {
        transferTax = _value;
        require(
            transferTax <= 100,
            "Total transfer fee cannot be higher than 100%"
        );
    }

    function retrieveaAddressSettings(
        address _target
    )
        external
        view
        returns (
            bool _isExemptFromFees,
            bool _exemptFromLimits,
            bool _UNIPair
        )
    {
        _isExemptFromFees = exemptFromFees[_target];
        _exemptFromLimits = exemptFromLimits[_target];
        _UNIPair = DEXPair[_target];
    }

    function changeAddressFeeExemption(
        address _add,
        bool _excluded
    ) public onlyOwner {
        exemptFromFees[_add] = _excluded;
        emit ExemptFromFee(_add, _excluded);
    }

    function _inSetUniPair(address pair, bool value) private {
        DEXPair[pair] = value;

        emit SetPairLPool(pair, value);
    }

    function changeMarketingaWallet(address _marketing) external onlyOwner {
        emit MarketingWalletUpdated(_marketing, marketingReceiver);
        marketingReceiver = _marketing;
    }

    function retrieveSwapbaackSettings()
        external
        view
        returns (
            bool _contractSwapBackEnabled,
            uint256 _caSwapBackcackValueMin,
            uint256 _caSwapBackcackValueMax
        )
    {
        _contractSwapBackEnabled = contractSwapBackEnabled;
        _caSwapBackcackValueMin = triggerSwapBack;
        _caSwapBackcackValueMax = limitSwapBack;
    }

    function retrieveTheLimitSettings()
        external
        view
        returns (bool _limitsEnabled, uint256 _maxWalletLimit, uint256 _maxTransactionLimit)
    {
        _limitsEnabled = limitsEnabled;
        _maxWalletLimit = maxWalletLimit;
        _maxTransactionLimit = maxTransactionLimit;
    }

    function retrieveTheFeeReceivers()
        external
        view
        returns (address _marketingReceiver)
    {
        return (marketingReceiver);
    }

    function retrieveTaxaRates()
        external
        view
        returns (
            uint256 _buyTax,
            uint256 _sellTax,
            uint256 _transferTax
        )
    {
        _buyTax = buyTax;
        _sellTax = sellTax;
        _transferTax = transferTax;
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
                if (!tradingOpen) {
                    require(
                        exemptFromFees[from] || exemptFromFees[to],
                        "_transfer:: Trading is not active."
                    );
                }

                //when buy
                if (
                    DEXPair[from] && !exemptFromLimits[to]
                ) {
                    require(
                        amount <= maxTransactionLimit,
                        "Buy transfer amount exceeds the maxTransactionLimit."
                    );
                    require(
                        amount + balanceOf(to) <= maxWalletLimit,
                        "Max wallet exceeded"
                    );
                }
                //when sell
                else if (
                    DEXPair[to] && !exemptFromLimits[from]
                ) {
                    require(
                        amount <= maxTransactionLimit,
                        "Sell transfer amount exceeds the maxTransactionLimit."
                    );
                } else if (!exemptFromLimits[to]) {
                    require(
                        amount + balanceOf(to) <= maxWalletLimit,
                        "Max wallet exceeded"
                    );
                }
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= triggerSwapBack;

        if (
            canSwap &&
            contractSwapBackEnabled &&
            !onSwapback &&
            !DEXPair[from] &&
            !exemptFromFees[from] &&
            !exemptFromFees[to] &&
            lastSwapBack != block.timestamp
        ) {
            onSwapback = true;

            swapBack(amount);

            lastSwapBack = block.timestamp;

            onSwapback = false;
        }

        bool takeFee = !onSwapback;

        if (exemptFromFees[from] || exemptFromFees[to]) {
            takeFee = false;
        }

        uint256 fees = 0;

        if (takeFee) {
            // on sell
            if (DEXPair[to] && sellTax > 0) {
                fees = amount.mul(sellTax).div(100);
            }
            // on buy
            else if (DEXPair[from] && buyTax > 0) {
                fees = amount.mul(buyTax).div(100);
            }
            // on transfers
            else if (
                transferTax > 0 &&
                !DEXPair[from] &&
                !DEXPair[to]
            ) {
                fees = amount.mul(transferTax).div(100);
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }

            amount -= fees;
        }

        super._transfer(from, to, amount);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniRouter.WETH();

        _approve(address(this), address(uniRouter), tokenAmount);
        uniRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function swapBack(uint256 amount) private {
        uint256 contractBalance = balanceOf(address(this));
        bool success;

        if (contractBalance == 0) {
            return;
        }
        if (contractBalance > limitSwapBack) {
            contractBalance = limitSwapBack;
        }
        if (contractBalance > amount * 15) {
            contractBalance = amount * 15;
        }

        uint256 amountToSwapForETH = contractBalance;

        swapTokensForEth(amountToSwapForETH);

        (success, ) = address(marketingReceiver).call{
            value: address(this).balance
        }("");
    }
}