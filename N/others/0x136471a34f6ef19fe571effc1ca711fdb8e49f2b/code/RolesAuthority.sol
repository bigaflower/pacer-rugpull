// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import {UUPSUpgradeable} from "openzeppelin/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "openzeppelin/proxy/utils/Initializable.sol";
import {RolesUtil} from "./RolesUtil.sol";
import {Ownable} from "./Ownable.sol";

import {IAuthority} from "../../interfaces/IAuthority.sol";

import "../../config/errors.sol";

/// @notice Role based Authority that supports up to 256 roles.
/// @author dsshap (Circle)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/authorities/RolesAuthority.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-roles/blob/master/src/roles.sol)
contract RolesAuthority is IAuthority, Initializable, Ownable, UUPSUpgradeable {
    using RolesUtil for bytes32;

    /*///////////////////////////////////////////////////////////////
                         State Variables V1
    //////////////////////////////////////////////////////////////*/

    bool public paused;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event UserRoleUpdated(address indexed user, uint8 indexed role, bool enabled);

    event PublicCapabilityUpdated(address indexed target, bytes4 indexed functionSig, bool enabled);

    event RoleCapabilityUpdated(uint8 indexed role, address indexed target, bytes4 indexed functionSig, bool enabled);

    event Paused(address account);

    event Unpaused(address account);

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor() {
        _disableInitializers();
    }

    /*///////////////////////////////////////////////////////////////
                            Initializer
    //////////////////////////////////////////////////////////////*/

    function initialize(address _owner) external initializer {
        if (_owner == address(0)) revert BadAddress();

        owner = _owner;
    }

    /*//////////////////////////////////////////////////////////////
                            ROLE/USER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => bytes32) public getUserRoles;

    mapping(address => mapping(bytes4 => bool)) public isCapabilityPublic;

    mapping(address => mapping(bytes4 => bytes32)) public getRolesWithCapability;

    function doesUserHaveRole(address user, uint8 role) public view virtual returns (bool) {
        if (paused) revert NoAccess();

        return getUserRoles[user].doesHaveRole(role);
    }

    function doesRoleHaveCapability(uint8 role, address target, bytes4 functionSig) public view virtual returns (bool) {
        if (paused) revert NoAccess();

        return getRolesWithCapability[target][functionSig].doesHaveCapability(role);
    }

    /*//////////////////////////////////////////////////////////////
                           AUTHORIZATION LOGIC
    //////////////////////////////////////////////////////////////*/

    function canCall(address user, address target, bytes4 functionSig) public view virtual returns (bool) {
        if (paused) revert NoAccess();

        return
            isCapabilityPublic[target][functionSig]
                || bytes32(0) != getUserRoles[user] & getRolesWithCapability[target][functionSig];
    }

    function canCall(address user1, address user2, address target, bytes4 functionSig) public view virtual returns (bool) {
        return canCall(user1, target, functionSig) && canCall(user2, target, functionSig);
    }

    /*//////////////////////////////////////////////////////////////
                   ROLE CAPABILITY CONFIGURATION LOGIC
    //////////////////////////////////////////////////////////////*/

    function _assertPermissions() internal view {
        if (!canCall(msg.sender, address(this), msg.sig)) revert NoAccess();
    }

    function setPublicCapability(address target, bytes4 functionSig, bool enabled) public virtual {
        _assertPermissions();

        isCapabilityPublic[target][functionSig] = enabled;

        emit PublicCapabilityUpdated(target, functionSig, enabled);
    }

    function setRoleCapability(uint8 role, address target, bytes4 functionSig, bool enabled) public virtual {
        role == type(uint8).max ? _assertOwner() : _assertPermissions();

        if (enabled) getRolesWithCapability[target][functionSig] |= bytes32(1 << role);
        else getRolesWithCapability[target][functionSig] &= ~bytes32(1 << role);

        emit RoleCapabilityUpdated(role, target, functionSig, enabled);
    }

    /*//////////////////////////////////////////////////////////////
                       USER ROLE ASSIGNMENT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _setUserRole(address user, uint8 role, bool enabled) internal virtual {
        if (enabled) getUserRoles[user] |= bytes32(1 << role);
        else getUserRoles[user] &= ~bytes32(1 << role);

        emit UserRoleUpdated(user, uint8(role), enabled);
    }

    function setUserRole(address user, uint8 role, bool enabled) public virtual {
        if (role == type(uint8).max) _assertOwner();
        else _assertPermissions();

        _setUserRole(user, role, enabled);
    }

    function setUserRoleBatch(address[] memory users, uint8[] memory roles, bool[] memory enabled) public virtual {
        _assertPermissions();

        uint256 length = users.length;
        if (length == 0 || length != roles.length || length != enabled.length) revert BadArrayLength();

        for (uint256 i; i < length;) {
            if (roles[i] == type(uint8).max) _assertOwner();

            _setUserRole(users[i], roles[i], enabled[i]);

            unchecked {
                ++i;
            }
        }
    }

    function revokeRole(uint8 role) external virtual {
        if (!doesUserHaveRole(msg.sender, role)) revert NoAccess();

        _setUserRole(msg.sender, role, false);
    }

    /*//////////////////////////////////////////////////////////////
                            PAUSE LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Pauses
     * @dev reverts on any check of permissions preventing any movement of funds
     *      between vault, auction, and option protocol
     */
    function pause() public {
        _assertPermissions();

        paused = true;

        emit Paused(msg.sender);
    }

    /**
     * @notice Unpauses
     */
    function unpause() public {
        _assertOwner();

        paused = false;

        emit Unpaused(msg.sender);
    }

    /*///////////////////////////////////////////////////////////////
                    Override Upgrade Permission
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Upgradable by the owner.
     *
     */
    function _authorizeUpgrade(
        address /*newImplementation*/
    )
        internal
        view
        override
    {
        _assertOwner();
    }
}
