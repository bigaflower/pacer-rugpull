// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../libraries/CopyrightToken.sol";

/**
 * @dev BasicToken: Simple ERC20 implementation
 */
contract BasicToken is ERC20, CopyrightToken {
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 initialSupply_,
        address payable feeReceiver_
    ) payable ERC20(name_, symbol_) {
        require(initialSupply_ > 0, "BasicToken: initial supply cannot be zero");
        payable(feeReceiver_).transfer(msg.value);
        _mint(_msgSender(), initialSupply_);
    }
}
