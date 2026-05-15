// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.28;

import {GenericERC20} from "./GenericERC20.sol";
import {IERC1046} from "./interfaces/IERC1046.sol";

contract GNET is GenericERC20, IERC1046 {
    string public tokenURI;

    constructor(
        string memory _tokenURI
    ) GenericERC20("GNET", "GNET", 1000000000 ether) {
        tokenURI = _tokenURI;
    }
}
