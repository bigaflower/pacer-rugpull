// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PietyPC is ERC20, Ownable {
    uint256 public constant INITIAL_SUPPLY = 3_100_000_000 * 10**18;

    constructor(address initialOwner)
        ERC20("Piety PayChain", "PietyPC")
        Ownable(initialOwner)
    {
        _mint(initialOwner, INITIAL_SUPPLY);
    }
}