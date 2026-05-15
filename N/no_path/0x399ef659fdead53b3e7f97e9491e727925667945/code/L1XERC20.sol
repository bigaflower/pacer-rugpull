// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract L1XERC20 is ERC20, AccessControl {
    // Declare the MINTER_ROLE as a constant bytes32 identifier
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // Constructor sets the name and symbol for the token and assigns the admin role
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        // Set the deployer as the DEFAULT_ADMIN_ROLE
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // Mint function: Only callable by addresses with the MINTER_ROLE
    function mint(address to, uint256 amount) public {
        // Check if the sender has the MINTER_ROLE before minting
        require(hasRole(MINTER_ROLE, msg.sender), "must have minter role to mint");
        _mint(to, amount);
    }
    // Function to grant MINTER_ROLE to an address (only callable by an admin)
    function grantMinterRole(address account) public {
        // Admin can grant minter role
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "must have admin role to grant");
        grantRole(MINTER_ROLE, account);
    }

    // Function to revoke MINTER_ROLE from an address (only callable by an admin)
    function revokeMinterRole(address account) public {
        // Admin can revoke minter role
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "MintableERC20: must have admin role to revoke");
        revokeRole(MINTER_ROLE, account);
    }
}
