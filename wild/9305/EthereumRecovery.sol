// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract EthereumRecovery is ERC20, Ownable {
    constructor() ERC20("Ethereum Recovery", "ETHR") Ownable(msg.sender) {
        // Mint 1 million tokens (1,000,000 * 10^18) to deployer
        _mint(msg.sender, 1_000_000 * 10 ** decimals());
    }
}
