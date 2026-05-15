// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.25;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        payable(owner()).transfer(address(this).balance);
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

contract FXT6900 is Context, IERC20, Ownable {
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromMaxWallet;

    uint8 private constant _decimals = 9;
    uint256 private _tTotal = 69000000000 * 10**_decimals;
    string private constant _name = unicode"Frog X Toad 6900";
    string private constant _symbol = unicode"FXT";
    
    uint256 public _maxTxAmount = 1380000000 * 10**_decimals;
    uint256 public _maxWalletSize = 1380000000 * 10**_decimals;

    event MaxTxAmountUpdated(uint256 maxTxAmount);
    event MaxWalletSizeUpdated(uint256 maxWalletSize);

    constructor () payable {
        _balances[_msgSender()] = _tTotal;

        // Exclude owner and Uniswap V2 router from max wallet limits
        _isExcludedFromMaxWallet[_msgSender()] = true;
        _isExcludedFromMaxWallet[0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D] = true;

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from zero");
        require(spender != address(0), "ERC20: approve to zero");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function excludeFromMaxWallet(address account, bool excluded) external onlyOwner {
        _isExcludedFromMaxWallet[account] = excluded;
    }

    function isExcludedFromMaxWallet(address account) external view returns (bool) {
        return _isExcludedFromMaxWallet[account];
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from zero");
        require(to != address(0), "ERC20: transfer to zero");
        require(amount > 0, "ERC20: transfer amount must be > 0");

        if (!_isExcludedFromMaxWallet[to]) {
            require(_balances[to] + amount <= _maxWalletSize, "Exceeds max wallet size");
        }

        if (amount > _maxTxAmount) {
            require(from == owner() || to == owner(), "Exceeds max tx amount");
        }

        _balances[from] -= amount;
        _balances[to] += amount;
        emit Transfer(from, to, amount);
    }

    function removeLimits() external onlyOwner {
        _maxTxAmount = _tTotal;
        _maxWalletSize = _tTotal;
        emit MaxTxAmountUpdated(_tTotal);
        emit MaxWalletSizeUpdated(_tTotal);
    }

    function restoreLimits(uint256 maxTx, uint256 maxWallet) external onlyOwner {
        require(maxTx > 0 && maxWallet > 0, "Limits must be > 0");
        _maxTxAmount = maxTx;
        _maxWalletSize = maxWallet;
        emit MaxTxAmountUpdated(maxTx);
        emit MaxWalletSizeUpdated(maxWallet);
    }

    function maxTxAmount() external view returns (uint256) {
        return _maxTxAmount;
    }

    function maxWalletSize() external view returns (uint256) {
        return _maxWalletSize;
    }

    function burn(uint256 amount) external {
        require(_balances[_msgSender()] >= amount, "Burn exceeds balance");
        _balances[_msgSender()] -= amount;
        _tTotal -= amount;
        emit Transfer(_msgSender(), address(0), amount);
    }

    receive() external payable {}
}