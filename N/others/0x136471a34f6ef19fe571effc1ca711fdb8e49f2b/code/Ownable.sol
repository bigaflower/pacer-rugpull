/**
 * Copyright 2025 Circle Internet Group, Inc. All rights reserved.
 *
 * SPDX-License-Identifier: Apache-2.0
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
pragma solidity ^0.8.0;

import "../../config/errors.sol";

/// @notice Slimmed down version of OpenZeppelin's Ownable2Step contract.
/// @author dsshap (Circle)
abstract contract Ownable {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /*///////////////////////////////////////////////////////////////
                          State Variables V1
    //////////////////////////////////////////////////////////////*/

    address public owner;
    address public pendingOwner;

    /// @notice gap from OwnableUpgradeable(49) - pendingOwner
    uint256[48] private __gap;

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _assertOwner() internal view virtual {
        if (owner != msg.sender) revert NoAccess();
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual {
        _assertOwner();

        if (newOwner == address(0)) revert BadAddress();

        pendingOwner = newOwner;

        emit OwnershipTransferStarted(owner, newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() external {
        if (pendingOwner != msg.sender) revert NoAccess();

        _transferOwnership(pendingOwner);
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual {
        _assertOwner();
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        delete pendingOwner;

        emit OwnershipTransferred(owner, newOwner);

        owner = newOwner;
    }
}
