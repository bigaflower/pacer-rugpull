/**
    X:          https://x.com/SocialLensAi
    Telegram:   https://t.me/SocialLensAi
    Website:    https://sociallens.ai/
    Docs:       https://sociallens.gitbook.io/
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    error OwnableUnauthorizedAccount(address account);

    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

interface IERC20Errors {
    error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);

    error ERC20InvalidSender(address sender);

    error ERC20InvalidReceiver(address receiver);

    error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);

    error ERC20InvalidApprover(address approver);

    error ERC20InvalidSpender(address spender);
}

abstract contract ERC20 is Context, IERC20, IERC20Metadata, IERC20Errors {
    mapping(address account => uint256) private _balances;

    mapping(address account => mapping(address spender => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, value);
        return true;
    }

    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public virtual returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, value);
        _transfer(from, to, value);
        return true;
    }

    function _transfer(address from, address to, uint256 value) internal {
        if (from == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        if (to == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(from, to, value);
    }

    function _update(address from, address to, uint256 value) internal virtual {
        if (from == address(0)) {
            // Overflow check required: The rest of the code assumes that totalSupply never overflows
            _totalSupply += value;
        } else {
            uint256 fromBalance = _balances[from];
            if (fromBalance < value) {
                revert ERC20InsufficientBalance(from, fromBalance, value);
            }
            unchecked {
                // Overflow not possible: value <= fromBalance <= totalSupply.
                _balances[from] = fromBalance - value;
            }
        }

        if (to == address(0)) {
            unchecked {
                // Overflow not possible: value <= totalSupply or value <= fromBalance <= totalSupply.
                _totalSupply -= value;
            }
        } else {
            unchecked {
                // Overflow not possible: balance + value is at most totalSupply, which we know fits into a uint256.
                _balances[to] += value;
            }
        }

        emit Transfer(from, to, value);
    }

    function _mint(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(address(0), account, value);
    }

    function _burn(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        _update(account, address(0), value);
    }

    function _approve(address owner, address spender, uint256 value) internal {
        _approve(owner, spender, value, true);
    }

    function _approve(address owner, address spender, uint256 value, bool emitEvent) internal virtual {
        if (owner == address(0)) {
            revert ERC20InvalidApprover(address(0));
        }
        if (spender == address(0)) {
            revert ERC20InvalidSpender(address(0));
        }
        _allowances[owner][spender] = value;
        if (emitEvent) {
            emit Approval(owner, spender, value);
        }
    }

    function _spendAllowance(address owner, address spender, uint256 value) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < value) {
                revert ERC20InsufficientAllowance(spender, currentAllowance, value);
            }
            unchecked {
                _approve(owner, spender, currentAllowance - value, false);
            }
        }
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IUniswapV2Router {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract SocialLensAi is Ownable, ERC20 {
    IUniswapV2Router public immutable uniswapV2Router;

    address public constant ZERO_ADDRESS = address(0);
    address public constant DEAD_ADDRESS = address(0xdEaD);

    address public immutable uniswapV2Pair;
    address public marketingWallet;
    address public developmentWallet;
    address public revenueWallet;

    bool public isLimitsEnabled;
    bool public isCooldownEnabled;
    bool public isTaxEnabled;
    bool private inSwapBack;
    bool public isLaunched;

    uint256 private lastSwapBackExecutionBlock;

    uint256 public constant MAX_FEE = 30;

    uint256 public maxBuy;
    uint256 public maxSell;
    uint256 public maxWallet;

    uint256 public swapTokensAtAmount;
    uint256 public buyFee;
    uint256 public sellFee;
    uint256 public transferFee;

    mapping(address => bool) public isBot;
    mapping(address => bool) public isExcludedFromFees;
    mapping(address => bool) public isExcludedFromLimits;
    mapping(address => bool) public automatedMarketMakerPairs;
    mapping(address => uint256) private _holderLastTransferTimestamp;

    event Launch();
    event SetMarketingWallet(address newWallet, address oldWallet);
    event SetDevelopmentWallet(address newWallet, address oldWallet);
    event SetRevenueWallet(address newWallet, address oldWallet);
    event SetLimitsEnabled(bool status);
    event SetCooldownEnabled(bool status);
    event SetTaxesEnabled(bool status);
    event SetMaxBuy(uint256 amount);
    event SetMaxSell(uint256 amount);
    event SetMaxWallet(uint256 amount);
    event SetSwapTokensAtAmount(uint256 newValue, uint256 oldValue);
    event SetBuyFees(uint256 newValue, uint256 oldValue);
    event SetSellFees(uint256 newValue, uint256 oldValue);
    event SetTransferFees(uint256 newValue, uint256 oldValue);
    event ExcludeFromFees(address account, bool isExcluded);
    event ExcludeFromLimits(address account, bool isExcluded);
    event SetBots(address account, bool isExcluded);
    event SetAutomatedMarketMakerPair(address pair, bool value);
    event WithdrawStuckTokens(address token, uint256 amount);

    error AlreadyLaunched();
    error InvalidSender();
    error AddressZero();
    error AmountTooLow();
    error AmountTooHigh();
    error FeeTooHigh();
    error AMMAlreadySet();
    error NoNativeTokens();
    error NoTokens();
    error FailedToWithdrawNativeTokens();
    error BotDetected();
    error TransferDelay();
    error MaxBuyAmountExceed();
    error MaxSellAmountExceed();
    error MaxWalletAmountExceed();
    error NotLaunched();

    modifier lockSwapBack() {
        inSwapBack = true;
        _;
        inSwapBack = false;
    }

    constructor() Ownable(msg.sender) ERC20("Social Lens AI", "LENS") {
        address sender = msg.sender;
        _mint(sender, 100_000_000 ether);
        uint256 totalSupply = totalSupply();

        marketingWallet   = 0xbd8c1d156405996374c179B7b0b97c718C07B90B;
        developmentWallet = 0xbd8c1d156405996374c179B7b0b97c718C07B90B;
        revenueWallet     = 0xbd8c1d156405996374c179B7b0b97c718C07B90B;

        address uniswapFeeCollector = 0x000000fee13a103A10D593b9AE06b3e05F2E7E1c;

        maxBuy = (totalSupply * 12) / 1000;
        maxSell = (totalSupply * 12) / 1000;
        maxWallet = (totalSupply * 12) / 1000;
        swapTokensAtAmount = (totalSupply * 5) / 10000;

        isLimitsEnabled = true;
        isCooldownEnabled = true;
        isTaxEnabled = true;

        buyFee = 20;
        sellFee = 30;
        transferFee = 60;

        uniswapV2Router = IUniswapV2Router(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );

        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
            address(this),
            uniswapV2Router.WETH()
        );

        _setAutomatedMarketMakerPair(uniswapV2Pair, true);
        _approve(address(this), address(uniswapV2Router), type(uint256).max);
        _excludeFromFees(address(this), true);
        _excludeFromFees(DEAD_ADDRESS, true);
        _excludeFromFees(sender, true);
        _excludeFromFees(marketingWallet, true);
        _excludeFromFees(developmentWallet, true);
        _excludeFromFees(revenueWallet, true);
        _excludeFromFees(uniswapFeeCollector, true);
        _excludeFromLimits(address(this), true);
        _excludeFromLimits(DEAD_ADDRESS, true);
        _excludeFromLimits(sender, true);
        _excludeFromLimits(marketingWallet, true);
        _excludeFromLimits(developmentWallet, true);
        _excludeFromLimits(revenueWallet, true);
        _excludeFromLimits(uniswapFeeCollector, true);
    }

    receive() external payable {}

    fallback() external payable {}

    function launch() external onlyOwner {
        require(!isLaunched, AlreadyLaunched());
        isLaunched = true;
        emit Launch();
    }

    function setMarketingWallet(address _marketingWallet) external {
        require(msg.sender == marketingWallet, InvalidSender());
        require(_marketingWallet != ZERO_ADDRESS, AddressZero());
        address oldWallet = marketingWallet;
        marketingWallet = _marketingWallet;
        emit SetMarketingWallet(marketingWallet, oldWallet);
    }

    function setDevelopmentWallet(address _developmentWallet) external {
        require(msg.sender == developmentWallet, InvalidSender());
        require(_developmentWallet != ZERO_ADDRESS, AddressZero());
        address oldWallet = developmentWallet;
        developmentWallet = _developmentWallet;
        emit SetDevelopmentWallet(developmentWallet, oldWallet);
    }

    function setRevenueWallet(address _revenueWallet) external {
        require(msg.sender == revenueWallet, InvalidSender());
        require(_revenueWallet != ZERO_ADDRESS, AddressZero());
        address oldWallet = revenueWallet;
        revenueWallet = _revenueWallet;
        emit SetRevenueWallet(revenueWallet, oldWallet);
    }

    function setLimitsEnabled(bool value) external onlyOwner {
        isLimitsEnabled = value;
        emit SetLimitsEnabled(value);
    }

    function setCooldownEnabled(bool value) external onlyOwner {
        isCooldownEnabled = value;
        emit SetCooldownEnabled(value);
    }

    function setTaxesEnabled(bool value) external onlyOwner {
        isTaxEnabled = value;
        emit SetTaxesEnabled(value);
    }

    function setMaxBuy(uint256 amount) external onlyOwner {
        require(amount >= ((totalSupply() * 2) / 1000), AmountTooLow());
        maxBuy = amount;
        emit SetMaxBuy(maxBuy);
    }

    function setMaxSell(uint256 amount) external onlyOwner {
        require(amount >= ((totalSupply() * 2) / 1000), AmountTooLow());
        maxSell = amount;
        emit SetMaxSell(maxSell);
    }

    function setMaxWallet(uint256 amount) external onlyOwner {
        require(amount >= ((totalSupply() * 3) / 1000), AmountTooLow());
        maxWallet = amount;
        emit SetMaxWallet(maxWallet);
    }

    function setSwapTokensAtAmount(uint256 amount) external onlyOwner {
        uint256 _totalSupply = totalSupply();
        require(amount >= (_totalSupply * 1) / 1000000, AmountTooLow());
        require(amount <= (_totalSupply * 5) / 1000, AmountTooHigh());
        uint256 oldValue = swapTokensAtAmount;
        swapTokensAtAmount = amount;
        emit SetSwapTokensAtAmount(amount, oldValue);
    }

    function setBuyFees(uint256 _buyFee) external onlyOwner {
        require(_buyFee <= MAX_FEE, FeeTooHigh());
        uint256 oldValue = buyFee;
        buyFee = _buyFee;
        emit SetBuyFees(_buyFee, oldValue);
    }

    function setSellFees(uint256 _sellFee) external onlyOwner {
        require(_sellFee <= MAX_FEE, FeeTooHigh());
        uint256 oldValue = sellFee;
        sellFee = _sellFee;
        emit SetSellFees(_sellFee, oldValue);
    }

    function setTransferFees(uint256 _transferFee) external onlyOwner {
        require(_transferFee <= MAX_FEE, FeeTooHigh());
        uint256 oldValue = transferFee;
        transferFee = _transferFee;
        emit SetTransferFees(_transferFee, oldValue);
    }

    function excludeFromFees(address[] calldata accounts, bool value)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < accounts.length; i++) {
            _excludeFromFees(accounts[i], value);
        }
    }

    function excludeFromLimits(address[] calldata accounts, bool value)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < accounts.length; i++) {
            _excludeFromLimits(accounts[i], value);
        }
    }

    function setBots(address[] calldata accounts, bool value)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < accounts.length; i++) {
            if (
                (!automatedMarketMakerPairs[accounts[i]]) &&
                (accounts[i] != address(uniswapV2Router)) &&
                (accounts[i] != address(this)) &&
                (accounts[i] != ZERO_ADDRESS) &&
                (!isExcludedFromFees[accounts[i]] &&
                    !isExcludedFromLimits[accounts[i]])
            ) _setBots(accounts[i], value);
        }
    }

    function setAutomatedMarketMakerPair(address pair, bool value)
        external
        onlyOwner
    {
        require(!automatedMarketMakerPairs[pair], AMMAlreadySet());
        _setAutomatedMarketMakerPair(pair, value);
    }

    function withdrawStuckTokens(address _token) external {
        require(msg.sender == developmentWallet, InvalidSender());
        address sender = msg.sender;
        uint256 amount;
        if (_token == ZERO_ADDRESS) {
            bool success;
            amount = address(this).balance;
            require(amount > 0, NoNativeTokens());
            (success, ) = address(sender).call{value: amount}("");
            require(success, FailedToWithdrawNativeTokens());
        } else {
            amount = IERC20(_token).balanceOf(address(this));
            require(amount > 0, NoTokens());
            IERC20(_token).transfer(msg.sender, amount);
        }
        emit WithdrawStuckTokens(_token, amount);
    }

    function _transferOwnership(address newOwner) internal virtual override {
        address oldOwner = owner();
        if (oldOwner != ZERO_ADDRESS) {
            _excludeFromFees(oldOwner, false);
            _excludeFromLimits(oldOwner, false);
        }
        _excludeFromFees(newOwner, true);
        _excludeFromLimits(newOwner, true);
        super._transferOwnership(newOwner);
    }

    function _update(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        address sender = msg.sender;
        address origin = tx.origin;
        uint256 blockNumber = block.number;

        require(!isBot[from], BotDetected());
        require(sender == from || !isBot[sender], BotDetected());
        require(
            origin == from || origin == sender || !isBot[origin],
            BotDetected()
        );

        require(
            isLaunched ||
                isExcludedFromLimits[from] ||
                isExcludedFromLimits[to],
            NotLaunched()
        );

        bool limits = isLimitsEnabled &&
            !inSwapBack &&
            !(isExcludedFromLimits[from] || isExcludedFromLimits[to]);
        if (limits) {
            if (
                from != owner() &&
                to != owner() &&
                to != ZERO_ADDRESS &&
                to != DEAD_ADDRESS
            ) {
                if (isCooldownEnabled) {
                    if (to != address(uniswapV2Router) && to != uniswapV2Pair) {
                        require(
                            _holderLastTransferTimestamp[origin] <
                                blockNumber - 3 &&
                                _holderLastTransferTimestamp[to] <
                                blockNumber - 3,
                            TransferDelay()
                        );
                        _holderLastTransferTimestamp[origin] = blockNumber;
                        _holderLastTransferTimestamp[to] = blockNumber;
                    }
                }

                if (
                    automatedMarketMakerPairs[from] && !isExcludedFromLimits[to]
                ) {
                    require(amount <= maxBuy, MaxBuyAmountExceed());
                    require(
                        amount + balanceOf(to) <= maxWallet,
                        MaxWalletAmountExceed()
                    );
                } else if (
                    automatedMarketMakerPairs[to] && !isExcludedFromLimits[from]
                ) {
                    require(amount <= maxSell, MaxSellAmountExceed());
                } else if (!isExcludedFromLimits[to]) {
                    require(
                        amount + balanceOf(to) <= maxWallet,
                        MaxWalletAmountExceed()
                    );
                }
            }
        }

        bool takeFee = isTaxEnabled &&
            !inSwapBack &&
            !(isExcludedFromFees[from] || isExcludedFromFees[to]);

        if (takeFee) {
            uint256 fees = 0;
            if (automatedMarketMakerPairs[to] && sellFee > 0) {
                fees = (amount * sellFee) / 100;
            } else if (automatedMarketMakerPairs[from] && buyFee > 0) {
                fees = (amount * buyFee) / 100;
            } else if (
                !automatedMarketMakerPairs[to] &&
                !automatedMarketMakerPairs[from] &&
                transferFee > 0
            ) {
                fees = (amount * transferFee) / 100;
            }

            if (fees > 0) {
                amount -= fees;
                super._update(from, address(this), fees);
            }
        }

        uint256 balance = balanceOf(address(this));
        bool shouldSwap = balance >= swapTokensAtAmount;
        if (takeFee && !automatedMarketMakerPairs[from] && shouldSwap) {
            if (blockNumber > lastSwapBackExecutionBlock) {
                _swapBack(balance);
                lastSwapBackExecutionBlock = blockNumber;
            }
        }

        super._update(from, to, amount);
    }

    function _swapBack(uint256 balance) internal virtual lockSwapBack {
        bool success;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        uint256 maxSwapAmount = swapTokensAtAmount * 20;

        if (balance > maxSwapAmount) {
            balance = maxSwapAmount;
        }

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            balance,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 ethBalance = address(this).balance;

        uint256 ethForMarketing = ( ethBalance * 1 ) / 5;
        uint256 ethForRevenue = ( ethBalance * 1 ) / 5;
        uint256 ethForDevelopment = ethBalance - ethForMarketing - ethForRevenue;

        (success, ) = address(marketingWallet).call{value: ethForMarketing}(
            ""
        );

        (success, ) = address(developmentWallet).call{value: ethForDevelopment}(
            ""
        );

        (success, ) = address(revenueWallet).call{value: ethForRevenue}(
            ""
        );
    }

    function _excludeFromFees(address account, bool value) internal virtual {
        isExcludedFromFees[account] = value;
        emit ExcludeFromFees(account, value);
    }

    function _excludeFromLimits(address account, bool value) internal virtual {
        isExcludedFromLimits[account] = value;
        emit ExcludeFromLimits(account, value);
    }

    function _setBots(address account, bool value) internal virtual {
        isBot[account] = value;
        emit SetBots(account, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value)
        internal
        virtual
    {
        automatedMarketMakerPairs[pair] = value;
        emit SetAutomatedMarketMakerPair(pair, value);
    }
}