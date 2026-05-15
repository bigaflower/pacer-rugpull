// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ELP is ERC20Permit {
    constructor(
        string memory name,
        string memory symbol,
        address initialSupplyReceiver
    ) ERC20Permit(name) ERC20(name, symbol) {
        _mint(initialSupplyReceiver, 3_500_000_000 * (10 ** decimals()));
    }
}
