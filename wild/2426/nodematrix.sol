// SPDX-License-Identifier: MIT

/**
 __    _  _______  ______   _______  __   __  _______  _______  ______    ___   __   __ 
|  |  | ||       ||  ┌─D─|─|─┐     ||  |_|  ||   _   ||  ≡T≡  ||░░®░░░▒──|──┐| |0x|_|∴∵|
|   |_| ||   _   ||  |    || │  ___||       ||  |_|  ||_  ≡  _||░░░| |▒  |  || |ᴋᴇᴄᴄᴀᴋ²|
|   N──≡||≡─|█|  || |░|   || │ |___ |┌──M───||─┐     |  | ≡ |  |░░░|_|▒_ |  └I┐ |0xA7»|
|  _    ||  |█|  || |▒|   || E ┤████|┘      || [Â]───|──|─≡─|┐ |░░░░░░░░||   |└K|0xEF»| 
| | |   ||   └─O─||──┘    ||   |___ | ||_|| ||   _   |  |   |└─|▒▒▒|  |▒||   | |∴∵∴_∴∵∴|
|_|  |__||_______||______| |_______||_|   |_||__| |__|  |___|  |▓▓▓|  |▓||___| |__| |__| ⊻
 * 
 * ╔═══≡
 * ║
 * ╠==============================================╗
 * ║ NODEMATRIX — The automation layer on the EVM ║
 * ╠==============================================╝
 * ║
 * ║ NodeMatrix is a programmable automation system that lets users build blockchain logic the same
 * ║ way they would design a visual flowchart. Instead of writing low-level smart contracts, users
 * ║ connect nodes together to define automations, trading logic, agents, and on-chain strategies.
 * ║
 * ¹┐Links:
 *  ├ Website × https://nodematrix.one/
 *  ├ Telegram × https://t.me/nodematrix_tg
 *  ├ Twitter × https://x.com/nodematrix_x
 *  ├ MatrixDocs × https://matrixdocs.one/docs
 *  ├ API × https://api.nodematrix.one/
 *  └ Git/Repos × https://github.com/nodematrixgit
 * 
 * ²┐Features:
 *  ├ Automated flows for trading, staking & routing
 *  ├ Liquidity, LP & token execution logic
 *  ├ Detection, alerts & reactive execution
 *  └ Agent-driven on-chain automation
 *
 * ³┐Tokenomics:
 *  ├ Supply: 10,000,000,000 NOX
 *  ├ Taxes: Buy 5% | Sell 5% |
 *  └ Auto-swap + Rewards in ETH
 */

pragma solidity ^0.8.20;

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

interface IUniswapV2Router02 {
    function WETH() external pure returns (address);
    function factory() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn, uint256 amountOutMin, address[] calldata path,
        address to, uint256 deadline
    ) external;
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previous, address indexed current);
    constructor(address initialOwner) {
        require(initialOwner != address(0), "Owner cannot be zero");
        _owner = initialOwner;
        emit OwnershipTransferred(address(0), initialOwner);
    }
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Caller is not the owner");
        _;
    }
    function owner() public view returns (address) {
        return _owner;
    }
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner cannot be zero");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    function renounceOwnership() external onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _tokenName;
    string private _tokenSymbol;
    uint8 private constant _decimals = 18;

    constructor(string memory name_, string memory symbol_) {
        _tokenName = name_;
        _tokenSymbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _tokenName;
    }

    function symbol() public view virtual override returns (string memory) {
        return _tokenSymbol;
    }

    function decimals() public pure virtual override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount); return true;
    }

    function allowance(address owner_, address spender) public view virtual override returns (uint256) {
        return _allowances[owner_][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount); return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer > allowance");
        if (currentAllowance != type(uint256).max) {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0) && to != address(0), "Zero address");
        uint256 fromBal = _balances[from];
        require(fromBal >= amount, "Insufficient balance");
        _balances[from] = fromBal - amount;
        _balances[to] += amount;
        emit Transfer(from, to, amount);
    }

    function _mint(address to, uint256 amount) internal virtual {
        require(to != address(0), "Mint to zero");
        _totalSupply += amount;
        _balances[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    function _approve(address owner_, address spender, uint256 amount) internal virtual {
        require(owner_ != address(0) && spender != address(0), "Zero address");
        _allowances[owner_][spender] = amount;
        emit Approval(owner_, spender, amount);
    }
}

contract NodeMatrix is ERC20, Ownable {
    IUniswapV2Router02 public immutable router;
    address public immutable pair;

    address public treasuryWallet;
    address public dev1Wallet;
    address public dev2Wallet;

    uint256 public treasuryShare = 50;
    uint256 public dev1Share = 30;
    uint256 public dev2Share = 20;

    uint256 public buyTax = 5;
    uint256 public sellTax = 5;
    uint256 public swapThreshold;
    bool public tradingEnabled = false;
    bool private inSwap;

    mapping(address => bool) public isExcludedFromFees;
    mapping(address => bool) public isExcludedFromMaxWallet;

    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor(
        address _router,
        address _treasury,
        address _dev1,
        address _dev2
    ) ERC20("NodeMatrix", "NOX") Ownable(msg.sender) {
        require(_treasury != address(0) && _dev1 != address(0) && _dev2 != address(0), "Zero wallet");
        router = IUniswapV2Router02(_router);
        pair = IUniswapV2Factory(router.factory()).createPair(address(this), router.WETH());

        treasuryWallet = _treasury;
        dev1Wallet = _dev1;
        dev2Wallet = _dev2;

        isExcludedFromFees[msg.sender] = true;
        isExcludedFromFees[address(this)] = true;
        isExcludedFromMaxWallet[msg.sender] = true;
        isExcludedFromMaxWallet[address(this)] = true;
        isExcludedFromMaxWallet[pair] = true;

        swapThreshold = 500_000 * 10 ** decimals(); // Default: 0.05% of supply
        _mint(msg.sender, 1_000_000_000 * 10 ** decimals()); // 1B supply
    }

    function enableTrading() external onlyOwner {
        tradingEnabled = true;
    }

    function setWallets(address _treasury, address _dev1, address _dev2) external onlyOwner {
        require(_treasury != address(0) && _dev1 != address(0) && _dev2 != address(0), "Zero address");
        treasuryWallet = _treasury;
        dev1Wallet = _dev1;
        dev2Wallet = _dev2;
    }

    function setTaxRates(uint256 _buy, uint256 _sell) external onlyOwner {
        require(_buy <= 10 && _sell <= 10, "Tax too high");
        buyTax = _buy;
        sellTax = _sell;
    }

    function setDistributionShares(uint256 _treasury, uint256 _dev1, uint256 _dev2) external onlyOwner {
        require(_treasury + _dev1 + _dev2 == 100, "Shares must total 100");
        treasuryShare = _treasury;
        dev1Share = _dev1;
        dev2Share = _dev2;
    }

    function excludeFromFees(address addr, bool status) external onlyOwner {
        isExcludedFromFees[addr] = status;
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0) && to != address(0), "Zero address");
        require(tradingEnabled || isExcludedFromFees[from] || isExcludedFromFees[to], "Trading disabled");

        if (!inSwap && to == pair && !isExcludedFromFees[from]) {
            uint256 contractBalance = balanceOf(address(this));
            if (contractBalance >= swapThreshold) {
                _swapBack(contractBalance);
            }
        }

        uint256 feeAmount = 0;
        if (!inSwap && !isExcludedFromFees[from] && !isExcludedFromFees[to]) {
            if (from == pair) {
                feeAmount = (amount * buyTax) / 100;
            } else if (to == pair) {
                feeAmount = (amount * sellTax) / 100;
            }
        }

        if (feeAmount > 0) {
            super._transfer(from, address(this), feeAmount);
            amount -= feeAmount;
        }

        super._transfer(from, to, amount);
    }

function _swapBack(uint256 tokenAmount) internal swapping {
    address[] memory path = new address[](2); // Declare the path array
    path[0] = address(this);
    path[1] = router.WETH();

    _approve(address(this), address(router), tokenAmount);

    uint256 beforeETH = address(this).balance;

    router.swapExactTokensForETHSupportingFeeOnTransferTokens(
        tokenAmount,
        0,
        path,
        address(this),
        block.timestamp
    );

    uint256 receivedETH = address(this).balance - beforeETH;

    if (receivedETH > 0) {
        _distributeETH(receivedETH);
    }
}


    function _distributeETH(uint256 amount) internal {
        uint256 toTreasury = (amount * treasuryShare) / 100;
        uint256 toDev1 = (amount * dev1Share) / 100;
        uint256 toDev2 = amount - toTreasury - toDev1;

        payable(treasuryWallet).transfer(toTreasury);
        payable(dev1Wallet).transfer(toDev1);
        payable(dev2Wallet).transfer(toDev2);
    }

    receive() external payable {}
}
