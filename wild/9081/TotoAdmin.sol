// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Ownable2Step} from "./Ownable2Step.sol";
import {Pausable} from "./Pausable.sol";

/**
 * @title TOTOAdmin
 * @notice Admin management and related functionalities for TOTO Token
 * - The owner is targeted to be set / upgraded to a multi-sig wallet
 *   for enhanced security
 * - Minting and Burning permissions will be granted to the Swapper contract
 *   and cross-chain bridging contracts
 *
 * - Token contract can be paused, unpaused by the owner
 * - Owner can grant/revoke permissions to/from an account to mint and burn tokens
 * - Owner can be updated using 2 steps, as implemented by Openzeppelin's Ownable2Step
 */
abstract contract TOTOAdmin is Ownable2Step, Pausable {
    bytes32 internal constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 internal constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 internal constant MINTER_AND_BURNER_ROLE =
        keccak256("MINTER_AND_BURNER_ROLE");

    mapping(address => bytes32) internal minterBurnerRole;

    event RoleUpdated(
        address indexed caller,
        address indexed grantedAccount,
        bytes32 grantedRole
    );

    /**
     * @dev Don't renounce ownership
     */
    function renounceOwnership() public view override onlyOwner {
        require(false, "Can't renounce ownership");
    }

    /**
     * @dev Pauses the contract. Only owner can call.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract. Only owner can call.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Grant an account permission to mint tokens.
     * If the account had burn permission, it gets revoked.
     * Only callable by the current owner.
     */
    function grantMintOnlyPermission(address _account) external onlyOwner {
        _setMintBurnRole(_account, MINTER_ROLE);
    }

    /**
     * @dev Grant an account permission to burn tokens.
     * If the account had mint permission, it gets revoked.
     * Only callable by the current owner.
     */
    function grantBurnOnlyPermission(address _account) external onlyOwner {
        _setMintBurnRole(_account, BURNER_ROLE);
    }

    /**
     * @dev Grant an account permission to mint as well as to burn tokens.
     * Only callable by the current owner.
     */
    function grantMintAndBurnPermission(address _account) external onlyOwner {
        _setMintBurnRole(_account, MINTER_AND_BURNER_ROLE);
    }

    /**
     * @dev Revoke mint and/or burn permission(s) from an account.
     * Only callable by the current owner.
     */
    function revokeMintOrBurnPermission(address _account) external onlyOwner {
        _setMintBurnRole(_account, bytes32(0));
    }

    /**
     * @dev Returns true if the specified account has permission to mint tokens.
     */
    function hasMintPermission(address _account) public view returns (bool) {
        return (minterBurnerRole[_account] == MINTER_AND_BURNER_ROLE ||
            minterBurnerRole[_account] == MINTER_ROLE);
    }

    /**
     * @dev Returns true if the specified account has permission to burn tokens.
     */
    function hasBurnPermission(address _account) public view returns (bool) {
        return (minterBurnerRole[_account] == MINTER_AND_BURNER_ROLE ||
            minterBurnerRole[_account] == BURNER_ROLE);
    }

    /**
     * @dev Returns true if the specified account has both
     * the permissions of minting and burning.
     */
    function hasBothMintAndBurnPermission(
        address _account
    ) public view returns (bool) {
        return minterBurnerRole[_account] == MINTER_AND_BURNER_ROLE;
    }

    /**
     * @dev Internal function to set any specified role for an account.
     */
    function _setMintBurnRole(address _account, bytes32 _role) internal {
        minterBurnerRole[_account] = _role;
        emit RoleUpdated(_msgSender(), _account, _role);
    }
}
