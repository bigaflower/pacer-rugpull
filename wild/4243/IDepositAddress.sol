// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC20 } from "contracts/token/ERC20/IERC20.sol";

interface IDepositAddress {
    function setTransferApproval(IERC20 token) external;
    function sweepNative(uint256 amount) external;
}
