// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import { IOAppCore } from "@layerzerolabs/oapp-evm/contracts/oapp/interfaces/IOAppCore.sol";
import { MessagingFee, MessagingReceipt } from "@layerzerolabs/oft-evm/contracts/interfaces/IOFT.sol";

/**
 * @notice Struct representing messaging parameters for the Messenger send() operation.
 */
struct MessagingParam {
    uint32 dstEid; // Destination endpoint ID.
    bytes32 to; // Recipient address.
    uint256 amountLD; // Amount to send in local decimals.
    bytes extraOptions; // Additional options supplied by the caller to be used in the LayerZero message.
    bytes composeMsg; // The composed message for the send() operation.
}

/**
 * @title IMessenger
 * @notice Interface for the Messenger, the OApp responsible for routing OFT messages cross-chain.
 */
interface IMessenger is IOAppCore {
    // @dev Custom error messages
    error InvalidTokenRegistration(bytes32 tokenId, address tokenAddress);
    error InvalidTokenRegistrationWithOFT(bytes32 tokenId, address tokenAddress, address oftAddress);
    error TokenAlreadyRegistered(bytes32 tokenId, address tokenAddress);
    error TokenNotRegistered(bytes32 tokenId);
    error OFTAlreadyRegistered(address oftAddress, bytes32 existingTokenId);
    error InvalidOFT(address oft);
    error InvalidTokenId(bytes32 tokenId);
    error InvalidRateLimiter();

    // @dev Events
    event InspectorSet(address inspector);
    event RateLimiterSet(address rateLimiter);
    event TokenRegistered(bytes32 indexed tokenId, address indexed tokenAddress, address indexed oftAddress);
    event TokenDeregistered(bytes32 indexed tokenId, address indexed tokenAddress, address indexed oftAddress);

    // @dev Interface functions for the token detail mappings
    function idToOft(bytes32 tokenId) external view returns (address oftAddress);
    function idToToken(bytes32 tokenId) external view returns (address tokenAddress);
    function oftToId(address oftAddress) external view returns (bytes32 tokenId);

    /**
     * @notice Sets the inspector address, which is used to inspect messages before they are sent.
     * @param inspector The address of the inspector contract.
     * @dev This can be set to address(0) if no inspector is required.
     */
    function setInspector(address inspector) external;

    /**
     * @notice Sets the rate limiter address, which is used to validate inflows and outflows of tokens.
     * @param rateLimiter The address of the rate limiter contract.
     */
    function setRateLimiter(address rateLimiter) external;

    /**
     * @notice Registers a new token with its corresponding generated OFT contract.
     * @param tokenId The unique identifier for the token.
     * @param tokenAddress The address of the token contract.
     * @return oftAddress The address of the newly created OndoOFT contract.
     *
     * @dev This function is more limited in that it can only register a brand new tokenId, it cannot alter existing.
     */
    function registerToken(bytes32 tokenId, address tokenAddress) external returns (address oftAddress);

    /**
     * @notice Deregisters an existing token and clears all associated mappings.
     * @param tokenId The unique identifier for the token to be deregistered.
     *
     * @dev This function completely removes the token from all mappings, making it no longer usable.
     */
    function deregisterToken(bytes32 tokenId) external;

    /**
     * @notice Registers a token with an existing OFT contract address.
     * @param tokenId The unique identifier for the token.
     * @param tokenAddress The address of the token contract.
     * @param oftAddress The address of the existing OFT contract.
     *
     * @dev This function allows registering with a pre-existing OFT contract instead of creating a new one.
     * @dev Useful for fixing registration mistakes or migrating to new OFT contracts.
     */
    function registerTokenWithOFT(bytes32 tokenId, address tokenAddress, address oftAddress) external;

    /**
     * @notice Provides rate limit available for sending and receiving tokens by routing the call to the rateLimiter.
     * @param _tokenId The identifier for which the rate limit is being checked.
     * @param _tokenAddress The address of the token from the corresponding Id.
     * @param _remoteEid The remote endpoint id.
     * @return sendable The current amount that can be sent.
     * @return currentOutbound The current amount used for outbound flows.
     * @return receivable The amount that can be received.
     * @return currentInbound The current amount used for inbound flows.
     */
    function getRateLimitedAmounts(
        bytes32 _tokenId,
        address _tokenAddress,
        uint32 _remoteEid
    ) external view returns (uint256 sendable, uint256 currentOutbound, uint256 receivable, uint256 currentInbound);

    /**
     * @notice Provides a quote for the send() operation.
     * @param messagingParam The parameters for the send() operation.
     * @param payInLzToken Flag indicating whether the caller is paying in the LZ token.
     * @return msgFee The calculated LayerZero messaging fee from the send() operation.
     *
     * @dev MessagingFee: LayerZero msg fee
     *  - nativeFee: The native fee.
     *  - lzTokenFee: The lzToken fee.
     */
    function quoteSend(
        MessagingParam calldata messagingParam,
        bool payInLzToken
    ) external view returns (MessagingFee memory msgFee);

    /**
     * @notice Executes and routes the send function through the endpoint.
     * @param messagingParam The parameters for the send() operation.
     * @param fee The calculated fee for the send() operation.
     *      - nativeFee: The native fee.
     *      - lzTokenFee: The lzToken fee.
     * @param refundAddress The address to receive any excess funds.
     * @return msgReceipt The receipt for the send operation.
     *
     * @dev Since this is an external version, MUST index on the msg.sender to verify it's a valid OFT calling this.
     *
     * @dev MessagingReceipt: LayerZero msg receipt
     *  - guid: The unique identifier for the sent message.
     *  - nonce: The nonce of the sent message.
     *  - fee: The LayerZero fee incurred for the message.
     */
    function send(
        MessagingParam calldata messagingParam,
        MessagingFee calldata fee,
        address refundAddress
    ) external payable returns (MessagingReceipt memory msgReceipt);
}
