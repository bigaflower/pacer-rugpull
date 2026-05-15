// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "../contracts/openzeppelin/token/ERC20/IERC20.sol";

interface IX28 is IERC20 {
    function mintX28withTitanX(uint256 amount) external;

    function burnCAX28(address contractAddress) external;
}
