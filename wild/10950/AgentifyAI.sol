/*
Agentify empowers AI agents to interact, adapt, and automate Web3 tasks using the Model Context Protocol (MCP). 
From DeFi to cross-chain operations, deploy agents that evolve and monetize as they work.

Whitepaper: docs.agentifyai.org
Website: agentifyai.org
Telegram: https://t.me/agentifyportal
X: https://x.com/agentifyxyz?s=21
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

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

    error ERC20InsufficientBalance(
        address sender,
        uint256 balance,
        uint256 needed
    );

    error ERC20InvalidSender(address sender);

    error ERC20InvalidReceiver(address receiver);

    error ERC20InsufficientAllowance(
        address spender,
        uint256 allowance,
        uint256 needed
    );

    error ERC20InvalidApprover(address approver);

    error ERC20InvalidSpender(address spender);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    error OwnableUnauthorizedAccount(address account);

    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}
interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

abstract contract ERC20 is Context, IERC20, IERC20Metadata, IERC20Errors {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

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

    function allowance(address owner, address spender)
        public
        view
        virtual
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 value)
        public
        virtual
        returns (bool)
    {
        address owner = _msgSender();
        _approve(owner, spender, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public virtual returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, value);
        _transfer(from, to, value);
        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal {
        if (from == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        if (to == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(from, to, value);
    }

    function _update(
        address from,
        address to,
        uint256 value
    ) internal virtual {
        if (from == address(0)) {

            _totalSupply += value;
        } else {
            uint256 fromBalance = _balances[from];
            if (fromBalance < value) {
                revert ERC20InsufficientBalance(from, fromBalance, value);
            }
            unchecked {

                _balances[from] = fromBalance - value;
            }
        }

        if (to == address(0)) {
            unchecked {

                _totalSupply -= value;
            }
        } else {
            unchecked {

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

    function _approve(
        address owner,
        address spender,
        uint256 value
    ) internal {
        _approve(owner, spender, value, true);
    }

    function _approve(
        address owner,
        address spender,
        uint256 value,
        bool emitEvent
    ) internal virtual {
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

    function _spendAllowance(
        address owner,
        address spender,
        uint256 value
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < value) {
                revert ERC20InsufficientAllowance(
                    spender,
                    currentAllowance,
                    value
                );
            }
            unchecked {
                _approve(owner, spender, currentAllowance - value, false);
            }
        }
    }
}

contract AgentifyAI is Ownable, ERC20 {
    IUniswapV2Router public immutable uniswapV2Router;

    address public constant ZERO_ADDRESS = address(0);
    address public constant DEAD_ADDRESS = address(0xdEaD);

    address public uniswapV2Pair;

    address public GrowthWallet;
    address public OperationsWallet;
    address public BuildWallet;

    bool public isLimitsEnabled;
    bool public isAntiMEV;
    bool public isTaxEnabled;
    bool private inSwapBack;
    bool public isLaunched;

    uint256 public launchBlock;
    uint256 public launchTime;

    uint256 private lastSwapBackExecutionBlock;

    uint256 public maxBuy;
    uint256 public maxSell;
    uint256 public maxWallet;

    uint256 public swapTokensAtAmount;
    uint256 public buyFee;
    uint256 public sellFee;
    uint256 public transferFee;

    mapping(address => bool) public isExcludedFromFees;
    mapping(address => bool) public isExcludedFromLimits;
    mapping(address => bool) public automatedMarketMakerPairs;
    mapping(address => uint256) private _holderLastTransferTimestamp;

    modifier lockSwapBack() {
        inSwapBack = true;
        _;
        inSwapBack = false;
    }

    constructor(address strategic) Ownable(msg.sender) ERC20("Agentify AI", "AGF") {
        address sender = msg.sender;

        _excludeFromFees(address(this), true);
        _excludeFromFees(address(0xdead), true);
        _excludeFromFees(sender, true);
        _excludeFromFees(GrowthWallet, true);

        _excludeFromLimits(address(this), true);
        _excludeFromLimits(address(0xdead), true);
        _excludeFromLimits(sender, true);
        _excludeFromLimits(GrowthWallet, true);

        _mint(sender, 80_000_000 ether);
        _mint(strategic, 20_000_000 ether);

        uint256 totalSupply = totalSupply();

        GrowthWallet = 0x288287746451B83e73602e65e9E49812D4375c3F; //42
        OperationsWallet = 0x2ca981EB5CD4FbC67E86C4bC12348C12850bEaA5; //30
        BuildWallet = 0x4b46f03Fcea1163b17F93E631e822938731a9777; //28

        maxBuy = (totalSupply * 9) / 1000;
        maxSell = (totalSupply * 9) / 1000;
        maxWallet = (totalSupply * 9) / 1000;
        swapTokensAtAmount = (totalSupply * 325) / 1000000;

        isLimitsEnabled = true;
        isAntiMEV = true;
        isTaxEnabled = true;

        buyFee = 33;
        sellFee = 40;
        transferFee = 40;

        uniswapV2Router = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    }

    receive() external payable {}

    fallback() external payable {}

    function _transferOwnership(address newOwner) internal override {
        address oldOwner = owner();
        if (oldOwner != address(0)) {
            _excludeFromFees(oldOwner, false);
            _excludeFromLimits(oldOwner, false);
        }
        _excludeFromFees(newOwner, true);
        _excludeFromLimits(newOwner, true);
        super._transferOwnership(newOwner);
    }

    function StartTrade() external onlyOwner {
        require(!isLaunched, "AlreadyLaunched()");

        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
            address(this),
            uniswapV2Router.WETH()
        );

        _setAutomatedMarketMakerPair(uniswapV2Pair, true);
        _approve(address(this), address(uniswapV2Router), type(uint256).max);
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
        isLaunched = true;
        launchBlock = block.number;
        launchTime = block.timestamp;
    }

    function RemoveAllLimits() external onlyOwner {
        isLimitsEnabled = false;
        isAntiMEV = false;
    }

    function DisableAntiMEV() external onlyOwner {
        isAntiMEV = false;
    }
      
    function ToogleTaxes(bool value) external onlyOwner {
        isTaxEnabled = value;
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

    function _excludeFromFees(address account, bool value) internal virtual {
        isExcludedFromFees[account] = value;
    }

    function _excludeFromLimits(address account, bool value) internal virtual {
        isExcludedFromLimits[account] = value;
    }

    function withdrawStuckTokens(address _token) external onlyOwner {
        address sender = msg.sender;
        uint256 amount;
        if (_token == ZERO_ADDRESS) {
            bool success;
            amount = address(this).balance;
            require(amount > 0, "NoNativeTokens()");
            (success, ) = address(sender).call{value: amount}("");
            require(success, "FailedToWithdrawNativeTokens()");
        } else {
            amount = IERC20(_token).balanceOf(address(this));
            require(amount > 0, "NoTokens()");
            IERC20(_token).transfer(msg.sender, amount);
        }
    }

    function _update(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        address origin = tx.origin;

        require(
            isLaunched ||
                isExcludedFromLimits[from] ||
                isExcludedFromLimits[to],
            "NotLaunched()"
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
                if (isAntiMEV) {
                    if (to != address(uniswapV2Router) && to != uniswapV2Pair) {
                        require(
                            _holderLastTransferTimestamp[origin] <
                                block.number - 3 &&
                                _holderLastTransferTimestamp[to] <
                                block.number - 3,
                            "TransferDelay()"
                        );
                        _holderLastTransferTimestamp[origin] = block.number;
                        _holderLastTransferTimestamp[to] = block.number;
                    }
                }

                if (
                    automatedMarketMakerPairs[from] && !isExcludedFromLimits[to]
                ) {
                    require(amount <= maxBuy, "MaxBuyAmountExceed()");
                    require(
                        amount + balanceOf(to) <= maxWallet,
                        "MaxWalletAmountExceed()"
                    );
                } else if (
                    automatedMarketMakerPairs[to] && !isExcludedFromLimits[from]
                ) {
                    require(amount <= maxSell, "MaxSellAmountExceed()");
                } else if (!isExcludedFromLimits[to]) {
                    require(
                        amount + balanceOf(to) <= maxWallet,
                        "MaxWalletAmountExceed()"
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

        uint256 maxSwapAmount = swapTokensAtAmount * 20;
        if (takeFee && !automatedMarketMakerPairs[from] && shouldSwap) {
            if (block.number > lastSwapBackExecutionBlock) {
                if (balance > maxSwapAmount) {
                    balance = maxSwapAmount;
                }
                _swapBack(balance);
                lastSwapBackExecutionBlock = block.number;
            }
        }

        super._update(from, to, amount);
    }

    function _swapBack(uint256 balance) internal virtual lockSwapBack {
        bool success;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            balance,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 ethBalance = address(this).balance;

        uint256 ethForGrowth = (ethBalance * 42) / 100;
        uint256 ethForOperation = (ethBalance * 30) / 100;
        uint256 ethForBuild = (ethBalance * 28) / 100;

        (success, ) = address(GrowthWallet).call{value: ethForGrowth}("");
        (success, ) = address(OperationsWallet).call{value: ethForOperation}("");
        (success, ) = address(BuildWallet).call{value: ethForBuild}("");
    }

    function DripSwap(uint256 _percen) external onlyOwner {
        uint256 balance = balanceOf(address(this));
        uint256 amt = (balance * _percen)/100;
        _swapBack(amt);
    }

    function AdjustFess(uint256 _buyFee, uint256 _sellFee) external onlyOwner {
        if (block.number == launchBlock){
            buyFee = _buyFee;
            sellFee = _sellFee;
        } else {
        require(_buyFee <= buyFee && _sellFee <= sellFee, "FeeTooHigh()");
        buyFee = _buyFee;
        sellFee = _sellFee;
    }}

    function ReduceTransferFees(uint256 _transferFee) external onlyOwner {
        require(_transferFee <= transferFee, "FeeTooHigh()");
        transferFee = _transferFee;
    }

    function ChangeTaxWallets(address _OperationWallet, address _GrowthAddress, address _BuildWallet) external onlyOwner {
        GrowthWallet = _GrowthAddress;
        OperationsWallet = _OperationWallet;
        BuildWallet = _BuildWallet;
        
    }

    function _setAutomatedMarketMakerPair(address pair, bool value)
        internal
        virtual
    {
        automatedMarketMakerPairs[pair] = value;
    }
}