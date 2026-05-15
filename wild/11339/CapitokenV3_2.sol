// SPDX-License-Identifier: MIT

// Sources flattened with hardhat v2.28.2 https://hardhat.org


// File @openzeppelin/contracts/utils/Context.sol@v4.9.5

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.4) (utils/Context.sol)

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


// File @openzeppelin/contracts/access/Ownable.sol@v4.9.5

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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


// File @openzeppelin/contracts/token/ERC20/IERC20.sol@v4.9.5

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)


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
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}


// File @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol@v4.9.5

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
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


// File @openzeppelin/contracts/token/ERC20/ERC20.sol@v4.9.5

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)




/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
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
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
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
    function decimals() public view virtual override returns (uint8) {
        return 18;
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
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
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
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
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
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
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
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}


// File contracts/CapitokenV3_2.sol

// Original license: SPDX_License_Identifier: MIT

/**
 * CapitokenV3_2 (Phase 2)
 * - Basado en tu CapitokenV3 deployado (Phase 1 PASS)
 * - Compatible OpenZeppelin 4.9.5
 * - Phase 1: maxTx/maxWallet por % + cooldown escalonado + ventana 12 meses (igual)
 * - Phase 2: trading gating + AMM pairs + anti-bot por "dead blocks" + whitelist
 *
 * Diseño clave para NO romper Phase 1:
 * - Wallet->Wallet transfers: NO aplican límites/cooldown (Phase 2 UX-friendly).
 * - Limits/cooldown se aplican SOLO en buys/sells cuando una punta es AMM pair.
 * - Si no hay AMM pair configurado, se comporta esencialmente como Phase 1 (pero con wallet transfers libres).
 */


contract CapitokenV3_2 is ERC20, Ownable {
    // -----------------------------
    // Config general Phase 1
    // -----------------------------
    uint256 public immutable launchTime;
    uint256 public constant RULES_DURATION = 90 days; // 3 meses (auto-relax post-renounce)

    // phase: 0 = sin reglas; 1 = Phase 1; 2 = Phase 2 (DEX/antibot)
    uint8 public phase = 1;

    bool public limitsEnabled = true;

    mapping(address => bool) public isExcluded;

    // Antiwhale por porcentaje (basis points)
    // 100 bps = 1%, 700 bps = 7%
    uint16 public maxTxBps = 25;       // 0.25% (LAUNCH)
    uint16 public maxWalletBps = 100;   // 1.00% (LAUNCH)

    // Cooldown escalonado por sender (from) dentro de ventana de 24h
    mapping(address => uint8) public txLevel;       // 0..3
    mapping(address => uint256) public lastTxTime;  // timestamp

    uint32 public cooldownL1 = 1 hours;
    uint32 public cooldownL2 = 6 hours;
    uint32 public cooldownL3 = 24 hours;

    // Cooldown window (Phase 7.4):
    // - Si cooldownEndTime == 0 => cooldown SIEMPRE activo (modo legacy).
    // - Si cooldownEndTime > 0  => cooldown solo aplica mientras block.timestamp < cooldownEndTime.
    uint256 public cooldownEndTime = 0;

    event CooldownWindowUpdated(uint256 endTime);

    // -----------------------------
    // Phase 8: Observability flags
    // -----------------------------
    bool public cooldownExpiredEmitted = false;


    // ----------------------------
    // Rewards lock (12 meses)
    // ----------------------------
    mapping(address => uint256) public lockedRewards;       // tokens recibidos como recompensa y bloqueados
    mapping(address => uint256) public rewardsUnlockTime;   // timestamp de desbloqueo
    uint256 public constant REWARD_LOCK_SECONDS = 90 days;

    event RewardLocked(address indexed to, uint256 amount, uint256 unlockTime);

    // Renuncia programada
    uint256 public renounceAt;

    // Phase 8: explicit post-renounce mode
    bool public isRenounced = false;

    // -----------------------------
    // Phase 2: DEX / antibot
    // -----------------------------
    bool public tradingEnabled = false;
    uint256 public tradingEnabledAt; // timestamp
    uint256 public launchBlock;      // bloque cuando habilitas trading

    mapping(address => bool) public isAMMPair;      // pares DEX
    mapping(address => bool) public isWhitelisted;  // whitelist para ventana inicial

    uint256 public antiBotBlocks = 3; // "dead blocks" iniciales (recomendado)

    // -----------------------------
    // Events
    // -----------------------------
    event PhaseUpdated(uint8 newPhase);
    event LimitsEnabledUpdated(bool enabled);
    event ExcludedUpdated(address indexed account, bool excluded);

    event AntiwhaleBpsUpdated(uint16 maxTxBps, uint16 maxWalletBps);
    event CooldownUpdated(uint32 l1, uint32 l2, uint32 l3);

    event RenounceScheduled(uint256 when);
    event RenounceCancelled();

    event TradingEnabled(uint256 atTimestamp, uint256 atBlock);
    event TradingDisabled();

    event AMMPairUpdated(address indexed pair, bool enabled);
    event WhitelistUpdated(address indexed account, bool enabled);
    event AntiBotBlocksUpdated(uint256 blocksCount);
    
    // Phase 8 - Observability events
    event TradingEnabledV2(uint256 atBlock, uint256 atTimestamp);
    event CooldownWindowSet(uint256 start, uint256 end);
    event CooldownExpired(uint256 timestamp);

    event AntiWhaleUpdated(uint16 maxTxBps, uint16 maxWalletBps);
    event RulesRelaxed(bytes32 indexed rule, uint256 timestamp);

    event OwnershipRenounced(uint256 timestamp);


    // -----------------------------
    // Constructor (igual que V3)
    // -----------------------------
    constructor() ERC20("Capitoken", "CAPI") {
        launchTime = block.timestamp;

        uint256 total = 100_000_000_000 * 10 ** decimals();
        _mint(msg.sender, total);

        isExcluded[msg.sender] = true;
        isExcluded[address(this)] = true;

        emit ExcludedUpdated(msg.sender, true);
        emit ExcludedUpdated(address(this), true);
    }


    // -----------------------------
    // Phase 8: modifiers
    // -----------------------------
    modifier onlyBeforeRenounce() {
        require(!isRenounced, "Renounced");
        _;
    }


    // -----------------------------
    // View helpers
    // -----------------------------
    function rulesActive() public view returns (bool) {
        if (!limitsEnabled) return false;
        if (phase < 1) return false;
        if (block.timestamp >= launchTime + RULES_DURATION) return false;
        return true;
    }

    function maxTxAmount() public view returns (uint256) {
        return (totalSupply() * uint256(maxTxBps)) / 10_000;
    }

    function maxWalletAmount() public view returns (uint256) {
        return (totalSupply() * uint256(maxWalletBps)) / 10_000;
    }

    function cooldownRequiredForLevel(uint8 level) public view returns (uint256) {
        if (level == 0) return 0;
        if (level == 1) return cooldownL1;
        if (level == 2) return cooldownL2;
        return cooldownL3;
    }


    // -----------------------------
    // Phase 8: UX-friendly state getters
    // -----------------------------
    function isCooldownActive() public view returns (bool) {
        if (cooldownEndTime == 0) return true; // legacy: always on
        return block.timestamp < cooldownEndTime;
    }

    function timeUntilCooldownEnds() public view returns (uint256) {
        if (cooldownEndTime == 0) return type(uint256).max;
        if (block.timestamp >= cooldownEndTime) return 0;
        return cooldownEndTime - block.timestamp;
    }

    function isAntiWhaleActive() public view returns (bool) {
        return maxTxBps > 0 && maxWalletBps > 0 && rulesActive();
    }

    function currentMaxTx() public view returns (uint256) {
        return maxTxAmount();
    }

    function currentMaxWallet() public view returns (uint256) {
        return maxWalletAmount();
    }

    function isInDeadBlocks() public view returns (bool) {
        if (!tradingEnabled) return false;
        return block.number <= launchBlock + antiBotBlocks;
    }

    function isLaunchPhase() public view returns (bool) {
        if (!tradingEnabled) return false;
        if (phase < 2) return false;
        // Launch = dead blocks OR cooldown window active
        return isInDeadBlocks() || isCooldownActive();
    }

    // -----------------------------
    // Phase 8: NFT readiness (NO NFT inside token)
    // Tiers are based on % of totalSupply (bps).
    // -----------------------------
    uint16 public constant TIER1_BPS = 1;  // 0.01%
    uint16 public constant TIER2_BPS = 5;  // 0.05%
    uint16 public constant TIER3_BPS = 10; // 0.10%

    function snapshotBalance(address user) public view returns (uint256) {
        return balanceOf(user);
    }

    function holderTier(address user) public view returns (uint8) {
        uint256 bal = balanceOf(user);
        uint256 supply = totalSupply();

        if (bal >= (supply * uint256(TIER3_BPS)) / 10_000) return 3;
        if (bal >= (supply * uint256(TIER2_BPS)) / 10_000) return 2;
        if (bal >= (supply * uint256(TIER1_BPS)) / 10_000) return 1;
        return 0;
    }

    function isEligibleForNFT(address user) public view returns (bool) {
        return holderTier(user) > 0;
    }


    function isBuy(address from, address to) public view returns (bool) {
        // Buy: tokens salen del AMM pair hacia un usuario
        return isAMMPair[from] && !isAMMPair[to];
    }

    function isSell(address from, address to) public view returns (bool) {
        // Sell: tokens van de un usuario hacia el AMM pair
        return !isAMMPair[from] && isAMMPair[to];
    }

    function isAMMTransfer(address from, address to) public view returns (bool) {
        return isAMMPair[from] || isAMMPair[to];
    }

    // -----------------------------
    // Admin setters Phase 1
    // -----------------------------
    function setPhase(uint8 newPhase) external onlyOwner {
        require(newPhase <= 2, "Invalid phase");
        phase = newPhase;
        emit PhaseUpdated(newPhase);
    }

    function setLimitsEnabled(bool enabled) external onlyOwner {
        limitsEnabled = enabled;
        emit LimitsEnabledUpdated(enabled);
    }

    function setExcluded(address account, bool excluded) external onlyOwner {
        isExcluded[account] = excluded;
        emit ExcludedUpdated(account, excluded);
    }

    function setAntiwhaleBps(uint16 _maxTxBps, uint16 _maxWalletBps) external onlyOwner {
        require(_maxTxBps > 0 && _maxTxBps <= 1000, "maxTxBps too high");          // <=10%
        require(_maxWalletBps > 0 && _maxWalletBps <= 3000, "maxWalletBps too high"); // <=30%
        require(_maxWalletBps >= _maxTxBps, "wallet < tx");

        uint16 oldTx = maxTxBps;
        uint16 oldWallet = maxWalletBps;

        maxTxBps = _maxTxBps;
        maxWalletBps = _maxWalletBps;

        emit AntiwhaleBpsUpdated(_maxTxBps, _maxWalletBps);
        emit AntiWhaleUpdated(_maxTxBps, _maxWalletBps);

        // If limits became less restrictive, emit a standardized "RulesRelaxed" signal for dashboards.
        if (_maxTxBps > oldTx || _maxWalletBps > oldWallet) {
            emit RulesRelaxed(keccak256("ANTI_WHALE_RELAXED"), block.timestamp);
        }
    }

    function setCooldowns(uint32 l1, uint32 l2, uint32 l3) external onlyOwner {
        require(l1 <= l2 && l2 <= l3, "Bad cooldown order");
        cooldownL1 = l1;
        cooldownL2 = l2;
        cooldownL3 = l3;
        emit CooldownUpdated(l1, l2, l3);
    }

    /// @notice Define hasta cuándo aplica el cooldown (por timestamp). Recomendado: launch + 48h.
    /// @dev Pasa 0 para mantener cooldown permanente (modo legacy).
    function setCooldownEndTime(uint256 endTime) external onlyOwner {
        // Permite apagarlo (0) o configurarlo en el futuro
        cooldownEndTime = endTime;
        emit CooldownWindowUpdated(endTime);
        emit CooldownWindowSet(block.timestamp, cooldownEndTime);
    }

    /// @notice Conveniencia: fija cooldownEndTime a (ahora + secondsFromNow)
    function setCooldownWindow(uint256 secondsFromNow) external onlyOwner {
        cooldownEndTime = block.timestamp + secondsFromNow;
        emit CooldownWindowUpdated(cooldownEndTime);
        emit CooldownWindowSet(block.timestamp, cooldownEndTime);
    }

    // Renuncia programada
    function scheduleRenounce(uint256 delaySeconds) external onlyOwner {
        require(delaySeconds >= 1 hours, "Delay too small");
        renounceAt = block.timestamp + delaySeconds;
        emit RenounceScheduled(renounceAt);
    }

    function cancelRenounce() external onlyOwner {
        renounceAt = 0;
        emit RenounceCancelled();
    }

    function executeRenounce() external onlyOwner {
        require(renounceAt != 0, "Not scheduled");
        require(block.timestamp >= renounceAt, "Too early");
        renounceAt = 0;
        renounceOwnership();
    }

    // -----------------------------
    // Admin setters Phase 2
    // -----------------------------
    function setAMMPair(address pair, bool enabled) external onlyOwner {
        require(pair != address(0), "Zero pair");
        isAMMPair[pair] = enabled;
        emit AMMPairUpdated(pair, enabled);
    }

    function setWhitelist(address account, bool enabled) external onlyOwner {
        require(account != address(0), "Zero account");
        isWhitelisted[account] = enabled;
        emit WhitelistUpdated(account, enabled);
    }

    function setAntiBotBlocks(uint256 blocksCount) external onlyOwner {
        require(blocksCount <= 20, "Too many blocks"); // safety guard
        antiBotBlocks = blocksCount;
        emit AntiBotBlocksUpdated(blocksCount);
    }

    function enableTrading() external onlyOwner {
        tradingEnabled = true;
        tradingEnabledAt = block.timestamp;
        launchBlock = block.number;

        // Phase 7.4 (A2): cooldown window auto-set on launch (72h) unless already configured
        if (cooldownEndTime == 0) {
            cooldownEndTime = block.timestamp + 72 hours;
            emit CooldownWindowUpdated(cooldownEndTime);
        }

        emit TradingEnabled(tradingEnabledAt, launchBlock);

        // Phase 8 - explicit observability events (dashboard/CEX friendly)
        emit TradingEnabledV2(launchBlock, tradingEnabledAt);
        emit CooldownWindowSet(tradingEnabledAt, cooldownEndTime);
    }

    function disableTrading() external onlyOwner {
        tradingEnabled = false;
        emit TradingDisabled();
    }


    // ----------------------------
    // Rewards (lock 12 meses)
    // ----------------------------

    /// @notice Entrega una "recompensa" desde la tesorería (owner) a una wallet y la bloquea 12 meses.
    /// @dev No hace mint. Transfiere desde el owner para mantener TOTAL_SUPPLY fijo.
    function grantReward(address to, uint256 amount) external onlyOwner {
        _grantReward(to, amount, REWARD_LOCK_SECONDS);
    }

    /// @notice Igual que grantReward pero con lock custom (para pruebas).
    function grantRewardCustom(address to, uint256 amount, uint256 lockSeconds) external onlyOwner {
        _grantReward(to, amount, lockSeconds);
    }

    function _grantReward(address to, uint256 amount, uint256 lockSeconds) internal {
        require(to != address(0), "Zero address");
        require(amount > 0, "Zero amount");

        // Se transfiere primero; luego se marca el monto como "lockedRewards" en el receptor.
        _transfer(_msgSender(), to, amount);

        lockedRewards[to] += amount;

        uint256 unlockAt = block.timestamp + lockSeconds;
        if (unlockAt > rewardsUnlockTime[to]) {
            rewardsUnlockTime[to] = unlockAt;
        }

        emit RewardLocked(to, amount, rewardsUnlockTime[to]);
    }

    /// @notice Balance disponible para transferir (excluye recompensas bloqueadas si aun no vencen).
    function unlockedBalanceOf(address account) public view returns (uint256) {
        uint256 bal = balanceOf(account);
        uint256 locked = _effectiveLocked(account);
        if (locked >= bal) return 0;
        return bal - locked;
    }

    function _effectiveLocked(address account) internal view returns (uint256) {
        uint256 locked = lockedRewards[account];
        if (locked == 0) return 0;
        if (block.timestamp >= rewardsUnlockTime[account]) return 0;
        return locked;
    }

    /// @notice Limpia el lock si ya venció (opcional, para ahorrar gas en operaciones futuras).
    function refreshRewardLock(address account) public {
        if (lockedRewards[account] > 0 && block.timestamp >= rewardsUnlockTime[account]) {
            lockedRewards[account] = 0;
            rewardsUnlockTime[account] = 0;
        }
    }


    // -----------------------------
    // Core rules hook (OZ 4.9.5)
    // -----------------------------
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        super._beforeTokenTransfer(from, to, amount);

        // Mint/Burn no pasan por reglas
        if (from == address(0) || to == address(0)) return;

        // Rewards lock: no permite mover la parte bloqueada antes del unlock
        uint256 locked = _effectiveLocked(from);
        if (locked > 0) {
            uint256 bal = balanceOf(from);
            uint256 unlocked = bal - locked;
            require(amount <= unlocked, "Rewards locked");
        }


        // Exentos: si cualquiera de los lados está excluido, saltar TODO
        // Nota: NO uses nombres isBuy/isSell aquí porque existen funciones isBuy(from,to)/isSell(from,to)
        // y en Solidity eso causa "shadowing" (y luego no puedes llamar a la función).
        bool buyTxFromPair = isAMMPair[from];
        bool sellTxToPair = isAMMPair[to];

        // Si alguna parte está excluida, no aplicamos reglas (incluye AMM).
        // Esto permite: addLiquidity, movimientos de tesorería, etc.
        // IMPORTANTE: NO excluyas el AMM pair, o se saltarán las reglas en DEX.
        if (isExcluded[from] || isExcluded[to]) return;

        // Si reglas no activas, no validar
        if (!rulesActive()) return;

        // Phase 8: emit a one-time signal when cooldown window has expired (for dashboards).
        if (cooldownEndTime > 0 && !cooldownExpiredEmitted && block.timestamp >= cooldownEndTime) {
            cooldownExpiredEmitted = true;
            emit CooldownExpired(block.timestamp);
        }


        // -----------------------------
        // Phase 2 lógica: solo si phase == 2 y hay AMM involucrado
        // -----------------------------
        bool ammTx = isAMMTransfer(from, to);

        if (phase >= 2 && ammTx) {
            // Bloquear buys/sells si no has habilitado trading
            require(tradingEnabled || isExcluded[from] || isExcluded[to], "Trading disabled");

            // Ventana antibot por bloques iniciales (dead blocks)
            // Solo aplica a BUYs (bots compran al launch)
            if (isBuy(from, to)) {
                if (block.number <= launchBlock + antiBotBlocks) {
                    require(isWhitelisted[to], "AntiBot");
                }
            }

            // En Phase 2, limits/cooldown SOLO en buys/sells
            _applyAntiwhaleAndCooldown(from, to, amount, buyTxFromPair, sellTxToPair);
            return;
        }

        // -----------------------------
        // Phase 1 comportamiento (wallet->wallet):
        // Para mejorar UX/adopción y reducir fricción:
        // - No aplicamos antiwhale/cooldown en transfers normales.
        // Si quieres volver al comportamiento viejo (aplicar en todo), te lo habilito con un flag,
        // pero por ahora lo dejamos así para Phase 2.
        // -----------------------------
        if (phase == 1) {
            // Conservador: si aún estás en Phase 1 y quieres reglas solo DEX, no hacemos nada aquí.
            // (Esto no rompe tus pruebas Phase 1 en Sepolia si tú estabas usando transfer wallet->wallet,
            // pero si quieres que Phase 1 siga aplicando a todo, me lo dices y lo hacemos con un switch).
            _applyAntiwhaleAndCooldown(from, to, amount, buyTxFromPair, sellTxToPair);
            return;
        }

        // Phase 0: sin reglas
        // Phase 2 wallet->wallet: sin reglas (por diseño)
    }

    function _applyAntiwhaleAndCooldown(address /*from*/, address to, uint256 amount, bool buyTxFromPair, bool sellTxToPair) internal {
        // NOTE:
        // - En Phase 2 aplicamos reglas SOLO en transacciones con AMM (pair).
        // - MaxWallet y Cooldown se aplican SOLO en BUYs (from == pair), para no trabar ventas ni wallets normales.

        // 1) MaxTx: en BUY y en SELL
        require(amount <= maxTxAmount(), "Max TX");

        // 2) MaxWallet: solo en BUY (receptor)
        if (buyTxFromPair) {
            require(balanceOf(to) + amount <= maxWalletAmount(), "Max wallet");

            // 3) Cooldown escalonado por receptor (to) SOLO en BUY
            // 7.4: Cooldown solo durante ventana (si está configurada)
            if (cooldownEndTime == 0 || block.timestamp < cooldownEndTime) {
            uint256 last = lastTxTime[to];

            // Si es la primera compra (last==0) o pasó la ventana de 24h, reinicia y arranca en nivel 1
            if (last == 0 || block.timestamp >= last + 24 hours) {
                txLevel[to] = 1;
                lastTxTime[to] = block.timestamp;
            } else {
                uint8 level = txLevel[to];
                // level=0 no se usa; por seguridad tratamos 0 como 1
                uint256 required = cooldownRequiredForLevel(level == 0 ? 1 : level);

                if (required > 0) {
                    require(block.timestamp >= last + required, "Cooldown");
                }

                // Sube el nivel (cap en 3)
                if (level < 3) {
                    txLevel[to] = level + 1;
                }
                lastTxTime[to] = block.timestamp;
            }
            }
        } else if (sellTxToPair) {
            // En SELL no aplicamos MaxWallet ni Cooldown (para no frenar DEX exits).
        }
    }


    // -----------------------------
    // Phase 8: explicit renounce signal
    // -----------------------------
    function renounceOwnership() public override onlyOwner {
        super.renounceOwnership();
        isRenounced = true;
        emit OwnershipRenounced(block.timestamp);
    }


}