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

import {RolesAuthority} from "./RolesAuthority.sol";

import "../../config/constants.sol";
import "../../config/errors.sol";

/// @notice Abstract contract that provides a base for role-based access control.
/// @author dsshap (Circle)
abstract contract Access {
    /*///////////////////////////////////////////////////////////////
                         Immutables & Constants
    //////////////////////////////////////////////////////////////*/

    /// @notice authority to check entitlements
    RolesAuthority public immutable authority;

    /*///////////////////////////////////////////////////////////////
                         Storage Variables
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     */
    uint256[50] private __gap;

    /// @notice bytes sig for token transfer function
    bytes4 private constant _TOKEN_TRANSFER_SELECTOR = bytes4(keccak256("transfer(address,uint256)"));

    constructor(address _authority) {
        if (_authority == address(0)) revert BadAddress();

        authority = RolesAuthority(_authority);
    }

    /**
     * @dev queries if msg.sender is fund admin
     *
     */
    function _isFundAdmin() internal view virtual returns (bool) {
        return authority.doesUserHaveRole(msg.sender, ROLE_FUND_ADMIN);
    }

    /**
     * @dev asserts that msg.sender is fund admin
     *
     */
    function _assertFundAdmin() internal view virtual {
        if (!_isFundAdmin()) revert NotPermissioned();
    }

    /**
     * @dev asserts that address is able to call function
     *
     */
    function _assertPermission(address addr) internal view virtual {
        _assertCanCall(addr, address(this), msg.sig);
    }

    /**
     * @dev asserts that address is able to transfer erc20 token
     *
     */
    function _assertCanReceive(address token, address addr) internal view virtual {
        _assertCanCall(addr, token, _TOKEN_TRANSFER_SELECTOR);
    }

    /**
     * @dev asserts that two addresses can transfer erc20 token
     *
     */
    function _assertCanReceive(address token, address addr1, address addr2) internal view virtual {
        _assertCanCall(addr1, addr2, token, _TOKEN_TRANSFER_SELECTOR);
    }

    /**
     * @dev call authority and asserts if address can call function on target
     *
     */
    function _assertCanCall(address addr, address target, bytes4 functionSig) internal view virtual {
        if (!authority.canCall(addr, target, functionSig)) revert NotPermissioned();
    }

    /**
     * @dev call authority and asserts if two addresses can call function on target
     *
     */
    function _assertCanCall(address addr1, address addr2, address target, bytes4 functionSig) internal view virtual {
        if (!authority.canCall(addr1, addr2, target, functionSig)) revert NotPermissioned();
    }
}
