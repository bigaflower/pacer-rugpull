// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title IMainToken
 * @author Camelot
 * @notice Interface for the main governance token contract.
 * @dev Extends ERC20 with burn functionality and initialization.
 */
interface IMainToken is IERC20 {
    /**
     * @notice Initialization parameters for MainToken.
     * @param _initialSupply The initial token supply to mint.
     * @param _owner The owner address of the contract.
     * @param _name The name of the token.
     * @param _symbol The symbol of the token.
     */
    struct MainTokenInitParams {
        uint256 _initialSupply;
        address _owner;
        string _name;
        string _symbol;
    }

    /**
     * @notice Thrown when a zero amount is provided where it's not allowed.
     */
    error AmountZero();

    /**
     * @notice Thrown when a zero address is provided where it's not allowed.
     */
    error AddressZero();

    /**
     * @notice Initializes the main token contract.
     * @param params The initialization parameters.
     */
    function initialize(MainTokenInitParams calldata params) external;

    /**
     * @notice Burns a specific amount of tokens from caller's account.
     * @param amount The amount of token to be burned.
     */
    function burn(uint256 amount) external;

    /**
     * @notice Burns a specific amount of tokens from a specified account.
     * @param account The address of the account to burn tokens from.
     * @param amount The amount of token to be burned.
     */
    function burnFrom(address account, uint256 amount) external;
}
