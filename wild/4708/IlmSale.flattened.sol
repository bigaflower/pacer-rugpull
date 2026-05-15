// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol

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

// lib/openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Permit.sol

// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Permit.sol)

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
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

// lib/openzeppelin-contracts/contracts/utils/Address.sol

// OpenZeppelin Contracts (last updated v5.0.0) (utils/Address.sol)

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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

// lib/openzeppelin-contracts/contracts/utils/Context.sol

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

// lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol

// OpenZeppelin Contracts (last updated v5.0.0) (utils/ReentrancyGuard.sol)

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

// lib/openzeppelin-contracts/contracts/utils/introspection/IERC165.sol

// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/IERC165.sol)

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
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
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// lib/v2-core/contracts/interfaces/IUniswapV2Factory.sol

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

// lib/v2-core/contracts/interfaces/IUniswapV2Pair.sol

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

// lib/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol

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

// lib/openzeppelin-contracts/contracts/access/Ownable.sol

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

// lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol

// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC721/IERC721.sol)

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon
     *   a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or
     *   {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon
     *   a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the address zero.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// lib/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol

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

// lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol

// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/utils/SafeERC20.sol)

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    /**
     * @dev An operation with an ERC20 token failed.
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

// lib/ingredients/ProtocolContract_v1.sol

/**
 * Abstract protocol contract is Ownable and ReentrancyGuard and has virtual functions that allow
 * the Owner to transfer ERC20 and ERC721 tokens from this contract to any recipient.
 *
 * The aim is to collect tokens mistakenly sent to a child contract. The contracts that inherit from
 * this contract must consider what tokens need to be safeguarded from being withdrawable by the
 * Owner and thus override the virtual transfer functions defined in this contract.
 */
abstract contract ProtocolContract_v1 is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    error AmountToTransferExceedsContractBalance(
        uint256 _amount,
        uint256 _balance
    );
    error CannotSendToSelf();
    error OwnerApproveAndCallArraysMismatch(
        uint256 _tokensLength,
        uint256 _spendersLength,
        uint256 _amountsLength
    );
    error OwnerFailedToApproveAndCall(
        address _token,
        address _spender,
        uint256 _amount
    );
    error OwnerFailedToSendGasToken();
    error OwnerTransferArraysMismatch(
        uint256 _tokensLength,
        uint256 _amountsLength,
        uint256 _recipientsLength
    );

    event OwnerTransferredNft(
        address indexed _token,
        address indexed _to,
        uint256 indexed _nftId
    );
    event OwnerTransferredTokens(
        address indexed _token,
        address indexed _to,
        uint256 indexed _amount
    );

    constructor(address _initialOwner) Ownable(_initialOwner) {}

    /*
    //////////////////////////
    /// External functions ///
    //////////////////////////
    */

    fallback() external payable virtual {}

    receive() external payable virtual {}

    /* External virtual function called by Owner to transfer NFTs from this contract
     */
    function transferNfts(
        address[] calldata _nfts,
        address[] calldata _recipients,
        uint256[] calldata _nftIds
    ) external virtual nonReentrant onlyOwner {
        if (
            _nfts.length != _nftIds.length || _nfts.length != _recipients.length
        ) {
            revert OwnerTransferArraysMismatch(
                _nfts.length,
                _nftIds.length,
                _recipients.length
            );
        }
        for (uint256 i = 0; i < _nfts.length; ) {
            IERC721(_nfts[i]).safeTransferFrom(
                address(this),
                _recipients[i],
                _nftIds[i]
            );

            emit OwnerTransferredNft(_nfts[i], _recipients[i], _nftIds[i]);

            unchecked {
                ++i;
            }
        }
    }

    /* External virtual function called by Owner to transfer tokens from this contract
     */
    function transferTokens(
        address[] calldata _tokens,
        address[] calldata _recipients,
        uint256[] calldata _amounts
    ) external virtual nonReentrant onlyOwner {
        if (
            _tokens.length != _amounts.length ||
            _tokens.length != _recipients.length
        ) {
            revert OwnerTransferArraysMismatch(
                _tokens.length,
                _amounts.length,
                _recipients.length
            );
        }
        for (uint256 i = 0; i < _tokens.length; ) {
            if (_recipients[i] == address(this)) {
                revert CannotSendToSelf();
            }
            uint256 contractBalance = _tokens[i] == address(0)
                ? address(this).balance
                : IERC20(_tokens[i]).balanceOf(address(this));
            if (_amounts[i] > contractBalance) {
                revert AmountToTransferExceedsContractBalance(
                    _amounts[i],
                    contractBalance
                );
            }
            if (_tokens[i] == address(0)) {
                // native token
                (bool sent, ) = payable(_recipients[i]).call{
                    value: _amounts[i]
                }("");
                if (!sent) {
                    revert OwnerFailedToSendGasToken();
                }
            } else {
                if (_recipients[i] != address(0)) {
                    IERC20(_tokens[i]).safeTransfer(
                        _recipients[i],
                        _amounts[i]
                    );
                } else {
                    IERC20(_tokens[i]).transfer(_recipients[i], _amounts[i]);
                }
            }

            emit OwnerTransferredTokens(
                _tokens[i],
                _recipients[i],
                _amounts[i]
            );

            unchecked {
                ++i;
            }
        }
    }

    /* External function that allows Owner to approve and call a contract to perform actions with
     * this contract's tokens
     */
    function approveTokenAndCall(
        address _token,
        address _spender,
        uint256 _amount,
        bytes calldata _data
    ) external nonReentrant onlyOwner {
        bool success;
        if (_token != address(0)) {
            IERC20(_token).approve(_spender, _amount);
            (success, ) = _spender.call(_data);
        } else {
            (success, ) = _spender.call{value: _amount}(_data);
        }
        if (!success) {
            revert OwnerFailedToApproveAndCall(_token, _spender, _amount);
        }
    }

    /* External function that allows Owner to approve many tokens and call contracts to perform
     * actions with those tokens held by this contract
     */
    function approveManyTokensAndCall(
        address[] calldata _tokens,
        address[] calldata _spenders,
        uint256[] calldata _amounts,
        bytes[] calldata _data
    ) external nonReentrant onlyOwner {
        bool success;
        if (
            _tokens.length != _spenders.length ||
            _spenders.length != _amounts.length ||
            _amounts.length != _data.length
        ) {
            revert OwnerApproveAndCallArraysMismatch(
                _tokens.length,
                _spenders.length,
                _amounts.length
            );
        }
        for (uint256 i = 0; i < _tokens.length; ) {
            if (_tokens[i] != address(0)) {
                if (_amounts[i] > 0) {
                    IERC20(_tokens[i]).approve(_spenders[i], _amounts[i]);
                }
                (success, ) = _spenders[i].call(_data[i]);
            } else {
                (success, ) = _spenders[i].call{value: _amounts[i]}(_data[i]);
            }
            if (!success) {
                revert OwnerFailedToApproveAndCall(
                    _tokens[i],
                    _spenders[i],
                    _amounts[i]
                );
            }
            unchecked {
                ++i;
            }
        }
    }
}

// src/IlmSale.sol

/**
 * Sale contract for ILM token. The goal is to sell 20% of the max supply (1,333,333) of ILM to 
 * raise 200 ETH, with each ILM token thus priced at ~0.00015 ETH. Upon sale completion, liquidity 
 * will be added on Uniswap with 5% of the max supply (333,333) of ILM against 50 ETH, giving
 * ILM a circulating marketcap of 250 ETH, with an FDV of 1000 ETH.
 *
 * Once liquidity is deployed, the LP tokens received from Uniswap will be burned, locking liquidity
 * permanently. If liquidity is deployed before all ILM tokens are sold, the remaining ILM tokens
 * will be burned.
 */
contract IlmSale is ProtocolContract_v1 {

    using SafeERC20 for IERC20;

    struct _buyerInfo {
        uint256 buyLimit;
        uint256 ethContribution;
        bool ilmWithdrawn;
    }

    error BuyLimitArraysLengthMismatch(uint256 _investorsLength, uint256 _newBuyLimitsLength);
    error FailedToDeployLiquidity();
    error IlmTokensAlreadyWithdrawn();
    error InvalidBuyAmount();
    error LiquidityAlreadyDeployed();
    error LiquidityNotYetDeployed();
    error NotInvestor();
    error SaleEnded();
    error SaleOngoing();
    error UniswapRouterAddressInvalid();

    mapping(address => _buyerInfo) public buyerInfo; // buyer => buyer info

    bool public onlyWhitelisted; // only investors with Owner-set buy limits can buy while true
    bool public isSaleOngoing; // sale is ongoing while true
    address public ilmTokenAddress; // ILM token address
    address public uniswapRouterAddress; // Uniswap router address
    address public lpTokenAddress; // LP token address (ILM-ETH pair), set by Uniswap
    uint256 public saleLimit; // max ETH to be raised
    uint256 public defaultBuyLimit; // default buy limit for non-whitelisted
    uint256 public totalEthContribution; // total ETH raised
    
    IUniswapV2Router02 public uniswapRouter;

    event IlmBought(address indexed _buyer, uint256 indexed _amount);
    event IlmSaleTokensClaimed(address indexed _buyer, uint256 indexed _amount);
    event IlmSaleFinalized(uint256 indexed _totalEthRaised, uint256 indexed _endTime);

    constructor() ProtocolContract_v1(0xF9dE78c2531A7042bB6D425F17f70D8AF528b911) {
        ilmTokenAddress = 0x6660f37a534EF95f3Fb5C499D1DdD981098c5666;
        uniswapRouterAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        saleLimit = 200 ether;
        defaultBuyLimit = 2 ether;
        onlyWhitelisted = true;
        isSaleOngoing = true;
        uniswapRouter = IUniswapV2Router02(uniswapRouterAddress);
    }

    /*
    //////////////////////////
    /// External functions ///
    //////////////////////////
    */

    /* External function to end sale, callable only by Owner
     */
    function endSale()
        external
        onlyOwner
        liquidityNotDeployed 
    {
        isSaleOngoing = false;
    }

    /* External payable function to buy ILM tokens, callable by anyone during the sale
     */
    fallback()
        external
        override
        payable
        nonReentrant
    {
        if (totalEthContribution < saleLimit &&
            isSaleOngoing
        ) { // sale is ongoing
            uint256 userBuyLimit = 0;
            if (onlyWhitelisted) {
                userBuyLimit = buyerInfo[msg.sender].buyLimit;
            } else {
                userBuyLimit = buyerInfo[msg.sender].buyLimit + defaultBuyLimit;
            }
            if (
                buyerInfo[msg.sender].ethContribution + msg.value <= userBuyLimit && 
                totalEthContribution + msg.value <= saleLimit    
            ) {
                buyerInfo[msg.sender].ethContribution += msg.value;
                totalEthContribution += msg.value;

                emit IlmBought(msg.sender, msg.value);
            } else {
                revert InvalidBuyAmount();
            }
        } else {
            revert SaleEnded();
        }
    }

    /* External function to finalize the sale and add liquidity on Uniswap, callable by the Owner.
     */
    function finalize(uint256 _ilmTokenAmount, uint256 _ethAmount)
        external
        nonReentrant
        liquidityNotDeployed
        onlyOwner
    {
        isSaleOngoing = false;
        
        IERC20(ilmTokenAddress).approve(address(uniswapRouter), _ilmTokenAmount);
        uniswapRouter.addLiquidityETH{value: _ethAmount}(
            ilmTokenAddress,
            _ilmTokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp
        );

        lpTokenAddress =
          IUniswapV2Factory(uniswapRouter.factory()).getPair(ilmTokenAddress, uniswapRouter.WETH());
        
        if (lpTokenAddress == address(0) || 
            IERC20(lpTokenAddress).balanceOf(address(this)) == 0) {
            revert FailedToDeployLiquidity();
        }

        IERC20(lpTokenAddress).transfer(address(0x000000000000000000000000000000000000dEaD),
            IERC20(lpTokenAddress).balanceOf(address(this)));

        emit IlmSaleFinalized(totalEthContribution, block.timestamp);
    }

    /* External view function that returns buyer info struct for a user
     */
    function getBuyerInfo(address _buyer)
        external
        view
        returns (_buyerInfo memory)
    {
        return buyerInfo[_buyer];
    }

    /* External payable function to buy ILM tokens, callable by anyone during the sale
     */
    receive()
        external
        override
        payable
        nonReentrant
    {
        if (totalEthContribution < saleLimit &&
            isSaleOngoing
        ) { // sale is ongoing
            uint256 userBuyLimit = 0;
            if (onlyWhitelisted) {
                userBuyLimit = buyerInfo[msg.sender].buyLimit;
            } else {
                userBuyLimit = buyerInfo[msg.sender].buyLimit + defaultBuyLimit;
            }
            if (
                buyerInfo[msg.sender].ethContribution + msg.value <= userBuyLimit && 
                totalEthContribution + msg.value <= saleLimit    
            ) {
                buyerInfo[msg.sender].ethContribution += msg.value;
                totalEthContribution += msg.value;

                emit IlmBought(msg.sender, msg.value);
            } else {
                revert InvalidBuyAmount();
            }
        } else {
            revert SaleEnded();
        }
    }

    /* External function called by Owner to set the buy limit for an investor
     */
    function setBuyLimits(address[] calldata _investors, uint256[] calldata _newBuyLimits)
        external
        onlyOwner
        liquidityNotDeployed
    {
        if (_investors.length != _newBuyLimits.length) {
            revert BuyLimitArraysLengthMismatch(_investors.length, _newBuyLimits.length);
        }
        for (uint256 i = 0; i < _investors.length; ) {
            buyerInfo[_investors[i]].buyLimit = _newBuyLimits[i];
            unchecked {
                ++i;
            }
        }
    }

    /* External function called by Owner to set the default buy limit for non-whitelisted investors
     */
    function setDefaultBuyLimit(uint256 _defaultBuyLimit)
        external
        onlyOwner
        liquidityNotDeployed
    {
        defaultBuyLimit = _defaultBuyLimit;
    }
    

    /* External function called by Owner to set the ILM token address
     */
    function setIlmTokenAddress(address _ilmTokenAddress)
        external
        onlyOwner
        liquidityNotDeployed
    {
        ilmTokenAddress = _ilmTokenAddress;
    }

    /* External function called by Owner to set the onlyWhitelisted flag
     */
    function setOnlyWhitelisted(bool _onlyWhitelisted)
        external
        onlyOwner
        liquidityNotDeployed
    {
        onlyWhitelisted = _onlyWhitelisted;
    }

    /* External function called by Owner to set the sale limit
     */
    function setSaleLimit(uint256 _saleLimit)
        external
        onlyOwner
        liquidityNotDeployed
    {
        saleLimit = _saleLimit;
    }

    /* External function called by Owner to set the Uniswap router address
     */
    function setUniswapRouterAddress(address _uniswapRouterAddress)
        external
        onlyOwner
        liquidityNotDeployed
    {
        uniswapRouterAddress = _uniswapRouterAddress;
        uniswapRouter = IUniswapV2Router02(uniswapRouterAddress);
    }

    /* Buyers can withdraw ILM tokens from this contract after liquidity is deployed
     */
    function withdrawIlmTokens() external
        nonReentrant
        liquidityDeployed
    {
        if (buyerInfo[msg.sender].ethContribution == 0) {
            revert NotInvestor();
        }
        if (buyerInfo[msg.sender].ilmWithdrawn) {
            revert IlmTokensAlreadyWithdrawn();
        }
        uint256 userIlmAmountWithdrawable =
            buyerInfo[msg.sender].ethContribution * 1333333 ether / saleLimit;
        
        buyerInfo[msg.sender].ilmWithdrawn = true;
        
        IERC20(ilmTokenAddress).transfer(msg.sender, userIlmAmountWithdrawable);

        emit IlmSaleTokensClaimed(msg.sender, userIlmAmountWithdrawable);
    }

    /*
    //////////////////
    /// Modifiers  ///
    //////////////////
    */

    /* Modifier to check if liquidity is deployed
     */
    modifier liquidityDeployed()
    {
        if (lpTokenAddress == address(0)) {
            revert LiquidityNotYetDeployed();
        }
        _;
    }

    /* Modifier to check if liquidity is not deployed
     */
    modifier liquidityNotDeployed()
    {
        if (lpTokenAddress != address(0)) {
            revert LiquidityAlreadyDeployed();
        }
        _;
    }
}