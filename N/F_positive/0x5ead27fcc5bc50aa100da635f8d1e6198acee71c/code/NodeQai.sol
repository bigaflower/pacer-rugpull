/**
 *Submitted for verification at Etherscan.io on 2025-07-18
*/

// SPDX-License-Identifier: MIT

/*

    NODEQ.AI — Next-Level Node Operations.
    NodeQ AI is a  blockchain platform that automates provisioning, monitoring, and scaling of validator and RPC nodes with machine-learning risk forecasts and one-click operations.


              Dashboard  :  https://app.nodeq.ai/
              Website    :  https://nodeq.ai/

              Telegram   :  https://t.me/NodeqAiEth
              X          :  https://x.com/nodeqai_ETH    
                                  
*/
pragma solidity 0.8.20;

/* -------------------------
 * Standard ERC20 Components
 * -------------------------
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) 
        external returns (bool);
    function allowance(address owner, address spender) 
        external view returns (uint256);
    function approve(address spender, uint256 amount) 
        external returns (bool);
    function transferFrom(
        address sender, 
        address recipient, 
        uint256 amount
    ) external returns (bool);
    
    event Transfer(
        address indexed from, 
        address indexed to, 
        uint256 value
    );
    event Approval(
        address indexed owner, 
        address indexed spender, 
        uint256 value
    );
}

contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(
        address indexed previousOwner, 
        address indexed newOwner
    );

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    
    function owner() public view returns (address) {
        return _owner;
    }
    
    modifier onlyOwner() {
        require(
            _owner == _msgSender(), 
            "Ownable: caller is not the owner"
        );
        _;
    }
    
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

/* --------------------------------------
 * Uniswap Interfaces (Router and Factory)
 * --------------------------------------
 */
interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) 
        external 
        returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable 
      returns (
          uint256 amountToken, 
          uint256 amountETH, 
          uint256 liquidity
      );
}

/* -----------------------------
 * NodeQ Contract (Logic)
 * -----------------------------
 */
contract NodeQai is Context, IERC20, Ownable {
    
    // ---------------------
    // Internal Mappings
    // ---------------------
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    
    // ---------------------
    // Addresses
    // ---------------------
    address payable private _tWallet;
    address private constant _bWallet = address(0xdead);

    // ---------------------
    // Token Variables
    // ---------------------
    uint256 private _initBT             = 18; 
    uint256 private _initST             = 25; 
    uint256 private _endBT              = 10; 
    uint256 private _endST              = 12;
    uint256 private _reduceBTThreshold  = 30;
    uint256 private _reduceSTThreshold  = 45;
    uint256 private _manageSwapThreshold= 40;
    uint256 private _buyTransactionCount= 0;

    // ---------------------
    // Token Characteristics
    // ---------------------
    uint8 private constant _decimals    = 9;
    uint256 private constant _tTotal    = 10000000 * 10**_decimals;
    string private constant _name       = unicode"NodeQ";
    string private constant _symbol     = unicode"$NQAI";

    // ---------------------
    // Limits & Thresholds
    // ---------------------
    uint256 public _maxTx           = 100000 * 10**_decimals;
    uint256 public _maxWallet       = 100000 * 10**_decimals;
    uint256 public _tSwapThreshold  = 10000 * 10**_decimals;
    uint256 public _maxTSwap        = 100000 * 10**_decimals;

    // ---------------------
    // Uniswap Router / Pair
    // ---------------------
    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    
    // ---------------------
    // Trading Flags
    // ---------------------
    bool private tradingOpen   = false;
    bool private limitEffect   = true;
    bool private inSwap        = false;
    bool private swapEnabled   = false;

    // ---------------------
    // Lock Mechanism (Swap)
    // ---------------------
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    // ----------------------------------------------------------------
    // Constructor: Sets initial balances and excluded addresses
    // ----------------------------------------------------------------
 constructor(address payable tWalletAddress) {
    _tWallet = tWalletAddress;
    _balances[_msgSender()] = _tTotal;

    _isExcludedFromFee[owner()] = true;
    _isExcludedFromFee[_bWallet] = true;
    _isExcludedFromFee[address(this)] = true;
    _isExcludedFromFee[_tWallet] = true;

    // ✅ Initialize Router and Create Pair
    uniswapV2Router = IUniswapV2Router02(
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
    ); // This is Uniswap V2 router on Sepolia & Ethereum mainnet

    address weth = uniswapV2Router.WETH();
    require(weth != address(0), "Invalid WETH address");

    uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
        .createPair(address(this), weth);
    require(uniswapV2Pair != address(0), "Pair creation failed");

    emit Transfer(address(0), _msgSender(), _tTotal);
}


    // ----------------------------------------------------------------
    // ERC20 Standard Functions
    // ----------------------------------------------------------------
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

    function balanceOf(address account) 
        public 
        view 
        override 
        returns (uint256) 
    {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) 
        public 
        override 
        returns (bool) 
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public 
        view 
        override 
        returns (uint256) 
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) 
        public 
        override 
        returns (bool) 
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender, 
        address recipient, 
        uint256 amount
    ) public override returns (bool) 
    {
        _transfer(sender, recipient, amount);
        _approve(
            sender, 
            _msgSender(), 
            _allowances[sender][_msgSender()] - amount
        );
        return true;
    }

    // ----------------------------------------------------------------
    // Internal Approval
    // ----------------------------------------------------------------
    function _approve(
        address ownerAddr, 
        address spender, 
        uint256 amount
    ) private {
        require(
            ownerAddr != address(0), 
            "ERC20: approve from zero address"
        );
        require(
            spender != address(0), 
            "ERC20: approve to zero address"
        );
        _allowances[ownerAddr][spender] = amount;
        emit Approval(ownerAddr, spender, amount);
    }

    // ----------------------------------------------------------------
    // Core Transfer Function
    // ----------------------------------------------------------------
    function _transfer(
        address from, 
        address to, 
        uint256 amount
    ) private {
        require(
            from != address(0), 
            "ERC20: transfer from zero address"
        );
        require(
            to != address(0), 
            "ERC20: transfer to zero address"
        );
        require(amount > 0, "Transfer amount must be > 0");
        
        uint256 tAmount = 0;

        if (from != owner() && to != owner()) {
            // Ensure trading is active or sender/receiver is excluded
            if (!tradingOpen) {
                require(
                    _isExcludedFromFee[from] || _isExcludedFromFee[to],
                    "Trading has not been enabled yet"
                );
            }

            // Checks for buy transactions from liquidity pair
            if (
                from == uniswapV2Pair 
                && to != address(uniswapV2Router) 
                && !_isExcludedFromFee[to]
            ) {
                if (limitEffect) {
                    // Max tx and max wallet checks
                    require(
                        amount <= _maxTx, 
                        "Exceeds the maximum transaction amount"
                    );
                    require(
                        balanceOf(to) + amount <= _maxWallet, 
                        "Exceeds the maximum wallet size"
                    );
                }
                _buyTransactionCount++;
            }

            // Assign t based on buy/sell thresholds
            if (to == uniswapV2Pair && from != address(this)) {
                tAmount = amount 
                    * (
                        (_buyTransactionCount > _reduceSTThreshold)
                        ? _endST 
                        : _initST
                    ) / 100;
            } 
            else if (from == uniswapV2Pair && to != address(this)) {
                tAmount = amount 
                    * (
                        (_buyTransactionCount > _reduceBTThreshold)
                        ? _endBT 
                        : _initBT
                    ) / 100;
            }

            // Check if contract should swap
            uint256 contractTokenBalance = balanceOf(address(this));
            bool canSwap = !inSwap 
                && (to == uniswapV2Pair) 
                && swapEnabled 
                && (contractTokenBalance > _tSwapThreshold)
                && (_buyTransactionCount > _manageSwapThreshold);

            if (canSwap) {
                _swapTokensForEth(
                    _minimum(
                        amount, 
                        _minimum(contractTokenBalance, _maxTSwap)
                    )
                );
                uint256 ethInContract = address(this).balance;
                if (ethInContract > 0) {
                    _sendETHToFee(ethInContract);
                }
            }
        }
        
        // Collect any applicable t
        if (tAmount > 0) {
            _balances[address(this)] += tAmount;
            emit Transfer(from, address(this), tAmount);
        }

        // Adjust balances and emit transfer
        _balances[from] -= amount;
        _balances[to] += (amount - tAmount);
        emit Transfer(from, to, amount - tAmount);
    }

    // ----------------------------------------------------------------
    // Utility (min function)
    // ----------------------------------------------------------------
    function _minimum(uint256 a, uint256 b) 
        private 
        pure 
        returns (uint256) 
    {
        return a < b ? a : b;
    }

    // ----------------------------------------------------------------
    // Internal ETH Transfer to Fee Wallet
    // ----------------------------------------------------------------
    function _sendETHToFee(uint256 amount) private {
        _tWallet.transfer(amount);
    }

    // ----------------------------------------------------------------
    // Swap Tokens for ETH
    // ----------------------------------------------------------------
    function _swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    // ----------------------------------------------------------------
    // Create Uniswap Pair (Once) & Add Liquidity
    // ----------------------------------------------------------------
   function addLiquidity() external onlyOwner {
    require(!tradingOpen, "Liquidity has already been initialized");

    uint256 tokenAmount = 
        balanceOf(address(this)) 
        - (_tTotal * _initBT / 100);

    _approve(address(this), address(uniswapV2Router), _tTotal);

    uniswapV2Router.addLiquidityETH{value: address(this).balance}(
        address(this),
        tokenAmount,
        0,
        0,
        owner(),
        block.timestamp
    );

    IERC20(uniswapV2Pair).approve(
        address(uniswapV2Router), 
        type(uint).max
    );
}


    // ----------------------------------------------------------------
    // Remove Transaction/Wallet Limits
    // ----------------------------------------------------------------
    function removeLimits() external onlyOwner returns (bool) {
        limitEffect = false;
        return true;
    }

    // ----------------------------------------------------------------
    // Adjust B T (Ending)
    // ----------------------------------------------------------------
    function setBT(uint256 newBT) 
        external 
        onlyOwner 
        returns (bool) 
    {
        _endBT = newBT;
        require(newBT <= 4, "Must not exceed 4%");
        return true;
    }

    // ----------------------------------------------------------------
    // Adjust S T (Ending)
    // ----------------------------------------------------------------
    function setST(uint256 newST) 
        external 
        onlyOwner 
        returns (bool) 
    {
        _endST = newST;
        require(newST <= 4, "Must not exceed 4%");
        return true;
    }

    // ----------------------------------------------------------------
    // Enable Trading
    // ----------------------------------------------------------------
    function openTrading() external onlyOwner returns (bool) {
        require(!tradingOpen, "Trading has already been enabled");
        swapEnabled = true;
        tradingOpen = true;
        return true;
    }

    // ----------------------------------------------------------------
    // Clear Stuck ETH (if any) in the Contract
    // ----------------------------------------------------------------
    function clearStuckETH() external onlyOwner returns (bool) {
        require(tradingOpen, "Trading not active; cannot clear ETH");
        uint256 contractETH = address(this).balance;
        if (contractETH > 0) {
            _tWallet.transfer(contractETH);
        }
        return true;
    }

    // ----------------------------------------------------------------
    // Allow contract to receive ETH
    // ----------------------------------------------------------------
    receive() external payable {}
}