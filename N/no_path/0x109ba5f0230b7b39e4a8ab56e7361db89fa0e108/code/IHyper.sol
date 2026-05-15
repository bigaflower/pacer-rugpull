// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

interface IHyper is IERC20 {
    function updateVault() external;
}
