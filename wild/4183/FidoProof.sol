// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract FidoProof is ERC20 {
    constructor(uint256 initialSupply) ERC20("FidoProof", "FDP") {
        _mint(msg.sender, initialSupply);
    }
}