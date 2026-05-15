// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Ownable base semplice
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function renounceOwnership() external onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }
}

/// @title GIIT - Gold International Index Token
/// @notice ERC-20 semplice, supply iniziale assegnata a un indirizzo scelto.
contract GIIT is Ownable {
    string public name = "Gold International Index Token";
    string public symbol = "GIIT";
    uint8 public decimals = 18;

    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    /// @notice indirizzo oracle (opzionale, solo informativo)
    address public oracle;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OracleUpdated(address indexed oldOracle, address indexed newOracle);

    /// @param initialSupply supply iniziale in UNITA' INTERE (senza 18 decimali).
    /// @param initialRecipient indirizzo che riceve tutta la supply.
    constructor(uint256 initialSupply, address initialRecipient) {
        require(initialRecipient != address(0), "Zero recipient");

        uint256 supply = initialSupply * (10 ** uint256(decimals));
        totalSupply = supply;
        balanceOf[initialRecipient] = supply;
        emit Transfer(address(0), initialRecipient, supply);
    }

    /// @notice Imposta l'indirizzo dell'oracolo GIIT (facoltativo, non influisce sulla logica ERC-20)
    function setOracle(address _oracle) external onlyOwner {
        emit OracleUpdated(oracle, _oracle);
        oracle = _oracle;
    }

    // ========= ERC-20 BASE =========

    function _transfer(address from, address to, uint256 amount) internal {
        require(to != address(0), "Transfer to zero");

        uint256 fromBalance = balanceOf[from];
        require(fromBalance >= amount, "Balance too low");

        unchecked {
            balanceOf[from] = fromBalance - amount;
        }
        balanceOf[to] += amount;

        emit Transfer(from, to, amount);
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        uint256 currentAllowance = allowance[from][msg.sender];
        require(currentAllowance >= amount, "Not allowed");

        unchecked {
            allowance[from][msg.sender] = currentAllowance - amount;
        }

        _transfer(from, to, amount);
        return true;
    }
}
