// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Ownable} from "./utils/Ownable.sol";
import {IERC20} from "./interfaces/IERC20.sol";
import {IERC20Metadata} from "./interfaces/IERC20Metadata.sol";
import {IERC20Errors} from "./interfaces/IERC20Errors.sol";
import {IUniswapV2Router02} from "./interfaces/IUniswapV2Router02.sol";
import {IUniswapV2Factory} from "./interfaces/IUniswapV2Factory.sol";

/*
==  ADO Protocol is an ecosystem designed to improve on-chain efficiency
==  and connect Web2 businesses with blockchain technology.
  https://www.adoprotocol.com
  https://x.com/adoprotocol
  https://t.me/AdoProtocolEnglish
  https://medium.com/@AdoProtocol
*/
contract ADOToken is Ownable, IERC20, IERC20Metadata, IERC20Errors {
    string private _name = "ADO Protocol";
    string private _symbol = "ADO";
    uint8 _decimals = 18;
    mapping(address account => uint256) private _balances;
    mapping(address account => mapping(address spender => uint256)) private _allowances;
    IUniswapV2Router02 public immutable _uniswapRouter;
    address public immutable deployer;
    mapping(address => bool) private _isLP;
    bool private _swapping = false;
    uint256 private _totalSupply;
    uint256 private _tokensToLiqudate;
    uint256 private _fee = 5;
    address private _stableToken;
    address private _wETHlp;
    address private _stablelp;

    event TokenFeeUpdate(uint256 oldFee, uint256 newFee);
    event TokenBalanceToLiqudate(uint256 indexed newValue, uint256 indexed oldValue);

    modifier lockTheSwap() {
        _swapping = true;
        _;
        _swapping = false;
    }

    modifier onlyDeployer() {
        require(_msgSender() == deployer, "Token: Only the token deployer can call this function");
        _;
    }

    constructor() {
        deployer = _msgSender();
        _mint(_msgSender(), 1000000000 * (10 ** _decimals));
        _tokensToLiqudate = _totalSupply / 10000;
        _uniswapRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(_uniswapRouter), type(uint256).max);
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    function fee() external view returns(uint256) {
		return _fee;
	}

    function wETHlp() public view returns (address) {
        return _wETHlp;
    }

    function stablelp() public view returns (address) {
        return _stablelp;
    }

    function stableToken() public view returns (address) {
        return _stableToken;
    }

    function isLP(address account) public view returns (bool) {
        return _isLP[account];
    }

    function tokensToLiqudate() external view returns(uint256) {
		return _tokensToLiqudate;
	}

    function transfer(address to, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, value);
        return true;
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

    function updateStableToken(address stableERC20Token) external onlyDeployer returns (bool) {
        require(stableERC20Token.code.length > 0, "Token: stableToken, not a valid contract");
        IUniswapV2Factory factory = IUniswapV2Factory(_uniswapRouter.factory());
        if (_wETHlp == address(0)) {
            _wETHlp = factory.getPair(address(this), _uniswapRouter.WETH());
            _isLP[_wETHlp] = true;
        }
        _stablelp = factory.getPair(address(this), stableERC20Token);
        if (_stablelp != address(0)) {
            _stableToken = stableERC20Token;
            _isLP[_stablelp] = true;
        }
        return _isLP[_stablelp];
    }

    function updateFee(uint256 newFee) external onlyDeployer returns (bool) {
        require(newFee != _fee, "Token: The Fee is already set to the requested value");
        require(newFee <= 10, "Token: The fee can only be between 0 and 10%");
        emit TokenFeeUpdate(_fee, newFee);
        _fee = newFee;
        return true;
    }

    function updateTokensToLiqudate(uint256 newValue) external onlyDeployer returns (bool) {
        require(newValue >= 10 ** 18 && newValue <= 1000000 * 10 ** 18, "Token: Tokens too liqudate must be between 1 and 1.000.000 ADO");
        emit TokenBalanceToLiqudate(newValue, _tokensToLiqudate);
        _tokensToLiqudate = newValue;
        return true;
    }

    function _swapTokens() private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        if (_balances[_wETHlp] > _balances[_stablelp]) {
            path[1] = _uniswapRouter.WETH();
            _uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
                _tokensToLiqudate,
                0,
                path,
                deployer,
                block.timestamp
            );
        } else {
            path[1] = _stableToken;
            _uniswapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                _tokensToLiqudate,
                0,
                path,
                deployer,
                block.timestamp
            );
        }
    }

    function _transfer(address from, address to, uint256 value) internal {
        if (from == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        if (to == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        bool takeFee = false;
        uint256 _value = value;
        if (_isLP[from] || _isLP[to]) {
            takeFee = tx.origin != deployer;
        }
        if (!_swapping && _fee > 0 && takeFee) {
            if (_isLP[to]) {
                if (_balances[address(this)] >= _tokensToLiqudate) {
                    _swapTokens();
                }
            }
            uint256 txFee = (_value * _fee) / 100;
            _value -= txFee;
            _update(from, address(this), txFee);
        }
        _update(from, to, _value);
    }

    function _update(address from, address to, uint256 value) internal virtual {
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
        if (currentAllowance < type(uint256).max) {
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
