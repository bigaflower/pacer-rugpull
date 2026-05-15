// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract CustomToken is Initializable, ERC20Upgradeable {
    uint8 private _customDecimals;

    function initialize(
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_,
        uint8 decimals_,
        address owner_
    ) public initializer {
        __ERC20_init(name_, symbol_);
        _customDecimals = decimals_;
        _mint(owner_, totalSupply_ * 10 ** decimals_);
    }

    function decimals() public view override returns (uint8) {
        return _customDecimals;
    }
}
