// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface IHydra {
    function mintLPTokens(uint256 amount) external;

    function burnCAHydra(address contractAddress) external;

    function fundVortexTitanX(uint256 amount) external;

    function fundVortexDragonX(uint256 amount) external;

    function supportsInterface(bytes4 interfaceId) external returns (bool);
}
