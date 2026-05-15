// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import '@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PausableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';

contract ERC20Token is ERC20PausableUpgradeable, ERC20BurnableUpgradeable, AccessControlUpgradeable {
    /**
     * @notice Roles.
     */
    bytes32 public constant ADMIN_ROLE = keccak256('ADMIN_ROLE');

    /**
     * @notice Constructor.
     * @dev Disables initialization of the implementation contract.
     */
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initializer.
     * @param recipient_ Address where the total supply is minted.
     * @param admin_ Address of the initial admin.
     * @param name_ Name of the token.
     * @param symbol_ Symbol of the token.
     * @param supply_ Supply of the token, minted to the recipient address.
     */
    function initialize(
        address recipient_,
        address admin_,
        string memory name_,
        string memory symbol_,
        uint256 supply_
    ) external initializer {
        __ERC20Pausable_init();
        __ERC20Burnable_init();
        __ERC20_init(name_, symbol_);
        __AccessControl_init();

        _mint(recipient_, supply_);
        _grantRole(ADMIN_ROLE, admin_);
    }

    /**
     * @notice Pause token transfer by admin.
     */
    function pause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }

    /**
     * @notice Unpause token transfer by admin.
     */
    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    /**
     * @notice Override to pausable update.
     */
    function _update(
        address from,
        address to,
        uint256 value
    ) internal virtual override(ERC20PausableUpgradeable, ERC20Upgradeable) {
        ERC20PausableUpgradeable._update(from, to, value);
    }
}
