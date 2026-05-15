// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.7.0;

interface IDAI {

    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) external returns (bool);
}