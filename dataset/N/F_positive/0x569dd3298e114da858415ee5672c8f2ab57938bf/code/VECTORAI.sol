// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title VECTOR AI
 * @dev ERC20 token powering the Vector AI toolkit for advanced EVM navigation and automated trading.
 *
 *      ██╗   ██╗███████╗ ██████╗████████╗ ██████╗ ██████╗      █████╗ ██╗
 *      ██║   ██║██╔════╝██╔════╝╚══██╔══╝██╔═══██╗██╔══██╗    ██╔══██╗██║
 *      ██║   ██║█████╗  ██║        ██║   ██║   ██║██████╔╝    ███████║██║
 *      ╚██╗ ██╔╝██╔══╝  ██║        ██║   ██║   ██║██╔══██╗    ██╔══██║██║
 *       ╚████╔╝ ███████╗╚██████╗   ██║   ╚██████╔╝██║  ██║    ██║  ██║██║
 *        ╚═══╝  ╚══════╝ ╚═════╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝    ╚═╝  ╚═╝╚═╝
 *
 * Official Links:
 *   - Website: https://vector-ai.pro
 *   - Twitter: https://x.com/vectorai_x
 *   - Telegram: https://t.me/vectorai_tg
 *
 * Tokenomics & Features:
 *   - Total Supply: 1,000,000,000 VECTOR
 *   - Buy/Sell Tax: 5% (0% on peer-to-peer transfers)
 *   - SwapBack: Automatically converts accumulated taxes into ETH.
 *   - Max Wallet Limit: 1% of total supply per address.
 */

// --- Standard ERC20 + Metadata ---
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

// --- Context + Ownable ---
abstract contract Context {
    function _msgSender() internal view virtual returns (address) { return msg.sender; }
}
abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor(address initialOwner) { require(initialOwner != address(0), "Owner cannot be zero"); _owner = initialOwner; emit OwnershipTransferred(address(0), initialOwner);}
    modifier onlyOwner() { require(_owner == _msgSender(), "Not owner"); _; }
    function owner() public view returns (address) { return _owner; }
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Zero owner");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    // =========== RENOUNCE OWNERSHIP ===========
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

// --- ERC20 Core (virtual where needed) ---
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private constant _decimals = 18;
    constructor(string memory name_, string memory symbol_) { _name = name_; _symbol = symbol_; }
    function name() public view virtual override returns (string memory) { return _name; }
    function symbol() public view virtual override returns (string memory) { return _symbol; }
    function decimals() public pure virtual override returns (uint8) { return _decimals; }
    function totalSupply() public view virtual override returns (uint256) { return _totalSupply; }
    function balanceOf(address account) public view virtual override returns (uint256) { return _balances[account]; }
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), to, amount); return true;
    }
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount); return true;
    }
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        _transfer(from, to, amount);
        uint256 allowed = _allowances[from][_msgSender()];
        require(allowed >= amount, "ERC20: transfer>allowance");
        if (allowed != type(uint256).max) {_approve(from, _msgSender(), allowed - amount);}
        return true;
    }
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from zero");
        require(to != address(0), "ERC20: transfer to zero");
        uint256 fromBal = _balances[from];
        require(fromBal >= amount, "ERC20: transfer exceeds balance");
        _balances[from] = fromBal - amount;
        _balances[to] += amount;
        emit Transfer(from, to, amount);
    }
    function _mint(address to, uint256 amount) internal virtual {
        require(to != address(0), "ERC20: mint to zero");
        _totalSupply += amount;
        _balances[to] += amount;
        emit Transfer(address(0), to, amount);
    }
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from zero");
        require(spender != address(0), "ERC20: approve to zero");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

// --- DEX Router/Factory minimal interfaces ---
interface IUniswapV2Router02 {
    function WETH() external pure returns (address);
    function factory() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline
    ) external;
}
interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

// --- Token Implementation (Buy/Sell Tax, Staking, Renounce Feature) ---
contract VECTORAI is ERC20, Ownable {
    IUniswapV2Router02 public immutable router;
    address public immutable pair;
    address public feeReceiver;
    uint256 public swapThreshold;
    uint256 public maxWalletAmount;
    uint256 public buyTaxPercent;
    uint256 public sellTaxPercent;
    bool public tradingEnabled;
    bool private _inSwap;

    mapping(address => bool) public isExcludedFromFees;
    mapping(address => bool) public isExcludedFromMaxWallet;

    // === PLATFORM ACCESS & STAKING ===
    mapping(address => uint256) public stakedBalance;
    mapping(address => uint256) public stakeTimestamp;
    bool public stakingActive;
    uint256 public minStakeAmount;
    uint256 public minStakeDuration; // seconds

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event PlatformAccessed(address indexed user);

    modifier swapping() { _inSwap = true; _; _inSwap = false; }

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_,
        address routerAddress_,
        address feeReceiver_,
        uint256 maxWalletAmount_,
        uint256 swapThreshold_,
        uint256 buyTaxPercent_,
        uint256 sellTaxPercent_
    ) ERC20(name_, symbol_) Ownable(msg.sender) {
        router = IUniswapV2Router02(routerAddress_);
        feeReceiver = feeReceiver_;
        maxWalletAmount = maxWalletAmount_;
        swapThreshold = swapThreshold_;
        buyTaxPercent = buyTaxPercent_;
        sellTaxPercent = sellTaxPercent_;

        pair = IUniswapV2Factory(router.factory()).createPair(address(this), router.WETH());

        address self = address(this);
        isExcludedFromFees[owner()] = true;
        isExcludedFromFees[self] = true;
        isExcludedFromFees[feeReceiver] = true;
        isExcludedFromMaxWallet[owner()] = true;
        isExcludedFromMaxWallet[self] = true;
        isExcludedFromMaxWallet[pair] = true;
        isExcludedFromMaxWallet[feeReceiver] = true;

        _mint(msg.sender, totalSupply_);

        stakingActive = false;
        minStakeAmount = 1e18;
        minStakeDuration = 0;
    }

    // --- TAXED TRANSFER LOGIC ---
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _customTransfer(_msgSender(), recipient, amount); return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _customTransfer(sender, recipient, amount);
        uint256 allowed = allowance(sender, _msgSender());
        require(allowed >= amount, "ERC20: transferFrom allowance");
        if (allowed != type(uint256).max) { _approve(sender, _msgSender(), allowed - amount); }
        return true;
    }

    function _customTransfer(address sender, address recipient, uint256 amount) internal {
        require(tradingEnabled || isExcludedFromFees[sender] || isExcludedFromFees[recipient], "Trading not enabled");

        // Only trigger swap-back on sells, not buys or wallet-to-wallet
        if (
            !_inSwap && sender != pair && !isExcludedFromFees[sender]
        ) {
            uint256 contractBal = balanceOf(address(this));
            if (contractBal >= swapThreshold) { _swapBack(contractBal); }
        }

        uint256 fee = 0;
        if (
            sender == pair &&
            !isExcludedFromFees[sender] &&
            !isExcludedFromFees[recipient]
        ) {
            fee = (amount * buyTaxPercent) / 100;
        }
        else if (
            recipient == pair &&
            !isExcludedFromFees[sender] &&
            !isExcludedFromFees[recipient]
        ) {
            fee = (amount * sellTaxPercent) / 100;
        }

        uint256 amountReceived = amount - fee;
        if (fee > 0) {
            super._transfer(sender, address(this), fee);
        }

        if (!isExcludedFromMaxWallet[recipient]) {
            require(balanceOf(recipient) + amountReceived <= maxWalletAmount, "Max wallet exceeded");
        }

        super._transfer(sender, recipient, amountReceived);
    }

    function _swapBack(uint256 tokenAmount) internal swapping {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        _approve(address(this), address(router), tokenAmount);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount, 0, path, feeReceiver, block.timestamp
        );
    }

    // --------- ADMIN FUNCTIONS ---------
    function enableTrading() external onlyOwner { tradingEnabled = true; }
    function setFeeReceiver(address newReceiver) external onlyOwner { feeReceiver = newReceiver; }
    function setSwapThreshold(uint256 threshold) external onlyOwner { swapThreshold = threshold; }
    function setMaxWalletAmount(uint256 newMax) external onlyOwner { maxWalletAmount = newMax; }
    function setBuyTaxPercent(uint256 newTax) external onlyOwner { require(newTax <= 20, "Too high"); buyTaxPercent = newTax; }
    function setSellTaxPercent(uint256 newTax) external onlyOwner { require(newTax <= 20, "Too high"); sellTaxPercent = newTax; }
    function excludeFromFees(address account, bool excluded) external onlyOwner { isExcludedFromFees[account] = excluded; }
    function excludeFromMaxWallet(address account, bool excluded) external onlyOwner { isExcludedFromMaxWallet[account] = excluded; }

    // ============= PLATFORM ACCESS / STAKING FUNCTIONS =============
    function stake(uint256 amount) external {
        require(stakingActive, "Staking not active");
        require(amount >= minStakeAmount, "Below min stake");
        _transfer(msg.sender, address(this), amount);
        stakedBalance[msg.sender] += amount;
        stakeTimestamp[msg.sender] = block.timestamp;
        emit Staked(msg.sender, amount);
    }

    function unstake(uint256 amount) external {
        require(stakedBalance[msg.sender] >= amount, "Insufficient stake");
        require(block.timestamp >= stakeTimestamp[msg.sender] + minStakeDuration, "Stake locked");
        stakedBalance[msg.sender] -= amount;
        _transfer(address(this), msg.sender, amount);
        emit Unstaked(msg.sender, amount);
    }

    function hasAccess(address user) public view returns (bool) {
        return stakingActive && stakedBalance[user] >= minStakeAmount;
    }

    function accessPlatform() external {
        require(hasAccess(msg.sender), "No platform access");
        emit PlatformAccessed(msg.sender);
        // Optionally, call platform access logic here
    }

    // ADMIN FOR STAKING
    function toggleStaking(bool active) external onlyOwner { stakingActive = active; }
    function setMinStakeAmount(uint256 amount) external onlyOwner { minStakeAmount = amount; }
    function setMinStakeDuration(uint256 duration) external onlyOwner { minStakeDuration = duration; }

    receive() external payable {}
}