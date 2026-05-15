// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

/**
 * @title IInspector
 * @notice Interface for the Messaging Inspector, allowing examination of message and options contents.
 */
interface IInspector {
    // @dev Custom error messages
    error InspectionFailed(bytes message, bytes options);
    error GlobalPausedIdempotent(bool paused);
    error IdPausedIdempotent(bytes32 id, bool paused);
    error GlobalPaused();
    error IdPaused(bytes32 id);

    // @dev Events
    event GlobalPausedSet(bool paused);
    event IdPausedSet(bytes32 id, bool paused);

    /**
     * @notice Sets the global paused value.
     * @param paused The state of the global pause.
     * @dev Sets a global pause state applied to all messages that are inspected.
     */
    function setGlobalPaused(bool paused) external;

    /**
     * @notice Sets the id paused value.
     * @param id The identifier.
     * @param paused The state of the pause.
     * @dev Sets the pause state for a given 'id'.
     */
    function setIdPaused(bytes32 id, bool paused) external;

    /**
     * @notice Allows the inspectee to examine LayerZero message contents and optionally throw a revert if invalid.
     * @param id The identifier being inspected.
     * @param message The message payload to be inspected.
     * @param options Additional options or parameters for inspection.
     */
    function inspect(bytes32 id, bytes calldata message, bytes calldata options) external view;
}
