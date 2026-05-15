/* ===============================================================================

🟡 zippyunzipped.com/

🟡 instagram.com/zippyunzipped/

🟡 tiktok.com/@zippyunzipped

🟡 youtube.com/@Zippy-Unzipped

🟡 x.com/zippyunzipped

🤐 linktr.ee/zippyunzipped

=============================================================================== */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/* ===============================================================================
   ZIPPY – Fair Launch Memecoin
   Total Supply: 225,000,000,000 ZIPPY
   Buy Tax: 0.25% → Marketing
   Sell Tax: 0.25% → Airdrop + Burn Wallet
   =============================================================================== */

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

/* ========== Uniswap V2 Interfaces ========== */
interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IUniswapV2Router02 {
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

/* ========== Helper Contracts ========== */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) { return msg.sender; }
}

abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() { _transferOwnership(_msgSender()); }

    modifier onlyOwner() { require(owner() == _msgSender(), "Ownable: not owner"); _; }

    function owner() public view virtual returns (address) { return _owner; }

    function renounceOwnership() public virtual onlyOwner { _transferOwnership(address(0)); }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner zero");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

/* ===============================================================================
   ZIPPY TOKEN
   =============================================================================== */
contract Zippy is Context, IERC20Metadata, Ownable {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;

    string private _name = "Zippy";
    string private _symbol = "ZIPPY";
    uint8 private constant _decimals = 18;

    // ========== Supply ==========
    uint256 public constant TOTAL_SUPPLY = 225_000_000_000 * (10 ** 18);

    // ========== Allocation (basis points) ==========
    uint256 public constant MARKETING_PCT       = 150; 
    uint256 public constant AIRDROP_BURN_PCT    = 150; 
    uint256 public constant ZIPPY_DEV_PCT       = 165; 
    uint256 public constant AI_CREATOR_PCT      = 125; 
    uint256 public constant SOCIAL_TEAM_PCT     = 145; 
    uint256 public constant DEX_LISTING_PCT     = 135; 
    uint256 public constant MERCH_PCT           = 125; 

    uint256 public constant MARKETING_WALLET_AMT     = (TOTAL_SUPPLY * MARKETING_PCT) / 10_000;
    uint256 public constant AIRDROP_BURN_WALLET_AMT  = (TOTAL_SUPPLY * AIRDROP_BURN_PCT) / 10_000;
    uint256 public constant ZIPPY_DEV_WALLET_AMT     = (TOTAL_SUPPLY * ZIPPY_DEV_PCT) / 10_000;
    uint256 public constant AI_CREATOR_WALLET_AMT    = (TOTAL_SUPPLY * AI_CREATOR_PCT) / 10_000;
    uint256 public constant SOCIAL_TEAM_WALLET_AMT   = (TOTAL_SUPPLY * SOCIAL_TEAM_PCT) / 10_000;
    uint256 public constant DEX_LISTING_WALLET_AMT   = (TOTAL_SUPPLY * DEX_LISTING_PCT) / 10_000;
    uint256 public constant MERCH_WALLET_AMT         = (TOTAL_SUPPLY * MERCH_PCT) / 10_000;

    // ========== Tax Wallets ==========
    address public constant MARKETING_WALLET    = 0x99DD6e4311dEBE2dbb3469810B403fa7E289Ffe5;
    address public constant AIRDROP_BURN_WALLET = 0x408A3E9d99D15Ac4865bb1a0b7AD61F6c7840d33;

    // ========== Tax Settings ==========
    uint256 public constant BUY_TAX_BPS = 25;    
    uint256 public constant SELL_TAX_BPS = 25;   
    uint256 public constant BASIS_POINTS = 10_000;

    // ========== Uniswap ==========
    address public uniswapV2Pair;
    IUniswapV2Router02 public constant uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    bool public taxEnabled = true;

    constructor() {
        // Pre-mint allocations
        _mint(0x99DD6e4311dEBE2dbb3469810B403fa7E289Ffe5, MARKETING_WALLET_AMT);     
        _mint(0x408A3E9d99D15Ac4865bb1a0b7AD61F6c7840d33, AIRDROP_BURN_WALLET_AMT);  
        _mint(0xcA42bd338B2b7379a923B890021D9B03bB32060A, ZIPPY_DEV_WALLET_AMT);     
        _mint(0x8b6cE789da97024298496f03bAb131e1470A0AAd, AI_CREATOR_WALLET_AMT);    
        _mint(0x9480Da6267c1407E97180feC1C8A6C372d4768A4, SOCIAL_TEAM_WALLET_AMT);   
        _mint(0x2E12AE592f4F079C1aA1e12D5ead65793b65a900, DEX_LISTING_WALLET_AMT);   
        _mint(0x38153239D215CAC487B496F04584D7CFa3B8cB1A, MERCH_WALLET_AMT);         

        uint256 allocated = MARKETING_WALLET_AMT + AIRDROP_BURN_WALLET_AMT +
                            ZIPPY_DEV_WALLET_AMT + AI_CREATOR_WALLET_AMT +
                            SOCIAL_TEAM_WALLET_AMT + DEX_LISTING_WALLET_AMT +
                            MERCH_WALLET_AMT;

        _mint(owner(), TOTAL_SUPPLY - allocated);
    }

    /* ========== ERC20 Metadata ========== */
    function name() public view virtual override returns (string memory) { return _name; }
    function symbol() public view virtual override returns (string memory) { return _symbol; }
    function decimals() public view virtual override returns (uint8) { return _decimals; }

    /* ========== ERC20 Core ========== */
    function totalSupply() public view virtual override returns (uint256) { return _totalSupply; }
    function balanceOf(address account) public view virtual override returns (uint256) { return _balances[account]; }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), to, amount);
        return true;
    }

    function allowance(address ownerAddr, address spender) public view virtual override returns (uint256) {
        return _allowances[ownerAddr][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        uint256 currentAllowance = _allowances[from][_msgSender()];
        require(currentAllowance >= amount, "ERC20: allowance exceeded");
        _transfer(from, to, amount);
        _approve(from, _msgSender(), currentAllowance - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual override returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual override returns (bool) {
        uint256 current = _allowances[_msgSender()][spender];
        require(current >= subtractedValue, "ERC20: decreased below zero");
        _approve(_msgSender(), spender, current - subtractedValue);
        return true;
    }

    /* ========== Internal Transfer with Tax ========== */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "Zero address from");
        require(recipient != address(0), "Zero address to");
        require(amount > 0, "Amount zero");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "Insufficient balance");

        bool isBuy = (sender == uniswapV2Pair) && (uniswapV2Pair != address(0));
        bool isSell = (recipient == uniswapV2Pair) && (uniswapV2Pair != address(0));

        uint256 tax = 0;
        address taxWallet = address(0);

        if (taxEnabled && (isBuy || isSell)) {
            uint256 taxRate = isBuy ? BUY_TAX_BPS : SELL_TAX_BPS;
            tax = (amount * taxRate) / BASIS_POINTS;
            taxWallet = isBuy ? MARKETING_WALLET : AIRDROP_BURN_WALLET;

            _balances[taxWallet] += tax;
            emit Transfer(sender, taxWallet, tax);
        }

        uint256 amountAfterTax = amount - tax;

        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amountAfterTax;

        emit Transfer(sender, recipient, amountAfterTax);
    }

    /* ========== Mint / Burn ========== */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "Mint to zero");
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "Burn from zero");
        uint256 bal = _balances[account];
        require(bal >= amount, "Burn exceeds balance");
        _balances[account] = bal - amount;
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }

    function burn(uint256 amount) external {
        _burn(_msgSender(), amount);
    }

    function _approve(address ownerAddr, address spender, uint256 amount) internal virtual {
        require(ownerAddr != address(0) && spender != address(0), "Zero address");
        _allowances[ownerAddr][spender] = amount;
        emit Approval(ownerAddr, spender, amount);
    }

    /* ========== Owner Controls ========== */
    function setTaxEnabled(bool enabled) external onlyOwner {
        taxEnabled = enabled;
    }

    function createPair() public onlyOwner returns (address pair) {
        pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Pair = pair;
    }

    function addLiquidity(uint256 tokenAmount, uint256 minToken, uint256 minETH) external payable onlyOwner {
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        if (uniswapV2Pair == address(0)) {
            createPair();
        }

        uniswapV2Router.addLiquidityETH{value: msg.value}(
            address(this),
            tokenAmount,
            minToken,
            minETH,
            owner(),
            block.timestamp + 300
        );
    }

    // Emergency withdraw ETH (if stuck)
    function withdrawETH() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    receive() external payable {}
}