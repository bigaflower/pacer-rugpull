// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "../contracts/openzeppelin/token/ERC20/IERC20.sol";

interface ITITANX is IERC20 {
    function startMint(uint256 mintPower, uint256 numOfDays) external payable;

    function batchMint(uint256 mintPower, uint256 numOfDays, uint256 count) external payable;

    function claimMint(uint256 id) external;

    function batchClaimMint() external;

    function burnLPTokens() external;
}
