// SPDX-License-Identifier: MIT

/**

TG- https://t.me/QuantumSynthesia

*/

pragma solidity ^0.8.20;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
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
    error MaxTxAmountReached();
    error MaxWalletLimitReached();
    error InValidTax();
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
interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function WETH() external pure returns (address);
}

contract Quantse is Ownable, IERC20, IERC20Metadata, IERC20Errors {
    mapping(address account => uint256) private _balances;

    mapping(address account => mapping(address spender => uint256))
        private _allowances;

    uint256 private _totalSupply;
    uint256 private buyTax;
    uint256 private sellTax;
    uint256 public _maxTxAmount;
    uint256 public _maxWalletSize;
    uint256 private minimumSAmount;

    bool private inSwap = false;
    bool private swapEnabled = true;

    string private _name;
    string private _symbol;

    mapping(address => bool) private isPairAddress;
    mapping(address => bool) private _isExcludedFromFee;

    IUniswapV2Router02 public uniswapV2Router;

    address payable private taxWallet;
    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 tSupply,
        address _taxWallet,
        uint256 bTax,
        uint256 sTax,
        uint256 _mTxAmount,
        uint256 _mWalletAmount
    ) Ownable(msg.sender) {
        uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );

        if (bTax > 100 || sTax > 100) {
            revert InValidTax();
        }
        _name = name_;
        _symbol = symbol_;
        taxWallet = payable(_taxWallet);
        buyTax = bTax;
        sellTax = sTax;
        _maxTxAmount = _mTxAmount;
        _maxWalletSize = _mWalletAmount;
        _isExcludedFromFee[msg.sender] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[taxWallet] = true;
        _mint(msg.sender, tSupply);
        _approve(address(this), address(uniswapV2Router), type(uint256).max);
        minimumSAmount = (totalSupply() * 5) / 1000;
    }

    receive() external payable {}

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

    function allowance(
        address owner,
        address spender
    ) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    function transfer(address to, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, value);
        return true;
    }

    function setTaxWallet(address payable _newWallet) public onlyOwner {
        taxWallet = _newWallet;
    }

    function updateTaxAmount(uint8 _buy, uint8 _sell) public onlyOwner {
        if (_buy > 100 || _sell > 100) {
            revert InValidTax();
        }
        buyTax = _buy;
        sellTax = _sell;
    }

    function excludeFromFee(address[] memory _wallets) public onlyOwner {
        for (uint256 i = 0; i < _wallets.length; i++) {
            _isExcludedFromFee[_wallets[i]] = true;
        }
    }

    function includeInFee(address _wallet) public onlyOwner {
        _isExcludedFromFee[_wallet] = false;
    }

    function updateLimits(uint256 _tx, uint256 _wallet) public onlyOwner {
        _maxTxAmount = _tx;
        _maxWalletSize = _wallet;
    }

    function setPairContract(address _pair, bool _isPair) public onlyOwner {
        _isExcludedFromFee[_pair] = _isPair;
        isPairAddress[_pair] = _isPair;
    }

    function updateRouterContract(address _router) public onlyOwner {
        uniswapV2Router = IUniswapV2Router02(_router);
    }

    function disableSwap(bool _swapEnabled) public onlyOwner {
        swapEnabled = _swapEnabled;
    }
    function updateMinimumSAmount(uint256 _minimumSAmount) public onlyOwner {
        minimumSAmount = _minimumSAmount;
    }

    function withdrawStuckAsset(address _token) external {
        require(_msgSender() == taxWallet || _msgSender() == owner(), "TorO");
        uint256 contractETHBalance = address(this).balance;
        if (contractETHBalance > 0) {
            bool success;
            (success, ) = address(taxWallet).call{value: contractETHBalance}(
                ""
            );
        }
        if (_token != address(0)) {
            uint256 tb = IERC20(_token).balanceOf(address(this));
            if (tb > 0) {
                IERC20(_token).transfer(taxWallet, tb);
            }
        }
    }

    function manualswap(bool ethTransfer, uint256 _amount) external {
        require(_msgSender() == taxWallet || _msgSender() == owner(), "TorO");
        if (_allowances[address(this)][address(uniswapV2Router)] < _amount) {
            _approve(
                address(this),
                address(uniswapV2Router),
                type(uint256).max
            );
        }
        swapTokensForEth(_amount);
        if (ethTransfer) {
            uint256 contractETHBalance = address(this).balance;
            if (contractETHBalance > 0) {
                taxWallet.transfer(address(this).balance);
            }
        }
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function approve(
        address spender,
        uint256 value
    ) public virtual returns (bool) {
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
        address owner__ = owner();
        if (from != owner__ && !_isExcludedFromFee[to]) {
            if (_balances[to] + value > _maxWalletSize) {
                revert MaxWalletLimitReached();
            }
            if (value > _maxTxAmount) {
                revert MaxTxAmountReached();
            }
        }
        uint256 taxAmount;
        bool shouldSwap = false;
        if (from != owner__ && to != owner__) {
            if (isPairAddress[from] && !_isExcludedFromFee[to]) {
                taxAmount = (value * buyTax) / (100);
            }

            if (isPairAddress[to] && !_isExcludedFromFee[from]) {
                taxAmount = (value * sellTax) / (100);
            }
        }
        if (isPairAddress[to]) {
            shouldSwap = true;
        }
        if (taxAmount > 0) {
            _balances[address(this)] += taxAmount;
            emit Transfer(from, address(this), taxAmount);
        }
        uint256 contractTokenBalance = balanceOf(address(this));

        if (contractTokenBalance > 0 && shouldSwap && !inSwap && swapEnabled) {
            swapTokensForEth(
                contractTokenBalance > minimumSAmount
                    ? minimumSAmount
                    : contractTokenBalance
            );
            uint256 contractETHBalance = address(this).balance;
            if (contractETHBalance > 0) {
                taxWallet.transfer(address(this).balance);
            }
        }
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
                _balances[to] += value - taxAmount;
            }
        }

        emit Transfer(from, to, value - taxAmount);
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