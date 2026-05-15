// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Used to put cooldown USDz from sUSDz contract.
 */
contract USDzFlat {
    address public immutable susdz;
    IERC20 public immutable usdz;

    constructor(address _susdz, IERC20 _usdz) {
        susdz = _susdz;
        usdz = _usdz;
    }

    modifier onlysUSDz() {
        require(msg.sender == susdz, "CAN_ONLY_CALLED_BY_SUSDZ");
        _;
    }

    function withdraw(address _to, uint256 _amount) external onlysUSDz {
        usdz.transfer(_to, _amount);
    }
}
