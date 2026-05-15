// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ITOTO {
    // ========== ERC-20 Metadata ==========

    /**
     * @notice Returns the maximum allowed token supply that can ever exist.
     */
    function MAX_SUPPLY() external view returns (uint256);

    /**
     * @notice Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @notice Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @notice Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);

    // ========== ERC-20 functionalities ==========

    /**
     * @notice Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @notice Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    /**
     * @notice Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @notice Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @notice Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    /**
     * @notice Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @notice Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @notice Atomically increases the allowance granted to `spender` by the caller.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) external returns (bool);

    /**
     * @notice Atomically decreases the allowance granted to `spender` by the caller.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) external returns (bool);

    /**
     * @notice Mints new tokens to a specified address.
     *
     * Requirements:
     * - The contract must not be paused.
     * - The caller must have the minting permission.
     * - The resulting total supply must not exceed the `MAX_SUPPLY`.
     *
     * @param to The address to receive the newly minted tokens.
     * @param amount The number of tokens to mint (in smallest units).
     */
    function mint(address to, uint256 amount) external;

    /**
     * @dev Burns a specified amount of tokens from the caller's account.
     *
     * Requirements:
     * - The contract must not be paused.
     * - The caller must have the required burning permission.
     * - The caller's account must have at least the amount of tokens to be burned.
     *
     * @param amount The number of tokens to burn (in smallest units).
     */
    function burn(uint256 amount) external;

    // ========== TOTO Admin: Pausable etc. ==========

    /**
     * @notice Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @notice Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    /**
     * @notice Returns true if the contract is paused, and false otherwise.
     */
    function paused() external returns (bool);

    /**
     * @notice Emitted when the owner is updated
     */
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @notice Returns the address of the current owner.
     */
    function owner() external returns (address);

    /**
     * @notice Returns true if the specified account has permission to mint tokens.
     */
    function hasMintPermission(address _account) external view returns (bool);

    /**
     * @notice Returns true if the specified account has permission to burn tokens.
     */
    function hasBurnPermission(address _account) external view returns (bool);

    /**
     * @notice Returns true if the specified account has both
     * the permissions of minting and burning.
     */
    function hasBothMintAndBurnPermission(
        address _account
    ) external view returns (bool);
}
