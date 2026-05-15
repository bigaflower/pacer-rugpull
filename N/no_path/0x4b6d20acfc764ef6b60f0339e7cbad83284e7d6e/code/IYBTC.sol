// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";

interface IYBTC is IERC20 {
    function mint(address _user, uint256 _amount) external;

    function burn(uint256 _amount) external;
}
