// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import {ERC20} from "@openzeppelin/contracts@5.4.0/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts@5.4.0/token/ERC20/extensions/ERC20Burnable.sol";

contract LiquidChainToken is ERC20, ERC20Burnable {
    uint256 public constant aquaVaultReserve = 1_770_000_015 ether;
    uint256 public constant liquidLabsReserve = 3_835_000_032 ether;
    uint256 public constant rewardsReserve = 1_180_000_010 ether;
    uint256 public constant growthAndListingsReserve = 885_000_008 ether;
    uint256 public constant developmentReserve = 4_130_000_035 ether;
    constructor() ERC20("LiquidChain", "LIQUID") {
        _mint(0x2e067C037A2dD719dA429e7e18A87392950c0E63, aquaVaultReserve);
        _mint(0x6cc3893e2a220FD50Bc18cBfeba5567D62Ef4861, liquidLabsReserve);
        _mint(0x3BB0421a6B1b9F0D3328Aa344b53E0B560C6Db9C, rewardsReserve);
        _mint(0xC67E691117954cD6e145D40579511199cf2cac2c, growthAndListingsReserve);
        _mint(0x5F7dfc726eBe3B8aD2a0FDDAc953F8CeCFc392ce, developmentReserve);
    }
}
