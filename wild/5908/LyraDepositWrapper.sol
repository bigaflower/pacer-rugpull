// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 ^0.8.0 ^0.8.9;

// lib/openzeppelin-contracts/contracts/utils/Context.sol

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol

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

// src/interfaces/ILightAccountFactory.sol

interface ILightAccountFactory {
    /**
     * @notice Create an account, and return its address.
     * Returns the address even if the account is already deployed.
     * @dev During UserOperation execution, this method is called only if the account is not deployed.
     * This method returns an existing account address so that entryPoint.getSenderAddress() would work even after account creation.
     * @param owner The owner of the account to be created
     * @param salt A salt, which can be changed to create multiple accounts with the same owner
     * @return ret The address of either the newly deployed account or an existing account with this owner and salt
     */
    function createAccount(address owner, uint256 salt) external returns (address ret);

    /**
     * @notice Calculate the counterfactual address of this account as it would be returned by createAccount()
     * @param owner The owner of the account to be created
     * @param salt A salt, which can be changed to create multiple accounts with the same owner
     * @return The address of the account that would be created with createAccount()
     */
    function getAddress(address owner, uint256 salt) external view returns (address);
}

// src/interfaces/ISocketVault.sol

interface ISocketVault {
    function depositToAppChain(address receiver_, uint256 amount_, uint256 msgGasLimit_, address connector_)
        external
        payable;

    function __token() external view returns (address);

    function getMinFees(address connector, uint256 minGasLimit) external view returns (uint256);
}

// src/interfaces/IWETH.sol

interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint256) external;
}

// lib/openzeppelin-contracts/contracts/access/Ownable.sol

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

// src/helpers/LyraDepositWrapper.sol

/**
 * @title  LyraDepositWrapper
 * @dev    Helper contract to wrap ETH into L2 WETH, or deposit any token to L2 smart contract wallet address
 */
contract LyraDepositWrapper is Ownable {
    ///@dev L2 USDC address.
    address public immutable weth;

    ///@dev Light Account factory address.
    address public constant lightAccountFactory = 0x000000893A26168158fbeaDD9335Be5bC96592E2;

    constructor(address _weth) Ownable() {
        weth = _weth;
    }

    function recoverERC20(address token, uint256 amount) external onlyOwner {
        IERC20(token).transfer(owner(), amount);
    }

    function recoverETH(uint256 amount) external onlyOwner {
        payable(owner()).transfer(amount);
    }

    /**
     * @notice Wrap ETH into WETH and deposit to Lyra Chain via socket vault
     */
    function depositETHToLyra(address socketVault, bool isSCW, uint256 gasLimit, address connector) external payable {
        uint256 socketFee = ISocketVault(socketVault).getMinFees(connector, gasLimit);

        uint256 depositAmount = msg.value - socketFee;

        IWETH(weth).deposit{value: depositAmount}();
        IERC20(weth).approve(socketVault, depositAmount);

        address recipient = _getL2Receiver(isSCW);

        ISocketVault(socketVault).depositToAppChain{value: socketFee}(recipient, depositAmount, gasLimit, connector);
    }

    /**
     * @notice Deposit any token to Lyra Chain via socket vault.
     * @dev This function help calculate L2 smart wallet addresses for users
     */
    function depositToLyra(
        address token,
        address socketVault,
        bool isSCW,
        uint256 amount,
        uint256 gasLimit,
        address connector
    ) external payable {
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        IERC20(token).approve(socketVault, amount);

        address recipient = _getL2Receiver(isSCW);
        uint256 socketFee = ISocketVault(socketVault).getMinFees(connector, gasLimit);

        ISocketVault(socketVault).depositToAppChain{value: socketFee}(recipient, amount, gasLimit, connector);
    }

    /**
     * @notice Return the receiver address on L2
     */
    function _getL2Receiver(bool isScwWallet) internal view returns (address) {
        if (isScwWallet) {
            return ILightAccountFactory(lightAccountFactory).getAddress(msg.sender, 0);
        } else {
            return msg.sender;
        }
    }

    receive() external payable {}
}
