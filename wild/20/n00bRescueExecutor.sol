// SPDX-License-Identifier: MIT
pragma solidity =0.8.12;

/**
 * @title n00bRescueExecutor
 * @author @ylasgamers
 * @notice n00b Rescue EVM Tool By n00b Rescue Team, This tool helps recover assets from compromised wallets using sponsor wallets.
 * @dev This contract for execute rescue from site n00brescue.xyz using eip-7702.
 * x : x.com/n00brescue
 * telegram : t.me/n00brescue
 * website : n00brescue.xyz
 */

contract n00bRescueExecutor {
    struct n00bCall {
        address target;
        bool allowFailure;
        uint256 value;
        bytes callData;
    }

    struct Result {
        bool success;
        bytes returnData;
    }

    address public owner = 0x000003978375010c4A7699446d2852a656cd8b06;
    address public signer;

    mapping(address => uint256) public nonces; // user => current nonce

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor() {}

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid owner");
        owner = newOwner;
    }

    function setSigner(address newSigner) external onlyOwner {
        require(newSigner != address(0), "Invalid signer");
        signer = newSigner;
    }

    function getMessageHash(address user, uint256 nonce, uint256 expiry) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(user, nonce, expiry));
    }

    function getEthSignedMessageHash(bytes32 messageHash) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
    }

    function verify(
        address user,
        uint256 nonce,
        uint256 expiry,
        bytes memory signature
    ) public view returns (bool) {
        bytes32 messageHash = getMessageHash(user, nonce, expiry);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return recoverSigner(ethSignedMessageHash, signature) == signer;
    }

    function recoverSigner(bytes32 ethSignedMessageHash, bytes memory signature) public pure returns (address) {
        require(signature.length == 65, "Invalid signature length");
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }
        if (v < 27) v += 27;
        require(v == 27 || v == 28, "Invalid v");
        return ecrecover(ethSignedMessageHash, v, r, s);
    }

    function n00bRescueCall(
        n00bCall[] calldata calls,
        address user,
        uint256 expiry,
        bytes calldata signature
    ) external payable returns (Result[] memory returnData) {
        uint256 nonce = nonces[user];
        require(block.timestamp <= expiry, "Signature expired");
        require(verify(user, nonce, expiry, signature), "Invalid signature");

        // increment nonce to prevent replay
        nonces[user]++;

        uint256 valAccumulator;
        uint256 length = calls.length;
        returnData = new Result[](length);
        n00bCall calldata calln00b;
        for (uint256 i = 0; i < length;) {
            Result memory result = returnData[i];
            calln00b = calls[i];
            uint256 val = calln00b.value;
            unchecked { valAccumulator += val; }
            (result.success, result.returnData) = calln00b.target.call{value: val}(calln00b.callData);
            assembly {
                if iszero(or(calldataload(add(calln00b, 0x20)), mload(result))) {
                    mstore(0x00, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                    mstore(0x04, 0x0000000000000000000000000000000000000000000000000000000000000020)
                    mstore(0x24, 0x0000000000000000000000000000000000000000000000000000000000000017)
                    mstore(0x44, 0x6E30306252657363756543616C6C3A204661696C6564000000000000000000)
                    revert(0x00, 0x84)
                }
            }
            unchecked { ++i; }
        }
        require(msg.value == valAccumulator, "n00bRescueCall: value mismatch");
    }
}