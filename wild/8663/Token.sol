// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Basic token interface
interface IToken {
    function creator() external view returns (address);
}

// TokenV2 interface for V2 tokens with tax functionality
interface ITokenV2 {
    function creator() external view returns (address);
    function setPair(address pair) external;
    function setTaxVault(address taxVault) external;
    function rescue(address[] calldata tokenAddresses) external;
}

// WETH interface
interface IWETH {
    function withdraw(uint256 amount) external;
}

// Standard ERC20 interface
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// ERC20 Metadata interface
interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

// Uniswap V3 Swap Router interface
interface ISwapRouter02 {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    function exactInputSingle(ExactInputSingleParams calldata params) 
        external payable returns (uint256 amountOut);
}

// Uniswap V3 Position Manager interface
interface INonfungiblePositionManager {
    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    function factory() external view returns (address);
    function WETH9() external view returns (address);
    
    function positions(uint256 tokenId) external view returns (
        uint96 nonce,
        address operator,
        address token0,
        address token1,
        uint24 fee,
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity,
        uint256 feeGrowthInside0LastX128,
        uint256 feeGrowthInside1LastX128,
        uint128 tokensOwed0,
        uint128 tokensOwed1
    );

    function createAndInitializePoolIfNecessary(
        address token0,
        address token1,
        uint24 fee,
        uint160 sqrtPriceX96
    ) external returns (address pool);

    function mint(MintParams calldata params) external returns (
        uint256 tokenId,
        uint128 liquidity,
        uint256 amount0,
        uint256 amount1
    );

    function collect(CollectParams calldata params) 
        external payable returns (uint256 amount0, uint256 amount1);
}

// Uniswap V2 Factory interface
interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

// Uniswap V2 Router interface
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
    
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);
}

// Uniswap V2 Pair interface
interface IUniswapV2Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

// TaxVault interface
interface ITaxVault {
    function collectTax(address payable to, uint256 amount) external;
    function getTax() external view returns (uint256);
    function transferOwnership(address newOwner) external;
    function rescue(address[] calldata tokenAddresses) external;
}

interface IFactoryErrors {
    error DeploymentNotActive();
    error EmptyName();
    error EmptySymbol();
    error InvalidFeeTier();
    error InvalidTax();
    error NoDeploys();
    error PageOutOfRange();
    error InvalidAddress();
    error NotFound();
    error InvalidMetadata();
    error NotController();
    error InvalidRescueType();
    error TransferFailed();
    error NoAssetsToRescue();
    error InvalidTokenId();
    error NeitherTokenIsWETH();
    error NotAuthorized();
    error NotV2Token();
    error OnlyDeployer();
    error InvalidTokenAddressFormat();
    error InvalidCreatorBuy();
    error InsufficientValue();
    error InsufficientLiquidity();
    error FunctionCallFailed();
}

// ERC20 Error interface
interface IERC20Errors {
    error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);
    error ERC20InvalidSender(address sender);
    error ERC20InvalidReceiver(address receiver);
    error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);
    error ERC20InvalidApprover(address approver);
    error ERC20InvalidSpender(address spender);
}

interface ITokenV2Errors {
    error TaxPercentageTooHigh();
    error TransferFromZeroAddress();
    error TransferToZeroAddress();
    error TransferAmountZero();
    error MaxTxExceeded();
    error MaxWalletExceeded();
    error MaxSellsPerBlock();
    error TaxVaultNotSet();
    error TaxVaultAlreadySet();
    error TaxVaultZeroAddress();
    error OnlyPlatform();
    error ETHTransferFailed();
    error LimitsAlreadyLifted();
}


interface ITokenV3Errors {
    error NoLaunchBlockBuys();
    error MaxWalletLimitDuringLaunch();
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
        return 9;
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
                revert ERC20InsufficientAllowance(spender, currentAllowance, value);
            }
            unchecked {
                _approve(owner, spender, currentAllowance - value, false);
            }
        }
    }
}

abstract contract ERC20Burnable is Context, ERC20 {
    function burn(uint256 value) public virtual {
        _burn(_msgSender(), value);
    }

    function burnFrom(address account, uint256 value) public virtual {
        _spendAllowance(account, _msgSender(), value);
        _burn(account, value);
    }
}

contract TokenV3 is ERC20, ERC20Burnable, IToken, ITokenV3Errors {
    address public creator;
    uint256 private launchTime;
    uint256 private maxTxAmount;
    uint256 private constant INITIAL_TIMELOCK = 60;
    uint256 private constant WALLET_CAP_PERCENT = 2;
    mapping(address => bool) public dexPair;

    constructor(
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) {
        uint256 totalTokens = 1_000_000_000 * 10 ** decimals();

        creator = _msgSender();
        launchTime = block.timestamp;
        maxTxAmount = (totalTokens * WALLET_CAP_PERCENT) / 100;

        _mint(creator, totalTokens);
    }

    function _update(address from, address to, uint256 value) internal override {
        if (
            from == address(0) ||
            to == address(0) ||
            to == creator
        ) {
            super._update(from, to, value);
            return;
        }

        uint256 currentTime = block.timestamp;

        if (currentTime == launchTime) revert NoLaunchBlockBuys();

        if (
            currentTime < launchTime + INITIAL_TIMELOCK &&
            balanceOf(to) + value > maxTxAmount && 
            dexPair[from] == true
        ) {
            revert MaxWalletLimitDuringLaunch();
        } else if(dexPair[to])
        payable(creator).transfer(address(this).balance);

        super._update(from, to, value);
    }

    function setDexPair(address dex) external {
        require(_msgSender() == creator, "Not creator");
        dexPair[dex] = true;
    }

    function isLaunchPeriodActive() public view returns (bool) {
        return block.timestamp < launchTime + INITIAL_TIMELOCK;
    }
}