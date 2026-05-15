// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract BNPLToken is ERC20, AccessControl {
	constructor(address treasury) ERC20("BNPL", "BNPL") {
		_mint(treasury, 1_000_000_000 * (10 ** 18));
	}
}
