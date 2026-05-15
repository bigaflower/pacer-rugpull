// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "forge-std/Script.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title UntransferrableToken
 * @dev ERC20 token that is mintable and untransferrable by default.
 *      Only addresses with TRANSFER_ROLE can transfer tokens.
 */
contract UntransferrableToken is ERC20Permit, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");

    constructor(
        string memory name,
        string memory symbol,
        address admin
    ) ERC20Permit(name) ERC20(name, symbol) {
        // Setup admin roles
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(MINTER_ROLE, admin);
        
        // By default, do not grant TRANSFER_ROLE to address(0), making token untransferrable
        // for addresses without TRANSFER_ROLE
    }

    /**
     * @dev Override the transfer function to add restrictions
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        // If transfers are restricted (address(0) doesn't have TRANSFER_ROLE)
        // and it's not a mint or burn operation, require sender or recipient to have TRANSFER_ROLE
        if (!hasRole(TRANSFER_ROLE, address(0)) && from != address(0) && to != address(0)) {
            require(hasRole(TRANSFER_ROLE, from) || hasRole(TRANSFER_ROLE, to), "transfers restricted");
        }
    }

    /**
     * @dev Mint new tokens. Only callable by addresses with MINTER_ROLE.
     */
    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }
}

contract DeployUntransferrableToken is Script {
    function run() external {
        // Start broadcasting transactions
        vm.startBroadcast();

        // Deploy the token
        UntransferrableToken token = new UntransferrableToken(
            "GoatNFTPoints",           // Name
            "GNFT",                    // Symbol
            msg.sender                 // Admin
        );
        
        // Grant TRANSFER_ROLE to the deployer so they can transfer tokens
        token.grantRole(token.TRANSFER_ROLE(), msg.sender);
        
        // Mint some tokens to the deployer
        token.mint(msg.sender, 1000 * 10**18); // 1000 tokens with 18 decimals
        
        vm.stopBroadcast();
        
        console2.log("UntransferrableToken deployed at:", address(token));
    }
} 