// SPDX-License-Identifier: MIT
pragma solidity =0.8.12;

import "./ERC20Detailed.sol";

contract IXFI is ERC20Detailed {
    constructor() ERC20Detailed("IXFI", "IXFI", 18, 5000000000000000000000000000, 0x01D3375701ee7d3AA219dD6888EEc0126A256404) {
    }
}

