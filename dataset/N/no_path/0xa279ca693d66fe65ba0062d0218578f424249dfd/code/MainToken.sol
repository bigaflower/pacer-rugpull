// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ERC20BurnableUpgradeable} from
    "@openzeppelin-upgradeable/contracts/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import {ERC20PermitUpgradeable} from
    "@openzeppelin-upgradeable/contracts/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin-upgradeable/contracts/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {IMainToken} from "src/interfaces/IMainToken.sol";

/**
 * @title  Main Token
 * @author Camelot
 * @notice Native ERC20 upgradable token with burn and permit functionality.
 */
contract MainToken is
    ERC20BurnableUpgradeable,
    ERC20PermitUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable,
    IMainToken
{
    constructor() {
        _disableInitializers();
    }

    function initialize(MainTokenInitParams calldata params) external initializer {
        __ERC20_init(params._name, params._symbol);
        __ERC20Burnable_init();
        __ERC20Permit_init(params._symbol);
        __Ownable_init(params._owner);

        _mint(params._owner, params._initialSupply);
    }

    /**
     * @notice Authorizes the upgrade of the contract.
     * @dev Only the owner can authorize ERC1967 proxy upgrades.
     * @param newImplementation The address of the new implementation contract.
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /// @inheritdoc IMainToken
    function burn(uint256 amount) public virtual override(ERC20BurnableUpgradeable, IMainToken) {
        ERC20BurnableUpgradeable.burn(amount);
    }

    /// @inheritdoc IMainToken
    function burnFrom(address account, uint256 amount) public virtual override(ERC20BurnableUpgradeable, IMainToken) {
        ERC20BurnableUpgradeable.burnFrom(account, amount);
    }
}
