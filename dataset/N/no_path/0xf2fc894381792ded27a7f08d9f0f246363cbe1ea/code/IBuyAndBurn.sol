// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title IMatrixBuyAndBurn
 * @dev Interface for the MatrixBuyAndBurn contract, which performs token buy-and-burn operations and manages buy incentives.
 */
interface IMatrixBuyAndBurn {
    /* == STRUCTS == */

    /**
     * @notice Holds the state variables related to buy-and-burn operations.
     * @param lastCallTs The timestamp of the last buy-and-burn call.
     * @param intervalBetween The minimum interval (in seconds) required between buy-and-burn operations.
     * @param swapCap The maximum allowable amount of tokens that can be swapped for the buy-and-burn.
     * @param incentive The incentive amount provided for performing a buy-and-burn operation.
     */
    struct State {
        uint32 lastCallTs;
        uint32 intervalBetween;
        uint128 swapCap;
        uint64 incentive;
    }

    /* == STATE GETTERS == */

    /**
     * @notice Returns the total amount of MATRIX tokens that have been burnt.
     * @return totalMatrixBurnt The total number of MATRIX tokens that have been burnt.
     */
    function totalMatrixBurnt() external view returns (uint256);

    /**
     * @notice Returns the buy action state for a specific input token.
     * @param _inputToken The address of the input token whose buy action state is being queried.
     * @return buyActionState The `State` struct containing settings for the specified input token.
     */
    function buyActionState(address _inputToken) external view returns (State memory);

    /* == EVENTS == */

    /**
     * @notice Emitted when a buy-and-burn operation is performed.
     * @param matrixAmount The amount of MATRIX tokens burnt in the operation.
     * @param infernoAmount The amount of tokens sent to the Inferno pool as a result of the operation.
     */
    event BuyAndBurn(uint256 indexed matrixAmount, uint256 indexed infernoAmount);

    /**
     * @notice Emitted when a buy action is executed, swapping an input token for an output token.
     * @param inputToken The address of the input token used in the swap.
     * @param outputToken The address of the output token received from the swap.
     * @param outputAmount The amount of the output token received from the swap.
     */
    event BuyAction(address indexed inputToken, address indexed outputToken, uint256 indexed outputAmount);

    /* == ERRORS == */

    /// @notice Thrown when attempting a buy-and-burn operation before the required interval has passed.
    error IntervalWait();

    /* == FUNCTIONS == */

    /**
     * @notice Modifies the buy action state settings for a specific input token.
     * @param _inputToken The address of the input token for which the buy action state is being modified.
     * @param _s The new state settings for the buy action, including interval, cap, and incentive.
     * @dev Only callable by the contract owner.
     */
    function changeBuyActionState(address _inputToken, State memory _s) external;

    /**
     * @notice Executes a buy action to swap WETH for titanX.
     * @param _deadline The timestamp by which the buy action must be completed.
     */
    function buyTitanX(uint32 _deadline) external;

    /**
     * @notice Executes a buy action to swap titanX for HYPER.
     * @param _deadline The timestamp by which the buy action must be completed.
     */
    function buyHyper(uint32 _deadline) external;

    /**
     * @notice Executes a buy-and-burn operation, swapping HYPER for MATRIX tokens, distributing to incentive pool, and burning.
     * @param _deadline The timestamp by which the buy-and-burn operation must be completed.
     */
    function buyNBurn(uint32 _deadline) external;

    /**
     * @notice Directly burns MATRIX tokens.
     */
    function burnMatrix() external;
}
