// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0;

// ====================================================================
//             _        ______     ___   _______          _
//            / \     .' ___  |  .'   `.|_   __ \        / \
//           / _ \   / .'   \_| /  .-.  \ | |__) |      / _ \
//          / ___ \  | |   ____ | |   | | |  __ /      / ___ \
//        _/ /   \ \_\ `.___]  |\  `-'  /_| |  \ \_  _/ /   \ \_
//       |____| |____|`._____.'  `.___.'|____| |___||____| |____|
// ====================================================================
// ======================== AgoraAccessControl ========================
// ====================================================================

import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/// @title AgoraAccessControl
/// @notice An abstract contract that provides role-based access control with enumerable membership tracking
abstract contract AgoraAccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    string public constant ACCESS_CONTROL_MANAGER_ROLE = "ACCESS_CONTROL_MANAGER_ROLE";

    /// @notice The AgoraAccessControlStorage struct
    /// @param roleData A mapping of role identifier to AgoraAccessControlRoleData to store role data
    /// @custom:storage-location erc7201:AgoraAccessControl.AgoraAccessControlStorage
    struct AgoraAccessControlStorage {
        EnumerableSet.Bytes32Set roles;
        mapping(string _role => EnumerableSet.AddressSet membership) roleMembership;
    }

    //==============================================================================
    // Initialization Functions
    //==============================================================================

    function _initializeAgoraAccessControl(address _initialAdminAddress) internal virtual {
        _addRoleToSet({ _role: ACCESS_CONTROL_MANAGER_ROLE });
        _setRoleMembership({ _role: ACCESS_CONTROL_MANAGER_ROLE, _member: _initialAdminAddress, _insert: true });
        emit RoleAssigned({ role: ACCESS_CONTROL_MANAGER_ROLE, member: _initialAdminAddress });
    }

    // ============================================================================================
    // Procedural Functions
    // ============================================================================================

    function _addRoleToSet(string memory _role) internal virtual {
        // Checks: Role name must be shorter than 32 bytes
        if (bytes(_role).length > 32) revert RoleNameTooLong();
        _getPointerToAgoraAccessControlStorage().roles.add(bytes32(bytes(_role)));
    }

    function _removeRoleFromSet(string memory _role) internal virtual {
        if (_getPointerToAgoraAccessControlStorage().roleMembership[_role].length() > 0) {
            revert CannotRemoveRoleWithMembers({ role: _role });
        }
        _getPointerToAgoraAccessControlStorage().roles.remove(bytes32(bytes(_role)));
    }

    function _assignRole(string memory _role, address _member, bool _addRole) internal virtual {
        // Checks: Role must exist
        _requireRoleExists({ _role: _role });

        // Effects: Set the roleMembership to the new _member
        _setRoleMembership({ _role: _role, _member: _member, _insert: _addRole });

        // Emit event
        if (_addRole) emit RoleAssigned({ role: _role, member: _member });
        else emit RoleRevoked({ role: _role, member: _member });
    }

    /// @notice The ```grantAccessControlManagerRole``` function grants `ACCESS_CONTROL_MANAGER_ROLE` to an address
    /// @dev Must be called by an address holding `ACCESS_CONTROL_MANAGER_ROLE`
    /// @param _member The address to be granted the role
    function grantAccessControlManagerRole(address _member) public virtual {
        // Checks: Only `ACCESS_CONTROL_MANAGER_ROLE` can grant the role
        _requireSenderIsRole({ _role: ACCESS_CONTROL_MANAGER_ROLE });
        _assignRole({ _role: ACCESS_CONTROL_MANAGER_ROLE, _member: _member, _addRole: true });
    }

    /// @notice The ```revokeAccessControlManagerRole``` function revokes `ACCESS_CONTROL_MANAGER_ROLE` from an address
    /// @dev Must be called by an address holding `ACCESS_CONTROL_MANAGER_ROLE`
    /// @dev An `ACCESS_CONTROL_MANAGER_ROLE` member can't remove oneself from the role.
    /// @param _member The address to be revoked the role
    function revokeAccessControlManagerRole(address _member) public virtual {
        // Checks: Only `ACCESS_CONTROL_MANAGER_ROLE` can revoke the role
        _requireSenderIsRole({ _role: ACCESS_CONTROL_MANAGER_ROLE });

        // Checks: cannot revoke oneself as `ACCESS_CONTROL_MANAGER_ROLE`
        if (_member == msg.sender) revert CannotRevokeSelf();

        _assignRole({ _role: ACCESS_CONTROL_MANAGER_ROLE, _member: _member, _addRole: false });
    }

    // ============================================================================================
    // Internal Effects Functions
    // ============================================================================================

    /// @notice The ```_setRoleMembership``` function sets the role membership
    /// @param _role The role identifier to transfer
    /// @param _member The address of the new role
    /// @param _insert Whether to add or remove the address from the role
    function _setRoleMembership(string memory _role, address _member, bool _insert) internal virtual {
        if (_insert) _getPointerToAgoraAccessControlStorage().roleMembership[_role].add(_member);
        else _getPointerToAgoraAccessControlStorage().roleMembership[_role].remove(_member);
    }

    // ============================================================================================
    // Internal Checks Functions
    // ============================================================================================

    /// @notice The ```_roleExists``` function checks if _role exists in the role set
    /// @param _role The role identifier to check
    /// @return Whether or not _role exists as a known role
    function _roleExists(string memory _role) internal view virtual returns (bool) {
        return _getPointerToAgoraAccessControlStorage().roles.contains(bytes32(bytes(_role)));
    }

    /// @notice The ```_requireRoleExists``` function revers if _role does not exist in the role set
    /// @param _role The role identifier to check
    function _requireRoleExists(string memory _role) internal view virtual {
        if (!_roleExists({ _role: _role })) revert RoleDoesNotExist({ role: _role });
    }

    /// @notice The ```_isRole``` function checks if the member has the role
    /// @param _role The role identifier to check
    /// @param _member The address to check against the role
    /// @return Whether or not the address has the role
    function _isRole(string memory _role, address _member) internal view virtual returns (bool) {
        return _getPointerToAgoraAccessControlStorage().roleMembership[_role].contains(_member);
    }

    /// @notice The ```_requireIsRole``` function reverts if member doesn't have the role
    /// @param _role The role identifier to check
    /// @param _member The address to check against the role
    function _requireIsRole(string memory _role, address _member) internal view virtual {
        if (!_isRole({ _role: _role, _member: _member })) revert AddressIsNotRole({ role: _role });
    }

    /// @notice The ```_requireSenderIsRole``` function reverts if msg.sender doesn't have the role
    /// @dev This function is to be implemented by a public function
    /// @param _role The role identifier to check
    function _requireSenderIsRole(string memory _role) internal view virtual {
        _requireIsRole({ _role: _role, _member: msg.sender });
    }

    //==============================================================================
    // Public View Functions
    //==============================================================================

    /// @notice The ```hasRole``` function checks if _member has the role
    /// @param _role The role identifier to check
    /// @param _member The address to check against the role
    /// @return Whether or not _member has the role
    function hasRole(string memory _role, address _member) public view virtual returns (bool) {
        return _isRole({ _role: _role, _member: _member });
    }

    /// @notice The ```getRoleMembers``` function returns the members of the role
    /// @param _role The role identifier to check
    /// @return The members of the role
    function getRoleMembers(string memory _role) public view virtual returns (address[] memory) {
        EnumerableSet.AddressSet storage _roleMembership = _getPointerToAgoraAccessControlStorage().roleMembership[
            _role
        ];
        return _roleMembership.values();
    }

    /// @notice The ```getAllRoles``` function returns all roles
    /// @return _roles The roles
    function getAllRoles() public view virtual returns (string[] memory _roles) {
        uint256 _length = _getPointerToAgoraAccessControlStorage().roles.length();
        _roles = new string[](_length);
        for (uint256 i = 0; i < _length; i++) {
            _roles[i] = string(abi.encodePacked(_getPointerToAgoraAccessControlStorage().roles.at(i)));
        }
    }

    /// @notice The ```getAccessControlManagerRoleMembers``` function returns the addresses holding `ACCESS_CONTROL_MANAGER_ROLE`
    /// @return The array of addresses holding `ACCESS_CONTROL_MANAGER_ROLE`
    function getAccessControlManagerRoleMembers() public view virtual returns (address[] memory) {
        return getRoleMembers(ACCESS_CONTROL_MANAGER_ROLE);
    }

    //==============================================================================
    // Erc 7201: UnstructuredNamespace Storage Functions
    //==============================================================================

    /// @notice The ```AGORA_ACCESS_CONTROL_STORAGE_SLOT``` is the storage slot for the AgoraAccessControlStorage struct
    /// @dev keccak256(abi.encode(uint256(keccak256("AgoraAccessControlStorage")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 public constant AGORA_ACCESS_CONTROL_STORAGE_SLOT =
        0x8f8de9240b3899c03a31968f466af060ab1c78464aa7ae14941c20fe7917b000;

    /// @notice The ```_getPointerToAgoraAccessControlStorage``` function returns a pointer to the AgoraAccessControlStorage struct
    /// @return $ A pointer to the AgoraAccessControlStorage struct
    function _getPointerToAgoraAccessControlStorage()
        internal
        pure
        virtual
        returns (AgoraAccessControlStorage storage $)
    {
        /// @solidity memory-safe-assembly
        assembly {
            $.slot := AGORA_ACCESS_CONTROL_STORAGE_SLOT
        }
    }

    // ============================================================================================
    // Events
    // ============================================================================================

    /// @notice The ```RoleAssigned``` event is emitted when the role is assigned
    /// @param role The string identifier of the role that was transferred
    /// @param member The address of the new role member
    event RoleAssigned(string indexed role, address indexed member);

    /// @notice The ```RoleRevoked``` event is emitted when the role is revoked
    /// @param role The string identifier of the role that was transferred
    /// @param member The address of the previous role member
    event RoleRevoked(string indexed role, address indexed member);

    // ============================================================================================
    // Errors
    // ============================================================================================

    /// @notice Emitted when role is transferred
    /// @param role The role identifier
    error AddressIsNotRole(string role);

    /// @notice Emitted when role name is too long
    error RoleNameTooLong();

    /// @notice Emitted when role does not exist
    error RoleDoesNotExist(string role);

    /// @notice Emitted when role still has members
    error CannotRemoveRoleWithMembers(string role);

    /// @notice Emitted when a member attempts removing oneself
    error CannotRevokeSelf();
}
