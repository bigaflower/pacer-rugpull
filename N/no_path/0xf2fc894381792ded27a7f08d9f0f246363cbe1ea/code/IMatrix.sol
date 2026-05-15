// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {IMatrixAuction} from "@interfaces/IAuction.sol";
import {IMatrixBuyAndBurn} from "@interfaces/IBuyAndBurn.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

interface IMatriX is IERC20 {
    /* ==== EVENTS ==== */

    /// @notice Emitted when MATRIX tokens are minted
    /// @param to The address to which the tokens are minted
    /// @param amount The amount of tokens minted
    event MatrixMinted(address indexed to, uint256 amount);

    /* ==== ERRORS ==== */

    /// @notice Error thrown when the function caller is not the Auction contract
    error OnlyAuction();

    error CanOnlyBeSetOnce();

    /// @notice Error thrown when an invalid input is provided
    error InvalidInput();

    /* ==== EXTERNAL FUNCTIONS ==== */

    /**
     * @notice Mints MATRIX tokens to a specified address.
     * @dev Can only be called by the Auction contract.
     * @param to The address to mint the tokens to.
     * @param amount The amount of tokens to mint.
     */
    function mint(address to, uint256 amount) external;

    /**
     * @notice Sets the auction contract address.
     * @dev Can only be set once.
     * @param auction The address of the auction contract.
     */
    function setAuction(IMatrixAuction auction) external;

    /**
     * @notice Sets the Buy And Burn contract address.
     * @dev Can only be set once.
     * @param bnb The address of the Buy And Burn contract.
     */
    function setBnb(IMatrixBuyAndBurn bnb) external;

    /* ==== VIEW FUNCTIONS ==== */

    /**
     * @return The address of the auction contract.
     */
    function auction() external view returns (IMatrixAuction);

    /**
     * @return The address of the BnB contract.
     */
    function bnb() external view returns (IMatrixBuyAndBurn);

    /**
     * @notice Burns MATRIX tokens from the sender
     * @param amount The amount of MATRIX tokens to burn
     */
    function burn(uint256 amount) external;

    /**
     * @notice Burns MATRIX tokens from an address
     * @dev The caller has to have approval from the account in order to burn his tokens
     * @param account The account from where to burn matrix tokens
     * @param amount The amount of MATRIX tokens to burn
     */
    function burnFrom(address account, uint256 amount) external;
}
