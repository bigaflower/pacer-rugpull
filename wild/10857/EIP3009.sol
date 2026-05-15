// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.7.0;

interface EIP3009 {
    

    function transferWithAuthorization(
        address from,
        address to,
        uint256 value,
        uint256 validAfter,
        uint256 validBefore,
        bytes32 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

}
