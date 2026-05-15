/*
|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
Telegram: https://t.me/luntrainfra
X: https://x.com/luntrainfra
Documents : https://luntra.gitbook.io/luntra-infrastructure/
Website: https://www.luntrainfrastructure.com/#about

*/

pragma solidity 0.8.28;

// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)
/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

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
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Metadata.sol)

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
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

// OpenZeppelin Contracts (last updated v5.0.0) (utils/Context.sol)

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
}

// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/draft-IERC6093.sol)

/**
 * @dev Standard ERC20 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC20 tokens.
 */
interface IERC20Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientBalance(
        address sender,
        uint256 balance,
        uint256 needed
    );

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
     * @dev Indicates a failure with the `spender's `allowance`. Used in transfers.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     * @param allowance Amount of tokens a `spender` is allowed to operate with.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientAllowance(
        address spender,
        uint256 allowance,
        uint256 needed
    );

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

/**
 * @dev Standard ERC721 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC721 tokens.
 */
interface IERC721Errors {
    /**
     * @dev Indicates that an address can't be an owner. For example, `address(0)` is a forbidden owner in EIP-20.
     * Used in balance queries.
     * @param owner Address of the current owner of a token.
     */
    error ERC721InvalidOwner(address owner);

    /**
     * @dev Indicates a `tokenId` whose `owner` is the zero address.
     * @param tokenId Identifier number of a token.
     */
    error ERC721NonexistentToken(uint256 tokenId);

    /**
     * @dev Indicates an error related to the ownership over a particular token. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param tokenId Identifier number of a token.
     * @param owner Address of the current owner of a token.
     */
    error ERC721IncorrectOwner(address sender, uint256 tokenId, address owner);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC721InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC721InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `operator's approval`. Used in transfers.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     * @param tokenId Identifier number of a token.
     */
    error ERC721InsufficientApproval(address operator, uint256 tokenId);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC721InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC721InvalidOperator(address operator);
}

/**
 * @dev Standard ERC1155 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC1155 tokens.
 */
interface IERC1155Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     * @param tokenId Identifier number of a token.
     */
    error ERC1155InsufficientBalance(
        address sender,
        uint256 balance,
        uint256 needed,
        uint256 tokenId
    );

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC1155InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC1155InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `operator's approval`. Used in transfers.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     * @param owner Address of the current owner of a token.
     */
    error ERC1155MissingApprovalForAll(address operator, address owner);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC1155InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC1155InvalidOperator(address operator);

    /**
     * @dev Indicates an array length mismatch between ids and values in a safeBatchTransferFrom operation.
     * Used in batch transfers.
     * @param idsLength Length of the array of token identifiers
     * @param valuesLength Length of the array of token amounts
     */
    error ERC1155InvalidArrayLength(uint256 idsLength, uint256 valuesLength);
}

// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/ERC20.sol)

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
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 */
abstract contract ERC20 is Context, IERC20, IERC20Metadata, IERC20Errors {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

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
    function allowance(
        address owner,
        address spender
    ) public view virtual returns (uint256) {
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
    function approve(
        address spender,
        uint256 value
    ) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, value);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
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
    function _transfer(address from, address to, uint256 value) internal {
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
     * @dev Sets `value` as the allowance of `spender` over the `owner` s tokens.
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
     * ```
     * function _approve(address owner, address spender, uint256 value, bool) internal virtual override {
     *     super._approve(owner, spender, value, true);
     * }
     * ```
     *
     * Requirements are the same as {_approve}.
     */
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

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `value`.
     *
     * Does not update the allowance value in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Does not emit an {Approval} event.
     */
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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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

interface IUniswapV2Factory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

interface IUniswapV2Router {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

pragma solidity ^0.8.0;

contract LUNTRA is Ownable, ERC20 {
    IUniswapV2Router public immutable swapRouter;

    address public constant ZERO_ADDRESS = address(0);
    address public constant BURN_ADDRESS = address(0xdEaD);

    address public immutable swapPair;
    address public marketingWallet;
    address public devWallet;
    address public originalOwner;
    bool public taxesRevoked;

    bool public limitsEnabled;
    bool public cooldownEnabled;
    bool public feesEnabled;
    bool private inSwapProcess;
    bool public isActivated;
    bool public whitelistEnabled;

    uint256 public activationBlock;
    uint256 public activationTime;

    uint256 private lastSwapBlock;

    uint256 public constant MAX_TOTAL_FEE = 40;

    // Updated dynamic tax and limit constants for custom launch mechanics
    uint256 public constant BLOCK_0_TAX = 30; // 30% on buys for bundle block
    uint256 public constant BLOCK_0_WALLET_LIMIT = 143; // 1.43% max wallet for bundle block

    uint256 public constant BLOCKS_1_50_TAX = 19; // 19% tax for blocks 1-50
    uint256 public constant BLOCKS_1_50_WALLET_LIMIT = 30; // 0.3% max wallet for blocks 1-50

    uint256 public constant BLOCKS_50_75_TAX = 10; // 10% tax for blocks 50-75

    uint256 public maxBuyLimit;
    uint256 public maxSellLimit;
    uint256 public maxWalletLimit;

    uint256 public tokensForSwap;
    uint256 public buyTax;
    uint256 public sellTax;
    uint256 public transferTax;

    mapping(address => bool) public blacklistedBots;
    mapping(address => bool) public excludedFromFees;
    mapping(address => bool) public excludedFromLimits;
    mapping(address => bool) public marketPairs;
    mapping(address => bool) public whitelistedAddresses;
    mapping(address => uint256) private _lastTransferBlock;

    event Activation();
    event taxWalletUpdated(address newWallet, address oldWallet);
    event DevWalletUpdated(address newWallet, address oldWallet);
    event LimitsStatusChanged(bool status);
    event CooldownStatusChanged(bool status);
    event FeesStatusChanged(bool status);
    event WhitelistStatusChanged(bool status);
    event MaxBuyLimitUpdated(uint256 amount);
    event MaxSellLimitUpdated(uint256 amount);
    event MaxWalletLimitUpdated(uint256 amount);
    event TokensForSwapUpdated(uint256 newValue, uint256 oldValue);
    event BuyTaxUpdated(uint256 newValue, uint256 oldValue);
    event SellTaxUpdated(uint256 newValue, uint256 oldValue);
    event TransferTaxUpdated(uint256 newValue, uint256 oldValue);
    event ExcludedFromFees(address account, bool isExcluded);
    event ExcludedFromLimits(address account, bool isExcluded);
    event BotStatusUpdated(address account, bool isBlacklisted);
    event MarketPairStatusUpdated(address pair, bool value);
    event WhitelistAddressUpdated(address account, bool isWhitelisted);
    event StuckTokensWithdrawn(address token, uint256 amount);
    event TaxesRevoked(
        address indexed caller,
        uint256 previousBuyTax,
        uint256 previousSellTax,
        uint256 previousTransferTax
    );

    error AlreadyActivated();
    error InvalidAddress();
    error AmountTooSmall();
    error AmountTooLarge();
    error FeeTooHigh();
    error PairAlreadySet();
    error NoETHToWithdraw();
    error NoTokensToWithdraw();
    error ETHWithdrawalFailed();
    error BotActivityDetected();
    error TransferCooldown();
    error ExceedsMaxBuyLimit();
    error ExceedsMaxSellLimit();
    error ExceedsMaxWalletLimit();
    error NotActivated();
    error NotOriginalOwner();
    error TaxesAlreadyRevoked();
    error TaxSplitAlreadyRevoked();
    error NotWhitelisted();

    modifier lockSwapProcess() {
        inSwapProcess = true;
        _;
        inSwapProcess = false;
    }

    modifier onlyOriginalOwner() {
        require(msg.sender == originalOwner, NotOriginalOwner());
        _;
    }

    struct TaxSplit {
        uint256 marketing;
        uint256 dev;
        uint256 ecosystem;
    }
    TaxSplit public taxSplit;
    address public ecosystemWallet;
    uint256 public totalEthCollected;
    uint256 public constant ETH_SPLIT_THRESHOLD = 53 ether;

    constructor() Ownable(msg.sender) ERC20("LUNTRA", "LUNTRA") {
        address owner = msg.sender;
        originalOwner = owner;
        _mint(owner, 1_000_000_000 ether);
        uint256 totalSupplyTokens = totalSupply();

        marketingWallet = 0xdd6930E5164a9429C32bae29124Ea6C8c0689fC3; // Marketing wallet
        devWallet = 0x138bd6ddf39d237F2Ab7220317d7b28A5D38d268; // Dev wallet
        ecosystemWallet = 0x76361a7A9dFEcfE36F04Cf8bb3A897330D0c056e; 

        maxBuyLimit = (totalSupplyTokens * 143) / 10000;
        maxSellLimit = (totalSupplyTokens * 143) / 10000;
        maxWalletLimit = (totalSupplyTokens * 143) / 10000;
        tokensForSwap = (totalSupplyTokens * 200) / 1000000; // 0.02% to make maxSwapAmount 0.4%

        limitsEnabled = true;
        cooldownEnabled = false;
        feesEnabled = true;
        whitelistEnabled = true; // Enable whitelist for bundle block

        buyTax = 4; // Default tax after block 75
        sellTax = 4; // Default tax after block 75
        transferTax = 0;

        swapRouter = IUniswapV2Router(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        swapPair = IUniswapV2Factory(swapRouter.factory()).createPair(
            address(this),
            swapRouter.WETH()
        );

        SetMarketPair(swapPair, true);
        _approve(address(this), address(swapRouter), type(uint256).max);
        _excludeFromFees(address(this), true);
        _excludeFromFees(BURN_ADDRESS, true);
        _excludeFromFees(owner, true);
        _excludeFromFees(marketingWallet, true);
        _excludeFromFees(devWallet, true);
        ExcludeFromLimits(address(this), true);
        ExcludeFromLimits(BURN_ADDRESS, true);
        ExcludeFromLimits(owner, true);
        ExcludeFromLimits(marketingWallet, true);
        ExcludeFromLimits(devWallet, true);
        taxSplit = TaxSplit(51, 34, 15);
    }

    receive() external payable {}

    fallback() external payable {}

    function _transferOwnership(address newOwner) internal override {
        address oldOwner = owner();
        if (oldOwner != ZERO_ADDRESS) {
            _excludeFromFees(oldOwner, false);
            ExcludeFromLimits(oldOwner, false);
        }
        _excludeFromFees(newOwner, true);
        ExcludeFromLimits(newOwner, true);
        super._transferOwnership(newOwner);
    }

    function openTrading() external onlyOwner {
        require(!isActivated, AlreadyActivated());
        isActivated = true;
        activationBlock = block.number;
        activationTime = block.timestamp;
        emit Activation();
    }

    function _updatetaxWallet(address _taxWallet) external onlyOwner {
        require(_taxWallet != ZERO_ADDRESS, InvalidAddress());
        address oldWallet = marketingWallet;
        marketingWallet = _taxWallet;
        emit taxWalletUpdated(marketingWallet, oldWallet);
    }

    function _updateDevWallet(address _devWallet) external onlyOwner {
        require(_devWallet != ZERO_ADDRESS, InvalidAddress());
        address oldWallet = devWallet;
        devWallet = _devWallet;
        emit DevWalletUpdated(devWallet, oldWallet);
    }

    function changeLimitsEnabled(bool value) external onlyOwner {
        limitsEnabled = value;
        emit LimitsStatusChanged(value);
    }

    function changeCooldownEnabled(bool value) external onlyOwner {
        cooldownEnabled = value;
        emit CooldownStatusChanged(value);
    }

    function setFeesEnabled(bool value) external onlyOwner {
        feesEnabled = value;
        emit FeesStatusChanged(value);
    }

    function setMaxBuyLimit(uint256 amount) external onlyOwner {
        require(amount >= ((totalSupply() * 2) / 1000), AmountTooSmall());
        maxBuyLimit = amount;
        emit MaxBuyLimitUpdated(maxBuyLimit);
    }

    function setMaxSellLimit(uint256 amount) external onlyOwner {
        require(amount >= ((totalSupply() * 2) / 1000), AmountTooSmall());
        maxSellLimit = amount;
        emit MaxSellLimitUpdated(maxSellLimit);
    }

    function setMaxWalletLimit(uint256 amount) external onlyOwner {
        require(amount >= ((totalSupply() * 3) / 1000), AmountTooSmall());
        maxWalletLimit = amount;
        emit MaxWalletLimitUpdated(maxWalletLimit);
    }

    function setTokensForSwap(uint256 amount) external onlyOwner {
        uint256 totalSupplyTokens = totalSupply();
        require(amount >= (totalSupplyTokens * 1) / 1000000, AmountTooSmall());
        require(amount <= (totalSupplyTokens * 5) / 1000, AmountTooLarge());
        uint256 oldValue = tokensForSwap;
        tokensForSwap = amount;
        emit TokensForSwapUpdated(amount, oldValue);
    }

    function setTax(uint256 _buyTax, uint256 _sellTax) external onlyOwner {
        require(!taxesRevoked, TaxesAlreadyRevoked());
        require(_buyTax <= MAX_TOTAL_FEE, FeeTooHigh());
        require(_sellTax <= MAX_TOTAL_FEE, FeeTooHigh());

        buyTax = _buyTax;
        sellTax = _sellTax;
    }

    function changeTransferTax(uint256 _transferTax) external onlyOwner {
        require(!taxesRevoked, TaxesAlreadyRevoked());
        require(_transferTax <= MAX_TOTAL_FEE, FeeTooHigh());
        uint256 oldValue = transferTax;
        transferTax = _transferTax;
        emit TransferTaxUpdated(_transferTax, oldValue);
    }

    function excludeFromFees(
        address[] calldata accounts,
        bool value
    ) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            _excludeFromFees(accounts[i], value);
        }
    }

    function excludeFromLimits(
        address[] calldata accounts,
        bool value
    ) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            ExcludeFromLimits(accounts[i], value);
        }
    }

    function setBlacklistedBots(
        address[] calldata accounts,
        bool value
    ) external onlyOriginalOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            if (
                (!marketPairs[accounts[i]]) &&
                (accounts[i] != address(swapRouter)) &&
                (accounts[i] != address(this)) &&
                (accounts[i] != ZERO_ADDRESS) &&
                (!excludedFromFees[accounts[i]] &&
                    !excludedFromLimits[accounts[i]])
            ) UpdateBotStatus(accounts[i], value);
        }
    }

    function setMarketPair(address pair, bool value) external onlyOwner {
        require(!marketPairs[pair], PairAlreadySet());
        SetMarketPair(pair, value);
    }

    function clearStuckTokens(address _token) external onlyOwner {
        address owner = msg.sender;
        uint256 amount;
        if (_token == ZERO_ADDRESS) {
            bool success;
            amount = address(this).balance;
            require(amount > 0, NoETHToWithdraw());
            (success, ) = address(owner).call{value: amount}("");
            require(success, ETHWithdrawalFailed());
        } else {
            amount = IERC20(_token).balanceOf(address(this));
            require(amount > 0, NoTokensToWithdraw());
            IERC20(_token).transfer(msg.sender, amount);
        }
        emit StuckTokensWithdrawn(_token, amount);
    }

    function setWhitelistEnabled(bool value) external onlyOwner {
        whitelistEnabled = value;
        emit WhitelistStatusChanged(value);
    }

    function setWhitelistedAddresses(
        address[] calldata accounts,
        bool value
    ) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            whitelistedAddresses[accounts[i]] = value;
            emit WhitelistAddressUpdated(accounts[i], value);
        }
    }

    function isWhitelisted(address account) public view returns (bool) {
        return whitelistedAddresses[account];
    }

    function _update(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        address sender = msg.sender;
        address origin = tx.origin;

        require(!blacklistedBots[from], BotActivityDetected());
        require(
            sender == from || !blacklistedBots[sender],
            BotActivityDetected()
        );
        require(
            origin == from || origin == sender || !blacklistedBots[origin],
            BotActivityDetected()
        );

        require(
            isActivated || excludedFromLimits[from] || excludedFromLimits[to],
            NotActivated()
        );

        // Whitelist check for block 0 (bundle block)
        if (isActivated && whitelistEnabled) {
            uint256 blocksSinceActivation = block.number - activationBlock;
            if (blocksSinceActivation == 0) {
                // Block 0: Only whitelisted addresses can buy
                if (marketPairs[from] && !excludedFromLimits[to]) {
                    require(whitelistedAddresses[to], NotWhitelisted());
                }
            }
        }

        bool applyLimits = limitsEnabled &&
            !inSwapProcess &&
            !(excludedFromLimits[from] || excludedFromLimits[to]);
        if (applyLimits) {
            if (
                from != owner() &&
                to != owner() &&
                to != ZERO_ADDRESS &&
                to != BURN_ADDRESS
            ) {
                if (cooldownEnabled) {
                    if (to != address(swapRouter) && to != swapPair) {
                        require(
                            _lastTransferBlock[origin] < block.number - 3 &&
                                _lastTransferBlock[to] < block.number - 3,
                            TransferCooldown()
                        );
                        _lastTransferBlock[origin] = block.number;
                        _lastTransferBlock[to] = block.number;
                    }
                }

                // Dynamic limits based on block number (up to block 25)
                uint256 currentLimit;
                if (isActivated) {
                    uint256 blocksSinceActivation = block.number -
                        activationBlock;
                    if (blocksSinceActivation == 0) {
                        currentLimit =
                            (totalSupply() * BLOCK_0_WALLET_LIMIT) /
                            10000; // 1.67% bundle block
                    } else if (blocksSinceActivation <= 50) {
                        currentLimit =
                            (totalSupply() * BLOCKS_1_50_WALLET_LIMIT) /
                            10000; // 0.3% blocks 1-50
                    } else {
                        currentLimit = totalSupply();
                        limitsEnabled = false;
                    }
                } else {
                    currentLimit = maxBuyLimit;
                }

                if (marketPairs[from] && !excludedFromLimits[to]) {
                    require(amount <= currentLimit, ExceedsMaxBuyLimit());
                    require(
                        amount + balanceOf(to) <= currentLimit,
                        ExceedsMaxWalletLimit()
                    );
                } else if (marketPairs[to] && !excludedFromLimits[from]) {
                    require(amount <= currentLimit, ExceedsMaxSellLimit());
                } else if (!excludedFromLimits[to]) {
                    require(
                        amount + balanceOf(to) <= currentLimit,
                        ExceedsMaxWalletLimit()
                    );
                }
            }
        }

        bool applyFee = feesEnabled &&
            !inSwapProcess &&
            !(excludedFromFees[from] || excludedFromFees[to]);

        if (applyFee) {
            uint256 feeAmount = 0;

            // Optimized tax calculation - use static taxes after block 25
            uint256 currentSellTax;
            uint256 currentBuyTax;
            if (isActivated) {
                uint256 blocksSinceActivation = block.number - activationBlock;
                if (blocksSinceActivation == 0) {
                    currentBuyTax = BLOCK_0_TAX; // 30% bundle block
                    currentSellTax = BLOCK_0_TAX;
                } else if (blocksSinceActivation <= 50) {
                    currentBuyTax = BLOCKS_1_50_TAX; // 19% blocks 1-50
                    currentSellTax = BLOCKS_1_50_TAX;
                } else if (blocksSinceActivation <= 75) {
                    currentBuyTax = BLOCKS_50_75_TAX; // 10% blocks 50-75
                    currentSellTax = BLOCKS_50_75_TAX;
                } else {
                    // After block 25, use static taxes (4%)
                    currentBuyTax = buyTax;
                    currentSellTax = sellTax;
                }
            } else {
                currentBuyTax = buyTax;
                currentSellTax = sellTax;
            }

            if (marketPairs[to] && currentSellTax > 0) {
                feeAmount = (amount * currentSellTax) / 100;
            } else if (marketPairs[from] && currentBuyTax > 0) {
                feeAmount = (amount * currentBuyTax) / 100;
            } else if (
                !marketPairs[to] && !marketPairs[from] && transferTax > 0
            ) {
                feeAmount = (amount * transferTax) / 100;
            }

            if (feeAmount > 0) {
                amount -= feeAmount;
                super._update(from, address(this), feeAmount);
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= tokensForSwap;
        if (applyFee && !marketPairs[from] && canSwap) {
            if (
                block.number > lastSwapBlock && block.number > activationBlock
            ) {
                _swapTokens(contractTokenBalance);
                lastSwapBlock = block.number;
            }
        }

        super._update(from, to, amount);
    }

    function _swapTokens(uint256 tokenAmount) internal virtual lockSwapProcess {
        bool success;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = swapRouter.WETH();

        uint256 maxSwapAmount = tokensForSwap * 20;

        if (tokenAmount > maxSwapAmount) {
            tokenAmount = maxSwapAmount;
        }

        swapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 ethBalance = address(this).balance;
        totalEthCollected += ethBalance;
        TaxSplit memory currentTaxSplit = taxSplit;
        // Switch split after threshold
        if (totalEthCollected < ETH_SPLIT_THRESHOLD) {
            currentTaxSplit = TaxSplit(60, 40, 0);
        }

        uint256 ethForMarketing = (ethBalance * currentTaxSplit.marketing) /
            100;
        uint256 ethForDev = (ethBalance * currentTaxSplit.dev) / 100;
        uint256 ethForEco = ethBalance - ethForMarketing - ethForDev;

        (success, ) = address(marketingWallet).call{value: ethForMarketing}("");
        (success, ) = address(devWallet).call{value: ethForDev}("");
        (success, ) = address(ecosystemWallet).call{value: ethForEco}("");
    }

    function _excludeFromFees(address account, bool value) internal virtual {
        excludedFromFees[account] = value;
        emit ExcludedFromFees(account, value);
    }

    function ExcludeFromLimits(address account, bool value) internal virtual {
        excludedFromLimits[account] = value;
        emit ExcludedFromLimits(account, value);
    }

    function UpdateBotStatus(address account, bool value) internal virtual {
        blacklistedBots[account] = value;
        emit BotStatusUpdated(account, value);
    }

    function SetMarketPair(address pair, bool value) internal virtual {
        marketPairs[pair] = value;
        emit MarketPairStatusUpdated(pair, value);
    }

    function revokeTaxes() external onlyOriginalOwner {
        require(!taxesRevoked, TaxesAlreadyRevoked());

        uint256 previousBuyTax = buyTax;
        uint256 previousSellTax = sellTax;
        uint256 previousTransferTax = transferTax;

        buyTax = 0;
        sellTax = 0;
        transferTax = 0;
        taxesRevoked = true;

        emit TaxesRevoked(
            msg.sender,
            previousBuyTax,
            previousSellTax,
            previousTransferTax
        );
    }

    function areTaxesRevoked() external view returns (bool) {
        return taxesRevoked;
    }

    function setTaxSplit(
        uint256 marketing,
        uint256 dev,
        uint256 ecosystem
    ) external onlyOwner {
        require(marketing + dev + ecosystem == 100, "Split must sum to 100");
        taxSplit = TaxSplit(marketing, dev, ecosystem);
    }

    function setEcosystemWallet(address _eco) external onlyOwner {
        require(_eco != address(0), "Zero address");
        ecosystemWallet = _eco;
    }
}
