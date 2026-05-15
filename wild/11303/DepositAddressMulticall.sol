// SPDX-License-Identifier: MIT

/**
 *Submitted for verification at Etherscan.io on 2018-10-22
*/

pragma solidity ^0.8.13;

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

/**
 * @dev Struct representing token parameters for the OFT send() operation.
 */
struct SendParam {
    uint32 dstEid;        // Destination endpoint ID.
    bytes32 to;           // Recipient address.
    uint256 amountLD;     // Amount to send in local decimals.
    uint256 minAmountLD;  // Minimum amount to send in local decimals.
    bytes extraOptions;   // Additional options supplied by the caller to be used in the LayerZero message.
    bytes composeMsg;     // The composed message for the send() operation.
    bytes oftCmd;         // The OFT command to be executed, unused in default OFT implementations.
}

struct MessagingFee {
    uint256 nativeFee; // The native fee.
    uint256 lzTokenFee; // The lzToken fee.
}

/**
 * @dev Minimal structs to model OFT send() return types.
 */
struct MessagingReceipt {
    // LayerZero msg receipt
    bytes32 guid;   // The unique identifier for the sent message.
    uint64 nonce;   // The nonce of the sent message.
    uint256 fee;    // The LayerZero fee incurred for the message.
}

struct OFTReceipt {
    uint256 amountSentLD;
    uint256 amountReceivedLD;
}

interface IOFT {
    /**
     * @dev Executes the send operation.
     * @param _sendParam The parameters for the send operation.
     * @param _fee The calculated fee for the send() operation.
     *      - nativeFee: The native fee.
     *      - lzTokenFee: The lzToken fee.
     * @param _refundAddress The address to receive any excess funds.
     * @return msgReceipt The receipt for the send operation.
     * @return oftReceipt The OFT receipt information.
     *
     * @dev MessagingReceipt: LayerZero msg receipt
     *  - guid: The unique identifier for the sent message.
     *  - nonce: The nonce of the sent message.
     *  - fee: The LayerZero fee incurred for the message.
     */
    function send(
        SendParam calldata _sendParam,
        MessagingFee calldata _fee,
        address _refundAddress
    ) external payable returns (MessagingReceipt memory msgReceipt, OFTReceipt memory oftReceipt);
}

struct OFTDepositParams {
    address oftContract;
    bool requiresAllowance;
    SendParam sendParam;
    MessagingFee messagingFee;
    address refundAddress;
    address erc20Contract;
    address feeRecipient;
    uint256 fees;
}

contract DepositAddress {
    // Reentrancy lock
    bool private locked;

    // Deposit address Multicall address
    address private constant AUTHORIZED_CALLER = 0xf2154Bd34f5538019AaFC335C22179dA742A394B;
    
    modifier nonReentrant() {
        require(!locked, "Reentrant call");
        locked = true;
        _;
        locked = false;
    }

    function transfer(OFTDepositParams memory params) external payable nonReentrant {
        require(msg.sender == AUTHORIZED_CALLER, "Unauthorized");

        if (params.requiresAllowance) {
            IERC20(params.erc20Contract).approve(params.oftContract, params.sendParam.amountLD);
        }

        IOFT(params.oftContract).send{value: msg.value}(params.sendParam, params.messagingFee, params.refundAddress);

        if (params.fees > 0) {
            IERC20(params.erc20Contract).transfer(params.feeRecipient, params.fees);
        }
    }
}

contract DepositAddressMulticall {
    address public authorizedCaller;
    
    constructor(address _authorizedCaller) {
        authorizedCaller = _authorizedCaller;
    }
    
    function batchTransfer(OFTDepositParams[] calldata calls, address[] calldata depositAddresses) external payable {
        require(msg.sender == authorizedCaller, "Only authorized caller can batch");
        require(calls.length == depositAddresses.length, "Calls and deposit addresses must have the same length");
        
        for (uint i = 0; i < calls.length; i++) {
            DepositAddress(depositAddresses[i]).transfer{value: calls[i].messagingFee.nativeFee}(calls[i]);
        }
    }
}