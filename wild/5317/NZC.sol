// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IERC20 Interface
 * @notice Interface of the ERC20 standard as defined in the EIP
 */
interface IERC20 {
    /**
     * @notice Emitted when tokens are moved from one account to another
     * @param from The address tokens are transferred from
     * @param to The address tokens are transferred to
     * @param value The amount of tokens transferred
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @notice Emitted when token allowance is set
     * @param owner The address granting the allowance
     * @param spender The address receiving the allowance
     * @param value The amount of tokens allowed
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @notice Returns total token supply
     * @return The total supply of tokens
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Get the balance of an account
     * @param account The address to query
     * @return The token balance of the account
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @notice Transfer tokens to a specified address
     * @param to The address to transfer to
     * @param amount The amount to transfer
     * @return A boolean indicating transfer success
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @notice Check the spending allowance granted to a spender
     * @param owner The address granting the allowance
     * @param spender The address granted the allowance
     * @return The remaining allowance of tokens
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @notice Set allowance for a spender
     * @param spender The address to grant allowance to
     * @param amount The amount of allowance to grant
     * @return A boolean indicating approval success
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @notice Transfer tokens from one address to another using allowance
     * @param from The address to transfer from
     * @param to The address to transfer to
     * @param amount The amount to transfer
     * @return A boolean indicating transfer success
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

/**
 * @title IERC20Metadata Interface
 * @notice Interface for the optional metadata functions from the ERC20 standard
 */
interface IERC20Metadata is IERC20 {
    /**
     * @notice Get the token name
     * @return The name of the token
     */
    function name() external view returns (string memory);

    /**
     * @notice Get the token symbol
     * @return The symbol of the token
     */
    function symbol() external view returns (string memory);

    /**
     * @notice Get the number of decimals used for display
     * @return The number of decimals
     */
    function decimals() external view returns (uint8);
}

/**
 * @title Context Contract
 * @notice Provides information about transaction execution context
 * @dev Abstract contract for context utilities
 */
abstract contract Context {
    /**
     * @notice Get the transaction sender
     * @return The address of the sender
     */
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    /**
     * @notice Get the transaction data
     * @return The calldata of the transaction
     */
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

/**
 * @title ERC20 Token Implementation
 * @notice Standard implementation of the ERC20 token contract
 * @dev Implementation of the IERC20 interface
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    /**
     * @notice Contract constructor
     * @param name_ The name of the token
     * @param symbol_ The symbol of the token
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @notice Get the name of the token
     * @return The name of the token
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @notice Get the symbol of the token
     * @return The symbol of the token
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @notice Get the number of decimals used for token display
     * @return The number of decimals
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @notice Get the total supply of tokens
     * @return The total supply of tokens
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @notice Get the balance of an account
     * @param account The address to query
     * @return The token balance of the account
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @notice Transfer tokens to a specified address
     * @param to The recipient address
     * @param amount The amount to transfer
     * @return success A boolean indicating transfer success
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @notice Get the allowance granted to a spender
     * @param owner The address granting the allowance
     * @param spender The address granted the allowance
     * @return The remaining allowance of tokens
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @notice Approve a spender to spend tokens
     * @param spender The address to approve
     * @param amount The amount to approve
     * @return success A boolean indicating approval success
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @notice Transfer tokens using the allowance mechanism
     * @param from The address to transfer from
     * @param to The recipient address
     * @param amount The amount to transfer
     * @return success A boolean indicating transfer success
     */
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @notice Increase the allowance granted to a spender
     * @param spender The address to increase allowance for
     * @param addedValue The amount to increase by
     * @return success A boolean indicating the operation succeeded
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @notice Decrease the allowance granted to a spender
     * @param spender The address to decrease allowance for
     * @param subtractedValue The amount to decrease by
     * @return success A boolean indicating the operation succeeded
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
     * @notice Execute token transfer between addresses
     * @dev Internal function to handle transfers
     * @param from The address to transfer from
     * @param to The address to transfer to
     * @param amount The amount to transfer
     */
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);
        _afterTokenTransfer(from, to, amount);
    }

    /**
     * @notice Create new tokens
     * @dev Internal function to mint tokens
     * @param account The address to mint tokens to
     * @param amount The amount of tokens to mint
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @notice Destroy tokens
     * @dev Internal function to burn tokens
     * @param account The address to burn tokens from
     * @param amount The amount of tokens to burn
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);
        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @notice Set allowance for spender
     * @dev Internal function to set allowances
     * @param owner The address granting the allowance
     * @param spender The address receiving the allowance
     * @param amount The amount of the allowance
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @notice Spend allowance
     * @dev Internal function to spend allowance
     * @param owner The address who granted the allowance
     * @param spender The address spending the allowance
     * @param amount The amount to spend from the allowance
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
     * @notice Hook that is called before any transfer of tokens
     * @dev Called before token transfer, including minting and burning
     * @param from The address tokens are sent from
     * @param to The address tokens are sent to
     * @param amount The amount of tokens being transferred
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    /**
     * @notice Hook that is called after any transfer of tokens
     * @dev Called after token transfer, including minting and burning
     * @param from The address tokens were sent from
     * @param to The address tokens were sent to
     * @param amount The amount of tokens that were transferred
     */
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}


/**
 * @title Ownable
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev Emitted when ownership is transferred
     * @param previousOwner Address of the previous owner
     * @param newOwner Address of the new owner
     */
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner
     * @return Current owner address
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner
     * @notice Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account
     * @param newOwner The address of the new owner
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account
     * Internal function without access restriction
     * @param newOwner The address of the new owner
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

/**
 * @title Net Zero Climate Token
 * @notice The GESIA Token (NZC), within the protocol, functions as collateral for validators in the form of bonds. It operates as an ERC20 token, maintaining precision with 18 decimal places.
 * @dev Extends ERC20 standard token implementation
 */
contract NZC is ERC20, Ownable {
    /**
     * @notice Initializes the NZC token contract
     * @dev Mints initial supply of 5 billion tokens to contract deployer
     */
    constructor() ERC20("Net Zero Climate", "NZC") {
        _mint(msg.sender, 5000000000000000000000000000); // 5 billion tokens with 18 decimals
    }
}
