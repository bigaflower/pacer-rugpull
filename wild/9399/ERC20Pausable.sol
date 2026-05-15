// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {ERC20Base} from "./ERC20Base.sol";

/**
 * @dev ERC20 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC20Pausable is ERC20Base, Pausable {
    /**
     * @dev Pause the contract
     * Access restriction must be overriden in derived class
     */
    function pause() external virtual {
        _pause();
    }

    /**
     * @dev Resume the contract
     * Access restriction must be overriden in derived class
     */
    function resume() external virtual {
        _unpause();
    }

    /**
     * verify that the contract is not paused before transfering tokens.
     */
    function _update(address from, address to, uint256 value) internal virtual override {
        require(!paused(), "ERC20Pausable: transfer paused");
        super._update(from, to, value);
    }
}
