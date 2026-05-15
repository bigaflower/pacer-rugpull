//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract LayerEdgeToken is ERC20Permit {
    constructor(string memory name, string memory symbol, uint256 _totalSupply, address _custody) ERC20(name, symbol) ERC20Permit(name) {
        _mint(_custody, _totalSupply);
    }
}
