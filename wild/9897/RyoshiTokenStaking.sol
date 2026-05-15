// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v5.1.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

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

// File: @openzeppelin/contracts/interfaces/IERC20.sol


// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/IERC20.sol)

pragma solidity ^0.8.20;


// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts (last updated v5.1.0) (utils/introspection/IERC165.sol)

pragma solidity ^0.8.20;

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

// File: @openzeppelin/contracts/interfaces/IERC165.sol


// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/IERC165.sol)

pragma solidity ^0.8.20;


// File: @openzeppelin/contracts/interfaces/IERC1363.sol


// OpenZeppelin Contracts (last updated v5.1.0) (interfaces/IERC1363.sol)

pragma solidity ^0.8.20;



/**
 * @title IERC1363
 * @dev Interface of the ERC-1363 standard as defined in the https://eips.ethereum.org/EIPS/eip-1363[ERC-1363].
 *
 * Defines an extension interface for ERC-20 tokens that supports executing code on a recipient contract
 * after `transfer` or `transferFrom`, or code on a spender contract after `approve`, in a single transaction.
 */
interface IERC1363 is IERC20, IERC165 {
    /*
     * Note: the ERC-165 identifier for this interface is 0xb0202a11.
     * 0xb0202a11 ===
     *   bytes4(keccak256('transferAndCall(address,uint256)')) ^
     *   bytes4(keccak256('transferAndCall(address,uint256,bytes)')) ^
     *   bytes4(keccak256('transferFromAndCall(address,address,uint256)')) ^
     *   bytes4(keccak256('transferFromAndCall(address,address,uint256,bytes)')) ^
     *   bytes4(keccak256('approveAndCall(address,uint256)')) ^
     *   bytes4(keccak256('approveAndCall(address,uint256,bytes)'))
     */

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`
     * and then calls {IERC1363Receiver-onTransferReceived} on `to`.
     * @param to The address which you want to transfer to.
     * @param value The amount of tokens to be transferred.
     * @return A boolean value indicating whether the operation succeeded unless throwing.
     */
    function transferAndCall(address to, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`
     * and then calls {IERC1363Receiver-onTransferReceived} on `to`.
     * @param to The address which you want to transfer to.
     * @param value The amount of tokens to be transferred.
     * @param data Additional data with no specified format, sent in call to `to`.
     * @return A boolean value indicating whether the operation succeeded unless throwing.
     */
    function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the allowance mechanism
     * and then calls {IERC1363Receiver-onTransferReceived} on `to`.
     * @param from The address which you want to send tokens from.
     * @param to The address which you want to transfer to.
     * @param value The amount of tokens to be transferred.
     * @return A boolean value indicating whether the operation succeeded unless throwing.
     */
    function transferFromAndCall(address from, address to, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the allowance mechanism
     * and then calls {IERC1363Receiver-onTransferReceived} on `to`.
     * @param from The address which you want to send tokens from.
     * @param to The address which you want to transfer to.
     * @param value The amount of tokens to be transferred.
     * @param data Additional data with no specified format, sent in call to `to`.
     * @return A boolean value indicating whether the operation succeeded unless throwing.
     */
    function transferFromAndCall(address from, address to, uint256 value, bytes calldata data) external returns (bool);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens and then calls {IERC1363Spender-onApprovalReceived} on `spender`.
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     * @return A boolean value indicating whether the operation succeeded unless throwing.
     */
    function approveAndCall(address spender, uint256 value) external returns (bool);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens and then calls {IERC1363Spender-onApprovalReceived} on `spender`.
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     * @param data Additional data with no specified format, sent in call to `spender`.
     * @return A boolean value indicating whether the operation succeeded unless throwing.
     */
    function approveAndCall(address spender, uint256 value, bytes calldata data) external returns (bool);
}

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


// OpenZeppelin Contracts (last updated v5.3.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.20;



/**
 * @title SafeERC20
 * @dev Wrappers around ERC-20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    /**
     * @dev An operation with an ERC-20 token failed.
     */
    error SafeERC20FailedOperation(address token);

    /**
     * @dev Indicates a failed `decreaseAllowance` request.
     */
    error SafeERC20FailedDecreaseAllowance(address spender, uint256 currentAllowance, uint256 requestedDecrease);

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transfer, (to, value)));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transferFrom, (from, to, value)));
    }

    /**
     * @dev Variant of {safeTransfer} that returns a bool instead of reverting if the operation is not successful.
     */
    function trySafeTransfer(IERC20 token, address to, uint256 value) internal returns (bool) {
        return _callOptionalReturnBool(token, abi.encodeCall(token.transfer, (to, value)));
    }

    /**
     * @dev Variant of {safeTransferFrom} that returns a bool instead of reverting if the operation is not successful.
     */
    function trySafeTransferFrom(IERC20 token, address from, address to, uint256 value) internal returns (bool) {
        return _callOptionalReturnBool(token, abi.encodeCall(token.transferFrom, (from, to, value)));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     *
     * IMPORTANT: If the token implements ERC-7674 (ERC-20 with temporary allowance), and if the "client"
     * smart contract uses ERC-7674 to set temporary allowances, then the "client" smart contract should avoid using
     * this function. Performing a {safeIncreaseAllowance} or {safeDecreaseAllowance} operation on a token contract
     * that has a non-zero temporary allowance (for that particular owner-spender) will result in unexpected behavior.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        forceApprove(token, spender, oldAllowance + value);
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `requestedDecrease`. If `token` returns no
     * value, non-reverting calls are assumed to be successful.
     *
     * IMPORTANT: If the token implements ERC-7674 (ERC-20 with temporary allowance), and if the "client"
     * smart contract uses ERC-7674 to set temporary allowances, then the "client" smart contract should avoid using
     * this function. Performing a {safeIncreaseAllowance} or {safeDecreaseAllowance} operation on a token contract
     * that has a non-zero temporary allowance (for that particular owner-spender) will result in unexpected behavior.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 requestedDecrease) internal {
        unchecked {
            uint256 currentAllowance = token.allowance(address(this), spender);
            if (currentAllowance < requestedDecrease) {
                revert SafeERC20FailedDecreaseAllowance(spender, currentAllowance, requestedDecrease);
            }
            forceApprove(token, spender, currentAllowance - requestedDecrease);
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     *
     * NOTE: If the token implements ERC-7674, this function will not modify any temporary allowance. This function
     * only sets the "standard" allowance. Any temporary allowance will remain active, in addition to the value being
     * set here.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeCall(token.approve, (spender, value));

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeCall(token.approve, (spender, 0)));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Performs an {ERC1363} transferAndCall, with a fallback to the simple {ERC20} transfer if the target has no
     * code. This can be used to implement an {ERC721}-like safe transfer that rely on {ERC1363} checks when
     * targeting contracts.
     *
     * Reverts if the returned value is other than `true`.
     */
    function transferAndCallRelaxed(IERC1363 token, address to, uint256 value, bytes memory data) internal {
        if (to.code.length == 0) {
            safeTransfer(token, to, value);
        } else if (!token.transferAndCall(to, value, data)) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    /**
     * @dev Performs an {ERC1363} transferFromAndCall, with a fallback to the simple {ERC20} transferFrom if the target
     * has no code. This can be used to implement an {ERC721}-like safe transfer that rely on {ERC1363} checks when
     * targeting contracts.
     *
     * Reverts if the returned value is other than `true`.
     */
    function transferFromAndCallRelaxed(
        IERC1363 token,
        address from,
        address to,
        uint256 value,
        bytes memory data
    ) internal {
        if (to.code.length == 0) {
            safeTransferFrom(token, from, to, value);
        } else if (!token.transferFromAndCall(from, to, value, data)) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    /**
     * @dev Performs an {ERC1363} approveAndCall, with a fallback to the simple {ERC20} approve if the target has no
     * code. This can be used to implement an {ERC721}-like safe transfer that rely on {ERC1363} checks when
     * targeting contracts.
     *
     * NOTE: When the recipient address (`to`) has no code (i.e. is an EOA), this function behaves as {forceApprove}.
     * Opposedly, when the recipient address (`to`) has code, this function only attempts to call {ERC1363-approveAndCall}
     * once without retrying, and relies on the returned value to be true.
     *
     * Reverts if the returned value is other than `true`.
     */
    function approveAndCallRelaxed(IERC1363 token, address to, uint256 value, bytes memory data) internal {
        if (to.code.length == 0) {
            forceApprove(token, to, value);
        } else if (!token.approveAndCall(to, value, data)) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturnBool} that reverts if call fails to meet the requirements.
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        uint256 returnSize;
        uint256 returnValue;
        assembly ("memory-safe") {
            let success := call(gas(), token, 0, add(data, 0x20), mload(data), 0, 0x20)
            // bubble errors
            if iszero(success) {
                let ptr := mload(0x40)
                returndatacopy(ptr, 0, returndatasize())
                revert(ptr, returndatasize())
            }
            returnSize := returndatasize()
            returnValue := mload(0)
        }

        if (returnSize == 0 ? address(token).code.length == 0 : returnValue != 1) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silently catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly ("memory-safe") {
            success := call(gas(), token, 0, add(data, 0x20), mload(data), 0, 0x20)
            returnSize := returndatasize()
            returnValue := mload(0)
        }
        return success && (returnSize == 0 ? address(token).code.length > 0 : returnValue == 1);
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
    function owner() public view virtual  returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (_owner != _msgSender()) {
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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts (last updated v5.1.0) (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.20;


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

// File: RyoshiTokenStaking.sol


pragma solidity 0.8.28;







contract RyoshiTokenStaking is ReentrancyGuard, Ownable, Pausable {
    using SafeERC20 for IERC20;

    // --- Tokens ---
    IERC20 public stakingToken;
    IERC20 public rewardToken;

    // --- Lock-up Periods ---
    uint256 public constant THIRTY_DAYS = 30 days;
    uint256 public constant SIXTY_DAYS = 60 days;
    uint256 public constant ONE_HUNDRED_TWENTY_DAYS = 120 days;
    uint256 public constant ONE_HUNDRED_EIGHTY_DAYS = 180 days;
    uint256 public constant THREE_HUNDRED_SIXTY_DAYS = 360 days;


    // --- APRs (in basis points, e.g., 2000 = 20.00%) ---
    uint256 public constant thirtyDaysAPR = 800;
    uint256 public constant sixtyDaysAPR = 1200;
    uint256 public constant oneHundredTwentyDaysAPR = 2000;
    uint256 public constant oneHundredEightyDaysAPR = 2800;
    uint256 public constant threeHundredSixtyDaysAPR = 4000;

    // reward tracking
    uint256 public totalDistributedRewards;

    // --- Global Staking State ---
    uint256 public totalStakedAmount;
    uint256 public totalWeightedStake;
    uint256 public totalStakeCount;

    address private penaltyRecipient;

    // --- Injection Parameters ---
    uint256 public distributionAmount;
    uint256 public DISTRIBUTION_INTERVAL = THREE_HUNDRED_SIXTY_DAYS;

    // --- Reward Accumulator ---
    uint256 public constant PRECISION = 1e18;
    uint256 public accRewardPerWeight;
    uint256 public lastRewardUpdate;

    // --- Staking Deadline ---
    uint256 public stakingStartTime;
    uint256 public constant STAKING_DEADLINE = THREE_HUNDRED_SIXTY_DAYS;
    uint256 public constant SWEEP_GRACE_PERIOD = 7 days;

    // --- Stake Data ---
    struct Stake {
        uint256 amount;
        uint256 startTime;
        uint256 lockUpPeriod;
        uint256 apr;
        uint256 weightedStake;
        uint256 rewardDebt;
    }
    mapping(address => Stake[]) public stakes;

    // --- History ---
    struct History {
        uint256 time;
        uint256 totalWeightedStake;
        uint256 accRewardPerWeight;
    }
    History[] public history;

    // --- Events ---
    event Staked(
        address indexed user,
        uint256 amount,
        uint256 lockUpPeriod,
        uint256 apr
    );
    event Unstaked(address indexed user, uint256 amount, uint256 reward);
    event RewardClaimed(address indexed user, uint256 reward);
    event EmergencyUnstaked(
        address indexed user,
        uint256 amount,
        uint256 penalty
    );

    // --- Constructor ---
    constructor(
        address _stakingToken,
        address _rewardToken,
        uint256 _distributionAmount,
        address _penaltyRecipient,
        address _ownerAddress
    ) Ownable(_ownerAddress) {
        require(_stakingToken != address(0), "Zero staking token address");
        require(_rewardToken != address(0), "Zero reward token address");
        require(_penaltyRecipient != address(0), "Zero address is not allowed");
        stakingToken = IERC20(_stakingToken);
        rewardToken = IERC20(_rewardToken);
        require(_distributionAmount > 0, "Invalid amount");
        penaltyRecipient = _penaltyRecipient;

        // Initialize history time
        history.push(History(block.timestamp, 0, 0));

        distributionAmount = _distributionAmount;

        stakingStartTime = 0;
    }

    modifier updateRewards() {
        _updateAccumulator();
        _;
    }

    function _updateAccumulator() internal {
        if (
            block.timestamp <= stakingStartTime + STAKING_DEADLINE &&
            totalWeightedStake > 0
        ) {
            uint256 timeDelta = block.timestamp - lastRewardUpdate;
            uint256 rewardDelta = (distributionAmount * timeDelta * PRECISION) /
                (totalWeightedStake * DISTRIBUTION_INTERVAL);

            accRewardPerWeight += rewardDelta;
        }
        lastRewardUpdate = block.timestamp;
    }

    function _updateHistory() internal {
        if (
            history.length > 0 &&
            history[history.length - 1].time == block.timestamp
        ) {
            history[history.length - 1].totalWeightedStake = totalWeightedStake;
            history[history.length - 1].accRewardPerWeight = accRewardPerWeight;
        } else {
            history.push(
                History(block.timestamp, totalWeightedStake, accRewardPerWeight)
            );
        }
    }

    function getAccRewardPerWeightAt(
        uint256 targetTime
    ) internal view returns (uint256) {
        if (history.length == 0) return 0;
        // Binary search to find the last entry where time <= targetTime
        uint256 left = 0;
        uint256 right = history.length - 1;
        while (left < right) {
            uint256 mid = left + (right - left + 1) / 2;
            if (history[mid].time <= targetTime) {
                left = mid;
            } else {
                right = mid - 1;
            }
        }
        History memory h = history[left];
        if (h.time > targetTime) return 0; // Before first update
        if (h.totalWeightedStake == 0) return h.accRewardPerWeight;
        uint256 timeDelta = targetTime - h.time;
        uint256 rewardDelta = (distributionAmount * timeDelta * PRECISION) /
            (h.totalWeightedStake * DISTRIBUTION_INTERVAL);
        return h.accRewardPerWeight + rewardDelta;
    }

    function stake(
        uint256 amount,
        uint256 lockUpPeriod
    ) external nonReentrant whenNotPaused updateRewards {
        require(
            stakingStartTime > 0 && block.timestamp >= stakingStartTime,
            "Staking has not started yet"
        );
        // Check if staking is still allowed (within 360 days of deployment)
        require(
            block.timestamp <= stakingStartTime + STAKING_DEADLINE,
            "Staking period has ended"
        );
        require(amount > 0, "Cannot stake zero tokens");

        uint8 decimals = IERC20Metadata(address(stakingToken)).decimals();
        uint256 minStake = 2500 * (10 ** decimals);
        require(amount >= minStake, "Stake amount is below the minimum");

        require(stakes[msg.sender].length < 15, "Maximum stakes reached");

        require(
            lockUpPeriod == THIRTY_DAYS ||
                lockUpPeriod == SIXTY_DAYS ||
                lockUpPeriod == ONE_HUNDRED_TWENTY_DAYS ||
                lockUpPeriod == ONE_HUNDRED_EIGHTY_DAYS ||
                lockUpPeriod == THREE_HUNDRED_SIXTY_DAYS,
            "Invalid lock-up period"
        );

        uint256 apr = getAPRForLockupPeriod(lockUpPeriod);

        uint256 weighted = (amount * apr) / 10000;

        stakes[msg.sender].push(
            Stake({
                amount: amount,
                startTime: block.timestamp,
                lockUpPeriod: lockUpPeriod,
                apr: apr,
                weightedStake: weighted,
                rewardDebt: accRewardPerWeight
            })
        );

        totalStakedAmount += amount;
        totalWeightedStake += weighted;
        totalStakeCount++;

        _updateHistory();

        stakingToken.safeTransferFrom(msg.sender, address(this), amount);

        emit Staked(msg.sender, amount, lockUpPeriod, apr);
    }

    function unstake(
        uint256 index
    ) external updateRewards nonReentrant whenNotPaused {
        require(index < stakes[msg.sender].length, "Invalid stake index");
        Stake memory userStake = stakes[msg.sender][index];

        uint256 stakeEndTime = userStake.startTime + userStake.lockUpPeriod;
        uint256 stakingPeriodEnd = stakingStartTime + STAKING_DEADLINE;

        bool isLockupComplete = block.timestamp >= stakeEndTime;
        bool isProgramEnded = block.timestamp >= stakingPeriodEnd;

        require(
            isLockupComplete || isProgramEnded,
            "Funds are locked: Lock-up period active and program ongoing"
        );

        // Determine the reward end time (earlier of stakeEndTime or stakingPeriodEnd)
        uint256 rewardEndTime = stakeEndTime < stakingPeriodEnd
            ? stakeEndTime
            : stakingPeriodEnd;

        // Since unstaking is only allowed after stakeEndTime, and rewardEndTime <= stakeEndTime,
        // we can directly use the accumulator at rewardEndTime
        uint256 accAtEnd = getAccRewardPerWeightAt(rewardEndTime);

        uint256 reward = (userStake.weightedStake *
            (accAtEnd - userStake.rewardDebt)) / PRECISION;

        require(
            reward <= rewardToken.balanceOf(address(this)),
            "Insufficient rewards pool"
        );

        totalStakedAmount -= userStake.amount;
        if (totalWeightedStake > 0) {
            totalWeightedStake -= userStake.weightedStake;
        }

        if (index != stakes[msg.sender].length - 1) {
            stakes[msg.sender][index] = stakes[msg.sender][
                stakes[msg.sender].length - 1
            ];
        }
        stakes[msg.sender].pop();

        totalStakeCount--;

        _updateHistory();
        _updateRewardDistributeTracker(reward);

        // Transfer staked tokens and rewards to user
        stakingToken.safeTransfer(msg.sender, userStake.amount);
        rewardToken.safeTransfer(msg.sender, reward);

        emit Unstaked(msg.sender, userStake.amount, reward);
    }

    function claimReward(
        uint256 index
    ) external nonReentrant updateRewards whenNotPaused {
        require(index < stakes[msg.sender].length, "Invalid stake index");
        Stake storage userStake = stakes[msg.sender][index];

        uint256 stakeEndTime = userStake.startTime + userStake.lockUpPeriod;
        uint256 stakingPeriodEnd = stakingStartTime + STAKING_DEADLINE;

        // Determine the reward end time (earlier of stakeEndTime or stakingPeriodEnd)
        uint256 rewardEndTime = stakeEndTime < stakingPeriodEnd
            ? stakeEndTime
            : stakingPeriodEnd;

        uint256 effectiveAcc;

        if (block.timestamp >= rewardEndTime) {
            effectiveAcc = getAccRewardPerWeightAt(rewardEndTime);
        } else {
            effectiveAcc = accRewardPerWeight;
        }
        // Calculate pending reward
        uint256 reward = (userStake.weightedStake *
            (effectiveAcc - userStake.rewardDebt)) / PRECISION;
        require(reward > 0, "No rewards to claim");
        require(
            reward <= rewardToken.balanceOf(address(this)),
            "Insufficient rewards pool"
        );

        _updateRewardDistributeTracker(reward);

        // Update rewardDebt to prevent double-claiming
        userStake.rewardDebt = effectiveAcc;

        // Transfer reward to user
        rewardToken.safeTransfer(msg.sender, reward);

        emit RewardClaimed(msg.sender, reward);
    }

    // For frontend
    function calculateReward(
        Stake memory userStake
    ) public view returns (uint256) {
        uint256 stakeEndTime = userStake.startTime + userStake.lockUpPeriod;
        uint256 stakingPeriodEnd = stakingStartTime + STAKING_DEADLINE;

        // Determine the reward end time (earlier of stakeEndTime or stakingPeriodEnd)
        uint256 rewardEndTime = stakeEndTime < stakingPeriodEnd
            ? stakeEndTime
            : stakingPeriodEnd;

        uint256 effectiveAcc;

        if (block.timestamp >= rewardEndTime) {
            // If current time is past the reward end time, use the accumulator at rewardEndTime
            effectiveAcc = getAccRewardPerWeightAt(rewardEndTime);
        } else {
            // Otherwise, use the current accumulator and add any pending rewards up to the current time
            effectiveAcc = accRewardPerWeight;
            if (
                block.timestamp > lastRewardUpdate &&
                totalWeightedStake > 0 &&
                block.timestamp <= stakingPeriodEnd
            ) {
                uint256 timeDelta = block.timestamp - lastRewardUpdate;
                uint256 pending = (distributionAmount * timeDelta * PRECISION) /
                    (totalWeightedStake * DISTRIBUTION_INTERVAL);
                effectiveAcc += pending;
            }
        }

        return
            (userStake.weightedStake * (effectiveAcc - userStake.rewardDebt)) /
            PRECISION;
    }

    function emergencyUnstake(
        uint256 stakeIndex
    ) external nonReentrant updateRewards {
        require(stakeIndex < stakes[msg.sender].length, "Invalid stake index");
        Stake memory userStake = stakes[msg.sender][stakeIndex];

        uint256 penaltyPercent = 1500; // 15%

        uint256 totalPenalty = (userStake.amount * penaltyPercent) / 10000;

        stakingToken.safeTransfer(msg.sender, userStake.amount - totalPenalty);
        stakingToken.safeTransfer(penaltyRecipient, totalPenalty);

        // Update global staking totals
        totalStakedAmount -= userStake.amount;
        if (totalWeightedStake > 0) {
            totalWeightedStake -= userStake.weightedStake;
        }

        // Remove the stake
        uint256 lastIndex = stakes[msg.sender].length - 1;
        if (stakeIndex != lastIndex) {
            stakes[msg.sender][stakeIndex] = stakes[msg.sender][lastIndex];
        }
        stakes[msg.sender].pop();
        totalStakeCount--;

        _updateHistory();

        emit EmergencyUnstaked(
            msg.sender,
            userStake.amount - totalPenalty,
            totalPenalty
        );
    }

    function startStaking() external {
        require(
            msg.sender == owner() || msg.sender == penaltyRecipient,
            "Unknown caller"
        );
        require(stakingStartTime == 0, "Staking already started");

        uint256 rewardBalance = rewardToken.balanceOf(address(this));
        require(
            rewardBalance >= distributionAmount,
            "Insufficient reward tokens deposited"
        );

        stakingStartTime = block.timestamp;
        lastRewardUpdate = block.timestamp;
    }

    function _updateRewardDistributeTracker(uint256 rewardAmount) internal {
        totalDistributedRewards += rewardAmount;
    }

    function getStakeCount(address user) external view returns (uint256) {
        return stakes[user].length;
    }

    function getAPRForLockupPeriod(
        uint256 lockupPeriod
    ) public pure returns (uint256) {
        if (lockupPeriod == THIRTY_DAYS) return thirtyDaysAPR;
        if (lockupPeriod == SIXTY_DAYS) return sixtyDaysAPR;
        if (lockupPeriod == ONE_HUNDRED_TWENTY_DAYS)
            return oneHundredTwentyDaysAPR;
        if (lockupPeriod == ONE_HUNDRED_EIGHTY_DAYS)
            return oneHundredEightyDaysAPR;
        if (lockupPeriod == THREE_HUNDRED_SIXTY_DAYS)
            return threeHundredSixtyDaysAPR;
        revert("Invalid lock-up period");
    }

    function recoverERC20(address token, uint256 amount) external {
        require(
            msg.sender == owner() || msg.sender == penaltyRecipient,
            "Unknown caller"
        );
        require(
            token != address(stakingToken) && token != address(rewardToken),
            "Cannot recover staking/reward tokens"
        );
        IERC20(token).safeTransfer(msg.sender, amount);
    }

    function getRewardPoolBalance() public view returns (uint256) {
        return rewardToken.balanceOf(address(this));
    }

    function sweepRemainingRewardTokens() external {
        require(
            msg.sender == owner() || msg.sender == penaltyRecipient,
            "Unknown caller"
        );

        require(
            block.timestamp >
                stakingStartTime + STAKING_DEADLINE + SWEEP_GRACE_PERIOD,
            "Sweep grace period not yet ended"
        );

        uint256 remainingReward = rewardToken.balanceOf(address(this));
        require(remainingReward > 0, "Nothing left to sweep");

        // sweep any leftover rewards
        rewardToken.safeTransfer(msg.sender, remainingReward);
        emit RewardClaimed(msg.sender, remainingReward);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}