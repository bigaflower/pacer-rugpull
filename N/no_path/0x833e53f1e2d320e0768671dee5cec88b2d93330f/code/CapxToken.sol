// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/*
 ██████╗ █████╗ ██████╗ ██╗  ██╗
██╔════╝██╔══██╗██╔══██╗╚██╗██╔╝
██║     ███████║██████╔╝ ╚███╔╝ 
██║     ██╔══██║██╔═══╝  ██╔██╗ 
╚██████╗██║  ██║██║     ██╔╝ ██╗
 ╚═════╝╚═╝  ╚═╝╚═╝     ╚═╝  ╚═╝                       
*/

contract CapxToken is ERC20Permit, Ownable {
    constructor(
        string memory _name,
        string memory _symbol,
        address _owner
    ) ERC20(_name, _symbol) ERC20Permit(_name) Ownable(_owner) {
        _mint(_owner, 1_000_000_000 * 10 ** decimals());
    }
}