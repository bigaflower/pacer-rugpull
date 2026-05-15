// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {ERC20Permit} from "@openzeppelin/token/ERC20/extensions/ERC20Permit.sol";
import {ERC20} from "@openzeppelin/token/ERC20/ERC20.sol";
import {Errors} from "src/Errors.sol";
import {IRoleConfig} from "src/interfaces/IRoleConfig.sol";
import {Errors} from "src/Errors.sol";
import {IYBTC} from "src/interfaces/IYBTC.sol";

/// @title YBTC
/// @notice This contract is ERC20 representation of yield bearing staked BTC
contract YBTC is ERC20Permit, IYBTC {
    /// @notice This is the role config for the YBTC system
    IRoleConfig public immutable roleConfig;

    constructor(IRoleConfig _roleConfig) ERC20Permit("YBTC") ERC20("YBTC", "YBTC") {
        if (address(_roleConfig) == address(0)) {
            revert Errors.ZeroAddress();
        }
        roleConfig = _roleConfig;
    }

    modifier onlyMinter() {
        if (!roleConfig.isMinter(msg.sender)) {
            revert Errors.InvalidAccess();
        }
        _;
    }

    modifier onlyBurner() {
        if (!roleConfig.isBurner(msg.sender)) {
            revert Errors.InvalidAccess();
        }
        _;
    }

    /**
     * @notice Mints new YBTC tokens to a specified user
     * @dev Can only be called by an address with the MINTER_ROLE
     * @param _user The address to receive the minted tokens
     * @param _amount The amount of tokens to mint
     */
    function mint(address _user, uint256 _amount) external override onlyMinter {
        _mint(_user, _amount);
    }

    /**
     * @notice Burns YBTC tokens from the caller's address
     * @dev Can only be called by an address with the BURNER_ROLE
     * @param _amount The amount of tokens to burn
     */
    function burn(uint256 _amount) external override onlyBurner {
        _burn(msg.sender, _amount);
    }

    /// @notice Overrides the decimals function to return 8
    /// @return uint8 The number of decimals
    function decimals() public pure override returns (uint8) {
        return 8;
    }
}
