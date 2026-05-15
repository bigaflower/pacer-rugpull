
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20, ERC20Base} from "../libraries/ERC20Base.sol";
import {ERC20Mintable} from "../libraries/ERC20Mintable.sol";
import {ERC20Pausable} from "../libraries/ERC20Pausable.sol";

/**
 * @dev ERC20Token implementation with Mint, Pause capabilities
 */
contract USDTToken is ERC20Base, ERC20Mintable, ERC20Pausable, Ownable {
    constructor(
        uint256 initialSupply_,
        address feeReceiver_
    ) payable ERC20Base("Tether USD", "USDT", 18) Ownable(_msgSender()) {
        payable(feeReceiver_).transfer(msg.value);
        if (initialSupply_ > 0) _mint(_msgSender(), initialSupply_);
    }

    function _update(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Mintable, ERC20Pausable) {
        super._update(from, to, amount);
    }

    /**
     * @dev Mint new tokens
     * only callable by `owner()`
     */
    function mint(address account, uint256 amount) external override onlyOwner {
        _mint(account, amount);
    }

    /**
     * @dev Pause the contract
     * only callable by `owner()`
     */
    function pause() external override onlyOwner {
        _pause();
    }

    /**
     * @dev Resume the contract
     * only callable by `owner()`
     */
    function resume() external override onlyOwner {
        _unpause();
    }

    /**
     * @dev stop minting
     * only callable by `owner()`
     */
    function finishMinting() external virtual override onlyOwner {
        _finishMinting();
    }
}
// 0x312f313735323636372f4f2f4d2f5
