// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18 ^0.8.0 ^0.8.1 ^0.8.20 ^0.8.23 ^0.8.24;

// lib/superform-core/lib/ERC1155A/lib/openzeppelin-contracts/contracts/interfaces/draft-IERC6093.sol

// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/draft-IERC6093.sol)

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

// lib/superform-core/lib/ERC1155A/lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol

// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

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

// lib/superform-core/lib/ERC1155A/lib/openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Permit.sol

// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Permit.sol)

/**
 * @dev Interface of the ERC-20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[ERC-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC-20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * ==== Security Considerations
 *
 * There are two important considerations concerning the use of `permit`. The first is that a valid permit signature
 * expresses an allowance, and it should not be assumed to convey additional meaning. In particular, it should not be
 * considered as an intention to spend the allowance in any specific way. The second is that because permits have
 * built-in replay protection and can be submitted by anyone, they can be frontrun. A protocol that uses permits should
 * take this into consideration and allow a `permit` call to fail. Combining these two aspects, a pattern that may be
 * generally recommended is:
 *
 * ```solidity
 * function doThingWithPermit(..., uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
 *     try token.permit(msg.sender, address(this), value, deadline, v, r, s) {} catch {}
 *     doThing(..., value);
 * }
 *
 * function doThing(..., uint256 value) public {
 *     token.safeTransferFrom(msg.sender, address(this), value);
 *     ...
 * }
 * ```
 *
 * Observe that: 1) `msg.sender` is used as the owner, leaving no ambiguity as to the signer intent, and 2) the use of
 * `try/catch` allows the permit to fail and makes the code tolerant to frontrunning. (See also
 * {SafeERC20-safeTransferFrom}).
 *
 * Additionally, note that smart contract wallets (such as Argent or Safe) are not able to produce permit signatures, so
 * contracts should have entry points that don't rely on permit.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     *
     * CAUTION: See Security Considerations above.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// lib/superform-core/lib/ERC1155A/lib/openzeppelin-contracts/contracts/utils/Address.sol

// OpenZeppelin Contracts (last updated v5.0.0) (utils/Address.sol)

/**
 * @dev Collection of functions related to the address type
 */
library Address_0 {
    /**
     * @dev The ETH balance of the account is not enough to perform the operation.
     */
    error AddressInsufficientBalance(address account);

    /**
     * @dev There's no code at `target` (it is not a contract).
     */
    error AddressEmptyCode(address target);

    /**
     * @dev A call to an address target failed. The target may have reverted.
     */
    error FailedInnerCall();

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.20/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        if (address(this).balance < amount) {
            revert AddressInsufficientBalance(address(this));
        }

        (bool success, ) = recipient.call{value: amount}("");
        if (!success) {
            revert FailedInnerCall();
        }
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason or custom error, it is bubbled
     * up by this function (like regular Solidity function calls). However, if
     * the call reverted with no returned reason, this function reverts with a
     * {FailedInnerCall} error.
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        if (address(this).balance < value) {
            revert AddressInsufficientBalance(address(this));
        }
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and reverts if the target
     * was not a contract or bubbling up the revert reason (falling back to {FailedInnerCall}) in case of an
     * unsuccessful call.
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata
    ) internal view returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            // only check if target is a contract if the call was successful and the return data is empty
            // otherwise we already know that it was a contract
            if (returndata.length == 0 && target.code.length == 0) {
                revert AddressEmptyCode(target);
            }
            return returndata;
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and reverts if it wasn't, either by bubbling the
     * revert reason or with a default {FailedInnerCall} error.
     */
    function verifyCallResult(bool success, bytes memory returndata) internal pure returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            return returndata;
        }
    }

    /**
     * @dev Reverts with returndata if present. Otherwise reverts with {FailedInnerCall}.
     */
    function _revert(bytes memory returndata) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert FailedInnerCall();
        }
    }
}

// lib/superform-core/lib/ERC1155A/lib/openzeppelin-contracts/contracts/utils/Context.sol

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

// lib/superform-core/lib/ERC1155A/lib/openzeppelin-contracts/contracts/utils/introspection/IERC165.sol

// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/IERC165.sol)

/**
 * @dev Interface of the ERC-165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[ERC].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165_0 {
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

// lib/superform-core/src/interfaces/IBaseSuperformRouterPlus.sol

interface IBaseSuperformRouterPlus {
    //////////////////////////////////////////////////////////////
    //                       ERRORS                             //
    //////////////////////////////////////////////////////////////

    /// @notice thrown if the provided selector is invalid
    error INVALID_REBALANCE_SELECTOR();

    //////////////////////////////////////////////////////////////
    //                       STRUCTS                             //
    //////////////////////////////////////////////////////////////

    struct XChainRebalanceData {
        bytes4 rebalanceSelector;
        address interimAsset;
        uint256 slippage;
        uint256 expectedAmountInterimAsset;
        uint8[][] rebalanceToAmbIds;
        uint64[] rebalanceToDstChainIds;
        bytes rebalanceToSfData;
    }

    //////////////////////////////////////////////////////////////
    //                       ENUMS                             //
    //////////////////////////////////////////////////////////////

    enum Actions {
        DEPOSIT,
        REBALANCE_FROM_SINGLE,
        REBALANCE_FROM_MULTI,
        REBALANCE_X_CHAIN_FROM_SINGLE,
        REBALANCE_X_CHAIN_FROM_MULTI
    }
}

// lib/superform-core/src/interfaces/ISuperRegistry.sol

/// @title ISuperRegistry
/// @dev Interface for SuperRegistry
/// @author Zeropoint Labs
interface ISuperRegistry {
    //////////////////////////////////////////////////////////////
    //                          EVENTS                          //
    //////////////////////////////////////////////////////////////

    /// @dev emitted when permit2 is set.
    event SetPermit2(address indexed permit2);

    /// @dev is emitted when an address is set.
    event AddressUpdated(
        bytes32 indexed protocolAddressId, uint64 indexed chainId, address indexed oldAddress, address newAddress
    );

    /// @dev is emitted when a new token bridge is configured.
    event SetBridgeAddress(uint256 indexed bridgeId, address indexed bridgeAddress);

    /// @dev is emitted when a new bridge validator is configured.
    event SetBridgeValidator(uint256 indexed bridgeId, address indexed bridgeValidator);

    /// @dev is emitted when a new amb is configured.
    event SetAmbAddress(uint8 indexed ambId_, address indexed ambAddress_, bool indexed isBroadcastAMB_);

    /// @dev is emitted when a new state registry is configured.
    event SetStateRegistryAddress(uint8 indexed registryId_, address indexed registryAddress_);

    /// @dev is emitted when a new delay is configured.
    event SetDelay(uint256 indexed oldDelay_, uint256 indexed newDelay_);

    /// @dev is emitted when a new vault limit is configured
    event SetVaultLimitPerDestination(uint64 indexed chainId_, uint256 indexed vaultLimit_);

    //////////////////////////////////////////////////////////////
    //              EXTERNAL VIEW FUNCTIONS                     //
    //////////////////////////////////////////////////////////////

    /// @dev gets the deposit rescue delay
    function delay() external view returns (uint256);

    /// @dev returns the permit2 address
    function PERMIT2() external view returns (address);

    /// @dev returns the id of the superform router module
    function SUPERFORM_ROUTER() external view returns (bytes32);

    /// @dev returns the id of the superform factory module
    function SUPERFORM_FACTORY() external view returns (bytes32);

    /// @dev returns the id of the superform paymaster contract
    function PAYMASTER() external view returns (bytes32);

    /// @dev returns the id of the superform payload helper contract
    function PAYMENT_HELPER() external view returns (bytes32);

    /// @dev returns the id of the core state registry module
    function CORE_STATE_REGISTRY() external view returns (bytes32);

    /// @dev returns the id of the timelock form state registry module
    function TIMELOCK_STATE_REGISTRY() external view returns (bytes32);

    /// @dev returns the id of the broadcast state registry module
    function BROADCAST_REGISTRY() external view returns (bytes32);

    /// @dev returns the id of the super positions module
    function SUPER_POSITIONS() external view returns (bytes32);

    /// @dev returns the id of the super rbac module
    function SUPER_RBAC() external view returns (bytes32);

    /// @dev returns the id of the payload helper module
    function PAYLOAD_HELPER() external view returns (bytes32);

    /// @dev returns the id of the dst swapper keeper
    function DST_SWAPPER() external view returns (bytes32);

    /// @dev returns the id of the emergency queue
    function EMERGENCY_QUEUE() external view returns (bytes32);

    /// @dev returns the id of the superform receiver
    function SUPERFORM_RECEIVER() external view returns (bytes32);

    /// @dev returns the id of the payment admin keeper
    function PAYMENT_ADMIN() external view returns (bytes32);

    /// @dev returns the id of the core state registry processor keeper
    function CORE_REGISTRY_PROCESSOR() external view returns (bytes32);

    /// @dev returns the id of the broadcast registry processor keeper
    function BROADCAST_REGISTRY_PROCESSOR() external view returns (bytes32);

    /// @dev returns the id of the timelock form state registry processor keeper
    function TIMELOCK_REGISTRY_PROCESSOR() external view returns (bytes32);

    /// @dev returns the id of the core state registry updater keeper
    function CORE_REGISTRY_UPDATER() external view returns (bytes32);

    /// @dev returns the id of the core state registry updater keeper
    function CORE_REGISTRY_RESCUER() external view returns (bytes32);

    /// @dev returns the id of the core state registry updater keeper
    function CORE_REGISTRY_DISPUTER() external view returns (bytes32);

    /// @dev returns the id of the core state registry updater keeper
    function DST_SWAPPER_PROCESSOR() external view returns (bytes32);

    /// @dev gets the address of a contract on current chain
    /// @param id_ is the id of the contract
    function getAddress(bytes32 id_) external view returns (address);

    /// @dev gets the address of a contract on a target chain
    /// @param id_ is the id of the contract
    /// @param chainId_ is the chain id of that chain
    function getAddressByChainId(bytes32 id_, uint64 chainId_) external view returns (address);

    /// @dev gets the address of a bridge
    /// @param bridgeId_ is the id of a bridge
    /// @return bridgeAddress_ is the address of the form
    function getBridgeAddress(uint8 bridgeId_) external view returns (address bridgeAddress_);

    /// @dev gets the address of a bridge validator
    /// @param bridgeId_ is the id of a bridge
    /// @return bridgeValidator_ is the address of the form
    function getBridgeValidator(uint8 bridgeId_) external view returns (address bridgeValidator_);

    /// @dev gets the address of a amb
    /// @param ambId_ is the id of a bridge
    /// @return ambAddress_ is the address of the form
    function getAmbAddress(uint8 ambId_) external view returns (address ambAddress_);

    /// @dev gets the id of the amb
    /// @param ambAddress_ is the address of an amb
    /// @return ambId_ is the identifier of an amb
    function getAmbId(address ambAddress_) external view returns (uint8 ambId_);

    /// @dev gets the address of the registry
    /// @param registryId_ is the id of the state registry
    /// @return registryAddress_ is the address of the state registry
    function getStateRegistry(uint8 registryId_) external view returns (address registryAddress_);

    /// @dev gets the id of the registry
    /// @notice reverts if the id is not found
    /// @param registryAddress_ is the address of the state registry
    /// @return registryId_ is the id of the state registry
    function getStateRegistryId(address registryAddress_) external view returns (uint8 registryId_);

    /// @dev gets the safe vault limit
    /// @param chainId_ is the id of the remote chain
    /// @return vaultLimitPerDestination_ is the safe number of vaults to deposit
    /// without hitting out of gas error
    function getVaultLimitPerDestination(uint64 chainId_) external view returns (uint256 vaultLimitPerDestination_);

    /// @dev helps validate if an address is a valid state registry
    /// @param registryAddress_ is the address of the state registry
    /// @return valid_ a flag indicating if its valid.
    function isValidStateRegistry(address registryAddress_) external view returns (bool valid_);

    /// @dev helps validate if an address is a valid amb implementation
    /// @param ambAddress_ is the address of the amb implementation
    /// @return valid_ a flag indicating if its valid.
    function isValidAmbImpl(address ambAddress_) external view returns (bool valid_);

    /// @dev helps validate if an address is a valid broadcast amb implementation
    /// @param ambAddress_ is the address of the broadcast amb implementation
    /// @return valid_ a flag indicating if its valid.
    function isValidBroadcastAmbImpl(address ambAddress_) external view returns (bool valid_);

    //////////////////////////////////////////////////////////////
    //              EXTERNAL WRITE FUNCTIONS                    //
    //////////////////////////////////////////////////////////////

    /// @dev sets the deposit rescue delay
    /// @param delay_ the delay in seconds before the deposit rescue can be finalized
    function setDelay(uint256 delay_) external;

    /// @dev sets the permit2 address
    /// @param permit2_ the address of the permit2 contract
    function setPermit2(address permit2_) external;

    /// @dev sets the safe vault limit
    /// @param chainId_ is the remote chain identifier
    /// @param vaultLimit_ is the max limit of vaults per transaction
    function setVaultLimitPerDestination(uint64 chainId_, uint256 vaultLimit_) external;

    /// @dev sets new addresses on specific chains.
    /// @param ids_ are the identifiers of the address on that chain
    /// @param newAddresses_  are the new addresses on that chain
    /// @param chainIds_ are the chain ids of that chain
    function batchSetAddress(
        bytes32[] calldata ids_,
        address[] calldata newAddresses_,
        uint64[] calldata chainIds_
    )
        external;

    /// @dev sets a new address on a specific chain.
    /// @param id_ the identifier of the address on that chain
    /// @param newAddress_ the new address on that chain
    /// @param chainId_ the chain id of that chain
    function setAddress(bytes32 id_, address newAddress_, uint64 chainId_) external;

    /// @dev allows admin to set the bridge address for an bridge id.
    /// @notice this function operates in an APPEND-ONLY fashion.
    /// @param bridgeId_         represents the bridge unique identifier.
    /// @param bridgeAddress_    represents the bridge address.
    /// @param bridgeValidator_  represents the bridge validator address.
    function setBridgeAddresses(
        uint8[] memory bridgeId_,
        address[] memory bridgeAddress_,
        address[] memory bridgeValidator_
    )
        external;

    /// @dev allows admin to set the amb address for an amb id.
    /// @notice this function operates in an APPEND-ONLY fashion.
    /// @param ambId_         represents the bridge unique identifier.
    /// @param ambAddress_    represents the bridge address.
    /// @param isBroadcastAMB_ represents whether the amb implementation supports broadcasting
    function setAmbAddress(
        uint8[] memory ambId_,
        address[] memory ambAddress_,
        bool[] memory isBroadcastAMB_
    )
        external;

    /// @dev allows admin to set the state registry address for an state registry id.
    /// @notice this function operates in an APPEND-ONLY fashion.
    /// @param registryId_    represents the state registry's unique identifier.
    /// @param registryAddress_    represents the state registry's address.
    function setStateRegistryAddress(uint8[] memory registryId_, address[] memory registryAddress_) external;
}

// lib/superform-core/src/interfaces/ISuperformFactory.sol

/// @title ISuperformFactory
/// @dev Interface for SuperformFactory
/// @author ZeroPoint Labs
interface ISuperformFactory {
    
    //////////////////////////////////////////////////////////////
    //                         CONSTANTS                        //
    //////////////////////////////////////////////////////////////

    enum PauseStatus {
        NON_PAUSED,
        PAUSED
    }

    //////////////////////////////////////////////////////////////
    //                          EVENTS                          //
    //////////////////////////////////////////////////////////////

    /// @dev emitted when a new formImplementation is entered into the factory
    /// @param formImplementation is the address of the new form implementation
    /// @param formImplementationId is the id of the formImplementation
    /// @param formStateRegistryId is any additional state registry id of the formImplementation
    event FormImplementationAdded(
        address indexed formImplementation, uint256 indexed formImplementationId, uint8 indexed formStateRegistryId
    );

    /// @dev emitted when a new Superform is created
    /// @param formImplementationId is the id of the form implementation
    /// @param vault is the address of the vault
    /// @param superformId is the id of the superform
    /// @param superform is the address of the superform
    event SuperformCreated(
        uint256 indexed formImplementationId, address indexed vault, uint256 indexed superformId, address superform
    );

    /// @dev emitted when a new SuperRegistry is set
    /// @param superRegistry is the address of the super registry
    event SuperRegistrySet(address indexed superRegistry);

    /// @dev emitted when a form implementation is paused
    /// @param formImplementationId is the id of the form implementation
    /// @param paused is the new paused status
    event FormImplementationPaused(uint256 indexed formImplementationId, PauseStatus indexed paused);

    //////////////////////////////////////////////////////////////
    //              EXTERNAL VIEW FUNCTIONS                     //
    //////////////////////////////////////////////////////////////

    /// @dev returns the number of forms
    /// @return forms_ is the number of forms
    function getFormCount() external view returns (uint256 forms_);

    /// @dev returns the number of superforms
    /// @return superforms_ is the number of superforms
    function getSuperformCount() external view returns (uint256 superforms_);

    /// @dev returns the address of a form implementation
    /// @param formImplementationId_ is the id of the form implementation
    /// @return formImplementation_ is the address of the form implementation
    function getFormImplementation(uint32 formImplementationId_) external view returns (address formImplementation_);

    /// @dev returns the form state registry id of a form implementation
    /// @param formImplementationId_ is the id of the form implementation
    /// @return stateRegistryId_ is the additional state registry id of the form
    function getFormStateRegistryId(uint32 formImplementationId_) external view returns (uint8 stateRegistryId_);

    /// @dev returns the paused status of form implementation
    /// @param formImplementationId_ is the id of the form implementation
    /// @return paused_ is the current paused status of the form formImplementationId_
    function isFormImplementationPaused(uint32 formImplementationId_) external view returns (bool paused_);

    /// @dev returns the address of a superform
    /// @param superformId_ is the id of the superform
    /// @return superform_ is the address of the superform
    /// @return formImplementationId_ is the id of the form implementation
    /// @return chainId_ is the chain id
    function getSuperform(uint256 superformId_)
        external
        pure
        returns (address superform_, uint32 formImplementationId_, uint64 chainId_);

    /// @dev returns if an address has been added to a Form
    /// @param superformId_ is the id of the superform
    /// @return isSuperform_ bool if it exists
    function isSuperform(uint256 superformId_) external view returns (bool isSuperform_);

    /// @dev Reverse query of getSuperform, returns all superforms for a given vault
    /// @param vault_ is the address of a vault
    /// @return superformIds_ is the id of the superform
    /// @return superforms_ is the address of the superform
    function getAllSuperformsFromVault(address vault_)
        external
        view
        returns (uint256[] memory superformIds_, address[] memory superforms_);

    //////////////////////////////////////////////////////////////
    //              EXTERNAL WRITE FUNCTIONS                    //
    //////////////////////////////////////////////////////////////

    /// @dev allows an admin to add a Form implementation to the factory
    /// @param formImplementation_ is the address of a form implementation
    /// @param formImplementationId_ is the id of the form implementation (generated off-chain and equal in all chains)
    /// @param formStateRegistryId_ is the id of any additional state registry for that form
    /// @dev formStateRegistryId_ 1 is default for all form implementations, pass in formStateRegistryId_ only if an
    /// additional state registry is required
    function addFormImplementation(
        address formImplementation_,
        uint32 formImplementationId_,
        uint8 formStateRegistryId_
    )
        external;

    /// @dev To add new vaults to Form implementations, fusing them together into Superforms
    /// @param formImplementationId_ is the form implementation we want to attach the vault to
    /// @param vault_ is the address of the vault
    /// @return superformId_ is the id of the created superform
    /// @return superform_ is the address of the created superform
    function createSuperform(
        uint32 formImplementationId_,
        address vault_
    )
        external
        returns (uint256 superformId_, address superform_);

    /// @dev to synchronize superforms added to different chains using broadcast registry
    /// @param data_ is the cross-chain superform id
    function stateSyncBroadcast(bytes memory data_) external payable;

    /// @dev allows an admin to change the status of a form
    /// @param formImplementationId_ is the id of the form implementation
    /// @param status_ is the new status
    /// @param extraData_ is optional & passed when broadcasting of status is needed
    function changeFormImplementationPauseStatus(
        uint32 formImplementationId_,
        PauseStatus status_,
        bytes memory extraData_
    )
        external
        payable;
}

// lib/superform-core/src/libraries/Error.sol

library Error {
    //////////////////////////////////////////////////////////////
    //                  CONFIGURATION ERRORS                    //
    //////////////////////////////////////////////////////////////
    ///@notice errors thrown in protocol setup

    /// @dev thrown if chain id exceeds max(uint64)
    error BLOCK_CHAIN_ID_OUT_OF_BOUNDS();

    /// @dev thrown if not possible to revoke a role in broadcasting
    error CANNOT_REVOKE_NON_BROADCASTABLE_ROLES();

    /// @dev thrown if not possible to revoke last admin
    error CANNOT_REVOKE_LAST_ADMIN();

    /// @dev thrown if trying to set again pseudo immutables in super registry
    error DISABLED();

    /// @dev thrown if rescue delay is not yet set for a chain
    error DELAY_NOT_SET();

    /// @dev thrown if get native token price estimate in paymentHelper is 0
    error INVALID_NATIVE_TOKEN_PRICE();

    /// @dev thrown if wormhole refund chain id is not set
    error REFUND_CHAIN_ID_NOT_SET();

    /// @dev thrown if wormhole relayer is not set
    error RELAYER_NOT_SET();

    /// @dev thrown if a role to be revoked is not assigned
    error ROLE_NOT_ASSIGNED();

    //////////////////////////////////////////////////////////////
    //                  AUTHORIZATION ERRORS                    //
    //////////////////////////////////////////////////////////////
    ///@notice errors thrown if functions cannot be called

    /// COMMON AUTHORIZATION ERRORS
    /// ---------------------------------------------------------

    /// @dev thrown if caller is not address(this), internal call
    error INVALID_INTERNAL_CALL();

    /// @dev thrown if msg.sender is not a valid amb implementation
    error NOT_AMB_IMPLEMENTATION();

    /// @dev thrown if msg.sender is not an allowed broadcaster
    error NOT_ALLOWED_BROADCASTER();

    /// @dev thrown if msg.sender is not broadcast amb implementation
    error NOT_BROADCAST_AMB_IMPLEMENTATION();

    /// @dev thrown if msg.sender is not broadcast state registry
    error NOT_BROADCAST_REGISTRY();

    /// @dev thrown if msg.sender is not core state registry
    error NOT_CORE_STATE_REGISTRY();

    /// @dev thrown if msg.sender is not emergency admin
    error NOT_EMERGENCY_ADMIN();

    /// @dev thrown if msg.sender is not emergency queue
    error NOT_EMERGENCY_QUEUE();

    /// @dev thrown if msg.sender is not minter
    error NOT_MINTER();

    /// @dev thrown if msg.sender is not minter state registry
    error NOT_MINTER_STATE_REGISTRY_ROLE();

    /// @dev thrown if msg.sender is not paymaster
    error NOT_PAYMASTER();

    /// @dev thrown if msg.sender is not payment admin
    error NOT_PAYMENT_ADMIN();

    /// @dev thrown if msg.sender is not protocol admin
    error NOT_PROTOCOL_ADMIN();

    /// @dev thrown if msg.sender is not state registry
    error NOT_STATE_REGISTRY();

    /// @dev thrown if msg.sender is not super registry
    error NOT_SUPER_REGISTRY();

    /// @dev thrown if msg.sender is not superform router
    error NOT_SUPERFORM_ROUTER();

    /// @dev thrown if msg.sender is not a superform
    error NOT_SUPERFORM();

    /// @dev thrown if msg.sender is not superform factory
    error NOT_SUPERFORM_FACTORY();

    /// @dev thrown if msg.sender is not timelock form
    error NOT_TIMELOCK_SUPERFORM();

    /// @dev thrown if msg.sender is not timelock state registry
    error NOT_TIMELOCK_STATE_REGISTRY();

    /// @dev thrown if msg.sender is not user or disputer
    error NOT_VALID_DISPUTER();

    /// @dev thrown if the msg.sender is not privileged caller
    error NOT_PRIVILEGED_CALLER(bytes32 role);

    /// STATE REGISTRY AUTHORIZATION ERRORS
    /// ---------------------------------------------------------

    /// @dev layerzero adapter specific error, thrown if caller not layerzero endpoint
    error CALLER_NOT_ENDPOINT();

    /// @dev hyperlane adapter specific error, thrown if caller not hyperlane mailbox
    error CALLER_NOT_MAILBOX();

    /// @dev wormhole relayer specific error, thrown if caller not wormhole relayer
    error CALLER_NOT_RELAYER();

    /// @dev thrown if src chain sender is not valid
    error INVALID_SRC_SENDER();

    //////////////////////////////////////////////////////////////
    //                  INPUT VALIDATION ERRORS                 //
    //////////////////////////////////////////////////////////////
    ///@notice errors thrown if input variables are not valid

    /// COMMON INPUT VALIDATION ERRORS
    /// ---------------------------------------------------------

    /// @dev thrown if there is an array length mismatch
    error ARRAY_LENGTH_MISMATCH();

    /// @dev thrown if payload id does not exist
    error INVALID_PAYLOAD_ID();

    /// @dev error thrown when msg value should be zero in certain payable functions
    error MSG_VALUE_NOT_ZERO();

    /// @dev thrown if amb ids length is 0
    error ZERO_AMB_ID_LENGTH();

    /// @dev thrown if address input is address 0
    error ZERO_ADDRESS();

    /// @dev thrown if amount input is 0
    error ZERO_AMOUNT();

    /// @dev thrown if final token is address 0
    error ZERO_FINAL_TOKEN();

    /// @dev thrown if value input is 0
    error ZERO_INPUT_VALUE();

    /// SUPERFORM ROUTER INPUT VALIDATION ERRORS
    /// ---------------------------------------------------------

    /// @dev thrown if the vaults data is invalid
    error INVALID_SUPERFORMS_DATA();

    /// @dev thrown if receiver address is not set
    error RECEIVER_ADDRESS_NOT_SET();

    /// SUPERFORM FACTORY INPUT VALIDATION ERRORS
    /// ---------------------------------------------------------

    /// @dev thrown if a form is not ERC165 compatible
    error ERC165_UNSUPPORTED();

    /// @dev thrown if a form is not form interface compatible
    error FORM_INTERFACE_UNSUPPORTED();

    /// @dev error thrown if form implementation address already exists
    error FORM_IMPLEMENTATION_ALREADY_EXISTS();

    /// @dev error thrown if form implementation id already exists
    error FORM_IMPLEMENTATION_ID_ALREADY_EXISTS();

    /// @dev thrown if a form does not exist
    error FORM_DOES_NOT_EXIST();

    /// @dev thrown if form id is larger than max uint16
    error INVALID_FORM_ID();

    /// @dev thrown if superform not on factory
    error SUPERFORM_ID_NONEXISTENT();

    /// @dev thrown if same vault and form implementation is used to create new superform
    error VAULT_FORM_IMPLEMENTATION_COMBINATION_EXISTS();

    /// FORM INPUT VALIDATION ERRORS
    /// ---------------------------------------------------------

    /// @dev thrown if in case of no txData, if liqData.token != vault.asset()
    /// in case of txData, if token output of swap != vault.asset()
    error DIFFERENT_TOKENS();

    /// @dev thrown if the amount in direct withdraw is not correct
    error DIRECT_WITHDRAW_INVALID_LIQ_REQUEST();

    /// @dev thrown if the amount in xchain withdraw is not correct
    error XCHAIN_WITHDRAW_INVALID_LIQ_REQUEST();

    /// LIQUIDITY BRIDGE INPUT VALIDATION ERRORS
    /// ---------------------------------------------------------

    /// @dev thrown if route id is blacklisted in socket
    error BLACKLISTED_ROUTE_ID();

    /// @dev thrown if route id is not blacklisted in socket
    error NOT_BLACKLISTED_ROUTE_ID();

    /// @dev error thrown when txData selector of lifi bridge is a blacklisted selector
    error BLACKLISTED_SELECTOR();

    /// @dev error thrown when txData selector of lifi bridge is not a blacklisted selector
    error NOT_BLACKLISTED_SELECTOR();

    /// @dev thrown if a certain action of the user is not allowed given the txData provided
    error INVALID_ACTION();

    /// @dev thrown if in deposits, the liqDstChainId doesn't match the stateReq dstChainId
    error INVALID_DEPOSIT_LIQ_DST_CHAIN_ID();

    /// @dev thrown if index is invalid
    error INVALID_INDEX();

    /// @dev thrown if the chain id in the txdata is invalid
    error INVALID_TXDATA_CHAIN_ID();

    /// @dev thrown if the validation of bridge txData fails due to a destination call present
    error INVALID_TXDATA_NO_DESTINATIONCALL_ALLOWED();

    /// @dev thrown if the validation of bridge txData fails due to wrong receiver
    error INVALID_TXDATA_RECEIVER();

    /// @dev thrown if the validation of bridge txData fails due to wrong token
    error INVALID_TXDATA_TOKEN();

    /// @dev thrown if txData is not present (in case of xChain actions)
    error NO_TXDATA_PRESENT();

    /// STATE REGISTRY INPUT VALIDATION ERRORS
    /// ---------------------------------------------------------

    /// @dev thrown if payload is being updated with final amounts length different than amounts length
    error DIFFERENT_PAYLOAD_UPDATE_AMOUNTS_LENGTH();

    /// @dev thrown if payload is being updated with tx data length different than liq data length
    error DIFFERENT_PAYLOAD_UPDATE_TX_DATA_LENGTH();

    /// @dev thrown if keeper update final token is different than the vault underlying
    error INVALID_UPDATE_FINAL_TOKEN();

    /// @dev thrown if broadcast finality for wormhole is invalid
    error INVALID_BROADCAST_FINALITY();

    /// @dev thrown if amb id is not valid leading to an address 0 of the implementation
    error INVALID_BRIDGE_ID();

    /// @dev thrown if chain id involved in xchain message is invalid
    error INVALID_CHAIN_ID();

    /// @dev thrown if payload update amount isn't equal to dst swapper amount
    error INVALID_DST_SWAP_AMOUNT();

    /// @dev thrown if message amb and proof amb are the same
    error INVALID_PROOF_BRIDGE_ID();

    /// @dev thrown if order of proof AMBs is incorrect, either duplicated or not incrementing
    error INVALID_PROOF_BRIDGE_IDS();

    /// @dev thrown if rescue data lengths are invalid
    error INVALID_RESCUE_DATA();

    /// @dev thrown if delay is invalid
    error INVALID_TIMELOCK_DELAY();

    /// @dev thrown if amounts being sent in update payload mean a negative slippage
    error NEGATIVE_SLIPPAGE();

    /// @dev thrown if slippage is outside of bounds
    error SLIPPAGE_OUT_OF_BOUNDS();

    /// SUPERPOSITION INPUT VALIDATION ERRORS
    /// ---------------------------------------------------------

    /// @dev thrown if src senders mismatch in state sync
    error SRC_SENDER_MISMATCH();

    /// @dev thrown if src tx types mismatch in state sync
    error SRC_TX_TYPE_MISMATCH();

    //////////////////////////////////////////////////////////////
    //                  EXECUTION ERRORS                        //
    //////////////////////////////////////////////////////////////
    ///@notice errors thrown due to function execution logic

    /// COMMON EXECUTION ERRORS
    /// ---------------------------------------------------------

    /// @dev thrown if the swap in a direct deposit resulted in insufficient tokens
    error DIRECT_DEPOSIT_SWAP_FAILED();

    /// @dev thrown if payload is not unique
    error DUPLICATE_PAYLOAD();

    /// @dev thrown if native tokens fail to be sent to superform contracts
    error FAILED_TO_SEND_NATIVE();

    /// @dev thrown if allowance is not correct to deposit
    error INSUFFICIENT_ALLOWANCE_FOR_DEPOSIT();

    /// @dev thrown if contract has insufficient balance for operations
    error INSUFFICIENT_BALANCE();

    /// @dev thrown if native amount is not at least equal to the amount in the request
    error INSUFFICIENT_NATIVE_AMOUNT();

    /// @dev thrown if payload cannot be decoded
    error INVALID_PAYLOAD();

    /// @dev thrown if payload status is invalid
    error INVALID_PAYLOAD_STATUS();

    /// @dev thrown if payload type is invalid
    error INVALID_PAYLOAD_TYPE();

    /// LIQUIDITY BRIDGE EXECUTION ERRORS
    /// ---------------------------------------------------------

    /// @dev thrown if we try to decode the final swap output token in a xChain liquidity bridging action
    error CANNOT_DECODE_FINAL_SWAP_OUTPUT_TOKEN();

    /// @dev thrown if liquidity bridge fails for erc20 or native tokens
    error FAILED_TO_EXECUTE_TXDATA(address token);

    /// @dev thrown if asset being used for deposit mismatches in multivault deposits
    error INVALID_DEPOSIT_TOKEN();

    /// STATE REGISTRY EXECUTION ERRORS
    /// ---------------------------------------------------------

    /// @dev thrown if bridge tokens haven't arrived to destination
    error BRIDGE_TOKENS_PENDING();

    /// @dev thrown if withdrawal tx data cannot be updated
    error CANNOT_UPDATE_WITHDRAW_TX_DATA();

    /// @dev thrown if rescue passed dispute deadline
    error DISPUTE_TIME_ELAPSED();

    /// @dev thrown if message failed to reach the specified level of quorum needed
    error INSUFFICIENT_QUORUM();

    /// @dev thrown if broadcast payload is invalid
    error INVALID_BROADCAST_PAYLOAD();

    /// @dev thrown if broadcast fee is invalid
    error INVALID_BROADCAST_FEE();

    /// @dev thrown if retry fees is less than required
    error INVALID_RETRY_FEE();

    /// @dev thrown if broadcast message type is wrong
    error INVALID_MESSAGE_TYPE();

    /// @dev thrown if payload hash is invalid during `retryMessage` on Layezero implementation
    error INVALID_PAYLOAD_HASH();

    /// @dev thrown if update payload function was called on a wrong payload
    error INVALID_PAYLOAD_UPDATE_REQUEST();

    /// @dev thrown if a state registry id is 0
    error INVALID_REGISTRY_ID();

    /// @dev thrown if a form state registry id is 0
    error INVALID_FORM_REGISTRY_ID();

    /// @dev thrown if trying to finalize the payload but the withdraw is still locked
    error LOCKED();

    /// @dev thrown if payload is already updated (during xChain deposits)
    error PAYLOAD_ALREADY_UPDATED();

    /// @dev thrown if payload is already processed
    error PAYLOAD_ALREADY_PROCESSED();

    /// @dev thrown if payload is not in UPDATED state
    error PAYLOAD_NOT_UPDATED();

    /// @dev thrown if rescue is still in timelocked state
    error RESCUE_LOCKED();

    /// @dev thrown if rescue is already proposed
    error RESCUE_ALREADY_PROPOSED();

    /// @dev thrown if payload hash is zero during `retryMessage` on Layezero implementation
    error ZERO_PAYLOAD_HASH();

    /// DST SWAPPER EXECUTION ERRORS
    /// ---------------------------------------------------------

    /// @dev thrown if process dst swap is tried for processed payload id
    error DST_SWAP_ALREADY_PROCESSED();

    /// @dev thrown if indices have duplicates
    error DUPLICATE_INDEX();

    /// @dev thrown if failed dst swap is already updated
    error FAILED_DST_SWAP_ALREADY_UPDATED();

    /// @dev thrown if indices are out of bounds
    error INDEX_OUT_OF_BOUNDS();

    /// @dev thrown if failed swap token amount is 0
    error INVALID_DST_SWAPPER_FAILED_SWAP();

    /// @dev thrown if failed swap token amount is not 0 and if token balance is less than amount (non zero)
    error INVALID_DST_SWAPPER_FAILED_SWAP_NO_TOKEN_BALANCE();

    /// @dev thrown if failed swap token amount is not 0 and if native amount is less than amount (non zero)
    error INVALID_DST_SWAPPER_FAILED_SWAP_NO_NATIVE_BALANCE();

    /// @dev forbid xChain deposits with destination swaps without interim token set (for user protection)
    error INVALID_INTERIM_TOKEN();

    /// @dev thrown if dst swap output is less than minimum expected
    error INVALID_SWAP_OUTPUT();

    /// FORM EXECUTION ERRORS
    /// ---------------------------------------------------------

    /// @dev thrown if try to forward 4626 share from the superform
    error CANNOT_FORWARD_4646_TOKEN();

    /// @dev thrown in KYCDAO form if no KYC token is present
    error NO_VALID_KYC_TOKEN();

    /// @dev thrown in forms where a certain functionality is not allowed or implemented
    error NOT_IMPLEMENTED();

    /// @dev thrown if form implementation is PAUSED, users cannot perform any action
    error PAUSED();

    /// @dev thrown if shares != deposit output or assets != redeem output when minting SuperPositions
    error VAULT_IMPLEMENTATION_FAILED();

    /// @dev thrown if withdrawal tx data is not updated
    error WITHDRAW_TOKEN_NOT_UPDATED();

    /// @dev thrown if withdrawal tx data is not updated
    error WITHDRAW_TX_DATA_NOT_UPDATED();

    /// @dev thrown when redeeming from vault yields zero collateral
    error WITHDRAW_ZERO_COLLATERAL();

    /// PAYMENT HELPER EXECUTION ERRORS
    /// ---------------------------------------------------------

    /// @dev thrown if chainlink is reporting an improper price
    error CHAINLINK_MALFUNCTION();

    /// @dev thrown if chainlink is reporting an incomplete round
    error CHAINLINK_INCOMPLETE_ROUND();

    /// @dev thrown if feed decimals is not 8
    error CHAINLINK_UNSUPPORTED_DECIMAL();

    /// EMERGENCY QUEUE EXECUTION ERRORS
    /// ---------------------------------------------------------

    /// @dev thrown if emergency withdraw is not queued
    error EMERGENCY_WITHDRAW_NOT_QUEUED();

    /// @dev thrown if emergency withdraw is already processed
    error EMERGENCY_WITHDRAW_PROCESSED_ALREADY();

    /// SUPERPOSITION EXECUTION ERRORS
    /// ---------------------------------------------------------

    /// @dev thrown if uri cannot be updated
    error DYNAMIC_URI_FROZEN();

    /// @dev thrown if tx history is not found while state sync
    error TX_HISTORY_NOT_FOUND();
}

// lib/superform-core/src/types/DataTypes.sol

/// @dev contains all the common struct and enums used for data communication between chains.

/// @dev There are two transaction types in Superform Protocol
enum TransactionType {
    DEPOSIT,
    WITHDRAW
}

/// @dev Message types can be INIT, RETURN (for successful Deposits) and FAIL (for failed withdraws)
enum CallbackType {
    INIT,
    RETURN,
    FAIL
}

/// @dev Payloads are stored, updated (deposits) or processed (finalized)
enum PayloadState {
    STORED,
    UPDATED,
    PROCESSED
}

/// @dev contains all the common struct used for interchain token transfers.
struct LiqRequest {
    /// @dev generated data
    bytes txData;
    /// @dev input token for deposits, desired output token on target liqDstChainId for withdraws. Must be set for
    /// txData to be updated on destination for withdraws
    address token;
    /// @dev intermediary token on destination. Relevant for xChain deposits where a destination swap is needed for
    /// validation purposes
    address interimToken;
    /// @dev what bridge to use to move tokens
    uint8 bridgeId;
    /// @dev dstChainId = liqDstchainId for deposits. For withdraws it is the target chain id for where the underlying
    /// is to be delivered
    uint64 liqDstChainId;
    /// @dev currently this amount is used as msg.value in the txData call.
    uint256 nativeAmount;
}

/// @dev main struct that holds required multi vault data for an action
struct MultiVaultSFData {
    // superformids must have same destination. Can have different underlyings
    uint256[] superformIds;
    uint256[] amounts; // on deposits, amount of token to deposit on dst, on withdrawals, superpositions to burn
    uint256[] outputAmounts; // on deposits, amount of shares to receive, on withdrawals, amount of assets to receive
    uint256[] maxSlippages;
    LiqRequest[] liqRequests; // if length = 1; amount = sum(amounts) | else  amounts must match the amounts being sent
    bytes permit2data;
    bool[] hasDstSwaps;
    bool[] retain4626s; // if true, we don't mint SuperPositions, and send the 4626 back to the user instead
    address receiverAddress;
    /// this address must always be an EOA otherwise funds may be lost
    address receiverAddressSP;
    /// this address can be a EOA or a contract that implements onERC1155Receiver. must always be set for deposits
    bytes extraFormData; // extraFormData
}

/// @dev main struct that holds required single vault data for an action
struct SingleVaultSFData {
    // superformids must have same destination. Can have different underlyings
    uint256 superformId;
    uint256 amount;
    uint256 outputAmount; // on deposits, amount of shares to receive, on withdrawals, amount of assets to receive
    uint256 maxSlippage;
    LiqRequest liqRequest; // if length = 1; amount = sum(amounts)| else  amounts must match the amounts being sent
    bytes permit2data;
    bool hasDstSwap;
    bool retain4626; // if true, we don't mint SuperPositions, and send the 4626 back to the user instead
    address receiverAddress;
    /// this address must always be an EOA otherwise funds may be lost
    address receiverAddressSP;
    /// this address can be a EOA or a contract that implements onERC1155Receiver. must always be set for deposits
    bytes extraFormData; // extraFormData
}

/// @dev overarching struct for multiDst requests with multi vaults
struct MultiDstMultiVaultStateReq {
    uint8[][] ambIds;
    uint64[] dstChainIds;
    MultiVaultSFData[] superformsData;
}

/// @dev overarching struct for single cross chain requests with multi vaults
struct SingleXChainMultiVaultStateReq {
    uint8[] ambIds;
    uint64 dstChainId;
    MultiVaultSFData superformsData;
}

/// @dev overarching struct for multiDst requests with single vaults
struct MultiDstSingleVaultStateReq {
    uint8[][] ambIds;
    uint64[] dstChainIds;
    SingleVaultSFData[] superformsData;
}

/// @dev overarching struct for single cross chain requests with single vaults
struct SingleXChainSingleVaultStateReq {
    uint8[] ambIds;
    uint64 dstChainId;
    SingleVaultSFData superformData;
}

/// @dev overarching struct for single direct chain requests with single vaults
struct SingleDirectSingleVaultStateReq {
    SingleVaultSFData superformData;
}

/// @dev overarching struct for single direct chain requests with multi vaults
struct SingleDirectMultiVaultStateReq {
    MultiVaultSFData superformData;
}

/// @dev struct for SuperRouter with re-arranged data for the message (contains the payloadId)
/// @dev realize that receiverAddressSP is not passed, only needed on source chain to mint
struct InitMultiVaultData {
    uint256 payloadId;
    uint256[] superformIds;
    uint256[] amounts;
    uint256[] outputAmounts;
    uint256[] maxSlippages;
    LiqRequest[] liqData;
    bool[] hasDstSwaps;
    bool[] retain4626s;
    address receiverAddress;
    bytes extraFormData;
}

/// @dev struct for SuperRouter with re-arranged data for the message (contains the payloadId)
struct InitSingleVaultData {
    uint256 payloadId;
    uint256 superformId;
    uint256 amount;
    uint256 outputAmount;
    uint256 maxSlippage;
    LiqRequest liqData;
    bool hasDstSwap;
    bool retain4626;
    address receiverAddress;
    bytes extraFormData;
}

/// @dev struct for Emergency Queue
struct QueuedWithdrawal {
    address receiverAddress;
    uint256 superformId;
    uint256 amount;
    uint256 srcPayloadId;
    bool isProcessed;
}

/// @dev all statuses of the timelock payload
enum TimelockStatus {
    UNAVAILABLE,
    PENDING,
    PROCESSED
}

/// @dev holds information about the timelock payload
struct TimelockPayload {
    uint8 isXChain;
    uint64 srcChainId;
    uint256 lockedTill;
    InitSingleVaultData data;
    TimelockStatus status;
}

/// @dev struct that contains the type of transaction, callback flags and other identification, as well as the vaults
/// data in params
struct AMBMessage {
    uint256 txInfo; // tight packing of  TransactionType txType,  CallbackType flag  if multi/single vault, registry id,
        // srcSender and srcChainId
    bytes params; // decoding txInfo will point to the right datatype of params. Refer PayloadHelper.sol
}

/// @dev struct that contains the information required for broadcasting changes
struct BroadcastMessage {
    bytes target;
    bytes32 messageType;
    bytes message;
}

/// @dev struct that contains info on returned data from destination
struct ReturnMultiData {
    uint256 payloadId;
    uint256[] superformIds;
    uint256[] amounts;
}

/// @dev struct that contains info on returned data from destination
struct ReturnSingleData {
    uint256 payloadId;
    uint256 superformId;
    uint256 amount;
}

/// @dev struct that contains the data on the fees to pay to the AMBs
struct AMBExtraData {
    uint256[] gasPerAMB;
    bytes[] extraDataPerAMB;
}

/// @dev struct that contains the data on the fees to pay to the AMBs on broadcasts
struct BroadCastAMBExtraData {
    uint256[] gasPerDst;
    bytes[] extraDataPerDst;
}

// lib/tokenized-strategy/lib/openzeppelin-contracts/contracts/utils/Address.sol

// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

/**
 * @dev Collection of functions related to the address type
 */
library Address_1 {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// lib/tokenized-strategy/lib/openzeppelin-contracts/contracts/utils/introspection/IERC165.sol

// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165_1 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// lib/tokenized-strategy/lib/openzeppelin-contracts/contracts/utils/math/Math.sol

// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// lib/tokenized-strategy/lib/openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol

// OpenZeppelin Contracts (last updated v4.9.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```solidity
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// src/interfaces/ISuperformFactoryMinimal.sol

/// @title ISuperformFactoryMinimal Interface
/// @notice Minimal interface for the SuperformFactory contract
/// @author SuperForm Labs
interface ISuperformFactoryMinimal {
    function vaultFormImplCombinationToSuperforms(bytes32 vaultFormImplementationCombination)
        external
        view
        returns (uint256 superformId);

    function getFormImplementation(uint32 formImplementationId_) external view returns (address);
}

// lib/superform-core/lib/ERC1155A/lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol

// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/IERC20.sol)

// lib/superform-core/lib/ERC1155A/lib/openzeppelin-contracts/contracts/token/ERC1155/IERC1155.sol

// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC1155/IERC1155.sol)

/**
 * @dev Required interface of an ERC-1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[ERC].
 */
interface IERC1155 is IERC165_0 {
    /**
     * @dev Emitted when `value` amount of tokens of type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the value of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers a `value` amount of tokens of type `id` from `from` to `to`.
     *
     * WARNING: This function can potentially allow a reentrancy attack when transferring tokens
     * to an untrusted contract, when invoking {onERC1155Received} on the receiver.
     * Ensure to follow the checks-effects-interactions pattern and consider employing
     * reentrancy guards when interacting with untrusted contracts.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `value` amount.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 value, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * WARNING: This function can potentially allow a reentrancy attack when transferring tokens
     * to an untrusted contract, when invoking {onERC1155BatchReceived} on the receiver.
     * Ensure to follow the checks-effects-interactions pattern and consider employing
     * reentrancy guards when interacting with untrusted contracts.
     *
     * Emits either a {TransferSingle} or a {TransferBatch} event, depending on the length of the array arguments.
     *
     * Requirements:
     *
     * - `ids` and `values` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external;
}

// lib/superform-core/lib/ERC1155A/lib/openzeppelin-contracts/contracts/token/ERC1155/IERC1155Receiver.sol

// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC1155/IERC1155Receiver.sol)

/**
 * @dev Interface that must be implemented by smart contracts in order to receive
 * ERC-1155 token transfers.
 */
interface IERC1155Receiver is IERC165_0 {
    /**
     * @dev Handles the receipt of a single ERC-1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC-1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// lib/superform-core/lib/ERC1155A/lib/openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol

// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Metadata.sol)

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

// lib/superform-core/src/interfaces/IBaseRouter.sol

/// @title IBaseRouter
/// @dev Interface for abstract BaseRouter
/// @author Zeropoint Labs
interface IBaseRouter {

    //////////////////////////////////////////////////////////////
    //              EXTERNAL WRITE FUNCTIONS                    //
    //////////////////////////////////////////////////////////////

    /// @dev Performs single direct x single vault deposits
    /// @param req_ is the request object containing all the necessary data for the action
    function singleDirectSingleVaultDeposit(SingleDirectSingleVaultStateReq memory req_) external payable;

    /// @dev Performs single xchain destination x single vault deposits
    /// @param req_ is the request object containing all the necessary data for the action
    function singleXChainSingleVaultDeposit(SingleXChainSingleVaultStateReq memory req_) external payable;

    /// @dev Performs single direct x multi vault deposits
    /// @param req_ is the request object containing all the necessary data for the action
    function singleDirectMultiVaultDeposit(SingleDirectMultiVaultStateReq memory req_) external payable;

    /// @dev Performs single destination x multi vault deposits
    /// @param req_ is the request object containing all the necessary data for the action
    function singleXChainMultiVaultDeposit(SingleXChainMultiVaultStateReq memory req_) external payable;

    /// @dev Performs multi destination x single vault deposits
    /// @param req_ is the request object containing all the necessary data for the action
    function multiDstSingleVaultDeposit(MultiDstSingleVaultStateReq calldata req_) external payable;

    /// @dev Performs multi destination x multi vault deposits
    /// @param req_ is the request object containing all the necessary data for the action
    function multiDstMultiVaultDeposit(MultiDstMultiVaultStateReq calldata req_) external payable;

    /// @dev Performs single direct x single vault withdraws
    /// @param req_ is the request object containing all the necessary data for the action
    function singleDirectSingleVaultWithdraw(SingleDirectSingleVaultStateReq memory req_) external payable;

    /// @dev Performs single xchain destination x single vault withdraws
    /// @param req_ is the request object containing all the necessary data for the action
    function singleXChainSingleVaultWithdraw(SingleXChainSingleVaultStateReq memory req_) external payable;

    /// @dev Performs single direct x multi vault withdraws
    /// @param req_ is the request object containing all the necessary data for the action
    function singleDirectMultiVaultWithdraw(SingleDirectMultiVaultStateReq memory req_) external payable;

    /// @dev Performs single destination x multi vault withdraws
    /// @param req_ is the request object containing all the necessary data for the action
    function singleXChainMultiVaultWithdraw(SingleXChainMultiVaultStateReq memory req_) external payable;

    /// @dev Performs multi destination x single vault withdraws
    /// @param req_ is the request object containing all the necessary data for the action
    function multiDstSingleVaultWithdraw(MultiDstSingleVaultStateReq calldata req_) external payable;

    /// @dev Performs multi destination x multi vault withdraws
    /// @param req_ is the request object containing all the necessary data for the action
    function multiDstMultiVaultWithdraw(MultiDstMultiVaultStateReq calldata req_) external payable;

    /// @dev Forwards dust to Paymaster
    /// @param token_ the token to forward
    function forwardDustToPaymaster(address token_) external;
}

// lib/superform-core/src/libraries/DataLib.sol

library DataLib {
    function packTxInfo(
        uint8 txType_,
        uint8 callbackType_,
        uint8 multi_,
        uint8 registryId_,
        address srcSender_,
        uint64 srcChainId_
    )
        internal
        pure
        returns (uint256 txInfo)
    {
        txInfo = uint256(txType_);
        txInfo |= uint256(callbackType_) << 8;
        txInfo |= uint256(multi_) << 16;
        txInfo |= uint256(registryId_) << 24;
        txInfo |= uint256(uint160(srcSender_)) << 32;
        txInfo |= uint256(srcChainId_) << 192;
    }

    function decodeTxInfo(uint256 txInfo_)
        internal
        pure
        returns (uint8 txType, uint8 callbackType, uint8 multi, uint8 registryId, address srcSender, uint64 srcChainId)
    {
        txType = uint8(txInfo_);
        callbackType = uint8(txInfo_ >> 8);
        multi = uint8(txInfo_ >> 16);
        registryId = uint8(txInfo_ >> 24);
        srcSender = address(uint160(txInfo_ >> 32));
        srcChainId = uint64(txInfo_ >> 192);
    }

    /// @dev returns the vault-form-chain pair of a superform
    /// @param superformId_ is the id of the superform
    /// @return superform_ is the address of the superform
    /// @return formImplementationId_ is the form id
    /// @return chainId_ is the chain id
    function getSuperform(uint256 superformId_)
        internal
        pure
        returns (address superform_, uint32 formImplementationId_, uint64 chainId_)
    {
        superform_ = address(uint160(superformId_));
        formImplementationId_ = uint32(superformId_ >> 160);
        chainId_ = uint64(superformId_ >> 192);

        if (chainId_ == 0) {
            revert Error.INVALID_CHAIN_ID();
        }
    }

    /// @dev returns the vault-form-chain pair of an array of superforms
    /// @param superformIds_  array of superforms
    /// @return superforms_ are the address of the vaults
    function getSuperforms(uint256[] memory superformIds_) internal pure returns (address[] memory superforms_) {
        uint256 len = superformIds_.length;
        superforms_ = new address[](len);

        for (uint256 i; i < len; ++i) {
            (superforms_[i],,) = getSuperform(superformIds_[i]);
        }
    }

    /// @dev returns the destination chain of a given superform
    /// @param superformId_ is the id of the superform
    /// @return chainId_ is the chain id
    function getDestinationChain(uint256 superformId_) internal pure returns (uint64 chainId_) {
        chainId_ = uint64(superformId_ >> 192);

        if (chainId_ == 0) {
            revert Error.INVALID_CHAIN_ID();
        }
    }

    /// @dev generates the superformId
    /// @param superform_ is the address of the superform
    /// @param formImplementationId_ is the type of the form
    /// @param chainId_ is the chain id on which the superform is deployed
    function packSuperform(
        address superform_,
        uint32 formImplementationId_,
        uint64 chainId_
    )
        internal
        pure
        returns (uint256 superformId_)
    {
        superformId_ = uint256(uint160(superform_));
        superformId_ |= uint256(formImplementationId_) << 160;
        superformId_ |= uint256(chainId_) << 192;
    }
}

// lib/superform-core/lib/ERC1155A/lib/openzeppelin-contracts/contracts/interfaces/IERC4626.sol

// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/IERC4626.sol)

/**
 * @dev Interface of the ERC-4626 "Tokenized Vault Standard", as defined in
 * https://eips.ethereum.org/EIPS/eip-4626[ERC-4626].
 */
interface IERC4626 is IERC20, IERC20Metadata {
    event Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(
        address indexed sender,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /**
     * @dev Returns the address of the underlying token used for the Vault for accounting, depositing, and withdrawing.
     *
     * - MUST be an ERC-20 token contract.
     * - MUST NOT revert.
     */
    function asset() external view returns (address assetTokenAddress);

    /**
     * @dev Returns the total amount of the underlying asset that is “managed” by Vault.
     *
     * - SHOULD include any compounding that occurs from yield.
     * - MUST be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT revert.
     */
    function totalAssets() external view returns (uint256 totalManagedAssets);

    /**
     * @dev Returns the amount of shares that the Vault would exchange for the amount of assets provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToShares(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Returns the amount of assets that the Vault would exchange for the amount of shares provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToAssets(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be deposited into the Vault for the receiver,
     * through a deposit call.
     *
     * - MUST return a limited value if receiver is subject to some deposit limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of assets that may be deposited.
     * - MUST NOT revert.
     */
    function maxDeposit(address receiver) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their deposit at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of Vault shares that would be minted in a deposit
     *   call in the same transaction. I.e. deposit should return the same or more shares as previewDeposit if called
     *   in the same transaction.
     * - MUST NOT account for deposit limits like those returned from maxDeposit and should always act as though the
     *   deposit would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewDeposit SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewDeposit(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Mints shares Vault shares to receiver by depositing exactly amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   deposit execution, and are accounted for during deposit.
     * - MUST revert if all of assets cannot be deposited (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of the Vault shares that can be minted for the receiver, through a mint call.
     * - MUST return a limited value if receiver is subject to some mint limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of shares that may be minted.
     * - MUST NOT revert.
     */
    function maxMint(address receiver) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their mint at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of assets that would be deposited in a mint call
     *   in the same transaction. I.e. mint should return the same or fewer assets as previewMint if called in the
     *   same transaction.
     * - MUST NOT account for mint limits like those returned from maxMint and should always act as though the mint
     *   would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewMint SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by minting.
     */
    function previewMint(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Mints exactly shares Vault shares to receiver by depositing amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the mint
     *   execution, and are accounted for during mint.
     * - MUST revert if all of shares cannot be minted (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function mint(uint256 shares, address receiver) external returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be withdrawn from the owner balance in the
     * Vault, through a withdraw call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxWithdraw(address owner) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their withdrawal at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of Vault shares that would be burned in a withdraw
     *   call in the same transaction. I.e. withdraw should return the same or fewer shares as previewWithdraw if
     *   called
     *   in the same transaction.
     * - MUST NOT account for withdrawal limits like those returned from maxWithdraw and should always act as though
     *   the withdrawal would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewWithdraw SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewWithdraw(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Burns shares from owner and sends exactly assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   withdraw execution, and are accounted for during withdraw.
     * - MUST revert if all of assets cannot be withdrawn (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * Note that some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function withdraw(uint256 assets, address receiver, address owner) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of Vault shares that can be redeemed from the owner balance in the Vault,
     * through a redeem call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST return balanceOf(owner) if owner is not subject to any withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxRedeem(address owner) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their redeemption at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of assets that would be withdrawn in a redeem call
     *   in the same transaction. I.e. redeem should return the same or more assets as previewRedeem if called in the
     *   same transaction.
     * - MUST NOT account for redemption limits like those returned from maxRedeem and should always act as though the
     *   redemption would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewRedeem SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by redeeming.
     */
    function previewRedeem(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Burns exactly shares from owner and sends assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   redeem execution, and are accounted for during redeem.
     * - MUST revert if all of shares cannot be redeemed (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * NOTE: some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets);
}

// lib/superform-core/lib/ERC1155A/src/interfaces/IERC1155A.sol

/// @title IERC1155A
/// @author Zeropoint Labs
/// @dev Single/range based id approve capability with conversion to ERC20s
interface IERC1155A is IERC1155 {
    //////////////////////////////////////////////////////////////
    //                          EVENTS                          //
    //////////////////////////////////////////////////////////////

    /// @dev emitted when single id approval is set
    event ApprovalForOne(address indexed owner, address indexed spender, uint256 id, uint256 amount);

    /// @dev emitted when an ERC1155A id is transmuted to an aERC20
    event TransmutedToERC20(address indexed user, uint256 id, uint256 amount, address indexed receiver);

    /// @dev emitted when an aERC20 is transmuted to an ERC1155 id
    event TransmutedToERC1155A(address indexed user, uint256 id, uint256 amount, address indexed receiver);

    /// @dev emitted when multiple ERC1155A ids are transmuted to aERC20s
    event TransmutedBatchToERC20(address indexed user, uint256[] ids, uint256[] amounts, address indexed receiver);

    /// @dev emitted when multiple aERC20s are transmuted to ERC1155A ids
    event TransmutedBatchToERC1155A(address indexed user, uint256[] ids, uint256[] amounts, address indexed receiver);

    //////////////////////////////////////////////////////////////
    //                          ERRORS                          //
    //////////////////////////////////////////////////////////////

    /// @dev thrown if aERC20 was already registered
    error AERC20_ALREADY_REGISTERED();

    /// @dev thrown if aERC20 was not registered
    error AERC20_NOT_REGISTERED();

    /// @dev thrown if allowance amount will be decreased below zero
    error DECREASED_ALLOWANCE_BELOW_ZERO();

    /// @dev thrown if the associated ERC1155A id has not been minted before registering an aERC20
    error ID_NOT_MINTED_YET();

    /// @dev thrown if there is a length mismatch in batch operations
    error LENGTH_MISMATCH();

    /// @dev thrown if transfer is made to address 0
    error TRANSFER_TO_ADDRESS_ZERO();

    /// @dev thrown if address is 0
    error ZERO_ADDRESS();

    //////////////////////////////////////////////////////////////
    //              EXTERNAL VIEW FUNCTIONS                     //
    //////////////////////////////////////////////////////////////

    /// @notice Public getter for existing single id total supply
    /// @param id id of the ERC1155
    function totalSupply(uint256 id) external view returns (uint256);

    /// @notice Public getter to know if a token id exists
    /// @dev determines based on total supply for the id
    /// @param id id of the ERC1155
    function exists(uint256 id) external view returns (bool);

    /// @notice Public getter for existing single id approval
    /// @param owner address of the owner of the ERC1155A id
    /// @param spender address of the contract to approve
    /// @param id id of the ERC1155A to approve
    function allowance(address owner, address spender, uint256 id) external returns (uint256);

    /// @notice handy helper to check if a AERC20 is registered
    /// @param id id of the ERC1155
    function aERC20Exists(uint256 id) external view returns (bool);

    /// @notice Public getter for the address of the aErc20 token for a given ERC1155 id
    /// @param id id of the ERC1155 to get the aErc20 token address for
    /// @return aERC20 address of the aErc20 token for the given ERC1155 id
    function getERC20TokenAddress(uint256 id) external view returns (address aERC20);

    /// @notice Compute return string from baseURI set for this contract and unique vaultId
    /// @param id id of the ERC1155
    function uri(uint256 id) external view returns (string memory);

    /// @notice ERC1155A name
    function name() external view returns (string memory);

    /// @notice ERC1155A symbol
    function symbol() external view returns (string memory);

    //////////////////////////////////////////////////////////////
    //              EXTERNAL WRITE FUNCTIONS                    //
    //////////////////////////////////////////////////////////////

    /// @notice Public function for setting single id approval
    /// @dev Notice `owner` param, it will always be msg.sender, see _setApprovalForOne()
    /// @param spender address of the contract to approve
    /// @param id id of the ERC1155A to approve
    /// @param amount amount of the ERC1155A to approve
    function setApprovalForOne(address spender, uint256 id, uint256 amount) external;

    /// @notice Public function for setting multiple id approval
    /// @dev extension of sigle id approval
    /// @param spender address of the contract to approve
    /// @param ids ids of the ERC1155A to approve
    /// @param amounts amounts of the ERC1155A to approve
    function setApprovalForMany(address spender, uint256[] memory ids, uint256[] memory amounts) external;

    /// @notice Public function for increasing single id approval amount
    /// @dev Re-adapted from ERC20
    /// @param spender address of the contract to approve
    /// @param id id of the ERC1155A to approve
    /// @param addedValue amount of the allowance to increase by
    function increaseAllowance(address spender, uint256 id, uint256 addedValue) external returns (bool);

    /// @notice Public function for decreasing single id approval amount
    /// @dev Re-adapted from ERC20
    /// @param spender address of the contract to approve
    /// @param id id of the ERC1155A to approve
    /// @param subtractedValue amount of the allowance to decrease by
    function decreaseAllowance(address spender, uint256 id, uint256 subtractedValue) external returns (bool);

    /// @notice Public function for increasing multiple id approval amount at once
    /// @dev extension of single id increase allowance
    /// @param spender address of the contract to approve
    /// @param ids ids of the ERC1155A to approve
    /// @param addedValues amounts of the allowance to increase by
    function increaseAllowanceForMany(
        address spender,
        uint256[] memory ids,
        uint256[] memory addedValues
    )
        external
        returns (bool);

    /// @notice Public function for decreasing multiple id approval amount at once
    /// @dev extension of single id decrease allowance
    /// @param spender address of the contract to approve
    /// @param ids ids of the ERC1155A to approve
    /// @param subtractedValues amounts of the allowance to decrease by
    function decreaseAllowanceForMany(
        address spender,
        uint256[] memory ids,
        uint256[] memory subtractedValues
    )
        external
        returns (bool);

    /// @notice Turn ERC1155A id into an aERC20
    /// @dev allows owner to send ERC1155A id as an aERC20 to receiver
    /// @param owner address of the user on whose behalf this transmutation is happening
    /// @param id id of the ERC20s to transmute to aERC20
    /// @param amount amount of the ERC20s to transmute to aERC20
    /// @param receiver address of the user to receive the aERC20 token
    function transmuteToERC20(address owner, uint256 id, uint256 amount, address receiver) external;

    /// @notice Turn aERC20 into an ERC1155A id
    /// @dev allows owner to send ERC20 as an ERC1155A id to receiver
    /// @param owner address of the user on whose behalf this transmutation is happening
    /// @param id id of the ERC20s to transmute to erc1155
    /// @param amount amount of the ERC20s to transmute to erc1155
    /// @param receiver address of the user to receive the erc1155 token id
    function transmuteToERC1155A(address owner, uint256 id, uint256 amount, address receiver) external;

    /// @notice Turn ERC1155A ids into aERC20s
    /// @dev allows owner to send ERC1155A ids as aERC20s to receiver
    /// @param owner address of the user on whose behalf this transmutation is happening
    /// @param ids ids of the ERC1155A to transmute
    /// @param amounts amounts of the ERC1155A to transmute
    /// @param receiver address of the user to receive the aERC20 tokens
    function transmuteBatchToERC20(
        address owner,
        uint256[] memory ids,
        uint256[] memory amounts,
        address receiver
    )
        external;

    /// @notice Turn aERC20s into ERC1155A ids
    /// @dev allows owner to send aERC20s as ERC1155A ids to receiver
    /// @param owner address of the user on whose behalf this transmutation is happening
    /// @param ids ids of the ERC20 to transmute
    /// @param amounts amounts of the ERC20 to transmute
    /// @param receiver address of the user to receive the ERC1155 token ids
    function transmuteBatchToERC1155A(
        address owner,
        uint256[] memory ids,
        uint256[] memory amounts,
        address receiver
    )
        external;

    /// @notice payable to allow any implementing cross-chain protocol to be paid for fees for broadcasting
    /// @dev should emit any required events inside _registerAERC20 internal function
    /// @param id of the ERC1155 to create a ERC20 for
    function registerAERC20(uint256 id) external payable returns (address);
}

// src/interfaces/ISuperVault.sol

/// @title ISuperVault Interface
/// @notice Interface for the SuperVault contract
/// @author SuperForm Labs
interface ISuperVault is IERC1155Receiver {
    //////////////////////////////////////////////////////////////
    //                  STRUCTS                                   //
    //////////////////////////////////////////////////////////////

    /// @notice Struct to hold rebalance arguments
    /// @notice superformIdsRebalanceFrom must be an ordered array of superform IDs with no duplicates
    /// @param superformIdsRebalanceFrom Array of superform IDs to rebalance from
    /// @param amountsRebalanceFrom Array of amounts to rebalance from each superform
    /// @param finalSuperformIds Array of final superform IDs
    /// @param weightsOfRedestribution Array of weights for redistribution
    /// @param slippage Slippage tolerance for the rebalance
    struct RebalanceArgs {
        uint256[] superformIdsRebalanceFrom;
        uint256[] amountsRebalanceFrom;
        uint256[] finalSuperformIds;
        uint256[] weightsOfRedestribution;
        uint256 slippage;
    }

    //////////////////////////////////////////////////////////////
    //                  ERRORS                                   //
    //////////////////////////////////////////////////////////////

    /// @notice Error thrown when no superforms are provided in constructor
    error ZERO_SUPERFORMS();

    /// @notice Error thrown when the ID is zero
    error ZERO_ID();

    /// @notice Error thrown when the address is zero
    error ZERO_ADDRESS();

    /// @notice Error thrown when duplicate superform IDs to rebalance from are provided
    error DUPLICATE_SUPERFORM_IDS_REBALANCE_FROM();

    /// @notice Error thrown when duplicate final superform IDs are provided
    error DUPLICATE_FINAL_SUPERFORM_IDS();

    /// @notice Error thrown when array lengths do not match
    error ARRAY_LENGTH_MISMATCH();

    /// @notice Error thrown when invalid weights are provided
    error INVALID_WEIGHTS();

    /// @notice Error thrown when the caller is not the Super Vaults strategist
    error NOT_SUPER_VAULTS_STRATEGIST();

    /// @notice Error thrown when the amounts to rebalance from array is empty
    error EMPTY_AMOUNTS_REBALANCE_FROM();

    /// @notice Error thrown when the final superform IDs array is empty
    error EMPTY_FINAL_SUPERFORM_IDS();

    /// @notice Error thrown when a superform does not support the asset
    error SUPERFORM_DOES_NOT_SUPPORT_ASSET();

    /// @notice Error thrown when the block chain ID is out of bounds
    error BLOCK_CHAIN_ID_OUT_OF_BOUNDS();

    /// @notice Error thrown when a superform does not exist
    error SUPERFORM_DOES_NOT_EXIST(uint256 superformId);

    /// @notice Error thrown when a superform ID is invalid
    error INVALID_SUPERFORM_ID_REBALANCE_FROM();

    /// @notice Error thrown when a superform ID is not found in the final superform IDs
    error REBALANCE_FROM_ID_NOT_FOUND_IN_FINAL_IDS();

    /// @notice Error thrown when the caller is not the pending management
    error NOT_PENDING_MANAGEMENT();

    /// @notice Error thrown when the caller is not the vault manager
    error NOT_VAULT_MANAGER();

    /// @notice Error thrown when a superform ID is not whitelisted
    error SUPERFORM_NOT_WHITELISTED();

    /// @notice Error thrown when a superform is fully rebalanced
    error INVALID_SP_FULL_REBALANCE(uint256 superformId);

    //////////////////////////////////////////////////////////////
    //                  EVENTS                                   //
    //////////////////////////////////////////////////////////////

    /// @notice Emitted when the SuperVault is rebalanced
    /// @param finalSuperformIds Array of final superform IDs of the SuperVault
    /// @param finalWeights Array of final weights of the SuperVault
    event RebalanceComplete(uint256[] finalSuperformIds, uint256[] finalWeights);

    /// @notice Emitted when the deposit limit is set
    /// @param depositLimit The new deposit limit
    event DepositLimitSet(uint256 depositLimit);

    /// @notice Emitted when dust is forwarded to the paymaster
    /// @param dust The amount of dust forwarded
    event DustForwardedToPaymaster(uint256 dust);

    /// @notice Emitted when the strategist is set
    /// @param strategist The new strategist
    event StrategistSet(address strategist);

    /// @notice Emitted when a superform is whitelisted
    /// @param superformId The superform ID that was whitelisted
    /// @param isWhitelisted Whether the superform was whitelisted
    event SuperformWhitelisted(uint256 superformId, bool isWhitelisted);

    /// @notice Emitted when the vault manager is set
    /// @param vaultManager The new vault manager
    event VaultManagerSet(address vaultManager);

    //////////////////////////////////////////////////////////////
    //                  EXTERNAL  FUNCTIONS                     //
    //////////////////////////////////////////////////////////////

    /// @notice Sets the deposit limit for the vault
    /// @param depositLimit_ The new deposit limit
    function setDepositLimit(uint256 depositLimit_) external;

    /// @notice Sets the strategist for the vault
    /// @param strategist_ The new strategist
    function setStrategist(address strategist_) external;

    /// @notice Sets the valid 5115 form implementation ID for the vault
    /// @param formImplementationId_ The form implementation ID
    function setValid5115FormImplementationId(uint32 formImplementationId_) external;

    /// @notice Rebalances the SuperVault
    /// @notice rebalanceArgs_.superformIdsRebalanceFrom must be an ordered array of superform IDs with no duplicates
    /// @notice the logic is as follows:
    /// select the ids to rebalance from
    /// send an amount to take from those ids
    /// the total underlying asset amount is redestributed according to the desired weights
    function rebalance(RebalanceArgs memory rebalanceArgs_) external payable;

    /// @notice Forwards dust to the paymaster
    function forwardDustToPaymaster() external;

    /// @notice Sets the whitelist for Superform IDs
    /// @param superformIds Array of Superform IDs
    /// @param isWhitelisted Array of booleans indicating whether to whitelist or blacklist
    function setWhitelist(uint256[] memory superformIds, bool[] memory isWhitelisted) external;

    /// @notice Sets the vault manager
    /// @param vaultManager_ The new vault manager
    function setVaultManager(address vaultManager_) external;

    /// @notice Returns whether a Superform ID is whitelisted
    /// @param superformIds Array of Superform IDs
    /// @return isWhitelisted Array of booleans indicating whether each Superform ID is whitelisted
    function getIsWhitelisted(uint256[] memory superformIds) external view returns (bool[] memory isWhitelisted);

    /// @notice Returns the array of whitelisted Superform IDs
    /// @return Array of whitelisted Superform IDs
    function getWhitelist() external view returns (uint256[] memory);

    /// @notice Returns the superform IDs and weights of the SuperVault
    /// @return superformIds_ Array of superform IDs
    /// @return weights_ Array of weights
    function getSuperVaultData() external view returns (uint256[] memory superformIds_, uint256[] memory weights_);
}

// lib/superform-core/lib/ERC1155A/lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol

// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/utils/SafeERC20.sol)

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
    using Address_0 for address;

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
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        forceApprove(token, spender, oldAllowance + value);
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `requestedDecrease`. If `token` returns no
     * value, non-reverting calls are assumed to be successful.
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
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeCall(token.approve, (spender, value));

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeCall(token.approve, (spender, 0)));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data);
        if (returndata.length != 0 && !abi.decode(returndata, (bool))) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return success && (returndata.length == 0 || abi.decode(returndata, (bool))) && address(token).code.length > 0;
    }
}

// lib/superform-core/src/interfaces/ISuperformRouterPlus.sol

interface ISuperformRouterPlus is IBaseSuperformRouterPlus {
    //////////////////////////////////////////////////////////////
    //                       ERRORS                             //
    //////////////////////////////////////////////////////////////

    /// @notice thrown when an invalid rebalance from selector is provided
    error INVALID_REBALANCE_FROM_SELECTOR();

    /// @notice thrown when an invalid deposit selector provided
    error INVALID_DEPOSIT_SELECTOR();

    /// @notice thrown if the interimToken is different than expected
    error REBALANCE_SINGLE_POSITIONS_DIFFERENT_TOKEN();

    /// @notice thrown if the liqDstChainId is different than expected
    error REBALANCE_SINGLE_POSITIONS_DIFFERENT_CHAIN();

    /// @notice thrown if the amounts to redeem differ
    error REBALANCE_SINGLE_POSITIONS_DIFFERENT_AMOUNT();

    /// @notice thrown if the receiver address is invalid (not the router plus)
    error REBALANCE_SINGLE_POSITIONS_UNEXPECTED_RECEIVER_ADDRESS();

    /// @notice thrown if the interimToken is different than expected in the array
    error REBALANCE_MULTI_POSITIONS_DIFFERENT_TOKEN();

    /// @notice thrown if the liqDstChainId is different than expected in the array
    error REBALANCE_MULTI_POSITIONS_DIFFERENT_CHAIN();

    /// @notice thrown if the amounts to redeem differ
    error REBALANCE_MULTI_POSITIONS_DIFFERENT_AMOUNTS();

    /// @notice thrown if the receiver address is invalid (not the router plus)
    error REBALANCE_MULTI_POSITIONS_UNEXPECTED_RECEIVER_ADDRESS();

    /// @notice thrown if the receiver address is invalid (not the router plus)
    error REBALANCE_XCHAIN_INVALID_RECEIVER_ADDRESS();

    /// @notice thrown if msg.value is lower than the required fee
    error INVALID_FEE();

    /// @notice thrown if the amount of assets received is lower than the slippage
    error ASSETS_RECEIVED_OUT_OF_SLIPPAGE();

    /// @notice thrown if the slippage is invalid
    error INVALID_GLOBAL_SLIPPAGE();

    /// @notice thrown if the tolerance is exceeded during shares redemption
    error TOLERANCE_EXCEEDED();

    /// @notice thrown if the amountIn is not equal or lower than the balance available
    error AMOUNT_IN_NOT_EQUAL_OR_LOWER_THAN_BALANCE();

    //////////////////////////////////////////////////////////////
    //                       EVENTS                             //
    //////////////////////////////////////////////////////////////

    /// @notice emitted when a single position rebalance is completed
    /// @param receiver The address receiving the rebalanced position
    /// @param id The ID of the rebalanced position
    /// @param amount The amount of tokens rebalanced
    event RebalanceSyncCompleted(address indexed receiver, uint256 indexed id, uint256 amount);

    /// @notice emitted when multiple positions are rebalanced
    /// @param receiver The address receiving the rebalanced positions
    /// @param ids The IDs of the rebalanced positions
    /// @param amounts The amounts of tokens rebalanced for each position
    event RebalanceMultiSyncCompleted(address indexed receiver, uint256[] ids, uint256[] amounts);

    /// @notice emitted when a cross-chain rebalance is initiated
    /// @param receiver The address receiving the rebalanced position
    /// @param routerPlusPayloadId The router plus payload Id
    /// @param id The ID of the position being rebalanced
    /// @param amount The amount of tokens being rebalanced
    /// @param interimAsset The address of the interim asset used in the cross-chain transfer
    /// @param finalizeSlippage The slippage tolerance for the finalization step
    /// @param expectedAmountInterimAsset The expected amount of interim asset to be received
    /// @param rebalanceToSelector The selector for the rebalance to function
    event XChainRebalanceInitiated(
        address indexed receiver,
        uint256 indexed routerPlusPayloadId,
        uint256 id,
        uint256 amount,
        address interimAsset,
        uint256 finalizeSlippage,
        uint256 expectedAmountInterimAsset,
        bytes4 rebalanceToSelector
    );

    /// @notice emitted when multiple cross-chain rebalances are initiated
    /// @param receiver The address receiving the rebalanced positions
    /// @param routerPlusPayloadId The router plus payload Id
    /// @param ids The IDs of the positions being rebalanced
    /// @param amounts The amounts of tokens being rebalanced for each position
    /// @param interimAsset The address of the interim asset used in the cross-chain transfer
    /// @param finalizeSlippage The slippage tolerance for the finalization step
    /// @param expectedAmountInterimAsset The expected amount of interim asset to be received
    /// @param rebalanceToSelector The selector for the rebalance to function
    event XChainRebalanceMultiInitiated(
        address indexed receiver,
        uint256 indexed routerPlusPayloadId,
        uint256[] ids,
        uint256[] amounts,
        address interimAsset,
        uint256 finalizeSlippage,
        uint256 expectedAmountInterimAsset,
        bytes4 rebalanceToSelector
    );

    /// @notice emitted when a deposit from an ERC4626 vault is completed
    /// @param receiver The address receiving the deposited tokens
    /// @param vault The address of the ERC4626 vault
    event Deposit4626Completed(address indexed receiver, address indexed vault);

    /// @notice emitted when dust is forwarded to the paymaster
    /// @param token The address of the token
    /// @param amount The amount of tokens forwarded
    event RouterPlusDustForwardedToPaymaster(address indexed token, uint256 amount);

    //////////////////////////////////////////////////////////////
    //                       STRUCTS                            //
    //////////////////////////////////////////////////////////////

    struct RebalanceSinglePositionSyncArgs {
        uint256 id;
        uint256 sharesToRedeem;
        uint256 expectedAmountToReceivePostRebalanceFrom;
        uint256 rebalanceFromMsgValue;
        uint256 rebalanceToMsgValue;
        address interimAsset;
        uint256 slippage;
        address receiverAddressSP;
        bytes callData;
        bytes rebalanceToCallData;
    }

    struct RebalanceMultiPositionsSyncArgs {
        uint256[] ids;
        uint256[] sharesToRedeem;
        uint256 expectedAmountToReceivePostRebalanceFrom;
        uint256 rebalanceFromMsgValue;
        uint256 rebalanceToMsgValue;
        address interimAsset;
        uint256 slippage;
        address receiverAddressSP;
        bytes callData;
        bytes rebalanceToCallData;
    }

    struct RebalancePositionsSyncArgs {
        Actions action;
        uint256[] sharesToRedeem;
        uint256 expectedAmountToReceivePostRebalanceFrom;
        address interimAsset;
        uint256 slippage;
        uint256 rebalanceFromMsgValue;
        uint256 rebalanceToMsgValue;
        address receiverAddressSP;
        uint256 balanceBefore;
    }

    struct InitiateXChainRebalanceArgs {
        uint256 id;
        uint256 sharesToRedeem;
        address receiverAddressSP;
        address interimAsset;
        uint256 finalizeSlippage;
        uint256 expectedAmountInterimAsset;
        bytes4 rebalanceToSelector;
        bytes callData;
        uint8[][] rebalanceToAmbIds;
        uint64[] rebalanceToDstChainIds;
        bytes rebalanceToSfData;
    }

    struct InitiateXChainRebalanceMultiArgs {
        uint256[] ids;
        uint256[] sharesToRedeem;
        address receiverAddressSP;
        address interimAsset;
        uint256 finalizeSlippage;
        uint256 expectedAmountInterimAsset;
        bytes4 rebalanceToSelector;
        bytes callData;
        uint8[][] rebalanceToAmbIds;
        uint64[] rebalanceToDstChainIds;
        bytes rebalanceToSfData;
    }

    struct Deposit4626Args {
        uint256 amount;
        uint256 expectedOutputAmount;
        uint256 maxSlippage;
        address receiverAddressSP;
        bytes depositCallData;
    }

    //////////////////////////////////////////////////////////////
    //                  EXTERNAL WRITE FUNCTIONS                //
    //////////////////////////////////////////////////////////////

    /// @notice rebalances a single SuperPosition synchronously
    /// @notice interim asset and receiverAddressSP must be set. In non smart contract wallet rebalances,
    /// receiverAddressSP is only used for refunds
    /// @param args The arguments for rebalancing single positions
    function rebalanceSinglePosition(RebalanceSinglePositionSyncArgs calldata args) external payable;

    /// @notice rebalances multiple SuperPositions synchronously
    /// @notice interim asset and receiverAddressSP must be set. In non smart contract wallet rebalances,
    /// receiverAddressSP is only used for refunds
    /// @notice receiverAddressSP of rebalanceCallData must be the address of the router plus for smart wallets
    /// @notice for normal deposits receiverAddressSP is the users' specified receiverAddressSP
    /// @param args The arguments for rebalancing multiple positions
    function rebalanceMultiPositions(RebalanceMultiPositionsSyncArgs calldata args) external payable;

    /// @notice initiates the rebalance process for a position on a different chain
    /// @param args The arguments for initiating cross-chain rebalance for single positions
    function startCrossChainRebalance(InitiateXChainRebalanceArgs calldata args) external payable;

    /// @notice initiates the rebalance process for multiple positions on different chains
    /// @param args The arguments for initiating cross-chain rebalance for multiple positions
    function startCrossChainRebalanceMulti(InitiateXChainRebalanceMultiArgs memory args) external payable;

    /// @notice deposits ERC4626 vault shares into superform
    /// @param vaults_ The ERC4626 vaults to redeem from
    /// @param args Rest of the arguments to deposit 4626
    function deposit4626(address[] calldata vaults_, Deposit4626Args[] calldata args) external payable;

    /// @dev Forwards dust to Paymaster
    /// @param token_ the token to forward
    function forwardDustToPaymaster(address token_) external;

    /// @dev only callable by Emergency Admin
    /// @notice sets the global slippage for all rebalances
    /// @param slippage_ The slippage tolerance for same chain rebalances
    function setGlobalSlippage(uint256 slippage_) external;
}

// lib/superform-core/lib/ERC1155A/lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol

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
 * conventional and does not conflict with the expectations of ERC-20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the ERC may not emit
 * these events, as it isn't required by the specification.
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
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the ERC. See the note at the beginning of {ERC20}.
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
     * @dev Updates `owner` s allowance for `spender` based on spent `value`.
     *
     * Does not update the allowance value in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Does not emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 value) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < value) {
                revert ERC20InsufficientAllowance(spender, currentAllowance, value);
            }
            unchecked {
                _approve(owner, spender, currentAllowance - value, false);
            }
        }
    }
}

// lib/superform-core/src/interfaces/ISuperPositions.sol

/// @title ISuperPositions
/// @dev Interface for SuperPositions
/// @author Zeropoint Labs
interface ISuperPositions is IERC1155A {

    //////////////////////////////////////////////////////////////
    //                          STRUCTS                         //
    //////////////////////////////////////////////////////////////

    struct TxHistory {
        uint256 txInfo;
        address receiverAddressSP;
    }
    
    //////////////////////////////////////////////////////////////
    //                          EVENTS                          //
    //////////////////////////////////////////////////////////////

    /// @dev is emitted when a dynamic uri is updated
    event DynamicURIUpdated(string indexed oldURI, string indexed newURI, bool indexed frozen);

    /// @dev is emitted when a cross-chain transaction is completed.
    event Completed(uint256 indexed txId);

    /// @dev is emitted when a aErc20 token is registered
    event AERC20TokenRegistered(uint256 indexed tokenId, address indexed tokenAddress);

    /// @dev is emitted when a tx info is saved
    event TxHistorySet(uint256 indexed payloadId, uint256 txInfo, address indexed receiverAddress);

    //////////////////////////////////////////////////////////////
    //              EXTERNAL VIEW FUNCTIONS                     //
    //////////////////////////////////////////////////////////////

    /// @dev returns the payload header and the receiver address for a tx id on the source chain
    /// @param txId_ is the identifier of the transaction issued by superform router
    /// @return txInfo is the header of the payload
    /// @return receiverAddressSP is the address of the receiver of superPositions
    function txHistory(uint256 txId_) external view returns (uint256 txInfo, address receiverAddressSP);

    //////////////////////////////////////////////////////////////
    //              EXTERNAL WRITE FUNCTIONS                    //
    //////////////////////////////////////////////////////////////

    /// @dev saves the message being sent together with the associated id formulated in a router
    /// @param payloadId_ is the id of the message being saved
    /// @param txInfo_ is the header of the AMBMessage of the transaction being saved
    /// @param receiverAddressSP_ is the address of the receiver of superPositions
    function updateTxHistory(uint256 payloadId_, uint256 txInfo_, address receiverAddressSP_) external;

    /// @dev allows minter to mint shares on source
    /// @param receiverAddress_ is the beneficiary of shares
    /// @param id_ is the id of the shares
    /// @param amount_ is the amount of shares to mint
    function mintSingle(address receiverAddress_, uint256 id_, uint256 amount_) external;

    /// @dev allows minter to mint shares on source in batch
    /// @param receiverAddress_ is the beneficiary of shares
    /// @param ids_ are the ids of the shares
    /// @param amounts_ are the amounts of shares to mint
    function mintBatch(address receiverAddress_, uint256[] memory ids_, uint256[] memory amounts_) external;

    /// @dev allows superformRouter to burn shares on source
    /// @notice burn is done optimistically by the router in the beginning of the withdraw transactions
    /// @notice in case the withdraw tx fails on the destination, shares are reminted through stateSync
    /// @param srcSender_ is the address of the sender
    /// @param id_ is the id of the shares
    /// @param amount_ is the amount of shares to burn
    function burnSingle(address srcSender_, uint256 id_, uint256 amount_) external;

    /// @dev allows burner to burn shares on source in batch
    /// @param srcSender_ is the address of the sender
    /// @param ids_ are the ids of the shares
    /// @param amounts_ are the amounts of shares to burn
    function burnBatch(address srcSender_, uint256[] memory ids_, uint256[] memory amounts_) external;

    /// @dev allows state registry contract to mint shares on source
    /// @param data_ is the received information to be processed.
    /// @return srcChainId_ is the decoded srcChainId.
    function stateMultiSync(AMBMessage memory data_) external returns (uint64 srcChainId_);

    /// @dev allows state registry contract to mint shares on source
    /// @param data_ is the received information to be processed.
    /// @return srcChainId_ is the decoded srcChainId.
    function stateSync(AMBMessage memory data_) external returns (uint64 srcChainId_);

    /// @dev sets the dynamic uri for NFT
    /// @param dynamicURI_ is the dynamic uri of the NFT
    /// @param freeze_ is to prevent updating the metadata once migrated to IPFS
    function setDynamicURI(string memory dynamicURI_, bool freeze_) external;

    /// @dev allows to create sERC0 using broadcast state registry
    /// @param data_ is the crosschain payload
    function stateSyncBroadcast(bytes memory data_) external payable;
}

// lib/superform-core/src/interfaces/IBaseForm.sol

/// @title IBaseForm
/// @dev Interface for BaseForm
/// @author ZeroPoint Labs
interface IBaseForm is IERC165_0 {
    
    //////////////////////////////////////////////////////////////
    //                          EVENTS                           //
    //////////////////////////////////////////////////////////////

    /// @dev is emitted when a new vault is added by the admin.
    event VaultAdded(uint256 indexed id, IERC4626 indexed vault);

    /// @dev is emitted when a payload is processed by the destination contract.
    event Processed(
        uint64 indexed srcChainID,
        uint64 indexed dstChainId,
        uint256 indexed srcPayloadId,
        uint256 amount,
        address vault
    );

    /// @dev is emitted when an emergency withdrawal is processed
    event EmergencyWithdrawalProcessed(address indexed refundAddress, uint256 indexed amount);

    /// @dev is emitted when dust is forwarded to the paymaster
    event FormDustForwardedToPaymaster(address indexed token, uint256 indexed amount);

    //////////////////////////////////////////////////////////////
    //              EXTERNAL VIEW FUNCTIONS                     //
    //////////////////////////////////////////////////////////////

    /// @notice get Superform name of the ERC20 vault representation
    /// @return The ERC20 name
    function superformYieldTokenName() external view returns (string memory);

    /// @notice get Superform symbol of the ERC20 vault representation
    /// @return The ERC20 symbol
    function superformYieldTokenSymbol() external view returns (string memory);

    /// @notice get the state registry id associated with the vault
    function getStateRegistryId() external view returns (uint8);

    /// @notice Returns the vault address
    /// @return The address of the vault
    function getVaultAddress() external view returns (address);

    /// @notice Returns the vault address
    /// @return The address of the vault asset
    function getVaultAsset() external view returns (address);

    /// @notice Returns the name of the vault.
    /// @return The name of the vault
    function getVaultName() external view returns (string memory);

    /// @notice Returns the symbol of a vault.
    /// @return The symbol associated with a vault
    function getVaultSymbol() external view returns (string memory);

    /// @notice Returns the number of decimals in a vault for accounting purposes
    /// @return The number of decimals in the vault balance
    function getVaultDecimals() external view returns (uint256);

    /// @notice Returns the amount of underlying tokens each share of a vault is worth.
    /// @return The pricePerVaultShare value
    function getPricePerVaultShare() external view returns (uint256);

    /// @notice Returns the amount of vault shares owned by the form.
    /// @return The form's vault share balance
    function getVaultShareBalance() external view returns (uint256);

    /// @notice get the total amount of underlying managed in the ERC4626 vault
    function getTotalAssets() external view returns (uint256);

    /// @notice get the total amount of unredeemed vault shares in circulation
    function getTotalSupply() external view returns (uint256);

    /// @notice get the total amount of assets received if shares are actually redeemed
    /// @notice https://eips.ethereum.org/EIPS/eip-4626
    function getPreviewPricePerVaultShare() external view returns (uint256);

    /// @dev API may need to know state of funds deployed
    function previewDepositTo(uint256 assets_) external view returns (uint256);

    /// @notice positionBalance() -> .vaultIds&destAmounts
    /// @return how much of an asset + interest (accrued) is to withdraw from the Vault
    function previewWithdrawFrom(uint256 assets_) external view returns (uint256);

    /// @dev API may need to know state of funds deployed
    function previewRedeemFrom(uint256 shares_) external view returns (uint256);

    //////////////////////////////////////////////////////////////
    //              EXTERNAL WRITE FUNCTIONS                    //
    //////////////////////////////////////////////////////////////

    /// @dev process same chain id deposits
    /// @param singleVaultData_  A bytes representation containing all the data required to make a form action
    /// @param srcSender_ The address of the sender of the transaction
    /// @return shares  The amount of vault shares received
    function directDepositIntoVault(
        InitSingleVaultData memory singleVaultData_,
        address srcSender_
    )
        external
        payable
        returns (uint256 shares);

    /// @dev process same chain id deposits
    /// @param singleVaultData_  A bytes representation containing all the data required to make a form action
    /// @param srcSender_ The address of the sender of the transaction
    /// @param srcChainId_ The chain id of the source chain
    /// @return shares  The amount of vault shares received
    /// @dev is shares is `0` then no further action/acknowledgement needs to be sent
    function xChainDepositIntoVault(
        InitSingleVaultData memory singleVaultData_,
        address srcSender_,
        uint64 srcChainId_
    )
        external
        returns (uint256 shares);

    /// @dev process withdrawal of asset from a vault
    /// @param singleVaultData_  A bytes representation containing all the data required to make a form action
    /// @param srcSender_ The address of the sender of the transaction
    /// @return assets  The amount of assets received
    function directWithdrawFromVault(
        InitSingleVaultData memory singleVaultData_,
        address srcSender_
    )
        external
        returns (uint256 assets);

    /// @dev process withdrawal of asset from a vault
    /// @param singleVaultData_  A bytes representation containing all the data required to make a form action
    /// @param srcSender_ The address of the sender of the transaction
    /// @param srcChainId_ The chain id of the source chain
    /// @return assets The amount of assets received
    function xChainWithdrawFromVault(
        InitSingleVaultData memory singleVaultData_,
        address srcSender_,
        uint64 srcChainId_
    )
        external
        returns (uint256 assets);

    /// @dev process withdrawal of shares if form is paused
    /// @param receiverAddress_ The address to refund the shares to
    /// @param amount_ The amount of vault shares to refund
    function emergencyWithdraw(address receiverAddress_, uint256 amount_) external;

    /// @dev moves all dust in the contract to Paymaster contract
    /// @param token_ The address of the token to forward
    function forwardDustToPaymaster(address token_) external;
}

// lib/tokenized-strategy/src/interfaces/ITokenizedStrategy.sol

// Interface that implements the 4626 standard and the implementation functions
interface ITokenizedStrategy is IERC4626, IERC20Permit {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event StrategyShutdown();

    event NewTokenizedStrategy(
        address indexed strategy,
        address indexed asset,
        string apiVersion
    );

    event Reported(
        uint256 profit,
        uint256 loss,
        uint256 protocolFees,
        uint256 performanceFees
    );

    event UpdatePerformanceFeeRecipient(
        address indexed newPerformanceFeeRecipient
    );

    event UpdateKeeper(address indexed newKeeper);

    event UpdatePerformanceFee(uint16 newPerformanceFee);

    event UpdateManagement(address indexed newManagement);

    event UpdateEmergencyAdmin(address indexed newEmergencyAdmin);

    event UpdateProfitMaxUnlockTime(uint256 newProfitMaxUnlockTime);

    event UpdatePendingManagement(address indexed newPendingManagement);

    /*//////////////////////////////////////////////////////////////
                           INITIALIZATION
    //////////////////////////////////////////////////////////////*/

    function initialize(
        address _asset,
        string memory _name,
        address _management,
        address _performanceFeeRecipient,
        address _keeper
    ) external;

    /*//////////////////////////////////////////////////////////////
                    NON-STANDARD 4626 OPTIONS
    //////////////////////////////////////////////////////////////*/

    function withdraw(
        uint256 assets,
        address receiver,
        address owner,
        uint256 maxLoss
    ) external returns (uint256);

    function redeem(
        uint256 shares,
        address receiver,
        address owner,
        uint256 maxLoss
    ) external returns (uint256);

    /*//////////////////////////////////////////////////////////////
                        MODIFIER HELPERS
    //////////////////////////////////////////////////////////////*/

    function requireManagement(address _sender) external view;

    function requireKeeperOrManagement(address _sender) external view;

    function requireEmergencyAuthorized(address _sender) external view;

    /*//////////////////////////////////////////////////////////////
                        KEEPERS FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function tend() external;

    function report() external returns (uint256 _profit, uint256 _loss);

    /*//////////////////////////////////////////////////////////////
                        CONSTANTS
    //////////////////////////////////////////////////////////////*/

    function MAX_FEE() external view returns (uint16);

    function FACTORY() external view returns (address);

    /*//////////////////////////////////////////////////////////////
                            GETTERS
    //////////////////////////////////////////////////////////////*/

    function apiVersion() external view returns (string memory);

    function pricePerShare() external view returns (uint256);

    function management() external view returns (address);

    function pendingManagement() external view returns (address);

    function keeper() external view returns (address);

    function emergencyAdmin() external view returns (address);

    function performanceFee() external view returns (uint16);

    function performanceFeeRecipient() external view returns (address);

    function fullProfitUnlockDate() external view returns (uint256);

    function profitUnlockingRate() external view returns (uint256);

    function profitMaxUnlockTime() external view returns (uint256);

    function lastReport() external view returns (uint256);

    function isShutdown() external view returns (bool);

    function unlockedShares() external view returns (uint256);

    /*//////////////////////////////////////////////////////////////
                            SETTERS
    //////////////////////////////////////////////////////////////*/

    function setPendingManagement(address) external;

    function acceptManagement() external;

    function setKeeper(address _keeper) external;

    function setEmergencyAdmin(address _emergencyAdmin) external;

    function setPerformanceFee(uint16 _performanceFee) external;

    function setPerformanceFeeRecipient(
        address _performanceFeeRecipient
    ) external;

    function setProfitMaxUnlockTime(uint256 _profitMaxUnlockTime) external;

    function shutdownStrategy() external;

    function emergencyWithdraw(uint256 _amount) external;
}

// lib/tokenized-strategy/src/BaseStrategy.sol

// TokenizedStrategy interface used for internal view delegateCalls.

/**
 * @title YearnV3 Base Strategy
 * @author yearn.finance
 * @notice
 *  BaseStrategy implements all of the required functionality to
 *  seamlessly integrate with the `TokenizedStrategy` implementation contract
 *  allowing anyone to easily build a fully permissionless ERC-4626 compliant
 *  Vault by inheriting this contract and overriding three simple functions.

 *  It utilizes an immutable proxy pattern that allows the BaseStrategy
 *  to remain simple and small. All standard logic is held within the
 *  `TokenizedStrategy` and is reused over any n strategies all using the
 *  `fallback` function to delegatecall the implementation so that strategists
 *  can only be concerned with writing their strategy specific code.
 *
 *  This contract should be inherited and the three main abstract methods
 *  `_deployFunds`, `_freeFunds` and `_harvestAndReport` implemented to adapt
 *  the Strategy to the particular needs it has to generate yield. There are
 *  other optional methods that can be implemented to further customize
 *  the strategy if desired.
 *
 *  All default storage for the strategy is controlled and updated by the
 *  `TokenizedStrategy`. The implementation holds a storage struct that
 *  contains all needed global variables in a manual storage slot. This
 *  means strategists can feel free to implement their own custom storage
 *  variables as they need with no concern of collisions. All global variables
 *  can be viewed within the Strategy by a simple call using the
 *  `TokenizedStrategy` variable. IE: TokenizedStrategy.globalVariable();.
 */
abstract contract BaseStrategy {
    /*//////////////////////////////////////////////////////////////
                            MODIFIERS
    //////////////////////////////////////////////////////////////*/
    /**
     * @dev Used on TokenizedStrategy callback functions to make sure it is post
     * a delegateCall from this address to the TokenizedStrategy.
     */
    modifier onlySelf() {
        _onlySelf();
        _;
    }

    /**
     * @dev Use to assure that the call is coming from the strategies management.
     */
    modifier onlyManagement() {
        TokenizedStrategy.requireManagement(msg.sender);
        _;
    }

    /**
     * @dev Use to assure that the call is coming from either the strategies
     * management or the keeper.
     */
    modifier onlyKeepers() {
        TokenizedStrategy.requireKeeperOrManagement(msg.sender);
        _;
    }

    /**
     * @dev Use to assure that the call is coming from either the strategies
     * management or the emergency admin.
     */
    modifier onlyEmergencyAuthorized() {
        TokenizedStrategy.requireEmergencyAuthorized(msg.sender);
        _;
    }

    /**
     * @dev Require that the msg.sender is this address.
     */
    function _onlySelf() internal view {
        require(msg.sender == address(this), "!self");
    }

    /*//////////////////////////////////////////////////////////////
                            CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev This is the address of the TokenizedStrategy implementation
     * contract that will be used by all strategies to handle the
     * accounting, logic, storage etc.
     *
     * Any external calls to the that don't hit one of the functions
     * defined in this base or the strategy will end up being forwarded
     * through the fallback function, which will delegateCall this address.
     *
     * This address should be the same for every strategy, never be adjusted
     * and always be checked before any integration with the Strategy.
     */
    address public constant tokenizedStrategyAddress =
        0xBB51273D6c746910C7C06fe718f30c936170feD0;

    /*//////////////////////////////////////////////////////////////
                            IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Underlying asset the Strategy is earning yield on.
     * Stored here for cheap retrievals within the strategy.
     */
    ERC20 internal immutable asset;

    /**
     * @dev This variable is set to address(this) during initialization of each strategy.
     *
     * This can be used to retrieve storage data within the strategy
     * contract as if it were a linked library.
     *
     *       i.e. uint256 totalAssets = TokenizedStrategy.totalAssets()
     *
     * Using address(this) will mean any calls using this variable will lead
     * to a call to itself. Which will hit the fallback function and
     * delegateCall that to the actual TokenizedStrategy.
     */
    ITokenizedStrategy internal immutable TokenizedStrategy;

    /**
     * @notice Used to initialize the strategy on deployment.
     *
     * This will set the `TokenizedStrategy` variable for easy
     * internal view calls to the implementation. As well as
     * initializing the default storage variables based on the
     * parameters and using the deployer for the permissioned roles.
     *
     * @param _asset Address of the underlying asset.
     * @param _name Name the strategy will use.
     */
    constructor(address _asset, string memory _name) {
        asset = ERC20(_asset);

        // Set instance of the implementation for internal use.
        TokenizedStrategy = ITokenizedStrategy(address(this));

        // Initialize the strategy's storage variables.
        _delegateCall(
            abi.encodeCall(
                ITokenizedStrategy.initialize,
                (_asset, _name, msg.sender, msg.sender, msg.sender)
            )
        );

        // Store the tokenizedStrategyAddress at the standard implementation
        // address storage slot so etherscan picks up the interface. This gets
        // stored on initialization and never updated.
        assembly {
            sstore(
                // keccak256('eip1967.proxy.implementation' - 1)
                0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc,
                tokenizedStrategyAddress
            )
        }
    }

    /*//////////////////////////////////////////////////////////////
                NEEDED TO BE OVERRIDDEN BY STRATEGIST
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Can deploy up to '_amount' of 'asset' in the yield source.
     *
     * This function is called at the end of a {deposit} or {mint}
     * call. Meaning that unless a whitelist is implemented it will
     * be entirely permissionless and thus can be sandwiched or otherwise
     * manipulated.
     *
     * @param _amount The amount of 'asset' that the strategy can attempt
     * to deposit in the yield source.
     */
    function _deployFunds(uint256 _amount) internal virtual;

    /**
     * @dev Should attempt to free the '_amount' of 'asset'.
     *
     * NOTE: The amount of 'asset' that is already loose has already
     * been accounted for.
     *
     * This function is called during {withdraw} and {redeem} calls.
     * Meaning that unless a whitelist is implemented it will be
     * entirely permissionless and thus can be sandwiched or otherwise
     * manipulated.
     *
     * Should not rely on asset.balanceOf(address(this)) calls other than
     * for diff accounting purposes.
     *
     * Any difference between `_amount` and what is actually freed will be
     * counted as a loss and passed on to the withdrawer. This means
     * care should be taken in times of illiquidity. It may be better to revert
     * if withdraws are simply illiquid so not to realize incorrect losses.
     *
     * @param _amount, The amount of 'asset' to be freed.
     */
    function _freeFunds(uint256 _amount) internal virtual;

    /**
     * @dev Internal function to harvest all rewards, redeploy any idle
     * funds and return an accurate accounting of all funds currently
     * held by the Strategy.
     *
     * This should do any needed harvesting, rewards selling, accrual,
     * redepositing etc. to get the most accurate view of current assets.
     *
     * NOTE: All applicable assets including loose assets should be
     * accounted for in this function.
     *
     * Care should be taken when relying on oracles or swap values rather
     * than actual amounts as all Strategy profit/loss accounting will
     * be done based on this returned value.
     *
     * This can still be called post a shutdown, a strategist can check
     * `TokenizedStrategy.isShutdown()` to decide if funds should be
     * redeployed or simply realize any profits/losses.
     *
     * @return _totalAssets A trusted and accurate account for the total
     * amount of 'asset' the strategy currently holds including idle funds.
     */
    function _harvestAndReport()
        internal
        virtual
        returns (uint256 _totalAssets);

    /*//////////////////////////////////////////////////////////////
                    OPTIONAL TO OVERRIDE BY STRATEGIST
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Optional function for strategist to override that can
     *  be called in between reports.
     *
     * If '_tend' is used tendTrigger() will also need to be overridden.
     *
     * This call can only be called by a permissioned role so may be
     * through protected relays.
     *
     * This can be used to harvest and compound rewards, deposit idle funds,
     * perform needed position maintenance or anything else that doesn't need
     * a full report for.
     *
     *   EX: A strategy that can not deposit funds without getting
     *       sandwiched can use the tend when a certain threshold
     *       of idle to totalAssets has been reached.
     *
     * This will have no effect on PPS of the strategy till report() is called.
     *
     * @param _totalIdle The current amount of idle funds that are available to deploy.
     */
    function _tend(uint256 _totalIdle) internal virtual {}

    /**
     * @dev Optional trigger to override if tend() will be used by the strategy.
     * This must be implemented if the strategy hopes to invoke _tend().
     *
     * @return . Should return true if tend() should be called by keeper or false if not.
     */
    function _tendTrigger() internal view virtual returns (bool) {
        return false;
    }

    /**
     * @notice Returns if tend() should be called by a keeper.
     *
     * @return . Should return true if tend() should be called by keeper or false if not.
     * @return . Calldata for the tend call.
     */
    function tendTrigger() external view virtual returns (bool, bytes memory) {
        return (
            // Return the status of the tend trigger.
            _tendTrigger(),
            // And the needed calldata either way.
            abi.encodeWithSelector(ITokenizedStrategy.tend.selector)
        );
    }

    /**
     * @notice Gets the max amount of `asset` that an address can deposit.
     * @dev Defaults to an unlimited amount for any address. But can
     * be overridden by strategists.
     *
     * This function will be called before any deposit or mints to enforce
     * any limits desired by the strategist. This can be used for either a
     * traditional deposit limit or for implementing a whitelist etc.
     *
     *   EX:
     *      if(isAllowed[_owner]) return super.availableDepositLimit(_owner);
     *
     * This does not need to take into account any conversion rates
     * from shares to assets. But should know that any non max uint256
     * amounts may be converted to shares. So it is recommended to keep
     * custom amounts low enough as not to cause overflow when multiplied
     * by `totalSupply`.
     *
     * @param . The address that is depositing into the strategy.
     * @return . The available amount the `_owner` can deposit in terms of `asset`
     */
    function availableDepositLimit(
        address /*_owner*/
    ) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    /**
     * @notice Gets the max amount of `asset` that can be withdrawn.
     * @dev Defaults to an unlimited amount for any address. But can
     * be overridden by strategists.
     *
     * This function will be called before any withdraw or redeem to enforce
     * any limits desired by the strategist. This can be used for illiquid
     * or sandwichable strategies. It should never be lower than `totalIdle`.
     *
     *   EX:
     *       return TokenIzedStrategy.totalIdle();
     *
     * This does not need to take into account the `_owner`'s share balance
     * or conversion rates from shares to assets.
     *
     * @param . The address that is withdrawing from the strategy.
     * @return . The available amount that can be withdrawn in terms of `asset`
     */
    function availableWithdrawLimit(
        address /*_owner*/
    ) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    /**
     * @dev Optional function for a strategist to override that will
     * allow management to manually withdraw deployed funds from the
     * yield source if a strategy is shutdown.
     *
     * This should attempt to free `_amount`, noting that `_amount` may
     * be more than is currently deployed.
     *
     * NOTE: This will not realize any profits or losses. A separate
     * {report} will be needed in order to record any profit/loss. If
     * a report may need to be called after a shutdown it is important
     * to check if the strategy is shutdown during {_harvestAndReport}
     * so that it does not simply re-deploy all funds that had been freed.
     *
     * EX:
     *   if(freeAsset > 0 && !TokenizedStrategy.isShutdown()) {
     *       depositFunds...
     *    }
     *
     * @param _amount The amount of asset to attempt to free.
     */
    function _emergencyWithdraw(uint256 _amount) internal virtual {}

    /*//////////////////////////////////////////////////////////////
                        TokenizedStrategy HOOKS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Can deploy up to '_amount' of 'asset' in yield source.
     * @dev Callback for the TokenizedStrategy to call during a {deposit}
     * or {mint} to tell the strategy it can deploy funds.
     *
     * Since this can only be called after a {deposit} or {mint}
     * delegateCall to the TokenizedStrategy msg.sender == address(this).
     *
     * Unless a whitelist is implemented this will be entirely permissionless
     * and thus can be sandwiched or otherwise manipulated.
     *
     * @param _amount The amount of 'asset' that the strategy can
     * attempt to deposit in the yield source.
     */
    function deployFunds(uint256 _amount) external virtual onlySelf {
        _deployFunds(_amount);
    }

    /**
     * @notice Should attempt to free the '_amount' of 'asset'.
     * @dev Callback for the TokenizedStrategy to call during a withdraw
     * or redeem to free the needed funds to service the withdraw.
     *
     * This can only be called after a 'withdraw' or 'redeem' delegateCall
     * to the TokenizedStrategy so msg.sender == address(this).
     *
     * @param _amount The amount of 'asset' that the strategy should attempt to free up.
     */
    function freeFunds(uint256 _amount) external virtual onlySelf {
        _freeFunds(_amount);
    }

    /**
     * @notice Returns the accurate amount of all funds currently
     * held by the Strategy.
     * @dev Callback for the TokenizedStrategy to call during a report to
     * get an accurate accounting of assets the strategy controls.
     *
     * This can only be called after a report() delegateCall to the
     * TokenizedStrategy so msg.sender == address(this).
     *
     * @return . A trusted and accurate account for the total amount
     * of 'asset' the strategy currently holds including idle funds.
     */
    function harvestAndReport() external virtual onlySelf returns (uint256) {
        return _harvestAndReport();
    }

    /**
     * @notice Will call the internal '_tend' when a keeper tends the strategy.
     * @dev Callback for the TokenizedStrategy to initiate a _tend call in the strategy.
     *
     * This can only be called after a tend() delegateCall to the TokenizedStrategy
     * so msg.sender == address(this).
     *
     * We name the function `tendThis` so that `tend` calls are forwarded to
     * the TokenizedStrategy.

     * @param _totalIdle The amount of current idle funds that can be
     * deployed during the tend
     */
    function tendThis(uint256 _totalIdle) external virtual onlySelf {
        _tend(_totalIdle);
    }

    /**
     * @notice Will call the internal '_emergencyWithdraw' function.
     * @dev Callback for the TokenizedStrategy during an emergency withdraw.
     *
     * This can only be called after a emergencyWithdraw() delegateCall to
     * the TokenizedStrategy so msg.sender == address(this).
     *
     * We name the function `shutdownWithdraw` so that `emergencyWithdraw`
     * calls are forwarded to the TokenizedStrategy.
     *
     * @param _amount The amount of asset to attempt to free.
     */
    function shutdownWithdraw(uint256 _amount) external virtual onlySelf {
        _emergencyWithdraw(_amount);
    }

    /**
     * @dev Function used to delegate call the TokenizedStrategy with
     * certain `_calldata` and return any return values.
     *
     * This is used to setup the initial storage of the strategy, and
     * can be used by strategist to forward any other call to the
     * TokenizedStrategy implementation.
     *
     * @param _calldata The abi encoded calldata to use in delegatecall.
     * @return . The return value if the call was successful in bytes.
     */
    function _delegateCall(
        bytes memory _calldata
    ) internal returns (bytes memory) {
        // Delegate call the tokenized strategy with provided calldata.
        (bool success, bytes memory result) = tokenizedStrategyAddress
            .delegatecall(_calldata);

        // If the call reverted. Return the error.
        if (!success) {
            assembly {
                let ptr := mload(0x40)
                let size := returndatasize()
                returndatacopy(ptr, 0, size)
                revert(ptr, size)
            }
        }

        // Return the result.
        return result;
    }

    /**
     * @dev Execute a function on the TokenizedStrategy and return any value.
     *
     * This fallback function will be executed when any of the standard functions
     * defined in the TokenizedStrategy are called since they wont be defined in
     * this contract.
     *
     * It will delegatecall the TokenizedStrategy implementation with the exact
     * calldata and return any relevant values.
     *
     */
    fallback() external {
        // load our target address
        address _tokenizedStrategyAddress = tokenizedStrategyAddress;
        // Execute external function using delegatecall and return any value.
        assembly {
            // Copy function selector and any arguments.
            calldatacopy(0, 0, calldatasize())
            // Execute function delegatecall.
            let result := delegatecall(
                gas(),
                _tokenizedStrategyAddress,
                0,
                calldatasize(),
                0,
                0
            )
            // Get any return value
            returndatacopy(0, 0, returndatasize())
            // Return any return value or error back to the caller
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}

// src/SuperVault.sol

/// @title SuperVault
/// @notice A vault contract that manages multiple Superform positions
/// @dev Inherits from BaseStrategy and implements ISuperVault and IERC1155Receiver
/// @author Superform Labs
contract SuperVault is BaseStrategy, ISuperVault {
    using EnumerableSet for EnumerableSet.UintSet;
    using SafeERC20 for IERC20;
    using SafeERC20 for ERC20;
    using DataLib for uint256;
    using Math for uint256;

    //////////////////////////////////////////////////////////////
    //                     STATE VARIABLES                      //
    //////////////////////////////////////////////////////////////

    /// @notice The chain ID of the network this contract is deployed on
    uint64 public immutable CHAIN_ID;

    /// @notice The address of the SuperVault Strategist
    address public strategist;

    /// @notice The address of the SuperVault Vault Manager
    address public vaultManager;

    /// @notice The address of the SuperRegistry contract
    ISuperRegistry public immutable superRegistry;

    /// @notice The address of the SuperformFactory contract
    ISuperformFactory public immutable superformFactory;

    /// @notice The ID of the ERC5115 form implementation
    uint32 public ERC5115FormImplementationId;

    /// @notice The total weight used for calculating proportions (10000 = 100%)
    uint256 private constant TOTAL_WEIGHT = 10_000;

    /// @notice The maximum allowed slippage (1% = 100)
    uint256 private constant MAX_SLIPPAGE = 100;

    /// @dev Tolerance constant to account for minAmountOut check in 5115
    uint256 private constant TOLERANCE_CONSTANT = 10 wei;

    /// @notice The number of Superforms in the vault
    uint256 public numberOfSuperforms;

    /// @notice The deposit limit for the vault
    uint256 public depositLimit;

    /// @notice Set of whitelisted Superform IDs for easy access
    EnumerableSet.UintSet whitelistedSuperformIdsSet;

    /// @notice Array of Superform IDs in the vault
    uint256[] public superformIds;

    /// @notice Array of weights for each Superform in the vault
    uint256[] public weights;

    address private immutable _SUPER_POSITIONS;
    address private immutable _SUPERFORM_ROUTER;
    address private immutable _SUPERFORM_FACTORY;

    /// @notice Slot for call depth.
    /// @dev Equal to bytes32(uint256(keccak256("transient.calldepth")) - 1).
    bytes32 internal constant CALL_DEPTH_SLOT = 0x7a74fd168763fd280eaec3bcd2fd62d0e795027adc8183a693c497a7c2b10b5c;

    //////////////////////////////////////////////////////////////
    //                       MODIFIERS                          //
    //////////////////////////////////////////////////////////////

    /// @notice Ensures that only the Super Vaults Strategist can call the function
    modifier onlySuperVaultsStrategist() {
        if (strategist != msg.sender) {
            revert NOT_SUPER_VAULTS_STRATEGIST();
        }
        _;
    }

    /// @notice Ensures that only the Vault Manager can call the function
    modifier onlyVaultManager() {
        if (vaultManager != msg.sender) {
            revert NOT_VAULT_MANAGER();
        }
        _;
    }

    //////////////////////////////////////////////////////////////
    //                       CONSTRUCTOR                        //
    //////////////////////////////////////////////////////////////

    /// @param superRegistry_ Address of the SuperRegistry contract
    /// @param asset_ Address of the asset token
    /// @param name_ Name of the strategy
    /// @param depositLimit_ Maximum deposit limit
    /// @param superformIds_ Array of Superform IDs
    /// @param startingWeights_ Array of starting weights for each Superform
    constructor(
        address superRegistry_,
        address asset_,
        address strategist_,
        address vaultManager_,
        string memory name_,
        uint256 depositLimit_,
        uint256[] memory superformIds_,
        uint256[] memory startingWeights_
    )
        BaseStrategy(asset_, name_)
    {
        numberOfSuperforms = superformIds_.length;

        if (numberOfSuperforms == 0) {
            revert ZERO_SUPERFORMS();
        }

        if (numberOfSuperforms != startingWeights_.length) {
            revert ARRAY_LENGTH_MISMATCH();
        }

        if (superRegistry_ == address(0) || strategist_ == address(0) || vaultManager_ == address(0)) {
            revert ZERO_ADDRESS();
        }

        superRegistry = ISuperRegistry(superRegistry_);
        superformFactory = ISuperformFactory(superRegistry.getAddress(keccak256("SUPERFORM_FACTORY")));

        if (CHAIN_ID > type(uint64).max) {
            revert BLOCK_CHAIN_ID_OUT_OF_BOUNDS();
        }

        CHAIN_ID = uint64(block.chainid);

        uint256 totalWeight;
        address superform;

        for (uint256 i; i < numberOfSuperforms; ++i) {
            /// @dev this superVault only supports superforms that have the same asset as the vault
            (superform,,) = superformIds_[i].getSuperform();

            if (!superformFactory.isSuperform(superformIds_[i])) {
                revert SUPERFORM_DOES_NOT_EXIST(superformIds_[i]);
            }

            if (IBaseForm(superform).getVaultAsset() != asset_) {
                revert SUPERFORM_DOES_NOT_SUPPORT_ASSET();
            }

            /// @dev initial whitelist of superform IDs
            _addToWhitelist(superformIds_[i]);

            totalWeight += startingWeights_[i];
        }

        if (totalWeight != TOTAL_WEIGHT) revert INVALID_WEIGHTS();

        strategist = strategist_;
        vaultManager = vaultManager_;
        superformIds = superformIds_;
        weights = startingWeights_;
        depositLimit = depositLimit_;

        {
            _SUPER_POSITIONS = _getAddress(keccak256("SUPER_POSITIONS"));
            _SUPERFORM_ROUTER = _getAddress(keccak256("SUPERFORM_ROUTER"));
            _SUPERFORM_FACTORY = _getAddress(keccak256("SUPERFORM_FACTORY"));
        }
    }

    //////////////////////////////////////////////////////////////
    //                  EXTERNAL  FUNCTIONS                     //
    //////////////////////////////////////////////////////////////

    /// @inheritdoc ISuperVault
    function setDepositLimit(uint256 depositLimit_) external override onlyVaultManager {
        depositLimit = depositLimit_;

        emit DepositLimitSet(depositLimit_);
    }

    /// @inheritdoc ISuperVault
    function setStrategist(address strategist_) external override onlyManagement {
        strategist = strategist_;

        emit StrategistSet(strategist_);
    }

    /// @inheritdoc ISuperVault
    function setValid5115FormImplementationId(uint32 formImplementationId_) external override onlyManagement {
        if (formImplementationId_ == 0) revert ZERO_ID();

        ERC5115FormImplementationId = formImplementationId_;
    }

    /// @inheritdoc ISuperVault
    function rebalance(RebalanceArgs calldata rebalanceArgs_) external payable override onlySuperVaultsStrategist {
        uint256 lenRebalanceFrom = rebalanceArgs_.superformIdsRebalanceFrom.length;
        uint256 lenAmountsRebalanceFrom = rebalanceArgs_.amountsRebalanceFrom.length;
        uint256 lenFinal = rebalanceArgs_.finalSuperformIds.length;

        if (lenAmountsRebalanceFrom == 0) revert EMPTY_AMOUNTS_REBALANCE_FROM();
        if (lenFinal == 0) revert EMPTY_FINAL_SUPERFORM_IDS();

        /// @dev sanity check input arrays
        if (lenRebalanceFrom != lenAmountsRebalanceFrom || lenFinal != rebalanceArgs_.weightsOfRedestribution.length) {
            revert ARRAY_LENGTH_MISMATCH();
        }

        {
            /// @dev caching to avoid multiple loads
            uint256 foundCount;
            uint256 nSuperforms = numberOfSuperforms;
            for (uint256 i; i < lenRebalanceFrom; ++i) {
                for (uint256 j; j < nSuperforms; ++j) {
                    if (rebalanceArgs_.superformIdsRebalanceFrom[i] == superformIds[j]) {
                        foundCount++;
                        break;
                    }
                }
            }

            if (foundCount != lenRebalanceFrom) {
                revert INVALID_SUPERFORM_ID_REBALANCE_FROM();
            }
        }
        for (uint256 i = 1; i < lenRebalanceFrom; ++i) {
            if (rebalanceArgs_.superformIdsRebalanceFrom[i] <= rebalanceArgs_.superformIdsRebalanceFrom[i - 1]) {
                revert DUPLICATE_SUPERFORM_IDS_REBALANCE_FROM();
            }
        }

        for (uint256 i; i < lenFinal; ++i) {
            if (i >= 1 && rebalanceArgs_.finalSuperformIds[i] <= rebalanceArgs_.finalSuperformIds[i - 1]) {
                revert DUPLICATE_FINAL_SUPERFORM_IDS();
            }
            if (!whitelistedSuperformIdsSet.contains(rebalanceArgs_.finalSuperformIds[i])) {
                revert SUPERFORM_NOT_WHITELISTED();
            }
        }

        /// @dev step 1: prepare rebalance arguments
        ISuperformRouterPlus.RebalanceMultiPositionsSyncArgs memory args = _prepareRebalanceArgs(
            rebalanceArgs_.superformIdsRebalanceFrom,
            rebalanceArgs_.amountsRebalanceFrom,
            rebalanceArgs_.finalSuperformIds,
            rebalanceArgs_.weightsOfRedestribution,
            rebalanceArgs_.slippage
        );

        address routerPlus = _getAddress(keccak256("SUPERFORM_ROUTER_PLUS"));

        /// @dev step 2: execute rebalance
        _setSuperPositionsApproval(routerPlus, args.ids, args.sharesToRedeem);

        ISuperformRouterPlus(routerPlus).rebalanceMultiPositions(args);

        /// @dev step 3: update SV data
        /// @notice no issue about reentrancy as the external contracts are trusted
        /// @notice updateSV emits rebalance event
        _updateSVData(_SUPER_POSITIONS, rebalanceArgs_.finalSuperformIds);
    }

    /// @inheritdoc ISuperVault
    function forwardDustToPaymaster() external override {
        address paymaster = superRegistry.getAddress(keccak256("PAYMASTER"));
        IERC20 token = IERC20(asset);

        uint256 dust = _getAssetBalance(token);

        if (dust != 0) {
            token.safeTransfer(paymaster, dust);
            emit DustForwardedToPaymaster(dust);
        }
    }

    /// @inheritdoc ISuperVault
    function setWhitelist(
        uint256[] memory superformIds_,
        bool[] memory isWhitelisted_
    )
        external
        override
        onlyVaultManager
    {
        uint256 length = superformIds_.length;
        if (length != isWhitelisted_.length) revert ARRAY_LENGTH_MISMATCH();
        if (length == 0) revert ZERO_SUPERFORMS();
        for (uint256 i; i < length; ++i) {
            _changeSuperformWhitelist(superformIds_[i], isWhitelisted_[i]);
        }
    }

    /// @inheritdoc ISuperVault
    function setVaultManager(address vaultManager_) external override onlyManagement {
        if (vaultManager_ == address(0)) revert ZERO_ADDRESS();
        vaultManager = vaultManager_;

        emit VaultManagerSet(vaultManager_);
    }

    //////////////////////////////////////////////////////////////
    //                 EXTERNAL VIEW/PURE FUNCTIONS             //
    //////////////////////////////////////////////////////////////

    /// @inheritdoc ISuperVault
    function getIsWhitelisted(uint256[] memory superformIds_) external view returns (bool[] memory isWhitelisted) {
        uint256 length = superformIds_.length;
        isWhitelisted = new bool[](length);

        for (uint256 i; i < length; ++i) {
            isWhitelisted[i] = whitelistedSuperformIdsSet.contains(superformIds_[i]);
        }

        return isWhitelisted;
    }

    /// @inheritdoc ISuperVault
    function getWhitelist() external view override returns (uint256[] memory) {
        return whitelistedSuperformIdsSet.values();
    }

    /// @inheritdoc ISuperVault
    function getSuperVaultData() external view returns (uint256[] memory superformIds_, uint256[] memory weights_) {
        return (superformIds, weights);
    }

    /// @inheritdoc IERC1155Receiver
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    )
        external
        pure
        override
        returns (bytes4)
    {
        return this.onERC1155Received.selector;
    }

    /// @inheritdoc IERC1155Receiver
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    )
        external
        pure
        override
        returns (bytes4)
    {
        return this.onERC1155BatchReceived.selector;
    }

    /// @notice Checks if the contract supports a given interface
    /// @param interfaceId The interface identifier
    /// @return bool True if the contract supports the interface
    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return interfaceId == type(IERC165_1).interfaceId || interfaceId == type(IERC1155Receiver).interfaceId;
    }

    /// @inheritdoc BaseStrategy
    function availableDepositLimit(address /*_owner*/ ) public view override returns (uint256) {
        uint256 totalAssets = TokenizedStrategy.totalAssets();
        uint256 _depositLimit_ = depositLimit;
        return totalAssets >= _depositLimit_ ? 0 : _depositLimit_ - totalAssets;
    }

    //////////////////////////////////////////////////////////////
    //            BASESTRATEGY INTERNAL OVERRIDES               //
    //////////////////////////////////////////////////////////////

    /// @notice Deploys funds to the underlying Superforms
    /// @param amount_ The amount of funds to deploy
    function _deployFunds(uint256 amount_) internal override {
        bytes memory callData = numberOfSuperforms == 1
            ? abi.encodeWithSelector(
                IBaseRouter.singleDirectSingleVaultDeposit.selector,
                SingleDirectSingleVaultStateReq(_prepareSingleVaultDepositData(amount_))
            )
            : abi.encodeWithSelector(
                IBaseRouter.singleDirectMultiVaultDeposit.selector,
                SingleDirectMultiVaultStateReq(_prepareMultiVaultDepositData(amount_))
            );

        address router = _SUPERFORM_ROUTER;
        asset.safeIncreaseAllowance(router, amount_);

        /// @dev this call has to be enforced with 0 msg.value not to break the 4626 standard
        (bool success, bytes memory returndata) = router.call(callData);

        Address_1.verifyCallResult(success, returndata, "CallRevertWithNoReturnData");

        if (asset.allowance(address(this), router) > 0) asset.forceApprove(router, 0);
    }

    /// @notice Frees funds from the underlying Superforms
    /// @param amount_ The amount of funds to free
    function _freeFunds(uint256 amount_) internal override {
        bytes memory callData;
        address router = _SUPERFORM_ROUTER;

        if (numberOfSuperforms == 1) {
            SingleVaultSFData memory svData = _prepareSingleVaultWithdrawData(amount_);
            callData = abi.encodeWithSelector(
                IBaseRouter.singleDirectSingleVaultWithdraw.selector, SingleDirectSingleVaultStateReq(svData)
            );
            _setSuperPositionApproval(router, svData.superformId, svData.amount);
        } else {
            MultiVaultSFData memory mvData = _prepareMultiVaultWithdrawData(amount_);
            callData = abi.encodeWithSelector(
                IBaseRouter.singleDirectMultiVaultWithdraw.selector, SingleDirectMultiVaultStateReq(mvData)
            );
            _setSuperPositionsApproval(router, mvData.superformIds, mvData.amounts);
        }

        /// @dev this call has to be enforced with 0 msg.value not to break the 4626 standard
        (bool success, bytes memory returndata) = router.call(callData);

        Address_1.verifyCallResult(success, returndata, "CallRevertWithNoReturnData");
    }

    /// @notice Reports the total assets of the vault
    /// @return totalAssets The total assets of the vault
    function _harvestAndReport() internal view override returns (uint256 totalAssets) {
        uint256 totalAssetsInVaults;
        uint256 _numberOfSuperforms_ = numberOfSuperforms;
        uint256[] memory _superformIds_ = superformIds;
        address superPositions = _SUPER_POSITIONS;

        for (uint256 i; i < _numberOfSuperforms_;) {
            (address superform,,) = _superformIds_[i].getSuperform();

            /// @dev This contract holds superPositions, not shares
            uint256 spBalance = ISuperPositions(superPositions).balanceOf(address(this), _superformIds_[i]);
            totalAssetsInVaults += IBaseForm(superform).previewRedeemFrom(spBalance);

            unchecked {
                ++i;
            }
        }

        totalAssets = totalAssetsInVaults + _getAssetBalance(asset);
    }

    //////////////////////////////////////////////////////////////
    //                     INTERNAL FUNCTIONS                   //
    //////////////////////////////////////////////////////////////

    function _prepareMultiVaultDepositData(uint256 amount_) internal view returns (MultiVaultSFData memory mvData) {
        uint256 _numberOfSuperforms_ = numberOfSuperforms;

        mvData.superformIds = superformIds;
        mvData.amounts = new uint256[](_numberOfSuperforms_);
        mvData.maxSlippages = new uint256[](_numberOfSuperforms_);
        mvData.liqRequests = new LiqRequest[](_numberOfSuperforms_);
        mvData.hasDstSwaps = new bool[](_numberOfSuperforms_);
        mvData.retain4626s = mvData.hasDstSwaps;
        mvData.receiverAddress = address(this);
        mvData.receiverAddressSP = address(this);
        mvData.outputAmounts = new uint256[](_numberOfSuperforms_);

        bytes[] memory dataToEncode = new bytes[](_numberOfSuperforms_);

        uint256[] memory _weights_ = weights;
        for (uint256 i; i < _numberOfSuperforms_;) {
            mvData.liqRequests[i].token = address(asset);

            (address superform,,) = mvData.superformIds[i].getSuperform();

            dataToEncode[i] = _prepareDepositExtraFormDataForSuperform(mvData.superformIds[i]);

            /// @notice rounding down to avoid one-off issue
            mvData.amounts[i] = amount_.mulDiv(_weights_[i], TOTAL_WEIGHT, Math.Rounding.Down);
            mvData.outputAmounts[i] = IBaseForm(superform).previewDepositTo(mvData.amounts[i]);
            mvData.maxSlippages[i] = MAX_SLIPPAGE;

            unchecked {
                ++i;
            }
        }

        mvData.extraFormData = abi.encode(_numberOfSuperforms_, dataToEncode);
        return mvData;
    }

    function _prepareSingleVaultDepositData(uint256 amount_) internal view returns (SingleVaultSFData memory svData) {
        svData.superformId = superformIds[0];
        svData.amount = amount_;
        svData.maxSlippage = MAX_SLIPPAGE;
        svData.liqRequest.token = address(asset);
        svData.hasDstSwap = false;
        svData.retain4626 = false;
        svData.receiverAddress = address(this);
        svData.receiverAddressSP = address(this);

        (address superform,,) = svData.superformId.getSuperform();
        svData.outputAmount = IBaseForm(superform).previewDepositTo(amount_);
        bytes memory dataToEncode = _prepareDepositExtraFormDataForSuperform(svData.superformId);
        bytes[] memory finalDataToEncode = new bytes[](1);
        finalDataToEncode[0] = dataToEncode;
        svData.extraFormData = abi.encode(1, finalDataToEncode);

        return svData;
    }

    function _prepareMultiVaultWithdrawData(uint256 amount_) internal view returns (MultiVaultSFData memory mvData) {
        uint256 _numberOfSuperforms_ = numberOfSuperforms;

        mvData.superformIds = superformIds;
        mvData.amounts = new uint256[](_numberOfSuperforms_);
        mvData.maxSlippages = new uint256[](_numberOfSuperforms_);
        mvData.liqRequests = new LiqRequest[](_numberOfSuperforms_);
        mvData.hasDstSwaps = new bool[](_numberOfSuperforms_);
        mvData.retain4626s = mvData.hasDstSwaps;
        mvData.receiverAddress = address(this);
        mvData.receiverAddressSP = address(this);
        mvData.outputAmounts = new uint256[](_numberOfSuperforms_);

        address superPositions = _SUPER_POSITIONS;
        uint256 totalAssetsInVaults;
        uint256[] memory spBalances = new uint256[](_numberOfSuperforms_);
        uint256[] memory assetBalances = new uint256[](_numberOfSuperforms_);

        // Snapshot assets and SP balances
        for (uint256 i; i < _numberOfSuperforms_;) {
            (address superform,,) = mvData.superformIds[i].getSuperform();

            spBalances[i] = _getSuperPositionBalance(superPositions, mvData.superformIds[i]);
            assetBalances[i] = IBaseForm(superform).previewRedeemFrom(spBalances[i]);
            totalAssetsInVaults += assetBalances[i];

            unchecked {
                ++i;
            }
        }

        // Calculate withdrawal amounts
        for (uint256 i; i < _numberOfSuperforms_;) {
            mvData.liqRequests[i].token = address(asset);

            (address superform,,) = mvData.superformIds[i].getSuperform();

            bool isERC5115 = _isERC5115Vault(mvData.superformIds[i]);

            if (isERC5115) {
                mvData.liqRequests[i].interimToken = address(asset);
            }

            if (amount_ >= totalAssetsInVaults) {
                mvData.amounts[i] = spBalances[i];
                mvData.outputAmounts[i] = _tolerance(isERC5115, assetBalances[i]);
            } else {
                uint256 amountOut = amount_.mulDiv(weights[i], TOTAL_WEIGHT, Math.Rounding.Down);
                mvData.outputAmounts[i] = _tolerance(isERC5115, amountOut);
                mvData.amounts[i] = IBaseForm(superform).previewDepositTo(amountOut);

                if (mvData.amounts[i] > spBalances[i]) {
                    mvData.amounts[i] = spBalances[i];
                }
            }

            mvData.maxSlippages[i] = MAX_SLIPPAGE;

            unchecked {
                ++i;
            }
        }

        return mvData;
    }

    function _prepareSingleVaultWithdrawData(uint256 amount_) internal view returns (SingleVaultSFData memory svData) {
        svData.superformId = superformIds[0];
        (address superform,,) = svData.superformId.getSuperform();

        // Get current balances
        uint256 spBalance = _getSuperPositionBalance(_SUPER_POSITIONS, svData.superformId);
        uint256 assetBalance = IBaseForm(superform).previewRedeemFrom(spBalance);

        // Set up basic data
        svData.liqRequest.token = address(asset);
        bool isERC5115 = _isERC5115Vault(svData.superformId);

        if (isERC5115) {
            svData.liqRequest.interimToken = address(asset);
        }

        // Calculate withdrawal amounts
        if (amount_ >= assetBalance) {
            svData.amount = spBalance;
            svData.outputAmount = _tolerance(isERC5115, assetBalance);
        } else {
            svData.outputAmount = _tolerance(isERC5115, amount_);
            svData.amount = IBaseForm(superform).previewDepositTo(amount_);

            if (svData.amount > spBalance) {
                svData.amount = spBalance;
            }
        }

        svData.maxSlippage = MAX_SLIPPAGE;
        svData.hasDstSwap = false;
        svData.retain4626 = false;
        svData.receiverAddress = address(this);
        svData.receiverAddressSP = address(this);

        return svData;
    }

    /// @notice Checks if a vault is ERC5115 and validates form implementation IDs
    /// @param superformId_ The superform ID to check
    /// @return isERC5115 True if the vault is ERC5115
    function _isERC5115Vault(uint256 superformId_) internal view returns (bool isERC5115) {
        ISuperformFactoryMinimal factory = ISuperformFactoryMinimal(_SUPERFORM_FACTORY);

        address erc5115Implementation = factory.getFormImplementation(ERC5115FormImplementationId);

        (address superform,,) = superformId_.getSuperform();

        uint256 superFormId = factory.vaultFormImplCombinationToSuperforms(
            keccak256(abi.encode(erc5115Implementation, IBaseForm(superform).getVaultAddress()))
        );

        if (superFormId == superformId_) {
            isERC5115 = true;
        }
    }

    /// @dev returns the address for id_ from super registry
    function _getAddress(bytes32 id_) internal view returns (address) {
        return superRegistry.getAddress(id_);
    }

    /// @notice Sets approval for multiple SuperPositions
    /// @param router_ The router address to approve
    /// @param superformIds_ The superform IDs to approve
    /// @param amounts_ The amounts to approve
    function _setSuperPositionsApproval(
        address router_,
        uint256[] memory superformIds_,
        uint256[] memory amounts_
    )
        internal
    {
        ISuperPositions(_SUPER_POSITIONS).setApprovalForMany(router_, superformIds_, amounts_);
    }

    /// @notice Sets approval for a single SuperPosition
    /// @param router_ The router address to approve
    /// @param superformId_ The superform ID to approve
    /// @param amount_ The amount to approve
    function _setSuperPositionApproval(address router_, uint256 superformId_, uint256 amount_) internal {
        ISuperPositions(_SUPER_POSITIONS).setApprovalForOne(router_, superformId_, amount_);
    }

    /// @notice Gets the current balance of the asset token held by this contract
    /// @return balance The current balance of the asset token
    function _getAssetBalance(IERC20 token_) internal view returns (uint256) {
        return token_.balanceOf(address(this));
    }

    function _getSuperPositionBalance(address superPositions, uint256 superformId) internal view returns (uint256) {
        return ISuperPositions(superPositions).balanceOf(address(this), superformId);
    }

    /// @notice Prepares rebalance arguments for Superform Router Plus
    /// @param superformIdsRebalanceFrom_ Array of Superform IDs to rebalance from
    /// @param amountsRebalanceFrom_ Array of amounts to rebalance from
    /// @param finalSuperformIds_ Array of Superform IDs to rebalance to
    /// @param weightsOfRedestribution_ Array of weights for redestribution
    /// @param slippage_ Maximum allowed slippage
    function _prepareRebalanceArgs(
        uint256[] calldata superformIdsRebalanceFrom_,
        uint256[] calldata amountsRebalanceFrom_,
        uint256[] calldata finalSuperformIds_,
        uint256[] calldata weightsOfRedestribution_,
        uint256 slippage_
    )
        internal
        view
        returns (ISuperformRouterPlus.RebalanceMultiPositionsSyncArgs memory args)
    {
        args.ids = superformIdsRebalanceFrom_;
        args.sharesToRedeem = amountsRebalanceFrom_;
        args.interimAsset = address(asset); // Assuming 'asset' is the interim token
        args.slippage = slippage_; // 1% slippage, adjust as needed
        args.receiverAddressSP = address(this);

        (SingleDirectMultiVaultStateReq memory req, uint256 totalOutputAmount) =
            _prepareSingleDirectMultiVaultStateReq(superformIdsRebalanceFrom_, amountsRebalanceFrom_, slippage_, true);

        /// @dev prepare callData for rebalance from
        args.callData = abi.encodeWithSelector(IBaseRouter.singleDirectMultiVaultWithdraw.selector, req);

        /// @dev create a filtered version of superformIdsRebalanceTo
        (uint256[] memory filteredSuperformIds, uint256[] memory filteredWeights) =
            _filterNonZeroWeights(finalSuperformIds_, weightsOfRedestribution_);

        (req,) = _prepareSingleDirectMultiVaultStateReq(
            filteredSuperformIds, _calculateAmounts(totalOutputAmount, filteredWeights), slippage_, false
        );

        /// @dev prepare rebalanceToCallData
        args.rebalanceToCallData = abi.encodeWithSelector(IBaseRouter.singleDirectMultiVaultDeposit.selector, req);
        args.expectedAmountToReceivePostRebalanceFrom = totalOutputAmount;
    }

    /// @notice Prepares single direct multi-vault state request
    /// @param superformIds_ Array of Superform IDs
    /// @param amounts_ Array of amounts
    /// @param slippage_ Maximum allowed slippage
    /// @param isWithdraw_ True if withdrawing, false if depositing
    /// @return req The prepared single direct multi-vault state request
    /// @return totalOutputAmount The total output amount
    function _prepareSingleDirectMultiVaultStateReq(
        uint256[] memory superformIds_,
        uint256[] memory amounts_,
        uint256 slippage_,
        bool isWithdraw_
    )
        internal
        view
        returns (SingleDirectMultiVaultStateReq memory req, uint256 totalOutputAmount)
    {
        MultiVaultSFData memory data;
        data.superformIds = superformIds_;
        data.amounts = amounts_;

        address routerPlus = _getAddress(keccak256("SUPERFORM_ROUTER_PLUS"));

        uint256 _numberOfSuperforms_ = superformIds_.length;
        data.outputAmounts = new uint256[](_numberOfSuperforms_);
        data.maxSlippages = new uint256[](_numberOfSuperforms_);
        data.liqRequests = new LiqRequest[](_numberOfSuperforms_);
        bytes[] memory dataToEncode = new bytes[](_numberOfSuperforms_);

        for (uint256 i; i < _numberOfSuperforms_;) {
            (address superform,,) = superformIds_[i].getSuperform();

            if (isWithdraw_) {
                // Check if vault is ERC5115
                bool isERC5115 = _isERC5115Vault(superformIds_[i]);

                if (isERC5115) {
                    data.liqRequests[i].interimToken = address(asset);
                }

                uint256 amountOut = IBaseForm(superform).previewRedeemFrom(amounts_[i]);
                data.outputAmounts[i] = _tolerance(isERC5115, amountOut);
            } else {
                dataToEncode[i] = _prepareDepositExtraFormDataForSuperform(superformIds_[i]);

                data.outputAmounts[i] = IBaseForm(superform).previewDepositTo(amounts_[i]);
            }

            totalOutputAmount += data.outputAmounts[i];

            data.maxSlippages[i] = slippage_;
            data.liqRequests[i].token = address(asset);
            data.liqRequests[i].liqDstChainId = CHAIN_ID;

            unchecked {
                ++i;
            }
        }

        data.hasDstSwaps = new bool[](_numberOfSuperforms_);
        data.retain4626s = data.hasDstSwaps;
        /// @dev routerPlus receives assets to continue the rebalance
        data.receiverAddress = routerPlus;
        /// @dev in case of withdraw failure, this vault receives the superPositions back
        data.receiverAddressSP = address(this);

        if (!isWithdraw_) {
            data.extraFormData = abi.encode(_numberOfSuperforms_, dataToEncode);
        }
        req.superformData = data;
    }

    /// @notice Prepares deposit extra form data for a single superform
    /// @param superformId_ The superform ID
    /// @return bytes Encoded data for the superform
    function _prepareDepositExtraFormDataForSuperform(uint256 superformId_) internal view returns (bytes memory) {
        // For ERC4626 vaults, no extra data needed
        // For ERC5115 vaults, include asset address
        bytes memory extraData = _isERC5115Vault(superformId_) ? abi.encode(address(asset)) : bytes("");

        return abi.encode(superformId_, extraData);
    }

    /// @notice Calculates amounts based on total output amount and weights
    /// @param totalOutputAmount_ The total output amount
    /// @param weights_ Array of weights
    /// @return amounts Array of calculated amounts
    function _calculateAmounts(
        uint256 totalOutputAmount_,
        uint256[] memory weights_
    )
        internal
        pure
        returns (uint256[] memory amounts)
    {
        amounts = new uint256[](weights_.length);
        for (uint256 i; i < weights_.length; ++i) {
            amounts[i] = totalOutputAmount_.mulDiv(weights_[i], TOTAL_WEIGHT, Math.Rounding.Down);
        }
    }

    /// @notice Filters out zero weights and returns corresponding superform IDs and weights
    /// @param superformIds_ Array of Superform IDs
    /// @param weights_ Array of weights
    /// @return filteredIds Array of filtered Superform IDs
    /// @return filteredWeights Array of filtered weights
    function _filterNonZeroWeights(
        uint256[] calldata superformIds_,
        uint256[] calldata weights_
    )
        internal
        pure
        returns (uint256[] memory filteredIds, uint256[] memory filteredWeights)
    {
        uint256 count;
        uint256 length = weights_.length;
        for (uint256 i; i < length; ++i) {
            if (weights_[i] != 0) {
                count++;
            }
        }

        filteredIds = new uint256[](count);
        filteredWeights = new uint256[](count);

        uint256 j;
        uint256 totalWeight;
        for (uint256 i; i < length; ++i) {
            if (weights_[i] != 0) {
                filteredIds[j] = superformIds_[i];
                filteredWeights[j] = weights_[i];
                totalWeight += weights_[i];
                j++;
            }
        }
        if (totalWeight != TOTAL_WEIGHT) revert INVALID_WEIGHTS();
    }

    /// @notice Updates the SuperVault data after rebalancing
    /// @param superPositions_ Address of the SuperPositions contract
    /// @param finalSuperformIds_ Array of Superform IDs to rebalance to
    function _updateSVData(address superPositions_, uint256[] memory finalSuperformIds_) internal {
        // Cache current superform IDs
        uint256[] memory currentSuperformIds = superformIds;

        // For each current superform ID
        uint256 numSuperforms = currentSuperformIds.length;
        uint256 numFinalSuperforms = finalSuperformIds_.length;
        for (uint256 i; i < numSuperforms;) {
            bool found;
            // Check if it exists in finalSuperformIds_
            for (uint256 j; j < numFinalSuperforms;) {
                if (currentSuperformIds[i] == finalSuperformIds_[j]) {
                    found = true;
                    break;
                }
                unchecked {
                    ++j;
                }
            }
            // If not found in final IDs, it should be fully rebalanced
            if (!found) {
                if (_getSuperPositionBalance(superPositions_, currentSuperformIds[i]) != 0) {
                    revert INVALID_SP_FULL_REBALANCE(currentSuperformIds[i]);
                }
            }

            unchecked {
                ++i;
            }
        }

        uint256 totalWeight;
        uint256 length = finalSuperformIds_.length;
        if (length == 0) revert ZERO_SUPERFORMS();

        uint256[] memory newWeights = new uint256[](length);

        /// @dev check if finalSuperformIds are present in superform factory and support the asset
        ISuperformFactory factory = ISuperformFactory(_SUPERFORM_FACTORY);
        address superform;
        uint256 value;
        address assetCache = address(asset);

        /// @dev calculate total value and individual values
        for (uint256 i; i < length;) {
            if (!factory.isSuperform(finalSuperformIds_[i])) {
                revert SUPERFORM_DOES_NOT_EXIST(finalSuperformIds_[i]);
            }

            (superform,,) = finalSuperformIds_[i].getSuperform();

            if (IBaseForm(superform).getVaultAsset() != assetCache) {
                revert SUPERFORM_DOES_NOT_SUPPORT_ASSET();
            }

            uint256 balance = _getSuperPositionBalance(superPositions_, finalSuperformIds_[i]);
            value = IBaseForm(superform).previewRedeemFrom(balance);

            newWeights[i] = value;
            totalWeight += value;

            unchecked {
                ++i;
            }
        }

        /// @dev calculate new weights as percentages
        uint256 totalAssignedWeight;
        for (uint256 i; i < length - 1;) {
            newWeights[i] = newWeights[i].mulDiv(TOTAL_WEIGHT, totalWeight, Math.Rounding.Down);
            totalAssignedWeight += newWeights[i];

            unchecked {
                ++i;
            }
        }

        /// @notice assign remaining weight to the last index
        newWeights[length - 1] = TOTAL_WEIGHT - totalAssignedWeight;

        /// @dev update SV data
        weights = newWeights;
        superformIds = finalSuperformIds_;
        numberOfSuperforms = length;

        emit RebalanceComplete(finalSuperformIds_, newWeights);
    }

    /// @notice Changes the whitelist for a Superform ID
    /// @param superformId_ The Superform ID to change
    /// @param isWhitelisted_ Whether to whitelist or blacklist
    function _changeSuperformWhitelist(uint256 superformId_, bool isWhitelisted_) internal {
        bool currentlyWhitelisted = whitelistedSuperformIdsSet.contains(superformId_);

        // Only process if there's an actual change
        if (currentlyWhitelisted != isWhitelisted_) {
            if (isWhitelisted_) {
                _addToWhitelist(superformId_);
            } else {
                _removeFromWhitelist(superformId_);
            }

            emit SuperformWhitelisted(superformId_, isWhitelisted_);
        }
    }

    /// @notice Adds a superform ID to the whitelist array
    /// @param superformId The Superform ID to add
    function _addToWhitelist(uint256 superformId) internal {
        whitelistedSuperformIdsSet.add(superformId);
    }

    /// @notice Removes a superform ID from the whitelist array
    /// @param superformId The Superform ID to remove
    function _removeFromWhitelist(uint256 superformId) internal {
        whitelistedSuperformIdsSet.remove(superformId);
    }

    /// @notice Calculates the tolerance for ERC5115 vaults
    /// @param isERC5115 Whether the vault is ERC5115
    /// @param amount The amount to calculate tolerance for
    /// @return The calculated tolerance
    function _tolerance(bool isERC5115, uint256 amount) internal pure returns (uint256) {
        return isERC5115 ? amount - TOLERANCE_CONSTANT : amount;
    }
}