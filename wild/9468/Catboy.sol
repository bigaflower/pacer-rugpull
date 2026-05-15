// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/**
 * @title IInterchainTokenStandard interface
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IInterchainTokenStandard {
    /**
     * @notice Implementation of the interchainTransfer method.
     * @dev We chose to either pass `metadata` as raw data on a remote contract call, or if no data is passed, just do a transfer.
     * A different implementation could use metadata to specify a function to invoke, or for other purposes as well.
     * @param destinationChain The destination chain identifier.
     * @param recipient The bytes representation of the address of the recipient.
     * @param amount The amount of token to be transferred.
     * @param metadata Optional metadata for the call for additional effects (such as calling a destination contract).
     */
    function interchainTransfer(
        string calldata destinationChain,
        bytes calldata recipient,
        uint256 amount,
        bytes calldata metadata
    ) external payable;

    /**
     * @notice Implementation of the interchainTransferFrom method
     * @dev We chose to either pass `metadata` as raw data on a remote contract call, or, if no data is passed, just do a transfer.
     * A different implementation could use metadata to specify a function to invoke, or for other purposes as well.
     * @param sender The sender of the tokens. They need to have approved `msg.sender` before this is called.
     * @param destinationChain The string representation of the destination chain.
     * @param recipient The bytes representation of the address of the recipient.
     * @param amount The amount of token to be transferred.
     * @param metadata Optional metadata for the call for additional effects (such as calling a destination contract.)
     */
    function interchainTransferFrom(
        address sender,
        string calldata destinationChain,
        bytes calldata recipient,
        uint256 amount,
        bytes calldata metadata
    ) external payable;
}
/**
 * @title ITransmitInterchainToken Interface
 * @notice Interface for transmiting interchain tokens via the interchain token service
 */
interface ITransmitInterchainToken {
    /**
     * @notice Transmit an interchain transfer for the given tokenId.
     * @dev Only callable by a token registered under a tokenId.
     * @param tokenId The tokenId of the token (which must be the msg.sender).
     * @param sourceAddress The address where the token is coming from.
     * @param destinationChain The name of the chain to send tokens to.
     * @param destinationAddress The destinationAddress for the interchainTransfer.
     * @param amount The amount of token to give.
     * @param metadata Optional metadata for the call for additional effects (such as calling a destination contract).
     */
    function transmitInterchainTransfer(
        bytes32 tokenId,
        address sourceAddress,
        string calldata destinationChain,
        bytes memory destinationAddress,
        uint256 amount,
        bytes calldata metadata
    ) external payable;
}
/**
 * @title An example implementation of the IInterchainTokenStandard.
 * @notice The is an abstract contract that needs to be extended with an ERC20 implementation. See `InterchainToken` for an example implementation.
 */
abstract contract InterchainTokenStandard is IInterchainTokenStandard {
    /**
     * @notice Getter for the tokenId used for this token.
     * @dev Needs to be overwritten.
     * @return tokenId_ The tokenId that this token is registerred under.
     */
    function interchainTokenId() public view virtual returns (bytes32 tokenId_);

    /**
     * @notice Getter for the interchain token service.
     * @dev Needs to be overwritten.
     * @return service The address of the interchain token service.
     */
    function interchainTokenService() public view virtual returns (address service);

    /**
     * @notice Implementation of the interchainTransfer method
     * @dev We chose to either pass `metadata` as raw data on a remote contract call, or if no data is passed, just do a transfer.
     * A different implementation could use metadata to specify a function to invoke, or for other purposes as well.
     * @param destinationChain The destination chain identifier.
     * @param recipient The bytes representation of the address of the recipient.
     * @param amount The amount of token to be transferred.
     * @param metadata Either empty, just to facilitate an interchain transfer, or the data to be passed for an interchain contract call with transfer
     * as per semantics defined by the token service.
     */
    function interchainTransfer(
        string calldata destinationChain,
        bytes calldata recipient,
        uint256 amount,
        bytes calldata metadata
    ) external payable {
        address sender = msg.sender;

        _beforeInterchainTransfer(msg.sender, destinationChain, recipient, amount, metadata);

        ITransmitInterchainToken(interchainTokenService()).transmitInterchainTransfer{ value: msg.value }(
            interchainTokenId(),
            sender,
            destinationChain,
            recipient,
            amount,
            metadata
        );
    }

    /**
     * @notice Implementation of the interchainTransferFrom method
     * @dev We chose to either pass `metadata` as raw data on a remote contract call, or, if no data is passed, just do a transfer.
     * A different implementation could use metadata to specify a function to invoke, or for other purposes as well.
     * @param sender The sender of the tokens. They need to have approved `msg.sender` before this is called.
     * @param destinationChain The string representation of the destination chain.
     * @param recipient The bytes representation of the address of the recipient.
     * @param amount The amount of token to be transferred.
     * @param metadata Either empty, just to facilitate an interchain transfer, or the data to be passed to an interchain contract call and transfer.
     */
    function interchainTransferFrom(
        address sender,
        string calldata destinationChain,
        bytes calldata recipient,
        uint256 amount,
        bytes calldata metadata
    ) external payable {
        _spendAllowance(sender, msg.sender, amount);

        _beforeInterchainTransfer(sender, destinationChain, recipient, amount, metadata);

        ITransmitInterchainToken(interchainTokenService()).transmitInterchainTransfer{ value: msg.value }(
            interchainTokenId(),
            sender,
            destinationChain,
            recipient,
            amount,
            metadata
        );
    }

    /**
     * @notice A method to be overwritten that will be called before an interchain transfer. One can approve the tokenManager here if needed,
     * to allow users for a 1-call transfer in case of a lock-unlock token manager.
     * @param from The sender of the tokens. They need to have approved `msg.sender` before this is called.
     * @param destinationChain The string representation of the destination chain.
     * @param destinationAddress The bytes representation of the address of the recipient.
     * @param amount The amount of token to be transferred.
     * @param metadata Either empty, just to facilitate an interchain transfer, or the data to be passed to an interchain contract call and transfer.
     */
    function _beforeInterchainTransfer(
        address from,
        string calldata destinationChain,
        bytes calldata destinationAddress,
        uint256 amount,
        bytes calldata metadata
    ) internal virtual {}

    /**
     * @notice A method to be overwritten that will decrease the allowance of the `spender` from `sender` by `amount`.
     * @dev Needs to be overwritten. This provides flexibility for the choice of ERC20 implementation used. Must revert if allowance is not sufficient.
     */
    function _spendAllowance(address sender, address spender, uint256 amount) internal virtual;
}
/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    error InvalidAccount();

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
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
}
/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
contract ERC20 is IERC20 {
    mapping(address => uint256) public override balanceOf;

    mapping(address => mapping(address => uint256)) public override allowance;

    uint256 public override totalSupply;
    uint256 internal constant UINT256_MAX = type(uint256).max;

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) external virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
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
    function approve(address spender, uint256 amount) external virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
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
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external virtual override returns (bool) {
        uint256 _allowance = allowance[sender][msg.sender];

        if (_allowance != UINT256_MAX) {
            _approve(sender, msg.sender, _allowance - amount);
        }

        _transfer(sender, recipient, amount);

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
    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
        _approve(msg.sender, spender, allowance[msg.sender][spender] + addedValue);
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
    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        _approve(msg.sender, spender, allowance[msg.sender][spender] - subtractedValue);
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        if (sender == address(0) || recipient == address(0)) revert InvalidAccount();

        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        if (account == address(0)) revert InvalidAccount();

        totalSupply += amount;
        balanceOf[account] += amount;
        emit Transfer(address(0), account, amount);
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
        if (account == address(0)) revert InvalidAccount();

        balanceOf[account] -= amount;
        totalSupply -= amount;
        emit Transfer(account, address(0), amount);
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
        if (owner == address(0) || spender == address(0)) revert InvalidAccount();

        allowance[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}
/**
 * @title RolesConstants
 * @notice This contract contains enum values representing different contract roles.
 */
contract RolesConstants {
    enum Roles {
        MINTER,
        OPERATOR,
        FLOW_LIMITER
    }
}
/**
 * @title IRolesBase Interface
 * @notice IRolesBase is an interface that abstracts the implementation of a
 * contract with role control internal functions.
 */
interface IRolesBase {
    error MissingRole(address account, uint8 role);
    error MissingAllRoles(address account, uint256 accountRoles);
    error MissingAnyOfRoles(address account, uint256 accountRoles);

    error InvalidProposedRoles(address fromAccount, address toAccount, uint256 accountRoles);

    event RolesProposed(address indexed fromAccount, address indexed toAccount, uint256 accountRoles);
    event RolesAdded(address indexed account, uint256 accountRoles);
    event RolesRemoved(address indexed account, uint256 accountRoles);

    /**
     * @notice Checks if an account has a role.
     * @param account The address to check
     * @param role The role to check
     * @return True if the account has the role, false otherwise
     */
    function hasRole(address account, uint8 role) external view returns (bool);
}
/**
 * @title IMinter Interface
 * @notice An interface for a contract module which provides a basic access control mechanism, where
 * there is an account (a minter) that can be granted exclusive access to specific functions.
 */
interface IMinter is IRolesBase {
    /**
     * @notice Change the minter of the contract.
     * @dev Can only be called by the current minter.
     * @param minter_ The address of the new minter.
     */
    function transferMintership(address minter_) external;

    /**
     * @notice Proposed a change of the minter of the contract.
     * @dev Can only be called by the current minter.
     * @param minter_ The address of the new minter.
     */
    function proposeMintership(address minter_) external;

    /**
     * @notice Accept a change of the minter of the contract.
     * @dev Can only be called by the proposed minter.
     * @param fromMinter The previous minter.
     */
    function acceptMintership(address fromMinter) external;

    /**
     * @notice Query if an address is a minter
     * @param addr the address to query for
     * @return bool Boolean value representing whether or not the address is a minter.
     */
    function isMinter(address addr) external view returns (bool);
}

/**
 * @title Minter Contract
 * @notice A contract module which provides a basic access control mechanism, where
 * there is an account (a minter) that can be granted exclusive access to
 * specific functions.
 * @dev This module is used through inheritance.
 */


/**
 * @title RolesBase
 * @notice A contract module which provides a set if internal functions
 * for implementing role control features.
 */
contract RolesBase is IRolesBase {
    bytes32 internal constant ROLES_PREFIX = keccak256('roles');
    bytes32 internal constant PROPOSE_ROLES_PREFIX = keccak256('propose-roles');

    /**
     * @notice Modifier that throws an error if called by any account missing the role.
     */
    modifier onlyRole(uint8 role) {
        if (!_hasRole(_getRoles(msg.sender), role)) revert MissingRole(msg.sender, role);

        _;
    }

    /**
     * @notice Modifier that throws an error if called by an account without all the roles.
     */
    modifier withEveryRole(uint8[] memory roles) {
        uint256 accountRoles = _toAccountRoles(roles);
        if (!_hasAllTheRoles(_getRoles(msg.sender), accountRoles)) revert MissingAllRoles(msg.sender, accountRoles);

        _;
    }

    /**
     * @notice Modifier that throws an error if called by an account without any of the roles.
     */
    modifier withAnyRole(uint8[] memory roles) {
        uint256 accountRoles = _toAccountRoles(roles);
        if (!_hasAnyOfRoles(_getRoles(msg.sender), accountRoles)) revert MissingAnyOfRoles(msg.sender, accountRoles);

        _;
    }

    /**
     * @notice Checks if an account has a role.
     * @param account The address to check
     * @param role The role to check
     * @return True if the account has the role, false otherwise
     */
    function hasRole(address account, uint8 role) public view returns (bool) {
        return _hasRole(_getRoles(account), role);
    }

    /**
     * @notice Internal function to convert an array of roles to a uint256.
     * @param roles The roles to convert
     * @return accountRoles The roles in uint256 format
     */
    function _toAccountRoles(uint8[] memory roles) internal pure returns (uint256) {
        uint256 length = roles.length;
        uint256 accountRoles;

        for (uint256 i = 0; i < length; ++i) {
            accountRoles |= (1 << roles[i]);
        }

        return accountRoles;
    }

    /**
     * @notice Internal function to get the key of the roles mapping.
     * @param account The address to get the key for
     * @return key The key of the roles mapping
     */
    function _rolesKey(address account) internal view virtual returns (bytes32 key) {
        return keccak256(abi.encodePacked(ROLES_PREFIX, account));
    }

    /**
     * @notice Internal function to get the roles of an account.
     * @param account The address to get the roles for
     * @return accountRoles The roles of the account in uint256 format
     */
    function _getRoles(address account) internal view returns (uint256 accountRoles) {
        bytes32 key = _rolesKey(account);
        assembly {
            accountRoles := sload(key)
        }
    }

    /**
     * @notice Internal function to set the roles of an account.
     * @param account The address to set the roles for
     * @param accountRoles The roles to set
     */
    function _setRoles(address account, uint256 accountRoles) private {
        bytes32 key = _rolesKey(account);
        assembly {
            sstore(key, accountRoles)
        }
    }

    /**
     * @notice Internal function to get the key of the proposed roles mapping.
     * @param fromAccount The address of the current role
     * @param toAccount The address of the pending role
     * @return key The key of the proposed roles mapping
     */
    function _proposalKey(address fromAccount, address toAccount) internal view virtual returns (bytes32 key) {
        return keccak256(abi.encodePacked(PROPOSE_ROLES_PREFIX, fromAccount, toAccount));
    }

    /**
     * @notice Internal function to get the proposed roles of an account.
     * @param fromAccount The address of the current role
     * @param toAccount The address of the pending role
     * @return proposedRoles_ The proposed roles of the account in uint256 format
     */
    function _getProposedRoles(address fromAccount, address toAccount) internal view returns (uint256 proposedRoles_) {
        bytes32 key = _proposalKey(fromAccount, toAccount);
        assembly {
            proposedRoles_ := sload(key)
        }
    }

    /**
     * @notice Internal function to set the proposed roles of an account.
     * @param fromAccount The address of the current role
     * @param toAccount The address of the pending role
     * @param proposedRoles_ The proposed roles to set in uint256 format
     */
    function _setProposedRoles(
        address fromAccount,
        address toAccount,
        uint256 proposedRoles_
    ) private {
        bytes32 key = _proposalKey(fromAccount, toAccount);
        assembly {
            sstore(key, proposedRoles_)
        }
    }

    /**
     * @notice Internal function to add a role to an account.
     * @dev emits a RolesAdded event.
     * @param account The address to add the role to
     * @param role The role to add
     */
    function _addRole(address account, uint8 role) internal {
        _addAccountRoles(account, 1 << role);
    }

    /**
     * @notice Internal function to add roles to an account.
     * @dev emits a RolesAdded event.
     * @dev Called in the constructor to set the initial roles.
     * @param account The address to add roles to
     * @param roles The roles to add
     */
    function _addRoles(address account, uint8[] memory roles) internal {
        _addAccountRoles(account, _toAccountRoles(roles));
    }

    /**
     * @notice Internal function to add roles to an account.
     * @dev emits a RolesAdded event.
     * @dev Called in the constructor to set the initial roles.
     * @param account The address to add roles to
     * @param accountRoles The roles to add
     */
    function _addAccountRoles(address account, uint256 accountRoles) internal {
        uint256 newAccountRoles = _getRoles(account) | accountRoles;

        _setRoles(account, newAccountRoles);

        emit RolesAdded(account, accountRoles);
    }

    /**
     * @notice Internal function to remove a role from an account.
     * @dev emits a RolesRemoved event.
     * @param account The address to remove the role from
     * @param role The role to remove
     */
    function _removeRole(address account, uint8 role) internal {
        _removeAccountRoles(account, 1 << role);
    }

    /**
     * @notice Internal function to remove roles from an account.
     * @dev emits a RolesRemoved event.
     * @param account The address to remove roles from
     * @param roles The roles to remove
     */
    function _removeRoles(address account, uint8[] memory roles) internal {
        _removeAccountRoles(account, _toAccountRoles(roles));
    }

    /**
     * @notice Internal function to remove roles from an account.
     * @dev emits a RolesRemoved event.
     * @param account The address to remove roles from
     * @param accountRoles The roles to remove
     */
    function _removeAccountRoles(address account, uint256 accountRoles) internal {
        uint256 newAccountRoles = _getRoles(account) & ~accountRoles;

        _setRoles(account, newAccountRoles);

        emit RolesRemoved(account, accountRoles);
    }

    /**
     * @notice Internal function to check if an account has a role.
     * @param accountRoles The roles of the account in uint256 format
     * @param role The role to check
     * @return True if the account has the role, false otherwise
     */
    function _hasRole(uint256 accountRoles, uint8 role) internal pure returns (bool) {
        return accountRoles & (1 << role) != 0;
    }

    /**
     * @notice Internal function to check if an account has all the roles.
     * @param hasAccountRoles The roles of the account in uint256 format
     * @param mustHaveAccountRoles The roles the account must have
     * @return True if the account has all the roles, false otherwise
     */
    function _hasAllTheRoles(uint256 hasAccountRoles, uint256 mustHaveAccountRoles) internal pure returns (bool) {
        return (hasAccountRoles & mustHaveAccountRoles) == mustHaveAccountRoles;
    }

    /**
     * @notice Internal function to check if an account has any of the roles.
     * @param hasAccountRoles The roles of the account in uint256 format
     * @param mustHaveAnyAccountRoles The roles to check in uint256 format
     * @return True if the account has any of the roles, false otherwise
     */
    function _hasAnyOfRoles(uint256 hasAccountRoles, uint256 mustHaveAnyAccountRoles) internal pure returns (bool) {
        return (hasAccountRoles & mustHaveAnyAccountRoles) != 0;
    }

    /**
     * @notice Internal function to propose to transfer roles of message sender to a new account.
     * @dev Original account must have all the proposed roles.
     * @dev Emits a RolesProposed event.
     * @dev Roles are not transferred until the new role accepts the role transfer.
     * @param fromAccount The address of the current roles
     * @param toAccount The address to transfer roles to
     * @param role The role to transfer
     */
    function _proposeRole(
        address fromAccount,
        address toAccount,
        uint8 role
    ) internal {
        _proposeAccountRoles(fromAccount, toAccount, 1 << role);
    }

    /**
     * @notice Internal function to propose to transfer roles of message sender to a new account.
     * @dev Original account must have all the proposed roles.
     * @dev Emits a RolesProposed event.
     * @dev Roles are not transferred until the new role accepts the role transfer.
     * @param fromAccount The address of the current roles
     * @param toAccount The address to transfer roles to
     * @param roles The roles to transfer
     */
    function _proposeRoles(
        address fromAccount,
        address toAccount,
        uint8[] memory roles
    ) internal {
        _proposeAccountRoles(fromAccount, toAccount, _toAccountRoles(roles));
    }

    /**
     * @notice Internal function to propose to transfer roles of message sender to a new account.
     * @dev Original account must have all the proposed roles.
     * @dev Emits a RolesProposed event.
     * @dev Roles are not transferred until the new role accepts the role transfer.
     * @param fromAccount The address of the current roles
     * @param toAccount The address to transfer roles to
     * @param accountRoles The account roles to transfer
     */
    function _proposeAccountRoles(
        address fromAccount,
        address toAccount,
        uint256 accountRoles
    ) internal {
        if (!_hasAllTheRoles(_getRoles(fromAccount), accountRoles)) revert MissingAllRoles(fromAccount, accountRoles);

        _setProposedRoles(fromAccount, toAccount, accountRoles);

        emit RolesProposed(fromAccount, toAccount, accountRoles);
    }

    /**
     * @notice Internal function to accept roles transferred from another account.
     * @dev Pending account needs to pass all the proposed roles.
     * @dev Emits RolesRemoved and RolesAdded events.
     * @param fromAccount The address of the current role
     * @param role The role to accept
     */
    function _acceptRole(
        address fromAccount,
        address toAccount,
        uint8 role
    ) internal virtual {
        _acceptAccountRoles(fromAccount, toAccount, 1 << role);
    }

    /**
     * @notice Internal function to accept roles transferred from another account.
     * @dev Pending account needs to pass all the proposed roles.
     * @dev Emits RolesRemoved and RolesAdded events.
     * @param fromAccount The address of the current role
     * @param roles The roles to accept
     */
    function _acceptRoles(
        address fromAccount,
        address toAccount,
        uint8[] memory roles
    ) internal virtual {
        _acceptAccountRoles(fromAccount, toAccount, _toAccountRoles(roles));
    }

    /**
     * @notice Internal function to accept roles transferred from another account.
     * @dev Pending account needs to pass all the proposed roles.
     * @dev Emits RolesRemoved and RolesAdded events.
     * @param fromAccount The address of the current role
     * @param accountRoles The account roles to accept
     */
    function _acceptAccountRoles(
        address fromAccount,
        address toAccount,
        uint256 accountRoles
    ) internal virtual {
        if (_getProposedRoles(fromAccount, toAccount) != accountRoles) {
            revert InvalidProposedRoles(fromAccount, toAccount, accountRoles);
        }

        _setProposedRoles(fromAccount, toAccount, 0);
        _transferAccountRoles(fromAccount, toAccount, accountRoles);
    }

    /**
     * @notice Internal function to transfer roles from one account to another.
     * @dev Original account must have all the proposed roles.
     * @param fromAccount The address of the current role
     * @param toAccount The address to transfer role to
     * @param role The role to transfer
     */
    function _transferRole(
        address fromAccount,
        address toAccount,
        uint8 role
    ) internal {
        _transferAccountRoles(fromAccount, toAccount, 1 << role);
    }

    /**
     * @notice Internal function to transfer roles from one account to another.
     * @dev Original account must have all the proposed roles.
     * @param fromAccount The address of the current role
     * @param toAccount The address to transfer role to
     * @param roles The roles to transfer
     */
    function _transferRoles(
        address fromAccount,
        address toAccount,
        uint8[] memory roles
    ) internal {
        _transferAccountRoles(fromAccount, toAccount, _toAccountRoles(roles));
    }

    /**
     * @notice Internal function to transfer roles from one account to another.
     * @dev Original account must have all the proposed roles.
     * @param fromAccount The address of the current role
     * @param toAccount The address to transfer role to
     * @param accountRoles The account roles to transfer
     */
    function _transferAccountRoles(
        address fromAccount,
        address toAccount,
        uint256 accountRoles
    ) internal {
        if (!_hasAllTheRoles(_getRoles(fromAccount), accountRoles)) revert MissingAllRoles(fromAccount, accountRoles);

        _removeAccountRoles(fromAccount, accountRoles);
        _addAccountRoles(toAccount, accountRoles);
    }
}

contract Minter is IMinter, RolesBase, RolesConstants {
    /**
     * @notice Internal function that stores the new minter address in the correct storage slot.
     * @param minter_ The address of the new minter.
     */
    function _addMinter(address minter_) internal {
        _addRole(minter_, uint8(Roles.MINTER));
    }

    /**
     * @notice Changes the minter of the contract.
     * @dev Can only be called by the current minter.
     * @param minter_ The address of the new minter.
     */
    function transferMintership(address minter_) external onlyRole(uint8(Roles.MINTER)) {
        _transferRole(msg.sender, minter_, uint8(Roles.MINTER));
    }

    /**
     * @notice Proposes a change of the minter of the contract.
     * @dev Can only be called by the current minter.
     * @param minter_ The address of the new minter.
     */
    function proposeMintership(address minter_) external onlyRole(uint8(Roles.MINTER)) {
        _proposeRole(msg.sender, minter_, uint8(Roles.MINTER));
    }

    /**
     * @notice Accept a change of the minter of the contract.
     * @dev Can only be called by the proposed minter.
     * @param fromMinter The previous minter.
     */
    function acceptMintership(address fromMinter) external {
        _acceptRole(fromMinter, msg.sender, uint8(Roles.MINTER));
    }

    /**
     * @notice Query if an address is a minter
     * @param addr the address to query for
     * @return bool Boolean value representing whether or not the address is a minter.
     */
    function isMinter(address addr) external view returns (bool) {
        return hasRole(addr, uint8(Roles.MINTER));
    }
}

/**
 * @title IERC20MintableBurnable Interface
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20MintableBurnable {
    /**
     * @notice Function to mint new tokens.
     * @dev Can only be called by the minter address.
     * @param to The address that will receive the minted tokens.
     * @param amount The amount of tokens to mint.
     */
    function mint(address to, uint256 amount) external;

    /**
     * @notice Function to burn tokens.
     * @dev Can only be called by the minter address.
     * @param from The address that will have its tokens burnt.
     * @param amount The amount of tokens to burn.
     */
    function burn(address from, uint256 amount) external;
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() external virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * Utility library of inline functions on addresses
 */
library Address {
    /**
     * Returns whether the target address is a contract
     * @dev This function will return false if invoked during the constructor of a contract,
     * as the code is not actually created until after the constructor finishes.
     * @param account address of the account to check
     * @return whether the target address is a contract
     */
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // XXX Currently there is no better way to check if there is a contract in an address
        // than to check the size of the code at that address.
        // See https://ethereum.stackexchange.com/a/14016/36603
        // for more details about how this works.
        // TODO Check this again before the Serenity release, because all addresses will be
        // contracts then.
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

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

contract Catboy is Ownable, InterchainTokenStandard, ERC20, Minter, IERC20MintableBurnable {
    using SafeMath for uint256;
    using Address for address;
    //events
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event SellFeesChanged(uint256 _marketingFee);
    event BuyFeesChanged(uint256 _marketingFee);
    event TransferFeeChanged(uint256 _transferFee);
    event SetFeeReceivers(address _marketingReceiver);
    event ChangedSwapBack(bool _enabled, uint256 _amount);
    event SetFeeExempt(address _addr, bool _value);
    event InitialDistributionFinished(bool _value);

    address public service;
    bytes32 public tokenId;
    bool internal tokenManagerRequiresApproval_ = true;
    address private WETH;

    string  constant public name = "Catboy";
    string constant public symbol = "CATBOY";
    uint8 constant public decimals = 18;
    uint256 constant public maxSupply = 200000000* 10 ** decimals;
    uint256 constant public initialSupply = 100000000* 10 ** decimals;
    address[] public _markerPairs;
    mapping (address => bool) public automatedMarketMakerPairs;

    //transfer fee
    uint256 private transferFee = 0;
    
    //totalFees
    uint256 private totalBuyFee = 3;
    uint256 private totalSellFee = 3;
    uint256 constant public maxFee = 5; 

    uint256 constant private feeDenominator  = 100;

    address private marketingFeeReceiver = 0x230265e5F1d1b43D3f56409E9D78b7eb4Cd4c1f1;

    IDEXRouter public router;
    address public pair;
    bool public swapEnabled = true;
    uint256 public swapThreshold = initialSupply * 1 / 5000;

    bool private inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }
    mapping (address => bool) public isFeeExempt;


    constructor(address service_, bytes32 tokenId_) {
        _addMinter(msg.sender);
        service = service_;
        tokenId = tokenId_; 
        router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        WETH = router.WETH();
        pair = IDEXFactory(router.factory()).createPair(WETH, address(this));

        setAutomatedMarketMakerPair(pair, true);
        isFeeExempt[msg.sender] = true;
        allowance[address(this)][address(router)] = type(uint256).max;
        _mint(msg.sender, initialSupply );
    }

    function interchainTokenService() public view override returns (address) {
        return service;
    }

    function interchainTokenId() public view override returns (bytes32) {
        return tokenId;
    }

    function _beforeInterchainTransfer(
        address sender,
        string calldata /*destinationChain*/,
        bytes calldata /*destinationAddress*/,
        uint256 amount,
        bytes calldata /*metadata*/
    ) internal override {
        if (!tokenManagerRequiresApproval_) return;
        address serviceAddress = service;
        uint256 allowance_ = allowance[sender][serviceAddress];
        if (allowance_ != UINT256_MAX) {
            if (allowance_ > UINT256_MAX - amount) {
                allowance_ = UINT256_MAX - amount;
            }

            _approve(sender, serviceAddress, allowance_ + amount);
        }
    }

    function _spendAllowance(address sender, address spender, uint256 amount) internal override {
        uint256 _allowance = allowance[sender][spender];

        if (_allowance != UINT256_MAX) {
            _approve(sender, spender, _allowance - amount);
        }
    }

    function setTokenManagerRequiresApproval(bool requiresApproval) external onlyOwner {
        tokenManagerRequiresApproval_ = requiresApproval;
    }

    function mint(address account, uint256 amount) external onlyRole(uint8(Roles.MINTER)) {
        require(totalSupply + amount <= maxSupply, "Cant mint that much");
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external onlyRole(uint8(Roles.MINTER)) {
        _burn(account, amount);
    }

    function setTokenId(bytes32 tokenId_) external onlyOwner {
        tokenId = tokenId_;
    }

    function setServiceAddress(address _service) external onlyOwner {
        service = _service;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual override {
        if(inSwap){ _basicTransfer(sender, recipient, amount); 
        return;}

        if(shouldSwapBack()){ swapBack(); }

        uint256 amountReceived = amount; 

        if(automatedMarketMakerPairs[sender]) { //buy
            if(!isFeeExempt[recipient]) {
                amountReceived = takeBuyFee(sender, amount);
            }

        } else if(automatedMarketMakerPairs[recipient]) { //sell
            if(!isFeeExempt[sender]) {
                amountReceived = takeSellFee(sender, amount);
            }
        } else {	
            if (!isFeeExempt[sender]) {	
                amountReceived = takeTransferFee(sender, amount);	
            }
        }

        balanceOf[sender] = balanceOf[sender].sub(amount);
        balanceOf[recipient] = balanceOf[recipient].add(amountReceived);
        emit Transfer(sender, recipient, amountReceived);
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        balanceOf[sender] = balanceOf[sender].sub(amount, "Insufficient Balance");
        balanceOf[recipient] = balanceOf[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }
    // Fees
    function takeBuyFee(address sender, uint256 amount) internal returns (uint256){

        uint256 feeAmount = amount.mul(totalBuyFee).div(feeDenominator);

        balanceOf[address(this)] = balanceOf[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        return amount.sub(feeAmount);
    }

    function takeSellFee(address sender, uint256 amount) internal returns (uint256){
        uint256 feeAmount = amount.mul(totalSellFee).div(feeDenominator);

        balanceOf[address(this)] = balanceOf[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        return amount.sub(feeAmount);
            
    }

    function takeTransferFee(address sender, uint256 amount) internal returns (uint256){
        uint256 feeAmount = amount.mul(transferFee).div(feeDenominator);
          
            
        if (feeAmount > 0) {
            balanceOf[address(this)] = balanceOf[address(this)].add(feeAmount);	
            emit Transfer(sender, address(this), feeAmount); 
        }
            	
        return amount.sub(feeAmount);	
    }    

    function shouldSwapBack() internal view returns (bool) {
        return
        !automatedMarketMakerPairs[msg.sender]
        && !inSwap
        && swapEnabled
        && balanceOf[address(this)] >= swapThreshold;
    }

    function swapBack() internal swapping {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            balanceOf[address(this)],
            0,
            path,
            marketingFeeReceiver,
            block.timestamp
        );
    }

    // Admin Functions
    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;

        emit SetFeeExempt(holder, exempt);
    }
    function setBuyFee(uint256 _marketingFee) external onlyOwner {
        totalBuyFee = _marketingFee;
        require(totalBuyFee <= maxFee, "Fees cannot be more than 5%");

        emit BuyFeesChanged(_marketingFee);
    }

    function setSellFee(uint256 _marketingFee) external onlyOwner {
        totalSellFee = _marketingFee;
        require(totalSellFee <= maxFee, "Fees cannot be more than 5%");

        emit SellFeesChanged(_marketingFee);
    }

    function setTransferFee(uint256 _transferFee) external onlyOwner {	
        require(_transferFee < maxFee, "Fees cannot be higher than 5%");	
        transferFee = _transferFee;	

	    emit TransferFeeChanged(_transferFee);	
    }


    function setFeeReceiver(address _marketingFeeReceiver) external onlyOwner {
        require( _marketingFeeReceiver != address(0), "Zero Address validation" );
        require(!_marketingFeeReceiver.isContract(), "Is a contract");
        marketingFeeReceiver = _marketingFeeReceiver;
    
        emit SetFeeReceivers(_marketingFeeReceiver);
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount) external onlyOwner {
        require(_amount > 0, "Can't be 0");
        swapEnabled = _enabled;
        swapThreshold = _amount;

        emit ChangedSwapBack(_enabled, _amount);
    }

    function setAutomatedMarketMakerPair(address _pair, bool _value) public onlyOwner {
            require(automatedMarketMakerPairs[_pair] != _value, "Value already set");

            automatedMarketMakerPairs[_pair] = _value;

            if(_value){
                _markerPairs.push(_pair);
            }else{
                require(_markerPairs.length > 1, "Required 1 pair");
                for (uint256 i = 0; i < _markerPairs.length; i++) {
                    if (_markerPairs[i] == _pair) {
                        _markerPairs[i] = _markerPairs[_markerPairs.length - 1];
                        _markerPairs.pop();
                        break;
                    }
                }
            }

            emit SetAutomatedMarketMakerPair(_pair, _value);
        }
}