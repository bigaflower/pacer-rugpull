// SPDX-License-Identifier:MIT
pragma solidity 0.8.20;

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

// Dex Factory contract interface
interface IDexFactory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

// Dex Router contract interface
interface IDexRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
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
        _owner = payable(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    /**
     * @dev Unauthorized reentrant call.
     */
    error ReentrancyGuardReentrantCall();

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        if (_status == _ENTERED) {
            revert ReentrancyGuardReentrantCall();
        }

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        _status = _NOT_ENTERED;
    }

    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

contract Pulse is Context, IERC20, Ownable, ReentrancyGuard {
    string private _name;
    string private _symbol;
    uint8 private _decimals = 18;
    uint256 private _totalSupply = 10000000 ether;
    uint256 public minSwapAmount;
    bool public trading;
    uint256 public launchedAt;

    uint256 public taxFeeOnBuy = 30;
    uint256 public taxFeeOnSell = 30;
    uint256 public percentDivider = 100;
    bool public distributeAndLiquifyStatus = true;

    address public feeReceiver; // fee receiver
    bool public feesStatus = true; // enable by default
    
    uint256 public maxTransactionAmount; // Max transaction limit (1% of total supply by default)

    IDexRouter public dexRouter; //Uniswap  router declaration
    address public dexPair; //Uniswap  pair address declaration

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public isExcludedFromFee;

    event ExcludeFromFee(address indexed account, bool isExcluded);
    event NewSwapAmount(uint256 newAmount);
    event DistributionStatus(bool Status);
    event FeeStatus(bool Status);

    event feeReceiverUpdated(
        address indexed newWallet,
        address indexed oldWallet
    );

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    event TaxFeeUpdated(
        string indexed feeType,
        uint256 oldFee,
        uint256 newFee
    );

    event MaxTransactionAmountUpdated(
        uint256 oldAmount,
        uint256 newAmount
    );

    constructor(
        string memory __name,
        string memory __symbol,
        address __feeReceiver
    ) {
        _name = __name;
        _symbol = __symbol;
        _balances[owner()] = _totalSupply;
        feeReceiver = __feeReceiver;
        minSwapAmount = _totalSupply;
        maxTransactionAmount = _totalSupply / 100; // 1% of total supply

        //exclude owner and this contract from fees
        isExcludedFromFee[owner()] = true;
        isExcludedFromFee[address(this)] = true;

        IDexRouter _dexRouter = IDexRouter( 
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        // Create a dex pair for this new ERC20
        address _dexPair = IDexFactory(_dexRouter.factory()).createPair(
            address(this),
            _dexRouter.WETH()
        );
        dexPair = _dexPair;

        // set the rest of the contract variables
        dexRouter = _dexRouter;

        isExcludedFromFee[address(dexRouter)] = true;
        emit Transfer(address(0), owner(), _totalSupply);
    }

    // Public viewable functions
    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
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
            _allowances[sender][_msgSender()] - amount
        );
        return true;
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + (addedValue)
        );
        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] - subtractedValue
        );
        return true;
    }

    function calculateBuyTax(uint256 amount) public view returns (uint256) {
        uint256 fee = (amount * taxFeeOnBuy) / percentDivider;
        return fee;
    }

    function calculateSellTax(uint256 amount) public view returns (uint256) {
        uint256 fee = (amount * taxFeeOnSell) / percentDivider;
        return fee;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "Approve from the zero address");
        require(spender != address(0), "Approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "Transfer from the zero address");
        require(to != address(0), "Transfer to the zero address");
        require(amount > 0, " Amount must be greater than zero");
        
        // Max transaction limit check (owner is exempt)
        if (from != owner() && to != owner()) {
            require(
                amount <= maxTransactionAmount,
                "Transfer amount exceeds max transaction limit"
            );
        }
        
        // trading disable till launch
        if (!trading) {
            require(
                (from == owner() && to == dexPair) ||
                    (from == dexPair && to == owner()) ||
                    (from != dexPair && to != dexPair),
                "Trading not enabled yet"
            );
        }

        //indicates if fee should be deducted from transfer
        bool takeFee = true;

        //if any account belongs to isExcludedFromFee account then remove the fee
        if (isExcludedFromFee[from] || isExcludedFromFee[to] || !feesStatus) {
            takeFee = false;
        }

        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from, to, amount, takeFee);
    }

    //this method is responsible for processing all fee, if takeFee is true
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (dexPair == sender && takeFee) {
            distributeAndLiquify(sender, recipient);

            uint256 allFee;
            uint256 tTransferAmount;
            allFee = calculateBuyTax(amount);
            tTransferAmount = amount - allFee;

            _balances[sender] = _balances[sender] - amount;
            _balances[recipient] = _balances[recipient] + tTransferAmount;
            emit Transfer(sender, recipient, tTransferAmount);

            takeTokenFee(sender, allFee);
        } else if (dexPair == recipient && takeFee) {
            distributeAndLiquify(sender, recipient);

            uint256 allFee = calculateSellTax(amount);
            uint256 tTransferAmount = amount - allFee;
            _balances[sender] = _balances[sender] - amount;
            _balances[recipient] = _balances[recipient] + tTransferAmount;
            emit Transfer(sender, recipient, tTransferAmount);

            takeTokenFee(sender, allFee);
        } else {
            _balances[sender] = _balances[sender] - amount;
            _balances[recipient] = _balances[recipient] + (amount);
            emit Transfer(sender, recipient, amount);
        }
    }

    function takeTokenFee(address sender, uint256 amount) private {
        _balances[address(this)] = _balances[address(this)] + amount;

        emit Transfer(sender, address(this), amount);
    }

    // Withdraw stuck ETH
    function removeETH(uint256 _amount) external onlyOwner nonReentrant {
        require(address(this).balance >= _amount, "Invalid Amount");

        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "Failed to send ETH to fee receiver");
    }

    // Withdraw stuck tokens (any ERC20 token)
    function removeStuckTokens(address _token, uint256 _amount) external onlyOwner nonReentrant {
        require(_token != address(0), "Token address cannot be zero");
        
        IERC20 token = IERC20(_token);
        uint256 balance = token.balanceOf(address(this));
        require(balance >= _amount, "Insufficient token balance");
        
        require(token.transfer(msg.sender, _amount), "Token transfer failed");
    }

    function launch() external onlyOwner {
        require(!trading, "Already enabled");
        trading = true;
        launchedAt = block.timestamp;
    }

    //callable by contract
    function distributeAndLiquify(address from, address to) private {
        uint256 contractTokenBalance = balanceOf(address(this));

        if (
            contractTokenBalance >= minSwapAmount &&
            from != dexPair &&
            distributeAndLiquifyStatus &&
            !(from == address(this) && to == dexPair) // swap 1 time
        ) {
            // approve contract
            _approve(address(this), address(dexRouter), minSwapAmount);

            // lock into liquidty pool
            Utils.swapTokensForEth(
                address(dexRouter),
                address(this),
                minSwapAmount
            );
            uint256 ethForMarketing = address(this).balance;

            // sending Eth to Marketing wallet
            if (ethForMarketing > 0) {
                (bool success, ) = payable(feeReceiver).call{
                    value: ethForMarketing
                }("");
                require(success, "Failed to send ETH to fee receiver");
            }
        }
    }

    function changeSwapAmount(uint256 _amount) external onlyOwner {
        require(_amount > 0, "min swap amount should be greater than zero");
        minSwapAmount = _amount * 1e18;
        emit NewSwapAmount(minSwapAmount);
    }

    function setDistributionStatus(bool _value) external onlyOwner {
        // Check if the new value is different from the current state
        require(
            _value != distributeAndLiquifyStatus,
            "Value must be different from current state"
        );
        distributeAndLiquifyStatus = _value;
        emit DistributionStatus(_value);
    }

    // to change fee receiver wallet
    function updateFeeWallet(address newfeeReceiver) external onlyOwner {
        require(
            newfeeReceiver != address(0),
            "Ownable: new feeReceiver is the zero address"
        );
        emit feeReceiverUpdated(newfeeReceiver, feeReceiver);
        feeReceiver = newfeeReceiver;
    }

    /**
     * @dev Owner can decrease buy tax fee (cannot increase)
     * @param _newTaxFee New buy tax fee (must be less than or equal to current fee)
     */
    function changeBuyTaxFee(uint256 _newTaxFee) external onlyOwner {
        require(
            _newTaxFee <= taxFeeOnBuy,
            "Cannot increase tax fee, only decrease allowed"
        );
        require(_newTaxFee <= percentDivider, "Tax fee cannot exceed 100%");
        
        uint256 oldFee = taxFeeOnBuy;
        taxFeeOnBuy = _newTaxFee;
        emit TaxFeeUpdated("Buy", oldFee, _newTaxFee);
    }

    /**
     * @dev Owner can decrease sell tax fee (cannot increase)
     * @param _newTaxFee New sell tax fee (must be less than or equal to current fee)
     */
    function changeSellTaxFee(uint256 _newTaxFee) external onlyOwner {
        require(
            _newTaxFee <= taxFeeOnSell,
            "Cannot increase tax fee, only decrease allowed"
        );
        require(_newTaxFee <= percentDivider, "Tax fee cannot exceed 100%");
        
        uint256 oldFee = taxFeeOnSell;
        taxFeeOnSell = _newTaxFee;
        emit TaxFeeUpdated("Sell", oldFee, _newTaxFee);
    }

    /**
     * @dev Owner can change max transaction amount
     * @param _newMaxTransactionAmount New max transaction amount (cannot be lower than 0.5% of total supply)
     */
    function changeMaxTransactionAmount(uint256 _newMaxTransactionAmount) external onlyOwner {
        uint256 minLimit = _totalSupply / 200; // 0.5% of total supply
        require(
            _newMaxTransactionAmount >= minLimit,
            "Max transaction amount cannot be lower than 0.5% of total supply"
        );
        require(_newMaxTransactionAmount <= _totalSupply, "Max transaction amount cannot exceed total supply");
        
        uint256 oldAmount = maxTransactionAmount;
        maxTransactionAmount = _newMaxTransactionAmount;
        emit MaxTransactionAmountUpdated(oldAmount, _newMaxTransactionAmount);
    }

    //to receive ETH from dexRouter when swapping
    receive() external payable {}
}

// Library dex swap
library Utils {
    function swapTokensForEth(
        address routerAddress,
        address tokenAddress,
        uint256 tokenAmount
    ) internal {
        IDexRouter dexRouter = IDexRouter(routerAddress);

        // generate the Dex pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = tokenAddress;
        path[1] = dexRouter.WETH();

        // make the swap
        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            tokenAddress,
            block.timestamp + 300
        );
    }
}