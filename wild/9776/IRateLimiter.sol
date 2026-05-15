// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

/**
 * @notice Rate Limit struct.
 * @param amount The current amount tracked against the rate limit.
 * @param lastUpdated Timestamp representing the last time the rate limit was checked or updated.
 * @param limit This represents the maximum allowed amount within a given window.
 * @param window Defines the duration of the rate limiting window.
 */
struct RateLimit {
    uint256 amount;
    uint256 lastUpdated;
    uint256 limit;
    uint256 window;
}

/**
 * @notice Rate Limit Configuration struct.
 * @param remoteEid The destination endpoint id.
 * @param tokenId The identifier for the token.
 * @param outboundLimit This represents the maximum allowed amount within a given window for outflows.
 * @param outboundWindow Defines the duration of the rate limiting window for outflows.
 * @param inboundLimit This represents the maximum allowed amount within a given window for inflows.
 * @param inboundWindow Defines the duration of the rate limiting window for inflows.
 */
struct RateLimitConfig {
    uint32 remoteEid;
    bytes32 tokenId;
    uint256 outboundLimit;
    uint256 outboundWindow;
    uint256 inboundLimit;
    uint256 inboundWindow;
}

/**
 * @title IRateLimiter
 * @notice Interface for the Rate Limiter, which manages rate limits for outflows and inflows of tokens.
 * @dev Indexes the rate limits by Id, can be done with token addresses etc.
 */
interface IRateLimiter {
    // @dev Custom error messages
    error MessengerIdempotent();
    error OnlyMessenger(address caller);
    error RateLimitExceeded();

    // @dev Events
    event MessengerSet(address indexed messenger);
    event RateLimitsSet(RateLimitConfig[] rateLimitConfig);

    // @dev The address of the Messenger contract, which is used to verify the caller in outflow and inflow functions.
    function messenger() external view returns (address);

    /**
     * @notice Sets the Messenger address, which is used to verify the caller in outflow and inflow functions.
     * @param _messenger The address of the Messenger contract.
     */
    function setMessenger(address _messenger) external;

    /**
     * @notice Configures the rate limits for the specified tokenId and destination endpoint id.
     * @param configs An array of `RateLimitConfig` structs representing the rate limit configurations.
     * - `remoteEid`: The destination endpoint id.
     * - `tokenId`: The identifier for the token.
     * - `outboundLimit`: This represents the maximum allowed amount within a given window for outflows.
     * - `outboundWindow`: Defines the duration of the rate limiting window for outflows.
     * - `inboundLimit`: This represents the maximum allowed amount within a given window for inflows.
     * - `inboundWindow`: Defines the duration of the rate limiting window for inflows.
     */
    function configureRateLimits(RateLimitConfig[] calldata configs) external;

    /**
     * @notice Current amount that can be sent to this dst endpoint id for the given rate limit window and tokenId.
     * @param tokenId The identifier for which the rate limit is being checked.
     * @param tokenAddress The address of the token from the corresponding Id.
     * @param remoteEid The remote endpoint id.
     * @return sendable The current amount that can be sent.
     * @return currentOutbound The current amount used for outbound flows.
     * @return receivable The amount that can be received.
     * @return currentInbound The current amount used for inbound flows.
     */
    function getAmountsAvailable(
        bytes32 tokenId,
        address tokenAddress,
        uint32 remoteEid
    ) external view returns (uint256 sendable, uint256 currentOutbound, uint256 receivable, uint256 currentInbound);

    /**
     * @notice Verifies whether the specified amount falls within the rate limit constraints for the targeted
     * endpoint ID. On successful verification, it updates amountInFlight and lastUpdated. If the amount exceeds
     * the rate limit, the operation reverts.
     * @param tokenId The identifier for the token.
     * @param tokenAddress The address of the token from the corresponding Id.
     * @param dstEid The destination endpoint id.
     * @param amount The amount to outflow.
     */
    function outflow(bytes32 tokenId, address tokenAddress, uint32 dstEid, uint256 amount) external;

    /**
     * @notice To be used when you want to calculate your rate limits as a function of net outbound AND inbound.
     * ie. If you move 150 out, and 100 in, your effective inflight should be 50.
     * Does not need to update decay values, as the inflow is effective immediately.
     * @param tokenId The identifier for the token.
     * @param tokenAddress The address of the token from the corresponding Id.
     * @param srcEid The source endpoint id.
     * @param amount The amount to inflow.
     */
    function inflow(bytes32 tokenId, address tokenAddress, uint32 srcEid, uint256 amount) external;
}
