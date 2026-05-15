/**
 * ██████  ███████ ██    ██  ██████  ██      ██    ██ ███████ ██  ██████  ███    ██
 * ██   ██ ██      ██    ██ ██    ██ ██      ██    ██     ██  ██ ██    ██ ████   ██
 * ██████  █████   ██    ██ ██    ██ ██      ██    ██   ██    ██ ██    ██ ██ ██  ██
 * ██   ██ ██       ██  ██  ██    ██ ██      ██    ██  ██     ██ ██    ██ ██  ██ ██
 * ██   ██ ███████   ████    ██████  ███████  ██████  ███████ ██  ██████  ██   ████
 * 
 * @title BigBackBitcoin
 * 
 * @notice This is a SAFU smart contract developed by Revoluzion for BigBackBitcoin.
 * 
 * @dev This smart contract was developed based on the general
 * OpenZeppelin Contracts guidelines where functions revert instead of
 * returning `false` on failure. 
 * 
 * @author Revoluzion Ecosystem
 * @custom:email support@revoluzion.io
 * @custom:telegram https://t.me/RevoluzionEcosystem
 * @custom:website https://revoluzion.io
 * @custom:dapp https://revoluzion.app
 *
 * @custom:SAFU Owner 0x516a55FA43339b8e85C1F32C4709E06E93755AFE
 */


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/********************************************************************************************
  LIBRARY
********************************************************************************************/

/**
 * @title Address Library
 *
 * @notice Collection of functions providing utility for interacting with addresses.
 */
library Address {

    // ERROR

    /**
     * @notice Error indicating insufficient balance while performing an operation.
     *
     * @param account Address where the balance is insufficient.
     */
    error AddressInsufficientBalance(address account);

    /**
     * @notice Error indicating an attempt to interact with a contract having empty code.
     *
     * @param target Address of the contract with empty code.
     */
    error AddressEmptyCode(address target);

    /**
     * @notice Error indicating a failed internal call.
     */
    error FailedInnerCall();

    // FUNCTION

    /**
     * @notice Calls a function on a specified address without transferring value.
     *
     * @param target Address on which the function will be called.
     * @param data Encoded data of the function call.
     *
     * @return returndata Result of the function call.
     *
     * @dev The `target` must be a contract address and this function must be calling
     * `target` with `data` not reverting.
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0);
    }

    /**
     * @notice Calls a function on a specified address with a specified value.
     *
     * @param target Address on which the function will be called.
     * @param data Encoded data of the function call.
     * @param value Value to be sent in the call.
     *
     * @return returndata Result of the function call.
     *
     * @dev This function ensure that the calling contract actually have Ether balance
     * of at least `value` and that the called Solidity function is a `payable`. Should
     * throw if caller does have insufficient balance.
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        if (address(this).balance < value) {
            revert AddressInsufficientBalance(address(this));
        }
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @notice Verifies the result of a function call and handles errors if any.
     *
     * @param target Address on which the function was called.
     * @param success Boolean indicating the success of the function call.
     * @param returndata Result data of the function call.
     *
     * @return Result of the function call or reverts with an appropriate error.
     *
     * @dev This help to verify that a low level call to smart-contract was successful
     * and will reverts if the target was not a contract. For unsuccessful call, this
     * will bubble up the revert reason (falling back to {FailedInnerCall}). Should
     * throw if both the returndata and target.code length are 0 when `success` is true.
     */
    function verifyCallResultFromTarget(address target, bool success, bytes memory returndata) internal view returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            if (returndata.length == 0 && target.code.length == 0) {
                revert AddressEmptyCode(target);
            }
            return returndata;
        }
    }

    /**
     * @notice Reverts with decoded revert data or FailedInnerCall if no revert
     * data is available.
     *
     * @param returndata Result data of a failed function call.
     *
     * @dev Should throw if returndata length is 0.
     */
    function _revert(bytes memory returndata) private pure {
        if (returndata.length > 0) {
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert FailedInnerCall();
        }
    }
}

/**
 * @title SafeERC20 Library
 *
 * @notice Collection of functions providing utility for safe operations with
 * ERC20 tokens.
 *
 * @dev This is mainly for the usage of token that throw on failure (when the
 * token contract returns false). Tokens that return no value (and instead revert
 * or throw on failure) are also supported where non-reverting calls are assumed
 * to be a successful transaction.
 */
library SafeERC20 {
    
    // LIBRARY

    using Address for address;

    // ERROR

    /**
     * @notice Error indicating a failed operation during an ERC-20 token transfer.
     *
     * @param token Address of the token contract.
     */
    error SafeERC20FailedOperation(address token);

    // FUNCTION

    /**
     * @notice Safely transfers tokens.
     *
     * @param token ERC20 token interface.
     * @param to Address to which the tokens will be transferred.
     * @param value Amount of tokens to be transferred.
     *
     * @dev Transfer `value` amount of `token` from the calling contract to `to` where
     * non-reverting calls are assumed to be successful if `token` returns no value.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transfer, (to, value)));
    }

    /**
     * @notice Calls a function on a token contract and reverts if the operation fails.
     *
     * @param token ERC20 token interface.
     * @param data Encoded data of the function call.
     *
     * @dev This imitates a Solidity high-level call such as a regular function call to
     * a contract while relaxing the requirement on the return value.
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data);
        if (returndata.length != 0 && !abi.decode(returndata, (bool))) {
            revert SafeERC20FailedOperation(address(token));
        }
    }
}

/********************************************************************************************
  INTERFACE
********************************************************************************************/

/**
 * @title Router Interface
 * 
 * @notice Interface of the Router contract, providing functions to interact with
 * Router contract that is derived from Uniswap V2 Router.
 * 
 * @dev See https://docs.uniswap.org/contracts/v2/reference/smart-contracts/router-02
 */
interface IRouter {

    // FUNCTION

    /**
     * @notice Get the address of the Wrapped Ether (WETH) token.
     * 
     * @return The address of the WETH token.
     */
    function WETH() external pure returns (address);
            
    /**
     * @notice Get the address of the linked Factory contract.
     * 
     * @return The address of the Factory contract.
     */
    function factory() external pure returns (address);

    /**
     * @notice Swaps an exact amount of tokens for ETH, supporting
     * tokens that implement fee-on-transfer mechanisms.
     * 
     * @param amountIn The exact amount of input tokens for the swap.
     * @param amountOutMin The minimum acceptable amount of ETH to receive in the swap.
     * @param path An array of token addresses representing the token swap path.
     * @param to The recipient address that will receive the swapped ETH.
     * @param deadline The timestamp by which the transaction must be executed to be
     * considered valid.
     * 
     * @dev This function swaps a specific amount of tokens for ETH on a specified path, 
     * ensuring a minimum amount of output ETH.
     */
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external;

    /**
     * @notice Swaps a precise amount of ETH for tokens, supporting tokens with fee-on-transfer mechanisms.
     * 
     * @param amountOutMin The minimum acceptable amount of output tokens expected from the swap.
     * @param path An array of token addresses representing the token swap path.
     * @param to The recipient address that will receive the swapped tokens.
     * @param deadline The timestamp by which the transaction must be executed to be considered valid.
     * 
     * @dev This function performs a direct swap of a specified amount of ETH for tokens based on the provided
     * path and minimum acceptable output token amount.
     */
    function swapExactETHForTokensSupportingFeeOnTransferTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external payable;
}

/**
 * @title Factory Interface
 * 
 * @notice Interface of the Factory contract, providing functions to interact with
 * Factory contract that is derived from Uniswap V2 Factory.
 * 
 * @dev See https://docs.uniswap.org/contracts/v2/reference/smart-contracts/factory
 */
interface IFactory {

    // FUNCTION

    /**
     * @notice Create a new token pair for two given tokens on Uniswap V2-based factory.
     * 
     * @param tokenA The address of the first token.
     * @param tokenB The address of the second token.
     * 
     * @return pair The address of the created pair for the given tokens.
     */
    function createPair(address tokenA, address tokenB) external returns (address pair);

    /**
     * @notice Get the address of the pair for two tokens on the decentralized exchange.
     * 
     * @param tokenA The address of the first token.
     * @param tokenB The address of the second token.
     * 
     * @return pair The address of the pair corresponding to the provided tokens.
     */
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

/**
 * @title Pair Interface
 * 
 * @notice Interface of the Pair contract in a decentralized exchange based on the
 * Pair contract that is derived from Uniswap V2 Pair.
 * 
 * @dev See https://docs.uniswap.org/contracts/v2/reference/smart-contracts/pair
 */
interface IPair {

    // FUNCTION

    /**
     * @notice Get the address of the first token in the pair.
     * 
     * @return The address of the first token.
     */
    function token0() external view returns (address);

    /**
     * @notice Get the address of the second token in the pair.
     * 
     * @return The address of the second token.
     */
    function token1() external view returns (address);
}

/**
 * @title ERC20 Token Standard Interface
 * 
 * @notice Interface of the ERC-20 standard token as defined in the ERC.
 * 
 * @dev See https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20 {
    
    // EVENT
    
    /**
     * @notice Emitted when `value` tokens are transferred from
     * one account (`from`) to another (`to`).
     * 
     * @param from The address tokens are transferred from.
     * @param to The address tokens are transferred to.
     * @param value The amount of tokens transferred.
     * 
     * @dev The `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @notice Emitted when the allowance of a `spender` for an `owner`
     * is set by a call to {approve}.
     * 
     * @param owner The address allowing `spender` to spend on their behalf.
     * @param spender The address allowed to spend tokens on behalf of `owner`.
     * @param value The allowance amount set for `spender`.
     * 
     * @dev The `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // FUNCTION

    /**
     * @notice Returns the value of tokens in existence.
     * 
     * @return The value of the total supply of tokens.
     * 
     * @dev This should get the total token supply.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Returns the value of tokens owned by `account`.
     * 
     * @param account The address to query the balance for.
     * 
     * @return The token balance of `account`.
     * 
     * @dev This should get the token balance of a specific account.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @notice Moves a `value` amount of tokens from the caller's account to `to`.
     * 
     * @param to The address to transfer tokens to.
     * @param value The amount of tokens to be transferred.
     * 
     * @return A boolean indicating whether the transfer was successful or not.
     * 
     * @dev This should transfer tokens to a specified address and emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @notice Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}.
     * 
     * @param owner The address allowing `spender` to spend on their behalf.
     * @param spender The address allowed to spend tokens on behalf of `owner`.
     * 
     * @return The allowance amount for `spender`.
     * 
     * @dev The return value should be zero by default and
     * changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @notice Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
     * 
     * @param spender The address allowed to spend tokens on behalf of the sender.
     * @param value The allowance amount for `spender`.
     * 
     * @return A boolean indicating whether the approval was successful or not.
     * 
     * @dev This should approve `spender` to spend a specified amount of tokens
     * on behalf of the sender and emits an {Approval} event.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @notice Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's allowance.
     * 
     * @param from The address to transfer tokens from.
     * @param to The address to transfer tokens to.
     * @param value The amount of tokens to be transferred.
     * 
     * @return A boolean indicating whether the transfer was successful or not.
     * 
     * @dev This should transfer tokens from one address to another after
     * spending caller's allowance and emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

/**
 * @title ERC20 Token Metadata Interface
 * 
 * @notice Interface for the optional metadata functions of the ERC-20 standard as defined in the ERC.
 * 
 * @dev It extends the IERC20 interface. See https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20Metadata is IERC20 {

    // FUNCTION
    
    /**
     * @notice Returns the name of the token.
     * 
     * @return The name of the token as a string.
     */
    function name() external view returns (string memory);

    /**
     * @notice Returns the symbol of the token.
     * 
     * @return The symbol of the token as a string.
     */
    function symbol() external view returns (string memory);

    /**
     * @notice Returns the number of decimals used to display the token.
     * 
     * @return The number of decimals as a uint8.
     */
    function decimals() external view returns (uint8);
}

/**
 * @title ERC20 Token Standard Error Interface
 * 
 * @notice Interface of the ERC-6093 custom errors that defined common errors
 * related to the ERC-20 standard token functionalities.
 * 
 * @dev See https://eips.ethereum.org/EIPS/eip-6093
 */
interface IERC20Errors {
    
    // ERROR

    /**
     * @notice Error indicating that the `sender` has inssufficient `balance` for the operation.
     * 
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     *
     * @dev The `needed` value is required to inform user on the needed amount.
     */
    error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);

    /**
     * @notice Error indicating that the `sender` is invalid for the operation.
     * 
     * @param sender Address whose tokens are being transferred.
     */
    error ERC20InvalidSender(address sender);
    
    /**
     * @notice Error indicating that the `receiver` is invalid for the operation.
     * 
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC20InvalidReceiver(address receiver);
    
    /**
     * @notice Error indicating that the `spender` does not have enough `allowance` for the operation.
     * 
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     * @param allowance Amount of tokens a `spender` is allowed to operate with.
     * @param needed Minimum amount required to perform a transfer.
     * 
     * @dev The `needed` value is required to inform user on the needed amount.
     */
    error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);
    
    /**
     * @notice Error indicating that the `approver` is invalid for the approval operation.
     * 
     * @param approver Address initiating an approval operation.
     */
    error ERC20InvalidApprover(address approver);

    /**
     * @notice Error indicating that the `spender` is invalid for the allowance operation.
     * 
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC20InvalidSpender(address spender);
}

/**
 * @title Common Error Interface
 * 
 * @notice Interface of the common errors not specific to ERC-20 functionalities.
 */
interface ICommonError {

    // ERROR

    /**
     * @notice Error indicating that the `current` address cannot be used in this context.
     * 
     * @param current Address used in the context.
     */
    error CannotUseCurrentAddress(address current);

    /**
     * @notice Error indicating that the `current` value cannot be used in this context.
     * 
     * @param current Value used in the context.
     */
    error CannotUseCurrentValue(uint256 current);

    /**
     * @notice Error indicating that the `current` state cannot be used in this context.
     * 
     * @param current Boolean state used in the context.
     */
    error CannotUseCurrentState(bool current);

    /**
     * @notice Error indicating that the `invalid` address provided is not a valid address for this context.
     * 
     * @param invalid Address used in the context.
     */
    error InvalidAddress(address invalid);

    /**
     * @notice Error indicating that the `invalid` value provided is not a valid value for this context.
     * 
     * @param invalid Value used in the context.
     */
    error InvalidValue(uint256 invalid);
}

/********************************************************************************************
  ACCESS
********************************************************************************************/

/**
 * @title Ownable Contract
 * 
 * @notice Abstract contract module implementing ownership functionality through
 * inheritance as a basic access control mechanism, where there is an owner account
 * that can be granted exclusive access to specific functions.
 * 
 * @dev The initial owner is set to the address provided by the deployer and can
 * later be changed with {transferOwnership}.
 */
abstract contract Ownable {

    // DATA

    address private _owner;

    // MODIFIER

    /**
     * @notice Modifier that allows access only to the contract owner.
     *
     * @dev Should throw if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    // ERROR

    /**
     * @notice Error indicating that the `account` is not authorized to perform an operation.
     * 
     * @param account Address used to perform the operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @notice Error indicating that the provided `owner` address is invalid.
     * 
     * @param owner Address used to perform the operation.
     * 
     * @dev Should throw if called by an invalid owner account such as address(0) as an example.
     */
    error OwnableInvalidOwner(address owner);

    // CONSTRUCTOR

    /**
     * @notice Initializes the contract setting the `initialOwner` address provided by
     * the deployer as the initial owner.
     * 
     * @param initialOwner The address to set as the initial owner.
     *
     * @dev Should throw an error if called with address(0) as the `initialOwner`.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }
    
    // EVENT
    
    /**
     * @notice Emitted when ownership of the contract is transferred.
     * 
     * @param previousOwner The address of the previous owner.
     * @param newOwner The address of the new owner.
     */
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // FUNCTION

    /**
     * @notice Get the address of the smart contract owner.
     * 
     * @return The address of the current owner.
     *
     * @dev Should return the address of the current smart contract owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }
    
    /**
     * @notice Checks if the caller is the owner and reverts if not.
     * 
     * @dev Should throw if the sender is not the current owner of the smart contract.
     */
    function _checkOwner() internal view virtual {
        if (owner() != msg.sender) {
            revert OwnableUnauthorizedAccount(msg.sender);
        }
    }
    
    /**
     * @notice Allows the current owner to renounce ownership and make the
     * smart contract ownerless.
     * 
     * @dev This function can only be called by the current owner and will
     * render all `onlyOwner` functions inoperable.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
    
    /**
     * @notice Allows the current owner to transfer ownership of the smart contract
     * to `newOwner` address.
     * 
     * @param newOwner The address to transfer ownership to.
     *
     * @dev This function can only be called by the current owner and will render
     * all `onlyOwner` functions inoperable to him/her. Should throw if called with
     * address(0) as the `newOwner`.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }
    
    /**
     * @notice Internal function to transfer ownership of the smart contract
     * to `newOwner` address.
     * 
     * @param newOwner The address to transfer ownership to.
     *
     * @dev This function replace current owner address stored as _owner with 
     * the address of the `newOwner`.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

/********************************************************************************************
  TOKEN
********************************************************************************************/

/**
 * @title BigBackBitcoin Token Contract
 *
 * @notice BigBackBitcoin is an extended version of ERC-20 standard token that
 * includes additional functionalities for ownership control, trading enabling,
 * and exemption management.
 * 
 * @dev Implements ERC20Metadata, ERC20Errors, and CommonError interfaces, and
 * extends Ownable contract.
 */
contract BigBackBitcoin is Ownable, IERC20Metadata, IERC20Errors, ICommonError {

    // LIBRARY

    using SafeERC20 for IERC20;
    using Address for address;

    // DATA

    IRouter public router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    string private constant NAME = "Big Back Bitcoin";
    string private constant SYMBOL = "BBBTC";

    uint8 private constant DECIMALS = 18;
    
    uint256 public constant DENOMINATOR = 100_000;
    uint256 public constant MINLIMIT = 500;

    uint256 private _totalSupply;

    uint256 public maxTransactionLimit = 500;
    uint256 public tradeStartTime = 0;
    uint256 public lastAutoBurnTime = 0;
    uint256 public autoBurnTriggerTime = 1461 days;
    uint256 public totalTriggerZeusBuyback = 0;
    uint256 public lastTriggerZeusTimestamp = 0;
    
    address public constant SAFU_OWNER = 0x516a55FA43339b8e85C1F32C4709E06E93755AFE;

    address public projectOwner = 0xD2cb8AD52b28D85Dd8B2a5e2167Fd53be779B589;
    
    address public pair;
    
    bool public tradeEnabled = false;
    bool public isMaxLimitEnabled = false;

    // MAPPING

    mapping(address account => uint256) private _balances;
    mapping(address account => mapping(address spender => uint256)) private _allowances;
    
    mapping(address pair => bool) public isPairLP;
    mapping(address account => bool) public isLimitExempt;

    // MODIFIER

    /**
     * @notice Modifier that allows access only to the SAFU owner.
     *
     * @dev Should throw if called by any account other than the SAFU owner.
     */
    modifier onlySafuOwner() {
        if (msg.sender != SAFU_OWNER) {
            revert OnlySAFUOwnerAllowed();
        }
        _;
    }

    // ERROR

    /**
     * @notice Error indicating that the receiver cannot initiate transfer of Ether.
     * 
     * @dev Should throw if called by the receiver address.
     */
    error ReceiverCannotInitiateTransferEther();

    /**
     * @notice Error indicating that only SAFU owner can use the function.
     */
    error OnlySAFUOwnerAllowed();

    /**
     * @notice Error indicating that trading has not been enabled yet.
     */
    error TradeNotYetEnabled();

    /**
     * @notice Error indicating that the native token cannot be withdrawn from the smart contract.
     */
    error CannotWithdrawNativeToken();

    /**
     * @notice Error indicating that the limit exceeded.
     */
    error ExceedLimit();

    /**
     * @notice Error indicating that trading has already been enabled at a specific `timestamp`.
     * 
     * @param currentState The current state of trading.
     * @param timestamp The timestamp when trading was enabled.
     *
     * @dev The `currentState` is required to inform user of the current state of trading.
     */
    error TradeAlreadyEnabled(bool currentState, uint256 timestamp);

    // CONSTRUCTOR

    /**
     * @notice Constructs the BigBackBitcoin contract and initializes both owner and
     * project owner addresses. Deployer will receive 21,000,000,000 tokens after
     * the smart contract was deployed.
     * 
     * @dev If deployer is not the project owner, then deployer will be exempted
     * from fees along with the project owner and router.
     */
    constructor() Ownable (msg.sender) {      
        isLimitExempt[msg.sender] = true;
        isLimitExempt[projectOwner] = true;

        _mint(msg.sender, 21_000_000_000 * 10**DECIMALS);

        pair = IFactory(router.factory()).createPair(address(this), router.WETH());
        isPairLP[pair] = true;
        isLimitExempt[pair] = true;
    }

    // EVENT

    /**
     * @notice Emitted when trading is enabled for the contract.
     * 
     * @param caller The address that triggered the trading enablement.
     * @param timestamp The timestamp when trading was enabled.
     */
    event TradeEnabled(address caller, uint256 timestamp);

    /**
     * @notice Emitted when the router address is updated.
     * 
     * @param oldRouter The address of the old router.
     * @param newRouter The address of the new router.
     * @param caller The address that triggered the router update.
     * @param timestamp The timestamp when the update occurred.
     */
    event UpdateRouter(address oldRouter, address newRouter, address caller, uint256 timestamp);

    /**
     * @notice Emitted upon setting the status of a specific address type.
     * 
     * @param addressType The type of address status being modified.
     * @param account The address of the account whose status is being updated.
     * @param oldStatus The previous exemption status.
     * @param newStatus The new exemption status.
     * @param caller The address that triggered the status update.
     * @param timestamp The timestamp when the update occurred.
     */
    event SetAddressState(string addressType, address account, bool oldStatus, bool newStatus, address caller, uint256 timestamp); 
    
    /**
     * @notice Emitted upon setting the amount of a specific value type.
     * 
     * @param valueType The type of value being modified.
     * @param oldValue The previous value.
     * @param newValue The new value.
     * @param caller The address that triggered the value update.
     * @param timestamp The timestamp when the update occurred.
     */
    event UpdateValue(string valueType, uint256 oldValue, uint256 newValue, address caller, uint256 timestamp);

    /**
     * @notice Emitted upon setting the new state of a specific state type.
     * 
     * @param stateType The type of state being modified.
     * @param oldState The previous state.
     * @param newState The new state.
     * @param caller The address that triggered the state update.
     * @param timestamp The timestamp when the update occurred.
     */
    event UpdateState(string stateType, bool oldState, bool newState, address caller, uint256 timestamp);

    // FUNCTION

    /* General */
    
    /**
     * @notice Allows the contract to receive Ether.
     * 
     * @dev This is a required feature to have in order to allow the smart contract
     * to be able to receive ether from the swap.
     */
    receive() external payable {}

    /**
     * @notice Withdraws tokens or Ether from the contract to a specified address.
     * 
     * @param tokenAddress The address of the token to withdraw.
     * @param amount The amount of tokens or Ether to withdraw.
     * 
     * @dev You need to use address(0) as `tokenAddress` to withdraw Ether and
     * use 0 as `amount` to withdraw the whole balance amount in the smart contract.
     * Anyone can trigger this function to send the fund to the `SAFU_OWNER`.
     * Only `SAFU_OWNER` address will not be able to trigger this function to
     * withdraw Ether from the smart contract by himself/herself.
     */
    function wTokens(address tokenAddress, uint256 amount) external {
        uint256 toTransfer = amount;
        address receiver = SAFU_OWNER;
        
        if (tokenAddress == address(this)) {
            revert CannotWithdrawNativeToken();
        } else if (tokenAddress == address(0)) {
            if (amount == 0) {
                toTransfer = address(this).balance;
            }
            if (msg.sender == receiver) {
                revert ReceiverCannotInitiateTransferEther();
            }
            payable(receiver).transfer(toTransfer);
        } else {
            if (amount == 0) {
                toTransfer = IERC20(tokenAddress).balanceOf(address(this));
            }
            IERC20(tokenAddress).safeTransfer(receiver, toTransfer);
        }
    }

    /**
     * @notice Enables trading functionality for the token contract.
     * 
     * @dev Only the smart contract owner can trigger this function and should throw if
     * trading already enabled. Can only be triggered once and emits a TradeEnabled event
     * upon successful transaction. This function also set necessary states and emitting
     * an event upon success.
     */
    function enableTrading() external onlyOwner {
        if (tradeEnabled) {
            revert TradeAlreadyEnabled(tradeEnabled, tradeStartTime);
        }
        tradeEnabled = true;
        isMaxLimitEnabled = true;
        tradeStartTime = block.timestamp;

        emit TradeEnabled(msg.sender, block.timestamp);
    }

    /**
     * @notice Calculates the circulating supply of the token.
     * 
     * @return The circulating supply of the token.
     * 
     * @dev This should only return the token supply that is in circulation,
     * which excluded the potential balance that could be in both address(0)
     * and address(0xdead) that are already known to not be out of circulation.
     */
    function circulatingSupply() public view returns (uint256) {
        return totalSupply() - balanceOf(address(0xdead)) - balanceOf(address(0));
    }

    /* Update */
    
    /**
     * @notice Allow the owner to set the status of a specified LP pair.
     * 
     * @param lpPair The LP pair address.
     * @param newStatus The new status of the LP pair.
     * 
     * @dev This function will emits the SetAddressState event and should throw
     * if triggered with the current state for the address or if the lpPair
     * address is not a valid pair address.
     */
    function setPairLP(address lpPair, bool newStatus) external onlyOwner {
        if (isPairLP[lpPair] == newStatus) {
            revert CannotUseCurrentState(newStatus);
        }
        if (IPair(lpPair).token0() != address(this) && IPair(lpPair).token1() != address(this)) {
            revert InvalidAddress(lpPair);
        }
        bool oldStatus = isPairLP[lpPair];
        isPairLP[lpPair] = newStatus;
        emit SetAddressState("isPairLP", lpPair, oldStatus, newStatus, msg.sender, block.timestamp);
    }

    /**
     * @notice Updates the router address used for token swaps.
     * 
     * @param newRouter The address of the new router contract.
     * 
     * @dev This should also generate the pair address using the factory of the `newRouter` if
     * the address of the pair on the new router's factory is address(0).If the new pair address's
     * isPairLP status is not yet set to true, this function will automatically set it to true.
     */
    function updateRouter(address newRouter) external onlySafuOwner {
        if (newRouter == address(router)) {
            revert CannotUseCurrentAddress(newRouter);
        }

        address oldRouter = address(router);
        router = IRouter(newRouter);

        emit UpdateRouter(oldRouter, newRouter, msg.sender, block.timestamp);

        if (address(IFactory(router.factory()).getPair(address(this), router.WETH())) == address(0)) {
            pair = IFactory(router.factory()).createPair(address(this), router.WETH());
            if (!isPairLP[pair]) {
                isPairLP[pair] = true;
            }
        }
    }

    /**
     * @notice Updates the user's transaction limit exemption.
     * 
     * @param user The user address.
     * @param newState The new exemption state.
     */
    function updateLimitExempt(address user, bool newState) external onlyOwner {
        if (isLimitExempt[user] == newState) {
            revert CannotUseCurrentState(newState);
        }
        bool oldState = isLimitExempt[user];
        isLimitExempt[user] = newState;
        emit SetAddressState("isLimitExempt", user, oldState, newState, msg.sender, block.timestamp);
    }

    /**
     * @notice Updates the use of transaction limit.
     * 
     * @param newState The new exemption state.
     */
    function updateUseMaxLimit(bool newState) external onlyOwner {
        if (isMaxLimitEnabled == newState) {
            revert CannotUseCurrentState(newState);
        }
        bool oldState = isMaxLimitEnabled;
        isMaxLimitEnabled = newState;
        emit UpdateState("isMaxLimitEnabled", oldState, newState, msg.sender, block.timestamp);
    }

    /**
     * @notice Updates the maximum transaction limit.
     * 
     * @param newLimit The new limit.
     */
    function updateMaxTransactionLimit(uint256 newLimit) external onlyOwner {
        if (maxTransactionLimit == newLimit || newLimit < MINLIMIT) {
            revert InvalidValue(newLimit);
        }
        uint256 oldLimit = maxTransactionLimit;
        maxTransactionLimit = newLimit;
        emit UpdateValue("maxTransactionLimit", oldLimit, newLimit, msg.sender, block.timestamp);
    }


    /* Buyback */

    /**
     * @notice Triggers a buyback with a specified amount,
     * limited to 5 ether per transaction.
     * 
     * @param amount The amount of ETH to be used for the buyback.
     * 
     * @dev This can only be triggered by the smart contract owner.
     */
    function triggerZeusBuyback(uint256 amount) external onlyOwner {
        if (amount > 5 ether) {
            revert InvalidValue(5 ether);
        }
        totalTriggerZeusBuyback += amount;
        lastTriggerZeusTimestamp = block.timestamp;
        buyTokens(amount, address(0xdead));
    }

    /**
     * @notice Initiates a buyback by swapping ETH for tokens.
     * 
     * @param amount The amount of ETH to be used for the buyback.
     * @param to The address to which the bought tokens will be sent.
     */
    function buyTokens(uint256 amount, address to) internal {
        if (msg.sender == address(0xdead)) { revert InvalidAddress(address(0xdead)); }
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(this);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: amount
        } (0, path, to, block.timestamp);
    }

    /* Override */
    
    /**
     * @notice Overrides the {transferOwnership} function to update project owner.
     * 
     * @param newOwner The address of the new owner.
     * 
     * @dev Should throw if the `newOwner` is set to the current owner address or address(0xdead).
     * This overrides function is just an extended version of the original {transferOwnership}
     * function. See {Ownable-transferOwnership} for more information.
     */
    function transferOwnership(address newOwner) public override onlyOwner {
        if (newOwner == owner()) {
            revert CannotUseCurrentAddress(newOwner);
        }
        if (newOwner == address(0xdead)) {
            revert InvalidAddress(newOwner);
        }
        projectOwner = newOwner;
        super.transferOwnership(newOwner);
    }

    /* ERC20 Standard */

    /**
     * @notice Returns the name of the token.
     * 
     * @return The name of the token.
     * 
     * @dev This is usually a longer version of the name.
     */
    function name() public view virtual returns (string memory) {
        return NAME;
    }

    /**
     * @notice Returns the symbol of the token.
     * 
     * @return The symbol of the token.
     * 
     * @dev This is usually a shorter version of the name.
     */
    function symbol() public view virtual returns (string memory) {
        return SYMBOL;
    }

    /**
     * @notice Returns the number of decimals used for token display purposes.
     * 
     * @return The number of decimals.
     * 
     * @dev This is purely used for user representation of the amount and does not
     * affect any of the arithmetic of the smart contract including, but not limited
     * to {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return DECIMALS;
    }

    /**
     * @notice Returns the total supply of tokens.
     * 
     * @return The total supply of tokens.
     * 
     * @dev See {IERC20-totalSupply} for more information.
     */
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    /**
     * @notice Returns the balance of tokens for a given account.
     * 
     * @param account The address of the account to check.
     * 
     * @return The token balance of the account.
     * 
     * @dev See {IERC20-balanceOf} for more information.
     */
    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    /**
     * @notice Transfers tokens from the sender to a specified recipient.
     * 
     * @param to The address of the recipient.
     * @param value The amount of tokens to transfer.
     * 
     * @return A boolean indicating whether the transfer was successful or not.
     * 
     * @dev See {IERC20-transfer} for more information.
     */
    function transfer(address to, uint256 value) public virtual returns (bool) {
        address provider = msg.sender;
        _transfer(provider, to, value);
        return true;
    }

    /**
     * @notice Returns the allowance amount that a spender is allowed to spend on behalf of a provider.
     * 
     * @param provider The address allowing spending.
     * @param spender The address allowed to spend tokens.
     * 
     * @return The allowance amount for the spender.
     * 
     * @dev See {IERC20-allowance} for more information.
     */
    function allowance(address provider, address spender) public view virtual returns (uint256) {
        return _allowances[provider][spender];
    }
    
    /**
     * @notice Approves a spender to spend a certain amount of tokens on behalf of the sender.
     * 
     * @param spender The address allowed to spend tokens.
     * @param value The allowance amount for the spender.
     * 
     * @return A boolean indicating whether the approval was successful or not.
     * 
     * @dev See {IERC20-approve} for more information.
     */
    function approve(address spender, uint256 value) public virtual returns (bool) {
        address provider = msg.sender;
        _approve(provider, spender, value);
        return true;
    }

    /**
     * @notice Transfers tokens from one address to another on behalf of a spender.
     * 
     * @param from The address to transfer tokens from.
     * @param to The address to transfer tokens to.
     * @param value The amount of tokens to transfer.
     * 
     * @return A boolean indicating whether the transfer was successful or not.
     * 
     * @dev See {IERC20-transferFrom} for more information.
     */
    function transferFrom(address from, address to, uint256 value) public virtual returns (bool) {
        address spender = msg.sender;
        _spendAllowance(from, spender, value);
        _transfer(from, to, value);
        return true;
    }

    /**
     * @notice Internal function to handle token transfers with additional checks.
     * 
     * @param from The address tokens are transferred from.
     * @param to The address tokens are transferred to.
     * @param value The amount of tokens to transfer.
     * 
     * @dev This internal function is equivalent to {transfer}, and thus can be used for other functions
     * such as implementing automatic token fees, slashing mechanisms, etc. Since this function is not
     * virtual, {_update} should be overridden instead. This function can only be called if the address
     * for `from` and `to` are not address(0) and the sender should at least have a balance of `value`.
     * It also enforces various conditions including validations for trade status, fees, exemptions,
     * and redemption.
     * 
     * IMPORTANT: Since this project implement logic for trading restriction, the transaction will only
     * go through if the trade was already enabled or if the trade is still disabled. Please note that
     * this feature could significantly impact the audit score as since it possesses the potential for
     * malicious exploitation, which might affect the received score. However, since this contract will
     * be a development for SAFU smart contract under Pinksale, this could be omitted.
     */
    function _transfer(address from, address to, uint256 value) internal {
        if (from == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        if (to == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        if (
            !tradeEnabled &&
            (!isLimitExempt[from] && !isLimitExempt[to])
        ) {
            revert TradeNotYetEnabled();
        }
        if (isMaxLimitEnabled && !isLimitExempt[from] && value > totalSupply() * maxTransactionLimit / DENOMINATOR) {
            revert ExceedLimit();
        }
        if ((block.timestamp - lastAutoBurnTime) >= autoBurnTriggerTime && balanceOf(address(this)) > 0) {
            uint256 burning = balanceOf(address(this));
            if (burning > totalSupply() * 2_100 / DENOMINATOR) {
                burning = totalSupply() * 2_100 / DENOMINATOR;
            }
            _update(address(this), address(0xdead), burning);
        }

        _update(from, to, value);
    }

    /**
     * @notice Internal function to update token balances during transfers.
     * 
     * @param from The address tokens are transferred from.
     * @param to The address tokens are transferred to.
     * @param value The amount of tokens to transfer.
     * 
     * @dev This function is used internally to transfer a `value` amount of token from
     * `from` address to `to` address. This function is also used for mints if `from`
     * is the zero address and for burns if `to` is the zero address.
     * 
     * IMPORTANT: All customizations that are required for transfers, mints, and burns
     * should be done by overriding this function.

     */
    function _update(address from, address to, uint256 value) internal virtual {
        if (from == address(0)) {
            _totalSupply += value;
        } else {
            uint256 fromBalance = _balances[from];
            if (fromBalance < value) {
                revert ERC20InsufficientBalance(from, fromBalance, value);
            }
            unchecked {
                _balances[from] = fromBalance - value;
            }
        }

        if (to == address(0)) {
            unchecked {
                _totalSupply -= value;
            }
        } else {
            unchecked {
                _balances[to] += value;
            }
        }

        emit Transfer(from, to, value);
    }
 
    /**
     * @notice Internal function to mint tokens and update the total supply.
     * 
     * @param account The address to mint tokens to.
     * @param value The amount of tokens to mint.
     * 
     * @dev The `account` address cannot be address(0) because it does not make any sense to mint to it.
     * Since this function is not virtual, {_update} should be overridden instead for customization.
     */
    function _mint(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(address(0), account, value);
    }
 
    /**
     * @notice Internal function to set an allowance for a `spender` to spend a specific `value` of tokens
     * on behalf of a `provider`.
     * 
     * @param provider The address allowing spending.
     * @param spender The address allowed to spend tokens.
     * @param value The allowance amount for the spender.
     * 
     * @dev This internal function is equivalent to {approve}, and thus can be used for other functions
     * such as setting automatic allowances for certain subsystems, etc. 
     * 
     * IMPORTANT: This function internally calls {_approve} with the emitEvent parameter set to `true`.
     */
    function _approve(address provider, address spender, uint256 value) internal {
        _approve(provider, spender, value, true);
    }

    /**
     * @notice Variant of {_approve} with an optional flag to enable or disable the {Approval} event.
     * 
     * @param provider The address allowing spending.
     * @param spender The address allowed to spend tokens.
     * @param value The allowance amount for the spender.
     * @param emitEvent A boolean indicating whether to emit the Approval event.
     * 
     * @dev This internal function is equivalent to {approve}, and thus can be used for other functions
     * such as setting automatic allowances for certain subsystems, etc. This function can only be called
     * if the address for `provider` and `spender` are not address(0). If `emitEvent` is set to `true`,
     * this function will emits the Approval event.
     */
    function _approve(address provider, address spender, uint256 value, bool emitEvent) internal virtual {
        if (provider == address(0)) {
            revert ERC20InvalidApprover(address(0));
        }
        if (spender == address(0)) {
            revert ERC20InvalidSpender(address(0));
        }
        _allowances[provider][spender] = value;
        if (emitEvent) {
            emit Approval(provider, spender, value);
        }
    }

    /**
     * @notice Internal function to decrease allowance when tokens are spent.
     * 
     * @param provider The address allowing spending.
     * @param spender The address allowed to spend tokens.
     * @param value The amount of tokens spent.
     * 
     * @dev If the allowance value for the `spender` is infinite/the max value of uint256,
     * this function will notupdate the allowance value. Should throw if not enough allowance
     * is available. On all occasion, this function will not emit an Approval event.
     */
    function _spendAllowance(address provider, address spender, uint256 value) internal virtual {
        uint256 currentAllowance = allowance(provider, spender);
        if (currentAllowance < type(uint256).max) {
            if (currentAllowance < value) {
                revert ERC20InsufficientAllowance(spender, currentAllowance, value);
            }
            unchecked {
                _approve(provider, spender, currentAllowance - value, false);
            }
        }
    }

    /* ERC20 Extended */

    /**
     * @notice Increases the allowance granted by the message sender to the spender.
     * 
     * @param spender The address to whom the allowance is being increased.
     * @param value The additional amount by which the allowance is increased.
     * 
     * @return A boolean indicating whether the operation was successful or not.
     * 
     * @dev Allow a spender to spend more tokens on behalf of the message sender and
     * update the allowance accordingly.
     */
    function increaseAllowance(address spender, uint256 value) external virtual returns (bool) {
        address provider = msg.sender;
        uint256 currentAllowance = allowance(provider, spender);
        _approve(provider, spender, currentAllowance + value, true);
        return true;
    }
    
    /**
     * @notice Decreases the allowance granted by the message sender to the spender.
     * 
     * @param spender The address whose allowance is being decreased.
     * @param value The amount by which the allowance is decreased.
     * 
     * @return A boolean indicating whether the operation was successful or not.
     * 
     * @dev Reduce the spender's allowance by a specified amount. Should throw if the
     * current allowance is insufficient.
     */
    function decreaseAllowance(address spender, uint256 value) external virtual returns (bool) {
        address provider = msg.sender;
        uint256 currentAllowance = allowance(provider, spender);
        if (currentAllowance < value) {
            revert ERC20InsufficientAllowance(spender, currentAllowance, value);
        }
        unchecked {
            _approve(provider, spender, currentAllowance - value, true);
        }
        return true;
    }
}