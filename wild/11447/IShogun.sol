// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface IShogun {
    function mintLPTokens() external;

    function burnCAShogun(address contractAddress) external;

    function genesisTs() external returns (uint256);

    function getGenesisAddress() external returns (address);

    function getLPAddress() external returns (address);
}
