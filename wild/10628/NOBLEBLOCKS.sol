// SPDX-License-Identifier: MIT

/**
 * @title NOBLEBLOCKS V2
 * @dev ERC20 Token for NOBLEBLOCKS
 * Website: www.nobleblocks.com
 * Email: info@nobleblocks.com
 */

pragma solidity ^0.8.20;

// OpenZeppelin Contracts (last updated v5.1.0) (utils/ReentrancyGuard.sol)

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

// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)
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

// OpenZeppelin Contracts (last updated v5.1.0) (token/ERC20/IERC20.sol)

/**
 * @dev Interface of the ERC-20 standard as defined in the ERC.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// OpenZeppelin Contracts (last updated v5.1.0) (token/ERC20/extensions/IERC20Metadata.sol)

/**
 * @dev Interface for the optional metadata functions from the ERC-20 standard.
 */
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

// OpenZeppelin Contracts (last updated v5.1.0) (interfaces/draft-IERC6093.sol)

/**
 * @dev Standard ERC-20 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC-20 tokens.
 */
interface IERC20Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC20InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC20InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `spender`’s `allowance`. Used in transfers.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     * @param allowance Amount of tokens a `spender` is allowed to operate with.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC20InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `spender` to be approved. Used in approvals.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC20InvalidSpender(address spender);
}

// OpenZeppelin Contracts (last updated v5.2.0) (token/ERC20/ERC20.sol)

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC-20
 * applications.
 */
abstract contract ERC20 is Context, IERC20, IERC20Metadata, IERC20Errors {
    mapping(address account => uint256) private _balances;

    mapping(address account => mapping(address spender => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
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
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `value`.
     */
    function transfer(address to, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, value);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `value` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, value);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Skips emitting an {Approval} event indicating an allowance update. This is not
     * required by the ERC. See {xref-ERC20-_approve-address-address-uint256-bool-}[_approve].
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `value`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `value`.
     */
    function transferFrom(address from, address to, uint256 value) public virtual returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, value);
        _transfer(from, to, value);
        return true;
    }

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _transfer(address from, address to, uint256 value) internal virtual {
        if (from == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        if (to == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(from, to, value);
    }

    /**
     * @dev Transfers a `value` amount of tokens from `from` to `to`, or alternatively mints (or burns) if `from`
     * (or `to`) is the zero address. All customizations to transfers, mints, and burns should be done by overriding
     * this function.
     *
     * Emits a {Transfer} event.
     */
    function _update(address from, address to, uint256 value) internal virtual {
        if (from == address(0)) {
            // Overflow check required: The rest of the code assumes that totalSupply never overflows
            _totalSupply += value;
        } else {
            uint256 fromBalance = _balances[from];
            if (fromBalance < value) {
                revert ERC20InsufficientBalance(from, fromBalance, value);
            }
            unchecked {
                // Overflow not possible: value <= fromBalance <= totalSupply.
                _balances[from] = fromBalance - value;
            }
        }

        if (to == address(0)) {
            unchecked {
                // Overflow not possible: value <= totalSupply or value <= fromBalance <= totalSupply.
                _totalSupply -= value;
            }
        } else {
            unchecked {
                // Overflow not possible: balance + value is at most totalSupply, which we know fits into a uint256.
                _balances[to] += value;
            }
        }

        emit Transfer(from, to, value);
    }

    /**
     * @dev Creates a `value` amount of tokens and assigns them to `account`, by transferring it from address(0).
     * Relies on the `_update` mechanism
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _mint(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(address(0), account, value);
    }

    /**
     * @dev Destroys a `value` amount of tokens from `account`, lowering the total supply.
     * Relies on the `_update` mechanism.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead
     */
    function _burn(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        _update(account, address(0), value);
    }

    /**
     * @dev Sets `value` as the allowance of `spender` over the `owner`'s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     *
     * Overrides to this logic should be done to the variant with an additional `bool emitEvent` argument.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        _approve(owner, spender, value, true);
    }

    /**
     * @dev Variant of {_approve} with an optional flag to enable or disable the {Approval} event.
     *
     * By default (when calling {_approve}) the flag is set to true. On the other hand, approval changes made by
     * `_spendAllowance` during the `transferFrom` operation set the flag to false. This saves gas by not emitting any
     * `Approval` event during `transferFrom` operations.
     *
     * Anyone who wishes to continue emitting `Approval` events on the`transferFrom` operation can force the flag to
     * true using the following override:
     *
     * ```solidity
     * function _approve(address owner, address spender, uint256 value, bool) internal virtual override {
     *     super._approve(owner, spender, value, true);
     * }
     * ```
     *
     * Requirements are the same as {_approve}.
     */
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

    /**
     * @dev Updates `owner`'s allowance for `spender` based on spent `value`.
     *
     * Does not update the allowance value in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Does not emit an {Approval} event.
     */
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

// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

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

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
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

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

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


contract NOBLEBLOCKS is ERC20, Ownable, ReentrancyGuard {

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    address public multisigWallet;

    uint256 public immutable TOTAL_SUPPLY = 1_000_000_000 * 10**decimals();
    uint8 private immutable percentageOfMaximumTokensToAccumate = 10;
    
    bool private swapping;
    bool public isOnlySellFee;
    bool public paused = false;

    uint256 public swapTokensAtAmount = 10 ** 5 * 10**decimals();
    uint256 public balanceLimit; // 1% of total supply
    address public adminWallet = 0xeE9B6aa7196C1d9a3Bb0dE858E1E0aB81D0cd0e0;
    address public fundWallet = 0xA21bb38c1c760F221D56f2e3226a27c9cdbe8061;

    uint16 public liquidityFee = 1000;  // 10%
    uint16 public adminFee = 1000;  // 10%
    uint16 public fundFee = 1000;   // 10%

    mapping (address => bool) public isExcluded;
    mapping (address => bool) public isLimitExcluded;

    event TransferFailed(address _recipient, uint256 _amount);
    event SetFee(uint16 liquidityFee, uint16 adminFee, uint16 fundFee);
    event SetSwapAtAmount(uint256 amount);
    event SetLimit(uint256 limit);
    event ExcludeLimitWallet(address indexed _address, bool _value);
    event ExcludeFeeWallet(address indexed _address, bool _value);
    event SetFundWallet(address indexed _address);
    event SetAdminWallet(address indexed _address);
    event RecoverETHSuccess(address to, uint256 amount);
    event RecoverETHFailed(address to, uint256 amount);
    event RecoverTokenSuccess(address tokenAddress, uint256 amount);
    event OwnerChanged(address indexed previousOwner, address indexed newOwner);
    event SetOnlySellFee(bool value);
    event Burned(address indexed burner, uint256 amount);
    event RouterChanged(address oldRounter, address newRouter);
    event MultisigWalletSet(address indexed multiSigWallet);
    event Paused(bool paused);

    constructor(address _uniswapV2RouterAddress, address _multisigWallet)  ERC20("NOBLEBLOCKS V2", "NOBL") Ownable(_msgSender()) {
        require(_uniswapV2RouterAddress != address(0), "Invalid uniswap router address");
        require(_multisigWallet != address(0), "Invalid multisign wallet address");

       
        balanceLimit = TOTAL_SUPPLY / 100; // 1% of total supply
        multisigWallet = _multisigWallet;
        IUniswapV2Router02 _UniswapV2Router = IUniswapV2Router02(_uniswapV2RouterAddress);
        address _UniswapV2Pair = IUniswapV2Factory(_UniswapV2Router.factory())
            .createPair(address(this), _UniswapV2Router.WETH());
        uniswapV2Router = _UniswapV2Router;
        uniswapV2Pair = _UniswapV2Pair;
        // isExcluded[owner()] = true;
        isExcluded[address(this)] = true;
        isExcluded[adminWallet] = true;
        isExcluded[fundWallet] = true;
        isExcluded[_multisigWallet] = true;

        // isLimitExcluded[owner()] = true;
        isLimitExcluded[address(this)] = true;
        isLimitExcluded[adminWallet] = true;
        isLimitExcluded[fundWallet] = true;
        isLimitExcluded[_UniswapV2Pair] = true;
        isLimitExcluded[_multisigWallet] = true;
        
        _mint(_multisigWallet,  TOTAL_SUPPLY);
        transferOwnership(_multisigWallet);

        emit MultisigWalletSet(_multisigWallet);

    }

    function setPaused(bool _paused) external onlyOwner {
        paused = _paused;
        emit Paused(_paused);
    }

    receive() external payable {
    }

    function setUniswapV2Router(address _uniswapV2Router) external onlyOwner {
        require(_uniswapV2Router != address(0), "setUniswapV2Router: Invalid router address");
        address oldRouter = address(uniswapV2Router);
        IUniswapV2Router02 _UniswapV2Router = IUniswapV2Router02(_uniswapV2Router);
        IUniswapV2Factory factory = IUniswapV2Factory(_UniswapV2Router.factory());

        // Check if pair already exists
        address existingPair = factory.getPair(address(this), _UniswapV2Router.WETH());

        address _UniswapV2Pair;
        if (existingPair == address(0)) { // If pair does not exist, create it
            _UniswapV2Pair = factory.createPair(address(this), _UniswapV2Router.WETH());
        } else { // If pair exists, use existing pair address
            _UniswapV2Pair = existingPair;
        }
        require(_UniswapV2Pair != address(0), "Pair address set to zero");
        uniswapV2Router = _UniswapV2Router;
        uniswapV2Pair = _UniswapV2Pair;
        isLimitExcluded[_UniswapV2Pair] = true;
        emit RouterChanged(oldRouter, _uniswapV2Router);
    }

    function burnToken (uint256 _amount) external onlyOwner{
        _burn(owner(), _amount);

        emit Burned(owner(), _amount);
    }

    function _transfer(address from,  address to,  uint256 amount) internal override {

        require(paused == false, "Contract is Paused");
        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;
        if(
            canSwap &&
            !swapping &&
            from != uniswapV2Pair &&
            from != owner() &&
            to != owner()
        ) {
            swapping = true;
            swapAndLiquify(contractTokenBalance);
            swapping = false;
            sendDividends();
        }

        if(!swapping){        
            bool takeFee = false;

            if(!isExcluded[from] && (from == uniswapV2Pair || to == uniswapV2Pair)){
                if(isOnlySellFee == false || (isOnlySellFee == true && to == uniswapV2Pair))
                takeFee = true;
            }

            if (takeFee){
                uint256 totalFee = liquidityFee + adminFee + fundFee;
                require(totalFee <= 5000, "Total fee exceeds 50%"); // Added check

                uint256 fees = amount * (liquidityFee + adminFee + fundFee) / 10000;
                amount = amount - fees;
                super._transfer(from, address(this), fees);
            }
        }
        if (!isLimitExcluded[to]){
            require((balanceOf(to) + amount) <= balanceLimit, "maxlimit");
        }
        super._transfer(from, to, amount);

    }

    function swapAndLiquify(uint256 contractTokenBalance) private nonReentrant {
        uint256 tokens = (contractTokenBalance * liquidityFee) / (liquidityFee + fundFee + adminFee);
        if(tokens % 2 == 1) tokens --;
        if(tokens == 0) return;
        uint256 half = tokens / 2;
        uint256 otherHalf = tokens - half;
        
        uint256 initialBalance = address(this).balance;
        uint256 halfPlusDividends = contractTokenBalance-otherHalf;
        swapTokensForEth(halfPlusDividends);
        uint256 newBalance = address(this).balance - initialBalance;
        addLiquidity(otherHalf, (newBalance*half)/halfPlusDividends);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp + 200
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            multisigWallet,
            block.timestamp + 200
        );
    }

    function sendDividends() private nonReentrant {
        uint256 ethBalance = address(this).balance;
        require(ethBalance > 0, "No ETH to distribute");

        uint256 totalFee = adminFee + fundFee;
        if (totalFee > 0) {
            uint256 adminETH = (ethBalance * adminFee) / (adminFee + fundFee);
            uint256 fundETH  = ethBalance - adminETH;
            (bool successAdmin, ) = adminWallet.call{value: adminETH}("");
            (bool successFund, ) = fundWallet.call{value: fundETH}("");

            if (!successAdmin) {
                emit TransferFailed(adminWallet, adminETH);
            }
            if (!successFund) {
                emit TransferFailed(fundWallet, fundETH);
            }
        }
    }


    function setSwapAtAmount (uint256 amount) external onlyOwner {
        require(amount <= (percentageOfMaximumTokensToAccumate * totalSupply()) / 100, "Amount greater than max accumulated percentage");
        require(swapTokensAtAmount != amount, "Same value provided");
        swapTokensAtAmount = amount;

        emit SetSwapAtAmount(amount);
    }

    function setAdminWallet (address _address) external onlyOwner {
        require(_address != address(0) && adminWallet != _address, "Invalid or same address provided");
        isExcluded[adminWallet] = false;
        isLimitExcluded[adminWallet] = false;
        adminWallet = _address;
        isExcluded[adminWallet] = true;
        isLimitExcluded[adminWallet] = true;

        emit SetAdminWallet(_address);
    }

    function setFundWallet (address _address) external onlyOwner {
        require(_address != address(0) && fundWallet != _address, "Invalid or same address provided");
        isExcluded[fundWallet] = false;
        isLimitExcluded[fundWallet] = false;
        fundWallet = _address;
        isExcluded[fundWallet] = true;
        isLimitExcluded[fundWallet] = true;
        emit SetFundWallet(_address);
    }

    function changeOwner (address _address) external onlyOwner {
        require(_address != address(0) && owner() != _address, "Invalid or same address provided");
        isExcluded[owner()] = false;
        isLimitExcluded[owner()] = false;
        address oldOwner = owner();
        transferOwnership(_address);
        isExcluded[_address] = true;
        isLimitExcluded[_address] = true;

        emit OwnerChanged(oldOwner, _address);
    }

    function setExcludeWallet (address _address, bool _value) external onlyOwner{
        require(_address != address(0), "setExcludeWallet: Invalid address");
        require(isExcluded[_address] != _value, "Same exclusion value provided");
        isExcluded[_address] = _value;

        emit ExcludeFeeWallet(_address, _value);
    }

    function setExcludeLimitWallet (address _address, bool _value) external onlyOwner{
        require(_address != address(0), "setExcludeLimitWallet: Invalid address");
        require(isLimitExcluded[_address] != _value, "Same limit exclusion value provided");
        isLimitExcluded[_address] = _value;

        emit ExcludeLimitWallet(_address, _value);
    }

    function setLimit (uint256 _limit) external onlyOwner {
        require(_limit > TOTAL_SUPPLY / 1000 && balanceLimit != _limit, "setLimit: Limit is too small or same value provided");
        
        balanceLimit = _limit;

        emit SetLimit(_limit);
    }

    function setFee (uint16 _newLPFee, uint16 _newadminFee, uint16 _newfundFee) external onlyOwner {
        require(0 <= _newLPFee && _newLPFee <= 9000, "setFee: Fee should be equal or smaller than 90%");
        require(0 <= _newadminFee && _newadminFee <= 9000, "setFee: Fee should be equal or smaller than 90%");
        require(0 <= _newfundFee && _newfundFee <= 9000, "setFee: Fee should be equal or smaller than 90%");
        require (0 < _newadminFee + _newfundFee && _newadminFee + _newfundFee <= 9000, "need to be strictly positive and equal or smaller than 90%");
        
        liquidityFee = _newLPFee;
        adminFee = _newadminFee;
        fundFee = _newfundFee;

        emit SetFee(liquidityFee, adminFee, fundFee);
    }

    // Recover tokens accidentally sent to the contract
    function recoverTokens(address tokenAddress, uint256 amount) external onlyOwner {
        require(tokenAddress != address(0), "RecoverTokens: Invalid address");
        require(tokenAddress != address(this), "RecoverTokens: Cannot recover NOBL token");
        require(IERC20(tokenAddress).balanceOf(address(this)) >= amount, "RecoverTokens: Insufficient token balance");
        IERC20(tokenAddress).transfer(_msgSender(), amount);

        emit RecoverTokenSuccess(tokenAddress, amount);
    }

     // Recover ETH sent to the contract
    function recoverETH(address to, uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "RecoverETH: Insufficient ETH balance");
        require(to != address(0), "RecoverETH: Invalid address");
        (bool success, ) = to.call{value: amount}("");
        if(success) {
            emit RecoverETHSuccess(to, amount);
        } else {
            emit RecoverETHFailed(to, amount);
        }
    }

    function setOnlySellFee(bool _value) external onlyOwner {
        require(_value != isOnlySellFee, "setOnlySellFee: Same value provided");
        isOnlySellFee = _value;

        emit SetOnlySellFee(_value);
    }
}