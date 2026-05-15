// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IDataGold is IERC20Upgradeable {

    error InvalidAddress(address);
    error MintingDenied(address);
    error BurningDenied(address);
    error AccessDenied(address);

    function mint(address to, uint256 amount) external;

    function burn(uint256 amount) external;
}
