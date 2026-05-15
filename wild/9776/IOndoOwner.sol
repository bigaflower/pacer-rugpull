// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { IInspector } from "./IInspector.sol";
import { IMessenger } from "./IMessenger.sol";
import { IOndoOFT } from "./IOndoOFT.sol";
import { IRateLimiter, RateLimitConfig } from "./IRateLimiter.sol";

/**
 * @title IOndoOwner
 * @notice Interface for the Ondo Owner contract, which manages administrative access control
 * and ownership of various components in the Ondo bridge system.
 */
interface IOndoOwner {
    // @dev Custom error messages
    error CallFailed();
    error ConstructorAddressesZero(address inspector, address messenger, address rateLimiter);
    error OnlyAdminCanUnPause();
    error OnlyPendingOwner(address targetContract, address caller);

    // @dev Events
    event ContractOwnershipTransferStarted(address indexed targetContract, address indexed newOwner);
    event ContractOwnershipTransferClaimed(address indexed targetContract, address indexed newOwner);

    /**
     * @notice Returns the pending owner for a target contract.
     * @param targetContract The address of the target contract.
     * @return The address of the pending owner.
     */
    function pendingOwners(address targetContract) external view returns (address);

    // ------------------- View Functions -------------------
    function inspector() external view returns (IInspector);
    function messenger() external view returns (IMessenger);
    function rateLimiter() external view returns (IRateLimiter);

    // ------------------- Admin -------------------
    /**
     * @notice Allows the super admin to execute arbitrary calls to target contracts.
     * @param targetContract The address of the contract to call.
     * @param data The calldata to pass to the target contract.
     * @return success Boolean indicating if the call was successful.
     * @return result The return data from the call.
     */
    function superCall(
        address targetContract,
        bytes calldata data
    ) external returns (bool success, bytes memory result);

    /**
     * @notice Initiates the transfer of ownership for a target contract.
     * @param targetContract The address of the contract whose ownership is being transferred.
     * @param newOwner The address of the new owner.
     */
    function transferContractOwnership(address targetContract, address newOwner) external;

    /**
     * @notice Claims ownership of a target contract by the pending owner.
     * @param targetContract The address of the contract whose ownership is being claimed.
     */
    function claimContractOwnership(address targetContract) external;

    // ------------------- Inspector -------------------
    /**
     * @notice Sets the global paused state on the Inspector contract.
     * @param paused The state of the global pause.
     */
    function setGlobalPaused(bool paused) external;

    /**
     * @notice Sets the paused state for a specific ID on the Inspector contract.
     * @param id The identifier to set the pause state for.
     * @param paused The state of the pause.
     */
    function setIdPaused(bytes32 id, bool paused) external;

    // ------------------- Messenger -------------------
    /**
     * @notice Sets the Inspector for a Messenger contract.
     * @param inspector The Inspector contract instance to set.
     */
    function setInspector(IInspector inspector) external;

    /**
     * @notice Sets the RateLimiter for a Messenger contract.
     * @param rateLimiter The RateLimiter contract instance to set.
     */
    function setRateLimiter(IRateLimiter rateLimiter) external;

    /**
     * @notice Registers a new token with the Messenger.
     * @param tokenId The unique identifier for the token.
     * @param tokenAddress The address of the token contract.
     * @return oftAddress The address of the newly created OndoOFT contract.
     */
    function registerToken(bytes32 tokenId, address tokenAddress) external returns (address oftAddress);

    /**
     * @notice Deregisters an existing token from the Messenger.
     * @param tokenId The unique identifier for the token to be deregistered.
     */
    function deregisterToken(bytes32 tokenId) external;

    /**
     * @notice Registers a token with an existing OFT contract in the Messenger.
     * @param tokenId The unique identifier for the token.
     * @param tokenAddress The address of the token contract.
     * @param oftAddress The address of the existing OFT contract.
     */
    function registerTokenWithOFT(bytes32 tokenId, address tokenAddress, address oftAddress) external;

    // ------------------- OFT -------------------
    /**
     * @notice Sets the Messenger address for an OndoOFT contract.
     * @param oft The OndoOFT contract instance.
     * @param messenger The address of the Messenger contract.
     */
    function setMessengerOFT(IOndoOFT oft, address messenger) external;

    // ------------------- Rate Limiter -------------------
    /**
     * @notice Sets the Messenger address for a RateLimiter contract.
     * @param rateLimiter The RateLimiter contract instance.
     * @param messenger The address of the Messenger contract.
     */
    function setMessengerRateLimiter(IRateLimiter rateLimiter, address messenger) external;

    /**
     * @notice Configures rate limits for the RateLimiter contract.
     * @param configs An array of RateLimitConfig structs representing the rate limit configurations.
     */
    function configureRateLimits(RateLimitConfig[] calldata configs) external;
}
