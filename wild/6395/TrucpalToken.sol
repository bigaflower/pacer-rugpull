// File: contracts/ERC1404/IERC1404.sol



pragma solidity 0.8.20;

interface IERC1404 {
    /// @notice Detects if a transfer will be reverted and if so returns an appropriate reference code
    /// @param from Sending address
    /// @param to Receiving address
    /// @param value Amount of tokens being transferred
    /// @return Code by which to reference message for rejection reasoning
    /// @dev Overwrite with your custom transfer restriction logic
    function detectTransferRestriction (address from, address to, uint256 value) external view returns (uint8);

    /// @notice Detects if a transferFrom will be reverted and if so returns an appropriate reference code
    /// @param spender Transaction sending address
    /// @param from Source of funds address
    /// @param to Receiving address
    /// @param value Amount of tokens being transferred
    /// @return Code by which to reference message for rejection reasoning
    /// @dev Overwrite with your custom transfer restriction logic
    function detectTransferFromRestriction (address spender, address from, address to, uint256 value) external view returns (uint8);

    /// @notice Returns a human-readable message for a given restriction code
    /// @param restrictionCode Identifier for looking up a message
    /// @return Text showing the restriction's reasoning
    /// @dev Overwrite with your custom message and restrictionCode handling
    function messageForTransferRestriction (uint8 restrictionCode) external view returns (string memory);
}


interface IERC1404getSuccessCode {
    /// @notice Return the uint256 that represents the SUCCESS_CODE
    /// @return uint8 SUCCESS_CODE
    function getSuccessCode () external view returns (uint8);
}


/**
 * @title IERC1404Success
 * @dev Combines IERC1404 and IERC1404getSuccessCode interfaces, to be implemented by the TransferRestrictions contract
 */
interface IERC1404Success is IERC1404getSuccessCode, IERC1404 {
}
// File: contracts/ERC1404/IERC1404Validators.sol



pragma solidity 0.8.20;

/**
 * @title IERC1404Validators
 * @dev Interfaces implemented by the token contract to be called by the TransferRestrictions contract
 */
interface IERC1404Validators {

    /// @notice Returns a boolean indicating the paused state of the contract
    /// @return true if contract is paused, false if unpaused
    function paused() external view returns (bool);

    /// @notice Determine if sender and receiver are whitelisted, return true if both accounts are whitelisted
    /// @param from The address sending tokens
    /// @param to The address receiving tokens
    /// @return true if both accounts are whitelisted, false if not
    function checkWhitelists(address from, address to) external view returns (bool);

    /// @notice Determine if spender, sender and receiver are whitelisted, return true if all accounts are whitelisted
    /// @param spender The address performing the transfer
    /// @param from The address sending tokens
    /// @param to The address receiving tokens
    /// @return true if both accounts are whitelisted, false if not
    function checkWhitelists(address spender, address from, address to) external view returns (bool);

    /// @notice Determine if a users tokens are locked preventing a transfer
    /// @param _address the address to retrieve the data from
    /// @param amount the amount to send
    /// @return true if user has sufficient unlocked token to transfer the requested amount, false if not
    function checkTimelock(address _address, uint256 amount) external view returns (bool);
}


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

// File: contracts/TrucpalToken.sol



pragma solidity 0.8.20;






/**
 * @title TrucpalToken
 * @notice Extended ERC20 contract with additional functionality:
 * 1. Access Control
 * 2. Contract pausability
 * 3. Whitelisting
 * 4. Token timelocking
 * 5. Token minting
 * 6. Token burning
 * 7. Token revoking
 * 8. Transfer restrictions
 * @dev Inherits from OpenZeppelin contracts: ERC20, AccessControl, Pausable.
 * @dev Implements ERC1404 for transfer restrictions
 */
contract TrucpalToken is ERC20, AccessControl, Pausable, IERC1404, IERC1404Validators {
    
    // Tracks whether an address is whitelisted
    // data field can track any external field (like a hash of personal details)
    struct WhiteListItem {
        bool status;
        string data;
    }
    
    // Tracks the amount and release time of locked tokens for an address
    struct LockupItem {
        uint256 amount;
        uint256 releaseTime;
    }

    // Token Details
    string constant TOKEN_NAME = "Trucpal Security Token";
    string constant TOKEN_SYMBOL = "Trucpal";

   
    /// @dev Determines whether minting was allowed at construction
    bool public immutable MINT_ALLOWED;

     /// @dev Determines whether burning was allowed at construction
    bool public immutable BURN_ALLOWED;

    /// @dev The only address where tokens can be burned from
    address public burnAddress;

    // Role identifiers for AccessControl
    // bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00; // inherited from AccessControl
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant REVOKER_ROLE = keccak256("REVOKER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant WHITELISTER_ROLE = keccak256("WHITELISTER_ROLE");
    bytes32 public constant TIMELOCKER_ROLE = keccak256("TIMELOCKER_ROLE");

    /// @dev Whitelisting info per address
    mapping (address => WhiteListItem) public whitelists;

    /// @dev Timelocking info per address
    mapping (address => LockupItem) public lockups;

    // tracks the external contract where restriction logic is defined
    IERC1404Success private _transferRestrictions;

    /// Minting was not allowed at construction
    error MintingNotAllowed();
    /// Burning was not allowed at construction
    error BurningNotAllowed();
    /// Burn address is not set
    error BurnAddressNotSet();
    /// Address zero is not allowed for this operation
    error AddressZeroNotAllowed();
    /// Release time must be in the future
    error ReleaseTimeMustBeInFuture();
    /// Amount must be greater than zero
    error AmountMustBeGreaterThanZero();
    /// Transfer restrictions contract must be set
    error TransferRestrictionsContractMustBeSet();
    /// Not enough unlocked tokens to revoke
    error InsufficientUnlockedBalance();

    /// @dev Modifier to make a function callable only when a transfer is not restricted
    modifier notRestricted(address from, address to, uint256 value) {
        IERC1404Success _transferRestrictions_ = _transferRestrictions;
        if (address(_transferRestrictions_) == address(0)) revert TransferRestrictionsContractMustBeSet();
        uint8 restrictionCode = _transferRestrictions_.detectTransferRestriction(from, to, value);
        require(restrictionCode == _transferRestrictions_.getSuccessCode(),
            _transferRestrictions_.messageForTransferRestriction(restrictionCode));
        _;
    }

    /// @dev Modifier to make a function callable only when a transferFrom is not restricted
    modifier notRestrictedTransferFrom(address spender, address from, address to, uint256 value) {
        IERC1404Success _transferRestrictions_ = _transferRestrictions;
        if (address(_transferRestrictions_) == address(0)) revert TransferRestrictionsContractMustBeSet();
        uint8 restrictionCode = _transferRestrictions_.detectTransferFromRestriction(spender, from, to, value);
        require(restrictionCode == _transferRestrictions_.getSuccessCode(),
            _transferRestrictions_.messageForTransferRestriction(restrictionCode));
        _;
    }

    /// @dev Event for logging timelocking of tokens for an address
    event AccountLock(address address_, uint256 amount, uint256 releaseTime);

    /// @dev Event for logging the release of locked tokens for an address
    event AccountRelease(address address_, uint256 amountReleased);

    /// @dev Event for logging the updating of the transfer restrictions contract
    event RestrictionsUpdated(address newRestrictionsAddress, address updatedBy);

    /// @dev Event for logging the revoking of tokens from an address
    event Revoke(address indexed revoker, address indexed from, uint256 amount);

    /// @dev Event for logging the updating of a whitelist entry
    event WhitelistUpdate(address address_, bool status, string data);

    /// @dev Event for logging the updating of the burn address
    event burnAddressUpdated(address newBurnAddress, address updatedBy);

    /**
     * @dev The constructor sets up the basic properties of the token such as its name and symbol. It also assigns the
     * entire initial supply to the owner specified in the parameters. The owner is also set as the administrator with
     * all roles. The mint and burn allowance are set as per the parameters.
     * @param owner The address that will receive the initial supply of tokens, and be granted the default admin role
     * @param isMintAllowed Permission flag for token minting
     * @param isBurnAllowed Permission flag for token burning
     * @param initialSupply The amount of tokens to mint
     */
    constructor(address owner, bool isMintAllowed, bool isBurnAllowed, uint256 initialSupply)
        ERC20(TOKEN_NAME, TOKEN_SYMBOL)
    {
        MINT_ALLOWED = isMintAllowed;
        BURN_ALLOWED = isBurnAllowed;
        _mint(owner, initialSupply);
        _grantRole(DEFAULT_ADMIN_ROLE, owner); // set up the owner as the default admin of all roles
        grantRole(DEFAULT_ADMIN_ROLE, owner); // grant the owner all roles
    }

    /**
     * @dev Overrides the default AccessControl implementation to add whitelisting and granting of all roles to owners
     * of DEFAULT_ADMIN_ROLE
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        if (role == DEFAULT_ADMIN_ROLE) {
            _grantRole(MINTER_ROLE, account);
            _grantRole(BURNER_ROLE, account);
            _grantRole(REVOKER_ROLE, account);
            _grantRole(PAUSER_ROLE, account);
            _grantRole(WHITELISTER_ROLE, account);
            _grantRole(TIMELOCKER_ROLE, account);
            setWhitelist(account, true, "default admin");
        }
            _grantRole(role, account);
    }

    /**
     * @dev Overrides the default AccessControl implementation to add unwhitelisting and revoking of all roles to
     * owners of DEFAULT_ADMIN_ROLE
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        if (role == DEFAULT_ADMIN_ROLE) {
            _revokeRole(MINTER_ROLE, account);
            _revokeRole(BURNER_ROLE, account);
            _revokeRole(REVOKER_ROLE, account);
            _revokeRole(PAUSER_ROLE, account);
            _revokeRole(WHITELISTER_ROLE, account);
            _revokeRole(TIMELOCKER_ROLE, account);
            setWhitelist(account, false, "default admin revoked");
        }
            _revokeRole(role, account);
    }

    /**
     * @notice Mints tokens to a specified address, only callable by a minter
     * @param to The address to mint tokens to
     * @param amount The amount of tokens to mint
     */
    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        if(!MINT_ALLOWED) revert MintingNotAllowed();
        _mint(to, amount);
    }

    /**
     * @notice Sets the burn address, which is the only address that tokens can be burnt from. Only callable by an admin
     * @param newBurnAddress The new burn address
     */
    function setBurnAddress(address newBurnAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        burnAddress = newBurnAddress;
        emit burnAddressUpdated(newBurnAddress, msg.sender);
    }

    /**
     * @notice Burns tokens from the burn address. Only callable by a burner
     * @param amount The amount of tokens to burn
     */
    function burn(uint256 amount) external onlyRole(BURNER_ROLE) {
        if (!BURN_ALLOWED) revert BurningNotAllowed();
        _burn(burnAddress, amount);
    }

    /**
     * @notice Revokes tokens from an address and transfers them to the burn address. Only callable by a revoker
     * @param from The address to revoke tokens from
     * @param amount The amount of tokens to revoke
     */
    function revoke(address from, uint256 amount) external onlyRole(REVOKER_ROLE) {
        if (!checkTimelock(from, amount)) revert InsufficientUnlockedBalance();
        ERC20._transfer(from, burnAddress, amount);
        emit Revoke(msg.sender, from, amount);
    }
    
    /**
     * @notice Pauses all token transfers. Only callable by a pauser
     */
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /**
     * @notice Unpauses all token transfers. Only callable by a pauser
     */
    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /**
     * @notice Set the whitelist status of an address. Only callable by a whitelister
     * @param address_ The address to set the whitelist status for
     * @param status The status to set the whitelist to
     * @param data A string with data about the whitelisted address
     */
    function setWhitelist(address address_, bool status, string memory data) public onlyRole(WHITELISTER_ROLE) {
        if (address_ == address(0)) revert AddressZeroNotAllowed();
        whitelists[address_] = WhiteListItem(status, data);
        emit WhitelistUpdate(address_, status, data);
    }

    /**
     * @notice Get the whitelist status of an address
     * @param address_ The address to check the whitelist status for
     * @return True if the address is whitelisted, false if not
     */
    function getWhitelistStatus(address address_) external view returns(bool){
        return whitelists[address_].status;
    }

    /**
     * @notice Get the whitelist data of an address
     * @param address_ The address to check the whitelist data for
     * @return The whitelist data string for the address
     */
    function getWhitelistData(address address_) external view returns(string memory){
        return whitelists[address_].data;
    }

    /**
     * @notice Determine if sender and receiver are both whitelisted
     * @param from The address sending tokens
     * @param to The address receiving tokens
     * @return True if both addresses are whitelisted, false if not
     */
    function checkWhitelists(address from, address to) external view returns (bool) {
        return whitelists[from].status && whitelists[to].status;
    }

    /**
     * @notice Determine if spender, sender and receiver are all whitelisted
     * @param spender The address performing the transfer
     * @param from The address sending tokens
     * @param to The address receiving tokens
     * @return True if all addresses are whitelisted, false if not
     */
    function checkWhitelists(address spender, address from, address to) external view returns (bool) {
        return whitelists[from].status && whitelists[to].status && whitelists[spender].status;
    }

    /**
     * @notice Lock tokens for a given address until a given time in the future. Only callable by a timelocker
     * @param address_ The address to lock tokens for
     * @param amount The amount of tokens to lock. If this is greater than the balance, the entire balance will be
     * locked
     * @param releaseTime The time in the future when the tokens will be released, in seconds since the epoch
     */
    function lock(address address_, uint256 amount, uint256 releaseTime) public onlyRole(TIMELOCKER_ROLE) {
        if (releaseTime <= block.timestamp) revert ReleaseTimeMustBeInFuture();
        if (address_ == address(0)) revert AddressZeroNotAllowed();
        if (amount == 0) revert AmountMustBeGreaterThanZero();

        // if the amount is greater than the balance, lock the entire balance
        uint256 balance = ERC20.balanceOf(address_);
        amount = amount <=  balance ? amount : balance;
        
        lockups[address_] = LockupItem(amount, releaseTime);
        emit AccountLock(address_, amount, releaseTime);
    }

    /**
     * @notice Release tokens for a given address. Only callable by a timelocker
     * @param address_ The address to release tokens for
     * @param amountToRelease The amount of tokens to release. If this is greater than the locked amount, the entire
     * locked amount will be released
     */
    function release(address address_, uint256 amountToRelease) external onlyRole(TIMELOCKER_ROLE) {
        if (address_ == address(0)) revert AddressZeroNotAllowed();

        uint256 lockedAmount = lockups[address_].amount;

        // nothing to release
        if(lockedAmount == 0 || amountToRelease == 0) {
            emit AccountRelease(address_, 0);
            return;
        }
        
        uint256 newLockedAmount;
        // if the amount to release is greater than the locked amount, release the entire locked amount
        unchecked { // lockedAmount - amountToRelease only in case lockedAmount > amountToRelease
            newLockedAmount = lockedAmount <= amountToRelease ? 0 : lockedAmount - amountToRelease;
        }

        // Update the lockup details (in case all was released, amount will be 0 and hence no lockup)
        lockups[address_].amount = newLockedAmount;

        unchecked { // newLockedAmount is either 0 or less than lockedAmount
          emit AccountRelease(address_, lockedAmount - newLockedAmount);   
        }
    }

    /**
     * @notice Determine if a user has sufficient unlocked tokens to transfer the requested amount
     * @dev This function is used by the transfer and transferFrom functions to determine if the transfer should be
     * allowed. It does not check if the user has sufficient tokens to transfer, only if they have sufficient unlocked
     * tokens. If the user does not have sufficient unlocked tokens, this function will return true but the transfer
     * will fail due to low balance.
     * @param address_ The address to check the timelock for
     * @param amount The amount to check if can be transferred
     * @return True if the user has sufficient unlocked tokens to transfer the requested amount, false if not
     */
    function checkTimelock(address address_, uint256 amount) public view returns (bool) {
        // get the address' token balance
        uint256 balance = balanceOf(address_);

        // if the user does not have enough tokens to send regardless of lock return true here
        // the failure will still fail but this should make it explicit that the transfer failure is not
        // due to locked tokens but because of too low token balance
        if (balance < amount) return true;

        // copy lockup data into memory
        LockupItem memory lockupItem = lockups[address_];

        // return true if the lock is expired
        if (block.timestamp > lockupItem.releaseTime) return true;

        // get the user's token balance that is not locked
        uint256 nonLockedAmount = balance - lockupItem.amount;

        // return true if the user has enough unlocked tokens to send the requested amount, false if not
        return amount <= nonLockedAmount;
    }
    
    /**
     * @notice Retrieve the timelock info for a given address
     * @param address_ The address to retrieve the lockup info for
     * @return The release time and amount of tokens locked
     */
    function getLockUpInfo(address address_) external view returns(uint256, uint256) {
        // copy lockup data into memory
        LockupItem memory lockupItem = lockups[address_];

        return (lockupItem.releaseTime, lockupItem.amount);
    }

    /**
     * @notice Update the transfer restriction contract. Only callable by an admin
     * @param newRestrictionsAddress The new transfer restriction contract address
     */
    function updateTransferRestrictions(address newRestrictionsAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _transferRestrictions = IERC1404Success(newRestrictionsAddress);
        emit RestrictionsUpdated(newRestrictionsAddress, msg.sender);
    }

    /**
     * @notice Return the address of the transfer restrictions contract
     * @return The address of the transfer restrictions contract
     */
    function getRestrictionsAddress() external view returns (address) {
        return address(_transferRestrictions);
    }

    /**
     * @notice Returns the transfer restriction code for a transfer with the given parameters.
     * If the function returns SUCCESS_CODE (0) then it should be allowed, otherwise it should be blocked.
     * @param from The address sending tokens
     * @param to The address receiving tokens
     * @param amount The amount of tokens to transfer
     * @return The restriction code, where 0 means success
     */
    function detectTransferRestriction(address from, address to, uint256 amount) external view returns (uint8) {
        // call detectTransferRestriction on the current transferRestrictions contract
        return _transferRestrictions.detectTransferRestriction(from, to, amount);
    }

    /**
     * @notice Returns the transfer restriction code for a transferFrom with the given parameters.
     * If the function returns SUCCESS_CODE (0) then it should be allowed.
     * @param spender The address initiating the transfer
     * @param from The address sending tokens
     * @param to The address receiving tokens
     * @param amount The amount of tokens to transfer
     * @return The restriction code, where 0 means success
     */
    function detectTransferFromRestriction(address spender, address from, address to, uint256 amount)
        external
        view
        returns (uint8)
    {
        // call detectTransferFromRestriction on the current transferRestrictions contract
        return _transferRestrictions.detectTransferFromRestriction(spender, from, to, amount);
    }

    /**
     * @notice Provides a human readable string for a transfer restriction code
     * @param restrictionCode The restriction code
     * @return The corresponding human readable string
     */
    function messageForTransferRestriction(uint8 restrictionCode) external view returns (string memory) {
        // call messageForTransferRestriction on the current transferRestrictions contract
        return _transferRestrictions.messageForTransferRestriction(restrictionCode);
    }

    /**
     * @notice Overrides the parent class token transfer function to enforce transfer restrictions. See {ERC20-transfer}
     * @param to The address to transfer tokens to
     * @param value The amount of tokens to transfer
     * @return success A boolean indicating whether the operation was successful
     */
    function transfer(address to, uint256 value)
        override public
        notRestricted(msg.sender, to, value)
        returns (bool success)
    {
        success = ERC20.transfer(to, value);
    }

    /**
     * @notice Overrides the parent class token transferFrom function to enforce transfer restrictions.
     * See {ERC20-transferFrom}
     * @param from The address to transfer tokens from
     * @param to The address to transfer tokens to
     * @param value The amount of tokens to transfer
     * @return success A boolean indicating whether the operation was successful
     */
    function transferFrom(address from, address to, uint256 value)
        override public
        notRestrictedTransferFrom(msg.sender, from, to, value)
        returns (bool success)
    {
        success = ERC20.transferFrom(from, to, value);
    }

    /**
     * @notice Indicates whether all transfers are paused. See {Pausable-paused}
     * @return True if transfers are paused, false otherwise
     */
    function paused() public view override(Pausable, IERC1404Validators) returns (bool) {
        return Pausable.paused();
    }

    /**
     * @notice Returns the number of decimals used for the token. See {ERC20-decimals}
     * @return The number of decimals used for the token
     */
    function decimals() public pure override(ERC20) returns (uint8) {
        return 6;
    }
}