// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

abstract contract Signature {
    using ECDSA for bytes32;

    address private signer; // Authorized signer
    mapping(bytes32 => bool) public nonces; // Tracks used nonces to prevent replay attacks

    function _setSigner(address _signer) internal {
        require(_signer != address(0), "Invalid signer address");
        signer = _signer;
    }

    /// @notice Verifies the cryptographic signature.
    /// @param data The hash of the data to verify.
    /// @param signature The signature to verify.
    /// @return True if the signature is valid, false otherwise.
    function _verifySignature(
        bytes32 data,
        bytes memory signature
    ) internal view returns (bool) {
        return data.toEthSignedMessageHash().recover(signature) == signer;
    }

    /// @notice Checks if the nonce is valid and hasn't been used.
    /// @param _nonce The nonce to check.
    /// @return True if the nonce is valid, false otherwise.
    function isValidNonce(bytes32 _nonce) public view returns (bool) {
        return !nonces[_nonce];
    }

    function _invalidateNonce(bytes32 _nonce) internal {
        nonces[_nonce] = true;
    }
}
