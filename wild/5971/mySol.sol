pragma solidity ^0.8.27;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract Tatracoin is ERC20, ERC20Permit {
    constructor(address recipient)
        ERC20("Tatracoin", "TC")
        ERC20Permit("Tatracoin")
    {
        _mint(recipient, 12000000 * 10 ** decimals());
    }
}