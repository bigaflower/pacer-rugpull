// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v5.4.0) (token/ERC20/IERC20.sol)

pragma solidity >=0.4.16;

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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts (last updated v5.4.0) (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity >=0.6.2;


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

// File: @openzeppelin/contracts/interfaces/draft-IERC6093.sol


// OpenZeppelin Contracts (last updated v5.4.0) (interfaces/draft-IERC6093.sol)
pragma solidity >=0.8.4;

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

/**
 * @dev Standard ERC-721 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC-721 tokens.
 */
interface IERC721Errors {
    /**
     * @dev Indicates that an address can't be an owner. For example, `address(0)` is a forbidden owner in ERC-20.
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
     * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
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
 * @dev Standard ERC-1155 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC-1155 tokens.
 */
interface IERC1155Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     * @param tokenId Identifier number of a token.
     */
    error ERC1155InsufficientBalance(address sender, uint256 balance, uint256 needed, uint256 tokenId);

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
     * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v5.4.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.20;





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
     * Both values are immutable: they can only be set once during construction.
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

    /// @inheritdoc IERC20
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    /// @inheritdoc IERC20
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

    /// @inheritdoc IERC20
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

// File: @openzeppelin/contracts/access/IAccessControl.sol


// OpenZeppelin Contracts (last updated v5.4.0) (access/IAccessControl.sol)

pragma solidity >=0.8.4;

/**
 * @dev External interface of AccessControl declared to support ERC-165 detection.
 */
interface IAccessControl {
    /**
     * @dev The `account` is missing a role.
     */
    error AccessControlUnauthorizedAccount(address account, bytes32 neededRole);

    /**
     * @dev The caller of a function is not the expected one.
     *
     * NOTE: Don't confuse with {AccessControlUnauthorizedAccount}.
     */
    error AccessControlBadConfirmation();

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted to signal this.
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call. This account bears the admin role (for the granted role).
     * Expected in cases where the role was granted using the internal {AccessControl-_grantRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `callerConfirmation`.
     */
    function renounceRole(bytes32 role, address callerConfirmation) external;
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts (last updated v5.4.0) (utils/introspection/IERC165.sol)

pragma solidity >=0.4.16;

/**
 * @dev Interface of the ERC-165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[ERC].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[ERC section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


// OpenZeppelin Contracts (last updated v5.4.0) (utils/introspection/ERC165.sol)

pragma solidity ^0.8.20;


/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC-165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 */
abstract contract ERC165 is IERC165 {
    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File: @openzeppelin/contracts/access/AccessControl.sol


// OpenZeppelin Contracts (last updated v5.4.0) (access/AccessControl.sol)

pragma solidity ^0.8.20;




/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```solidity
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```solidity
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it. We recommend using {AccessControlDefaultAdminRules}
 * to enforce additional security measures for this role.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address account => bool) hasRole;
        bytes32 adminRole;
    }

    mapping(bytes32 role => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with an {AccessControlUnauthorizedAccount} error including the required role.
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual returns (bool) {
        return _roles[role].hasRole[account];
    }

    /**
     * @dev Reverts with an {AccessControlUnauthorizedAccount} error if `_msgSender()`
     * is missing `role`. Overriding this function changes the behavior of the {onlyRole} modifier.
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Reverts with an {AccessControlUnauthorizedAccount} error if `account`
     * is missing `role`.
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert AccessControlUnauthorizedAccount(account, role);
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `callerConfirmation`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address callerConfirmation) public virtual {
        if (callerConfirmation != _msgSender()) {
            revert AccessControlBadConfirmation();
        }

        _revokeRole(role, callerConfirmation);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Attempts to grant `role` to `account` and returns a boolean indicating if `role` was granted.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual returns (bool) {
        if (!hasRole(role, account)) {
            _roles[role].hasRole[account] = true;
            emit RoleGranted(role, account, _msgSender());
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Attempts to revoke `role` from `account` and returns a boolean indicating if `role` was revoked.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual returns (bool) {
        if (hasRole(role, account)) {
            _roles[role].hasRole[account] = false;
            emit RoleRevoked(role, account, _msgSender());
            return true;
        } else {
            return false;
        }
    }
}

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
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
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
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

// File: new/TokenControllerImplementation.sol


pragma solidity ^0.8.19;





// --- Interfaces ---
interface IUniswapV2Router {
    function factory() external view returns (address);
    function WETH() external view returns (address);
    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidityETH(address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external returns (uint amountToken, uint amountETH);
}
interface IUniswapV2Factory { function createPair(address tokenA, address tokenB) external returns (address pair); }
interface IUniswapV2Pair { function balanceOf(address owner) external view returns (uint); function transfer(address to, uint value) external returns (bool); function approve(address spender, uint value) external returns (bool); }
interface ITokenFactory { function resolveReferrer(string calldata referral) external view returns (address); }

contract TokenControllerImplementation is ERC20, ReentrancyGuard, AccessControl, Pausable {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant KEEPER_ROLE = keccak256("KEEPER_ROLE");
    bytes32 public constant EMERGENCY_ROLE = keccak256("EMERGENCY_ROLE");

    struct TokenConfig { uint256 totalRaisedWei; uint256 maxSupply; uint256 limitPerMint; uint256 tokensForLP; uint256 mintPriceWei; bool finalized; }
    struct EmergencyConfig { address recipient; uint128 scheduledAt; }
    struct LPTrackingData { uint256 initialLPTokens; uint256 burnedLPTokens; uint256 harvestLPTokens; uint256 baselineTokensDeposited; uint256 baselineETHDeposited; uint256 lastHarvestTime; }
    struct ProfitTracking { uint256 cumulativeProfitTokens; uint256 cumulativeProfitETH; uint256 deployerClaimedTokens; uint256 deployerClaimedETH; uint256 collectorClaimedTokens; uint256 collectorClaimedETH; }
    
    struct InitConfig {
        string name; string symbol; address router; address deployer; address adminWallet; address keeper; address feeAddress; address feeCollector;
        uint256 tokensForLP; uint256 limitPerMint; uint256 maxSupply; uint256 mintPriceWei; bool emitBRC20JSON;
    }

    address public factory;
    address public deployer;
    address public feeAddress;
    address public feeCollector;
    IUniswapV2Router public router;
    TokenConfig public config;
    EmergencyConfig public emergencyConfig;
    LPTrackingData public lpTracking;
    ProfitTracking public profitTracking;
    address public lpTokenAddress;
    string private _tokenName;
    string private _tokenSymbol;
    bool public emitBRC20JSON;
    mapping(address => uint256) public lastMintTime;
    
    uint256 public constant REFERRAL_BP = 100;
    uint256 public constant BP_DENOM = 10000;
    uint256 public constant KEEPER_BP = 10;
    uint256 public constant DEPLOYER_HARVEST_BP = 5000;
    uint256 public constant COLLECTOR_HARVEST_BP = 5000;
    uint256 public constant EMERGENCY_DELAY = 3 days;
    uint256 public constant HARVEST_COOLDOWN = 1 hours;
    
    bool private _initialized;
    bool public emergencyMode;

    error ETHTransferFailed(); error InvalidInput(); error ExceedsMaxSupply(); error InsufficientPayment(); error AlreadyFinalized(); error NotFinalized(); error EmergencyNotReady(); error RateLimited(); error AlreadyInitialized(); error NoClaimableProfit(); error LPTransferFailed(); error HarvestCooldownActive(); error EmergencyModeActive();

    event EventMint(string p, string op, string tick, uint256 amt);
    event EventDeploy(string p, string op, string tick, uint256 max, uint256 lim, uint256 lp);
    event EventDeployJSON(string indexed tick, string json);
    event EventMintJSON(string indexed tick, string json);
    event Minted(address indexed buyer, uint256 amount, address indexed referrer, uint256 paidWei);
    event Finalized(uint256 ethForLP, uint256 toDeployer, uint256 keeperReward, uint256 toFee);
    event LiquidityInitialized(uint256 burnedLP, uint256 harvestLP, uint256 depositedTokens, uint256 depositedETH);
    event EmergencyWithdrawScheduled(address indexed recipient, uint256 when);
    event EmergencyWithdrawExecuted(address indexed recipient, uint256 amountWei);
    event ProfitsHarvested(uint256 tokenProfit, uint256 ethProfit, uint256 timestamp);
    event DeployerClaimedProfits(uint256 tokens, uint256 eth);
    event CollectorClaimedProfits(uint256 tokens, uint256 eth);

    constructor() ERC20("", "") { _initialized = true; }

    function name() public view override returns (string memory) { return _tokenName; }
    function symbol() public view override returns (string memory) { return _tokenSymbol; }

    function initialize(InitConfig calldata init) external {
        if (_initialized) revert AlreadyInitialized();
        _validateInitParams(init);
        _initialized = true;
        _tokenName = init.name; _tokenSymbol = init.symbol;
        factory = msg.sender; router = IUniswapV2Router(init.router); deployer = init.deployer; feeAddress = init.feeAddress; feeCollector = init.feeCollector;
        config = TokenConfig(0, init.maxSupply, init.limitPerMint, init.tokensForLP, init.mintPriceWei, false);
        emitBRC20JSON = init.emitBRC20JSON;
        _setupAccessControl(init.adminWallet, init.keeper);
        _emitDeployEvents(init.name, init.maxSupply, init.limitPerMint, init.tokensForLP, init.emitBRC20JSON);
    }
    function _validateInitParams(InitConfig calldata init) internal pure {
        if (init.router == address(0) || init.deployer == address(0) || init.adminWallet == address(0) || init.feeAddress == address(0) || init.feeCollector == address(0)) revert InvalidInput();
        if (init.tokensForLP == 0 || init.limitPerMint == 0 || init.maxSupply == 0 || init.mintPriceWei == 0) revert InvalidInput();
    }
    function _setupAccessControl(address adminWallet, address keeper) internal {
        _grantRole(DEFAULT_ADMIN_ROLE, adminWallet);
        _grantRole(ADMIN_ROLE, adminWallet);
        _grantRole(KEEPER_ROLE, keeper);
        _grantRole(EMERGENCY_ROLE, adminWallet);
    }
    function _emitDeployEvents(string memory name_, uint256 maxSupply_, uint256 limitPerMint_, uint256 tokensForLP_, bool emitBRC20JSON_) internal {
        emit EventDeploy("erc-2.0", "deploy", name_, maxSupply_, limitPerMint_, tokensForLP_);
        if (emitBRC20JSON_) {
            string memory jsonData = _createDeployJSON(name_, maxSupply_, limitPerMint_, tokensForLP_);
            emit EventDeployJSON(name_, jsonData);
        }
    }
    
    modifier rateLimited() { if (lastMintTime[msg.sender] + 10 > block.timestamp) revert RateLimited(); lastMintTime[msg.sender] = block.timestamp; _; }
    modifier notInEmergency() { if (emergencyMode) revert EmergencyModeActive(); _; }

    function mint(string calldata referral, bool emitJSON, uint256 tokensToMint) external payable nonReentrant whenNotPaused rateLimited notInEmergency {
        if (!_initialized) revert AlreadyInitialized();
        
        TokenConfig memory _cfg = config;
        
        // ✅ CORRECTED LOGIC: Check if the requested amount to mint is valid
        if (tokensToMint == 0 || tokensToMint > _cfg.limitPerMint) revert InvalidInput();

        if (_cfg.finalized) revert AlreadyFinalized();
        if (totalSupply() + tokensToMint > _cfg.maxSupply) revert ExceedsMaxSupply();
        
        uint256 required = _cfg.mintPriceWei;
        if (msg.value < required) revert InsufficientPayment();
        
        address referrer = ITokenFactory(factory).resolveReferrer(referral);
        uint256 refShare = (required * REFERRAL_BP) / BP_DENOM;
        
        config.totalRaisedWei += (required - refShare);
        _mint(msg.sender, tokensToMint);
        
        _safeETHTransfer(referrer != address(0) ? referrer : feeAddress, refShare);
        
        if (msg.value > required) {
            _safeETHTransfer(msg.sender, msg.value - required);
        }
        
        _emitMintEvents(tokensToMint, emitJSON);
        emit Minted(msg.sender, tokensToMint, referrer, required);
    }
    function _emitMintEvents(uint256 tokensToMint, bool shouldEmitJSON) internal {
        emit EventMint("erc-2.0", "mint", name(), tokensToMint);
        if (shouldEmitJSON) {
            string memory jsonData = _createMintJSON(tokensToMint);
            emit EventMintJSON(name(), jsonData);
        }
    }
    
    function finalize(uint256 minToken, uint256 minETH) external onlyRole(KEEPER_ROLE) nonReentrant whenNotPaused notInEmergency {
        if (!_initialized) revert AlreadyInitialized();
        if (config.finalized) revert AlreadyFinalized();
        if (totalSupply() < config.maxSupply) revert NotFinalized();
        config.finalized = true;
        _mint(address(this), config.tokensForLP);
        _processFinalizationFees();
        uint256 ethForLP = (config.totalRaisedWei - (config.totalRaisedWei * KEEPER_BP) / BP_DENOM) / 2;
        address pair = IUniswapV2Factory(router.factory()).createPair(address(this), router.WETH());
        lpTokenAddress = pair;
        _approve(address(this), address(router), config.tokensForLP);
        (uint actualTokens, uint actualETH, uint liquidity) = router.addLiquidityETH{value: ethForLP}(address(this), config.tokensForLP, minToken, minETH, address(this), block.timestamp);
        _handleLPDistribution(pair, liquidity, actualTokens, actualETH);
    }
    function _processFinalizationFees() internal {
        uint256 keeperReward = (config.totalRaisedWei * KEEPER_BP) / BP_DENOM;
        uint256 afterKeeper = config.totalRaisedWei - keeperReward;
        uint256 toDeployer = (afterKeeper * 500) / BP_DENOM;
        uint256 ethForLP = afterKeeper / 2;
        uint256 toFee = afterKeeper - ethForLP - toDeployer;
        _safeETHTransfer(msg.sender, keeperReward);
        _safeETHTransfer(deployer, toDeployer);
        _safeETHTransfer(feeAddress, toFee);
        emit Finalized(ethForLP, toDeployer, keeperReward, toFee);
    }
    function _handleLPDistribution(address pair, uint l, uint at, uint ae) internal {
        uint256 toBurn = l / 2;
        if (toBurn > 0) { IUniswapV2Pair(pair).transfer(address(0xdead), toBurn); }
        lpTracking = LPTrackingData(l, toBurn, l - toBurn, at, ae, block.timestamp);
        emit LiquidityInitialized(toBurn, l - toBurn, at, ae);
    }

    function harvestProfits() external onlyRole(KEEPER_ROLE) nonReentrant notInEmergency {
        if (lpTokenAddress == address(0)) revert InvalidInput();
        if (block.timestamp < lpTracking.lastHarvestTime + HARVEST_COOLDOWN) revert HarvestCooldownActive();
        (uint256 pTokens, uint256 pETH) = _executeHarvest();
        if (pTokens > 0 || pETH > 0) {
            profitTracking.cumulativeProfitTokens += pTokens;
            profitTracking.cumulativeProfitETH += pETH;
            lpTracking.lastHarvestTime = block.timestamp;
            emit ProfitsHarvested(pTokens, pETH, block.timestamp);
        }
    }
    function _executeHarvest() internal returns (uint, uint) {
        uint tBefore = balanceOf(address(this));
        uint eBefore = address(this).balance;
        _removeLiquidityCompletely();
        uint tReceived = balanceOf(address(this)) - tBefore;
        uint eReceived = address(this).balance - eBefore;
        uint pTokens = tReceived > lpTracking.baselineTokensDeposited ? tReceived - lpTracking.baselineTokensDeposited : 0;
        uint pETH = eReceived > lpTracking.baselineETHDeposited ? eReceived - lpTracking.baselineETHDeposited : 0;
        _reAddBaselineLiquidity();
        return (pTokens, pETH);
    }
    function _removeLiquidityCompletely() internal {
        uint balance = IUniswapV2Pair(lpTokenAddress).balanceOf(address(this));
        if (balance > 0) { IUniswapV2Pair(lpTokenAddress).approve(address(router), balance); router.removeLiquidityETH(address(this), balance, 0, 0, address(this), block.timestamp); }
    }
    function _reAddBaselineLiquidity() internal {
        _approve(address(this), address(router), lpTracking.baselineTokensDeposited);
        (,,uint newL) = router.addLiquidityETH{value: lpTracking.baselineETHDeposited}(address(this), lpTracking.baselineTokensDeposited, lpTracking.baselineTokensDeposited * 95 / 100, lpTracking.baselineETHDeposited * 95 / 100, address(this), block.timestamp);
        lpTracking.harvestLPTokens = newL;
    }

    function _getClaimable(address claimant) internal view returns (uint, uint) {
        if (claimant == deployer) { return ((profitTracking.cumulativeProfitTokens * DEPLOYER_HARVEST_BP) / BP_DENOM - profitTracking.deployerClaimedTokens, (profitTracking.cumulativeProfitETH * DEPLOYER_HARVEST_BP) / BP_DENOM - profitTracking.deployerClaimedETH); }
        if (claimant == feeCollector) { return ((profitTracking.cumulativeProfitTokens * COLLECTOR_HARVEST_BP) / BP_DENOM - profitTracking.collectorClaimedTokens, (profitTracking.cumulativeProfitETH * COLLECTOR_HARVEST_BP) / BP_DENOM - profitTracking.collectorClaimedETH); }
        return (0, 0);
    }
    function claimDeployerProfits() external nonReentrant notInEmergency {
        if (msg.sender != deployer) revert InvalidInput();
        (uint cTokens, uint cETH) = _getClaimable(deployer);
        if (cTokens == 0 && cETH == 0) revert NoClaimableProfit();
        profitTracking.deployerClaimedTokens += cTokens;
        profitTracking.deployerClaimedETH += cETH;
        if (cTokens > 0) _transfer(address(this), deployer, cTokens);
        if (cETH > 0) _safeETHTransfer(deployer, cETH);
        emit DeployerClaimedProfits(cTokens, cETH);
    }
    function claimCollectorProfits() external nonReentrant notInEmergency {
        if (msg.sender != feeCollector) revert InvalidInput();
        (uint cTokens, uint cETH) = _getClaimable(feeCollector);
        if (cTokens == 0 && cETH == 0) revert NoClaimableProfit();
        profitTracking.collectorClaimedTokens += cTokens;
        profitTracking.collectorClaimedETH += cETH;
        if (cTokens > 0) _transfer(address(this), feeCollector, cTokens);
        if (cETH > 0) _safeETHTransfer(feeCollector, cETH);
        emit CollectorClaimedProfits(cTokens, cETH);
    }

    function _safeETHTransfer(address to, uint amount) internal { if (amount > 0) { (bool s,) = payable(to).call{value: amount}(""); if (!s) revert ETHTransferFailed(); } }
    
    function _createDeployJSON(string memory name_, uint256 maxSupply_, uint256 limitPerMint_, uint256 tokensForLP_) internal pure returns (string memory) {
        return string(abi.encodePacked('{"p":"evm-2.0","op":"deploy","tick":"', name_, '","max":"', _uint2str(maxSupply_), '","lim":"', _uint2str(limitPerMint_), '","lp":"', _uint2str(tokensForLP_), '"}'));
    }
    function _createMintJSON(uint256 tokensToMint) internal view returns (string memory) {
        return string(abi.encodePacked('{"p":"evm-2.0","op":"mint","tick":"', name(), '","amt":"', _uint2str(tokensToMint), '"}'));
    }
    function _uint2str(uint256 _i) internal pure returns (string memory) {
        if (_i == 0) return "0";
        uint256 temp = _i;
        uint256 digits;
        while (temp != 0) { digits++; temp /= 10; }
        bytes memory buffer = new bytes(digits);
        while (_i != 0) { digits--; buffer[digits] = bytes1(uint8(48 + _i % 10)); _i /= 10; }
        return string(buffer);
    }

    /**
 * @dev Emergency withdrawal of ERC20 tokens (admin only)
 * @param token The ERC20 token contract address
 * @param recipient Address to receive the tokens
 * @param amount Amount to withdraw (0 = withdraw all)
 */
function withdrawERC20(address token, address recipient, uint256 amount) 
    external 
    onlyRole(ADMIN_ROLE) 
    nonReentrant 
{
    if (token == address(0) || recipient == address(0)) revert InvalidInput();
    
    // Prevent withdrawal of the contract's own token unless in emergency mode
    if (token == address(this) && !emergencyMode) revert InvalidInput();
    
    IERC20 tokenContract = IERC20(token);
    uint256 balance = tokenContract.balanceOf(address(this));
    
    if (balance == 0) revert InvalidInput();
    
    // If amount is 0, withdraw all
    uint256 withdrawAmount = (amount == 0 || amount > balance) ? balance : amount;
    
    // Use the existing safe transfer pattern
    bool success = tokenContract.transfer(recipient, withdrawAmount);
    if (!success) revert ETHTransferFailed(); // Reusing existing error
}

    function scheduleEmergencyWithdraw(address recipient) external onlyRole(EMERGENCY_ROLE) { if (recipient == address(0)) revert InvalidInput(); emergencyConfig = EmergencyConfig(recipient, uint128(block.timestamp + EMERGENCY_DELAY)); emergencyMode = true; emit EmergencyWithdrawScheduled(recipient, block.timestamp + EMERGENCY_DELAY); }
    function executeEmergencyWithdraw() external onlyRole(EMERGENCY_ROLE) nonReentrant { EmergencyConfig memory _em = emergencyConfig; if (_em.recipient == address(0) || block.timestamp < _em.scheduledAt) revert EmergencyNotReady(); uint bal = address(this).balance; if (bal == 0) revert InvalidInput(); emergencyConfig = EmergencyConfig(address(0), 0); _safeETHTransfer(_em.recipient, bal); emit EmergencyWithdrawExecuted(_em.recipient, bal); }
    function exitEmergencyMode() external onlyRole(ADMIN_ROLE) { emergencyMode = false; emergencyConfig = EmergencyConfig(address(0), 0); }

    function getTokenConfig() external view returns (uint256, uint256, uint256, bool) { return (config.maxSupply, config.limitPerMint, config.tokensForLP, config.finalized); }
    function getLPInfo() external view returns (uint, uint, uint, uint) { return (lpTracking.initialLPTokens, lpTracking.burnedLPTokens, lpTracking.harvestLPTokens, lpTracking.lastHarvestTime); }
    function getTotalProfits() external view returns (uint, uint) { return (profitTracking.cumulativeProfitTokens, profitTracking.cumulativeProfitETH); }
    function getDeployerClaimable() external view returns (uint, uint) { return _getClaimable(deployer); }
    function getCollectorClaimable() external view returns (uint, uint) { return _getClaimable(feeCollector); }
    function getAddresses() external view returns (address, address, address) { return (deployer, feeAddress, feeCollector); }

    receive() external payable { if (emergencyMode) revert EmergencyModeActive(); }
}