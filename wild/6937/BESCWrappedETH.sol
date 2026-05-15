// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: @openzeppelin/contracts/utils/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v5.1.0) (utils/ReentrancyGuard.sol)

pragma solidity ^0.8.20;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If EIP-1153 (transient storage) is available on the chain you're deploying at,
 * consider using {ReentrancyGuardTransient} instead.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    uint256 private _status;

    /**
     * @dev Unauthorized reentrant call.
     */
    error ReentrancyGuardReentrantCall();

    constructor() {
        _status = NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be NOT_ENTERED
        if (_status == ENTERED) {
            revert ReentrancyGuardReentrantCall();
        }

        // Any calls to nonReentrant after this point will fail
        _status = ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == ENTERED;
    }
}

// File: BESCBSC.sol


    pragma solidity ^0.8.20;




    library SafeMath {
        function add(uint256 a, uint256 b) internal pure returns (uint256) {
            uint256 c = a + b;
            require(c >= a, "SafeMath: addition overflow");
            return c;
        }
        function sub(uint256 a, uint256 b) internal pure returns (uint256) {
            return sub(a, b, "SafeMath: subtraction overflow");
        }
        function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
        function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
            require(b > 0, errorMessage);
            uint256 c = a / b;
            return c;
        }
    }

    interface IBEP20 {
        function totalSupply() external view returns (uint256);
        function decimals() external view returns (uint8);
        function symbol() external view returns (string memory);
        function name() external view returns (string memory);
        function getOwner() external view returns (address);
        function balanceOf(address account) external view returns (uint256);
        function transfer(address recipient, uint256 amount) external returns (bool);
        function allowance(address _owner, address spender) external view returns (uint256);
        function approve(address spender, uint256 amount) external returns (bool);
        function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
        event Transfer(address indexed from, address indexed to, uint256 value);
        event Approval(address indexed owner, address indexed spender, uint256 value);
    }

    abstract contract Auth {
        address internal owner;
        mapping (address => bool) internal authorizations;

        constructor(address _owner) {
            owner = _owner;
            authorizations[_owner] = true;
        }

        modifier onlyOwner() {
            require(isOwner(msg.sender), "!OWNER"); _;
        }

        modifier authorized() {
            require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
        }

        function authorize(address account) public onlyOwner {
            authorizations[account] = true;
        }

        function unauthorize(address account) public onlyOwner {
            authorizations[account] = false;
        }

        function isOwner(address account) public view returns (bool) {
            return account == owner;
        }

        function isAuthorized(address account) public view returns (bool) {
            return authorizations[account];
        }

        function transferOwnership(address payable account) public onlyOwner {
            owner = account;
            authorizations[account] = true;
            emit OwnershipTransferred(account);
        }

        event OwnershipTransferred(address owner);
    }

    interface IDEXFactory {
        function createPair(address tokenA, address tokenB) external returns (address pair);
    }

    interface IDEXRouter {
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
        function swapExactETHForTokensSupportingFeeOnTransferTokens(
            uint amountOutMin,
            address[] calldata path,
            address to,
            uint deadline
        ) external payable;
    }

    contract BESCWrappedETH is IBEP20, Auth, Pausable, ReentrancyGuard {
        using SafeMath for uint256;

        address public WBNB;
        address public constant DEAD = 0x000000000000000000000000000000000000dEaD;
        address public constant ZERO = 0x0000000000000000000000000000000000000000;
        address public DEV;
        address public autoLiquidityReceiver;
        address public marketingFeeReceiver;
        address public backend;

        string constant _name = "Wrapped BESC";
        string constant _symbol = "wBESC";
        uint8 constant _decimals = 9;

        uint256 _totalSupply = 0; // No initial supply, minted via bridge
        uint256 public _maxBuyTxAmount = 30_000 * (10 ** _decimals);
        uint256 public _maxSellTxAmount = 30_000 * (10 ** _decimals);
        uint256 public _maxWalletToken = 30_000 * (10 ** _decimals);

        mapping (address => uint256) _balances;
        mapping (address => mapping (address => uint256)) _allowances;
        mapping (address => bool) isFeeExempt;
        mapping (address => bool) isTxLimitExempt;
        mapping (address => bool) isTimelockExempt;
        mapping (address => bool) public isBlacklisted;

        uint256 liquidityFeeBuy = 0;
        uint256 buybackFeeBuy = 0;
        uint256 marketingFeeBuy = 0;
        uint256 devFeeBuy = 0;
        uint256 totalFeeBuy = 0;

        uint256 liquidityFeeSell = 200;
        uint256 buybackFeeSell = 0;
        uint256 marketingFeeSell = 200;
        uint256 devFeeSell = 0;
        uint256 totalFeeSell = 400;

        uint256 liquidityFee;
        uint256 buybackFee;
        uint256 marketingFee;
        uint256 devFee;
        uint256 totalFee;
        uint256 feeDenominator = 10000;

        uint256 GREEDTriggeredAt;
        uint256 GREEDDuration = 3600;
        uint256 deadBlocks = 3;
        uint256 public swapThreshold = 50 * (10 ** _decimals); // 150 BESC tokens
        uint256 targetLiquidity = 20;
        uint256 targetLiquidityDenominator = 100;

        uint256 buybackMultiplierNumerator = 200;
        uint256 buybackMultiplierDenominator = 100;
        uint256 buybackMultiplierTriggeredAt;
        uint256 buybackMultiplierLength = 30 minutes;

        bool public autoBuybackEnabled = false;
        bool public autoBuybackMultiplier = true;
        uint256 autoBuybackCap;
        uint256 autoBuybackAccumulator;
        uint256 autoBuybackAmount;
        uint256 autoBuybackBlockPeriod;
        uint256 autoBuybackBlockLast;

        bool public buyCooldownEnabled = true;
        uint8 public cooldownTimerInterval = 5;
        mapping (address => uint) private cooldownTimer;

        IDEXRouter public router;
        address public pair;
        uint256 public launchedAt;
        bool public tradingOpen = false;
        bool public swapEnabled = true;
        bool inSwap;
        modifier swapping() { inSwap = true; _; inSwap = false; }

        event BurnInitiated(address indexed user, uint256 amount, uint256 fee);

        constructor (
            address _backend,
            address _marketingFeeReceiver,
            address _autoLiquidityReceiver,
            address _dev,
            address _router,
            address _wbnb
        ) Auth(msg.sender) {
            require(_backend != address(0), "Invalid backend address");
            require(_marketingFeeReceiver != address(0), "Invalid marketing fee receiver");
            require(_autoLiquidityReceiver != address(0), "Invalid liquidity receiver");
            require(_dev != address(0), "Invalid dev address");
            require(_router != address(0), "Invalid router address");
            require(_wbnb != address(0), "Invalid WBNB address");

            backend = _backend;
            marketingFeeReceiver = _marketingFeeReceiver;
            autoLiquidityReceiver = _autoLiquidityReceiver;
            DEV = _dev;
            router = IDEXRouter(_router);
            WBNB = _wbnb;
            pair = IDEXFactory(router.factory()).createPair(WBNB, address(this));
            _allowances[address(this)][address(router)] = type(uint256).max;

            isFeeExempt[msg.sender] = true;
            isFeeExempt[address(this)] = true;
            isFeeExempt[_backend] = true;
            isTxLimitExempt[msg.sender] = true;
            isTxLimitExempt[_backend] = true;
            isTimelockExempt[msg.sender] = true;
            isTimelockExempt[DEAD] = true;
            isTimelockExempt[address(this)] = true;
            isTimelockExempt[_dev] = true;
        }

        receive() external payable { }

        function totalSupply() external view override returns (uint256) { return _totalSupply; }
        function decimals() external pure override returns (uint8) { return _decimals; }
        function symbol() external pure override returns (string memory) { return _symbol; }
        function name() external pure override returns (string memory) { return _name; }
        function getOwner() external view override returns (address) { return owner; }
        function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
        function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

        function approve(address spender, uint256 amount) public override returns (bool) {
            _allowances[msg.sender][spender] = amount;
            emit Approval(msg.sender, spender, amount);
            return true;
        }

        function approveMax(address spender) external returns (bool) {
            return approve(spender, type(uint256).max);
        }

        function transfer(address recipient, uint256 amount) external override returns (bool) {
            return _transferFrom(msg.sender, recipient, amount);
        }

        function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
            if(_allowances[sender][msg.sender] != type(uint256).max){
                _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
            }
            return _transferFrom(sender, recipient, amount);
        }

        function mint(address to, uint256 amount) external whenNotPaused nonReentrant {
            require(msg.sender == backend, "Only backend can mint");
            require(amount > 0, "Amount must be greater than 0");
            _totalSupply = _totalSupply.add(amount);
            _balances[to] = _balances[to].add(amount);
            emit Transfer(address(0), to, amount);
        }

        function burn(uint256 amount) external whenNotPaused nonReentrant {
            require(amount > 0, "Amount must be greater than 0");
            uint256 fee = amount.mul(10).div(10000); // 0.1% bridge fee
            uint256 netAmount = amount.sub(fee);
            require(netAmount > 0, "Amount too small after fee");
            _totalSupply = _totalSupply.sub(amount);
            _balances[msg.sender] = _balances[msg.sender].sub(amount, "Insufficient Balance");
            _balances[address(this)] = _balances[address(this)].add(fee); // Fee to contract
            emit Transfer(msg.sender, address(0), netAmount);
            emit BurnInitiated(msg.sender, netAmount, fee);
        }

        function setMaxWalletPercent(uint256 maxWallPercent) external onlyOwner {
            _maxWalletToken = _totalSupply.mul(maxWallPercent).div(10000);
        }

        function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
            if(inSwap){ return _basicTransfer(sender, recipient, amount); }
            if(!authorizations[sender] && !authorizations[recipient]){
                require(tradingOpen,"Trading not enabled yet");
            }
            require(!isBlacklisted[recipient] && !isBlacklisted[sender], 'Address is blacklisted');
            bool isSell = recipient == pair;
            setCorrectFees(isSell);
            checkMaxWallet(sender, recipient, amount);
            checkBuyCooldown(sender, recipient);
            checkTxLimit(sender, amount, recipient, isSell);
            bool GREEDMode = inGREEDTime();
            if(shouldSwapBack()){ swapBack(); }
            _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
            uint256 amountReceived = shouldTakeFee(sender) ? takeFee(sender, amount, isSell, GREEDMode) : amount;
            _balances[recipient] = _balances[recipient].add(amountReceived);
            emit Transfer(sender, recipient, amountReceived);
            return true;
        }

        function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
            _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
            _balances[recipient] = _balances[recipient].add(amount);
            emit Transfer(sender, recipient, amount);
            return true;
        }

        function setCorrectFees(bool isSell) internal {
            if(isSell){
                liquidityFee = liquidityFeeSell;
                buybackFee = buybackFeeSell;
                marketingFee = marketingFeeSell;
                devFee = devFeeSell;
                totalFee = totalFeeSell;
            } else {
                liquidityFee = liquidityFeeBuy;
                buybackFee = buybackFeeBuy;
                marketingFee = marketingFeeBuy;
                devFee = devFeeBuy;
                totalFee = totalFeeBuy;
            }
        }

        function inGREEDTime() public view returns (bool){
            if(GREEDTriggeredAt.add(GREEDDuration) > block.timestamp){
                return true;
            } else {
                return false;
            }
        }

        function checkTxLimit(address sender, uint256 amount, address recipient, bool isSell) internal view {
            if (recipient != owner){
                if(isSell){
                    require(amount <= _maxSellTxAmount || isTxLimitExempt[sender] || isTxLimitExempt[recipient], "TX Limit Exceeded");
                } else {
                    require(amount <= _maxBuyTxAmount || isTxLimitExempt[sender] || isTxLimitExempt[recipient], "TX Limit Exceeded");
                }
            }
        }

        function checkBuyCooldown(address sender, address recipient) internal {
            if (sender == pair &&
                buyCooldownEnabled &&
                !isTimelockExempt[recipient]) {
                require(cooldownTimer[recipient] < block.timestamp,"Please wait between two buys");
                cooldownTimer[recipient] = block.timestamp + cooldownTimerInterval;
            }
        }

        function checkMaxWallet(address sender, address recipient, uint256 amount) internal view {
            if (!authorizations[sender] && recipient != owner && recipient != address(this) && recipient != address(DEAD) && recipient != pair && recipient != marketingFeeReceiver && recipient != autoLiquidityReceiver && recipient != DEV){
                uint256 heldTokens = balanceOf(recipient);
                require((heldTokens + amount) <= _maxWalletToken,"Total Holding is currently limited, you can not buy that much.");
            }
        }

        function shouldTakeFee(address sender) internal view returns (bool) {
            return !isFeeExempt[sender];
        }

        function getTotalFee(bool selling) public view returns (uint256) {
            if(launchedAt + deadBlocks >= block.number){ return feeDenominator.sub(1); }
            if(selling && buybackMultiplierTriggeredAt.add(buybackMultiplierLength) > block.timestamp){ return getMultipliedFee(); }
            return totalFee;
        }

        function getMultipliedFee() public view returns (uint256) {
            uint256 remainingTime = buybackMultiplierTriggeredAt.add(buybackMultiplierLength).sub(block.timestamp);
            uint256 feeIncrease = totalFee.mul(buybackMultiplierNumerator).div(buybackMultiplierDenominator).sub(totalFee);
            return totalFee.add(feeIncrease.mul(remainingTime).div(buybackMultiplierLength));
        }

        function takeFee(address sender, uint256 amount, bool isSell, bool GREEDMode) internal returns (uint256) {
            uint256 feeAmount;
            if (GREEDMode){
                if(isSell){
                    feeAmount = amount.mul(totalFee).mul(3).div(2).div(feeDenominator);
                } else {
                    feeAmount = amount.mul(totalFee).div(2).div(feeDenominator);
                }
            } else {
                feeAmount = amount.mul(totalFee).div(feeDenominator);
            }
            _balances[address(this)] = _balances[address(this)].add(feeAmount);
            emit Transfer(sender, address(this), feeAmount);
            return amount.sub(feeAmount);
        }

        function shouldSwapBack() internal view returns (bool) {
            return msg.sender != pair
                && !inSwap
                && swapEnabled
                && _balances[address(this)] >= swapThreshold;
        }

        function swapBack() internal swapping {
            uint256 dynamicLiquidityFee = isOverLiquified(targetLiquidity, targetLiquidityDenominator) ? 0 : liquidityFee;
            uint256 amountToLiquify = swapThreshold.mul(dynamicLiquidityFee).div(totalFee).div(2);
            uint256 amountToSwap = swapThreshold.sub(amountToLiquify);

            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = WBNB;

            uint256 balanceBefore = address(this).balance;

            router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                amountToSwap,
                0,
                path,
                address(this),
                block.timestamp
            );
            uint256 amountBNB = address(this).balance.sub(balanceBefore);
            uint256 totalBNBFee = totalFee.sub(dynamicLiquidityFee.div(2));
            uint256 amountBNBLiquidity = amountBNB.mul(dynamicLiquidityFee).div(totalBNBFee).div(2);
            uint256 amountBNBMarketing = amountBNB.mul(marketingFee).div(totalBNBFee);
            uint256 amountBNBDev = amountBNB.mul(devFee).div(totalBNBFee);

            (bool successMarketing, /* bytes memory data */) = payable(marketingFeeReceiver).call{value: amountBNBMarketing, gas: 30000}("");
            (bool successDev, /* bytes memory data */) = payable(DEV).call{value: amountBNBDev, gas: 30000}("");
            require(successMarketing, "marketing receiver rejected ETH transfer");
            require(successDev, "dev receiver rejected ETH transfer");

            if(amountToLiquify > 0){
                router.addLiquidityETH{value: amountBNBLiquidity}(
                    address(this),
                    amountToLiquify,
                    0,
                    0,
                    autoLiquidityReceiver,
                    block.timestamp
                );
                emit AutoLiquify(amountBNBLiquidity, amountToLiquify);
            }
        }

        function shouldAutoBuyback() internal view returns (bool) {
            return msg.sender != pair
                && !inSwap
                && autoBuybackEnabled
                && autoBuybackBlockLast + autoBuybackBlockPeriod <= block.number
                && address(this).balance >= autoBuybackAmount;
        }

        function triggerManualBuyback(uint256 amount, bool triggerBuybackMultiplier) external authorized {
            uint256 amountWithDecimals = amount * (10 ** 18);
            uint256 amountToBuy = amountWithDecimals.div(100);
            buyTokens(amountToBuy, DEAD);
            if(triggerBuybackMultiplier){
                buybackMultiplierTriggeredAt = block.timestamp;
                emit BuybackMultiplierActive(buybackMultiplierLength);
            }
        }

        function clearBuybackMultiplier() external authorized {
            buybackMultiplierTriggeredAt = 0;
        }

        function triggerAutoBuyback() internal {
            buyTokens(autoBuybackAmount, DEAD);
            if(autoBuybackMultiplier){
                buybackMultiplierTriggeredAt = block.timestamp;
                emit BuybackMultiplierActive(buybackMultiplierLength);
            }
            autoBuybackBlockLast = block.number;
            autoBuybackAccumulator = autoBuybackAccumulator.add(autoBuybackAmount);
            if(autoBuybackAccumulator > autoBuybackCap){ autoBuybackEnabled = false; }
        }

        function buyTokens(uint256 amount, address to) internal swapping {
            address[] memory path = new address[](2);
            path[0] = WBNB;
            path[1] = address(this);
            router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
                0,
                path,
                to,
                block.timestamp
            );
        }

        function setAutoBuybackSettings(bool _enabled, uint256 _cap, uint256 _amount, uint256 _period, bool _autoBuybackMultiplier) external authorized {
            autoBuybackEnabled = _enabled;
            autoBuybackCap = _cap;
            autoBuybackAccumulator = 0;
            autoBuybackAmount = _amount;
            autoBuybackBlockPeriod = _period;
            autoBuybackBlockLast = block.number;
            autoBuybackMultiplier = _autoBuybackMultiplier;
        }

        function setBuybackMultiplierSettings(uint256 numerator, uint256 denominator, uint256 length) external authorized {
            require(numerator / denominator <= 2 && numerator > denominator);
            buybackMultiplierNumerator = numerator;
            buybackMultiplierDenominator = denominator;
            buybackMultiplierLength = length;
        }

        function launched() internal view returns (bool) {
            return launchedAt != 0;
        }

        function launch() internal {
            launchedAt = block.number;
        }

        function setBuyTxLimitInPercent(uint256 maxBuyTxPercent) external authorized {
            _maxBuyTxAmount = _totalSupply.mul(maxBuyTxPercent).div(10000);
        }

        function setSellTxLimitInPercent(uint256 maxSellTxPercent) external authorized {
            _maxSellTxAmount = _totalSupply.mul(maxSellTxPercent).div(10000);
        }

        function setIsFeeExempt(address holder, bool exempt) external authorized {
            isFeeExempt[holder] = exempt;
        }

        function setIsTxLimitExempt(address holder, bool exempt) external authorized {
            isTxLimitExempt[holder] = exempt;
        }

        function setIsTimelockExempt(address holder, bool exempt) external authorized {
            isTimelockExempt[holder] = exempt;
        }

        function setBuyFees(uint256 _liquidityFeeBuy, uint256 _buybackFeeBuy, uint256 _marketingFeeBuy, uint256 _devFeeBuy, uint256 _feeDenominator) external authorized {
            liquidityFeeBuy = _liquidityFeeBuy;
            buybackFeeBuy = _buybackFeeBuy;
            marketingFeeBuy = _marketingFeeBuy;
            devFeeBuy = _devFeeBuy;
            totalFeeBuy = _liquidityFeeBuy.add(_buybackFeeBuy).add(_marketingFeeBuy).add(_devFeeBuy);
            feeDenominator = _feeDenominator;
        }

        function setSellFees(uint256 _liquidityFeeSell, uint256 _buybackFeeSell, uint256 _marketingFeeSell, uint256 _devFeeSell, uint256 _feeDenominator) external authorized {
            liquidityFeeSell = _liquidityFeeSell;
            buybackFeeSell = _buybackFeeSell;
            marketingFeeSell = _marketingFeeSell;
            devFeeSell = _devFeeSell;
            totalFeeSell = _liquidityFeeSell.add(_buybackFeeSell).add(_marketingFeeSell).add(_devFeeSell);
            feeDenominator = _feeDenominator;
        }

        function setFeeReceivers(address _autoLiquidityReceiver, address _marketingFeeReceiver, address _dev) external authorized {
            autoLiquidityReceiver = _autoLiquidityReceiver;
            marketingFeeReceiver = _marketingFeeReceiver;
            DEV = _dev;
        }

        function setSwapBackSettings(bool _enabled, uint256 _amount) external authorized {
            swapEnabled = _enabled;
            swapThreshold = _amount * (10 ** _decimals);
        }

        function setTargetLiquidity(uint256 _target, uint256 _denominator) external authorized {
            targetLiquidity = _target;
            targetLiquidityDenominator = _denominator;
        }

        function manualSend() external authorized {
            uint256 contractETHBalance = address(this).balance;
            payable(marketingFeeReceiver).transfer(contractETHBalance);
        }

        function getCirculatingSupply() public view returns (uint256) {
            return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
        }

        function getLiquidityBacking(uint256 accuracy) public view returns (uint256) {
            return accuracy.mul(balanceOf(pair).mul(2)).div(getCirculatingSupply());
        }

        function isOverLiquified(uint256 target, uint256 accuracy) public view returns (bool) {
            return getLiquidityBacking(accuracy) > target;
        }

        function tradingStatus(bool _status) public onlyOwner {
            tradingOpen = _status;
            launch();
        }

        function enableGREED(uint256 _seconds) public authorized {
            GREEDTriggeredAt = block.timestamp;
            GREEDDuration = _seconds;
        }

        function disableGREED() external authorized {
            GREEDTriggeredAt = 0;
        }

        function cooldownEnabled(bool _status, uint8 _interval) public authorized {
            buyCooldownEnabled = _status;
            cooldownTimerInterval = _interval;
        }

        function blacklistAddress(address _address, bool _value) public authorized {
            isBlacklisted[_address] = _value;
        }

        event AutoLiquify(uint256 amountBNB, uint256 amountBOG);
        event BuybackMultiplierActive(uint256 duration);
    }