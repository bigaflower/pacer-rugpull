// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import { Origin } from "@layerzerolabs/oapp-evm/contracts/oapp/OApp.sol";

// @dev Disabling unused, because we want to pipe down the structs so we ensure correct ones are used.
// solhint-disable no-unused-import
import { IOFT, SendParam, MessagingFee, MessagingReceipt, OFTLimit, OFTFeeDetail, OFTReceipt } from "@layerzerolabs/oft-evm/contracts/interfaces/IOFT.sol";

/**
 * @title IOndoOFT
 * @notice Interface for the Ondo OFT, which extends the LayerZero OFT interface.
 * @dev This interface is used for handling cross-chain messaging and operations then routing to the Messenger contract.
 */
interface IOndoOFT is IOFT {
    // @dev Custom error messages
    error OnlyMessenger(address messenger);
    error EndpointMismatch(address actualEndpoint, address expectedEndpoint);

    // @dev Events
    event MessengerSet(address indexed messenger);

    /**
     * @notice The unique identifier for this token in the bridge system.
     * @return The token ID as a bytes32 value.
     */
    function tokenId() external view returns (bytes32);

    /**
     * @notice Sets the messenger address for the OFT contract.
     * @param _messenger The address of the messenger contract.
     *
     * @dev This function can only be called by the owner of the contract.
     * It allows changing the messenger address to a new one.
     */
    function setMessenger(address _messenger) external;

    /**
     * @notice Internal function to handle the receive on the LayerZero endpoint.
     * @param origin The origin information.
     *  - srcEid: The source chain endpoint ID.
     *  - sender: The sender address from the src chain.
     *  - nonce: The nonce of the LayerZero message.
     * @param guid The unique identifier for the received LayerZero message.
     * @param message The encoded message.
     * @param executor The address of the executor.
     * @param extraData Additional data.
     *
     * @dev This varies from the traditional lzReceive() because the OFT itself is NOT an OApp,
     * and thus we need to validate it comes from the current Messenger contract
     */
    function messagingReceive(
        Origin calldata origin,
        bytes32 guid,
        bytes calldata message,
        address executor,
        bytes calldata extraData
    ) external;
}
