// SPDX-License-Identifier: MIT
/**
 * Copyright (C) 2024 uSmart
 */
pragma solidity ^0.8.9;

import "./LibAccessControlStorage.sol";

import { IERC173 } from "../../interfaces/IERC173.sol";

import { EnumerableSet } from "../../utils/EnumerableSet.sol";
import { UintUtils } from "../../utils/UintUtils.sol";
import { AddressUtils } from "../../utils/AddressUtils.sol";

library LibAccessControl {
	using EnumerableSet for EnumerableSet.AddressSet;
	using UintUtils for uint256;
	using AddressUtils for address;

	error Ownable__NotOwner();
	error Ownable__NotTransitiveOwner();

	error AccessDenied(bytes32 role, address account);

	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	event RoleAdminChanged(address indexed owner, bytes32 role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);
	event RoleGranted(address indexed owner, bytes32 role, address indexed account, address indexed sender);
	event RoleRevoked(address indexed owner, bytes32 role, address indexed account, address indexed sender);

	bytes32 internal constant DEFAULT_ADMIN_ROLE = 0x00;

	function _setOwner(address _newOwner) internal {
		AccessControllStorage storage acls = LibAccessControlStorage.layout();
		address previousOwner = acls.owner;
		acls.owner = _newOwner;

		//Init DEFAULT_ADMIN_ROLE to _newOwner
		LibAccessControl._grantRole(LibAccessControl.DEFAULT_ADMIN_ROLE, _newOwner);

		emit OwnershipTransferred(previousOwner, _newOwner);
	}

	function _owner() internal view returns (address owner_) {
		AccessControllStorage storage acls = LibAccessControlStorage.layout();
		owner_ = acls.owner;
	}

	function _transitiveOwner() internal view returns (address owner_) {
		owner_ = LibAccessControl._owner();

		while (owner_.isContract()) {
			try IERC173(owner_).owner() returns (address transitiveOwner) {
				owner_ = transitiveOwner;
			} catch {
				break;
			}
		}
	}

	function _enforceIsOwner() internal view {
		//require(msg.sender == _owner(), "Not owner!");
		if (msg.sender != _owner()) {
			revert Ownable__NotOwner();
		}
	}

	function _enforceIsTransitiveOwner() internal view {
		//require(msg.sender == _transitiveOwner(), "Not transitive owner!");
		if (msg.sender != _transitiveOwner()) {
			revert Ownable__NotTransitiveOwner();
		}
	}

	/**
	 * @notice assign role to given account
	 * @param _role role to assign
	 * @param _account recipient of role assignment
	 */
	function _grantRole(bytes32 _role, address _account) internal {
		AccessControllStorage storage acls = LibAccessControlStorage.layout();
		if (!_hasRole(_role, _account)) {
			acls.roles[acls.owner][_role].members.add(_account);
			emit RoleGranted(acls.owner, _role, _account, msg.sender);
		}
	}

	/**
	 * @notice unassign role from given account
	 * @param _role role to unassign
	 * @param _account account to revokeAccessControlStorage
	 */
	function _revokeRole(bytes32 _role, address _account) internal {
		AccessControllStorage storage acls = LibAccessControlStorage.layout();
		// require(_role != LibAccessControl.DEFAULT_ADMIN_ROLE && _account != acls.owner);
		acls.roles[acls.owner][_role].members.remove(_account);
		emit RoleRevoked(acls.owner, _role, _account, msg.sender);
	}

	/**
	 * @notice relinquish role
	 * @param _role role to relinquish
	 */
	function _renounceRole(bytes32 _role) internal {
		_revokeRole(_role, msg.sender);
	}

	/**
	 * @notice Query one of the accounts that have role of the project
	 * @dev WARNING: When using _getProjectRoleMember and _getProjectRoleMemberCount, make sure you perform all queries on the same block.
	 * @param _role role to query
	 * @param _index index of role member
	 */
	function _getRoleMember(bytes32 _role, uint256 _index) internal view returns (address) {
		AccessControllStorage storage acls = LibAccessControlStorage.layout();
		return acls.roles[acls.owner][_role].members.at(_index);
	}

	/**
	 * @notice Query the number of accounts that have role.
	 * @dev WARNING: When using _getRoleMember and _getRoleMemberCount, make sure you perform all queries on the same block.
	 * @param _role role to query
	 */
	function _getRoleMemberCount(address, bytes32 _role) internal view returns (uint256) {
		AccessControllStorage storage acls = LibAccessControlStorage.layout();
		return acls.roles[acls.owner][_role].members.length();
	}

	/**
	 * @notice query whether role is assigned to account
	 * @param _role role to query
	 * @param _account account to query
	 * @return bool whether role is assigned to account
	 */
	function _hasRole(bytes32 _role, address _account) internal view returns (bool) {
		AccessControllStorage storage acls = LibAccessControlStorage.layout();
		return acls.roles[acls.owner][_role].members.contains(_account);
	}

	/**
	 * @notice revert if sender does not have given role
	 * @param _role role to query
	 */
	function _checkRole(bytes32 _role) internal view {
		_checkRole(_role, msg.sender);
	}

	/**
	 * @notice revert if given account does not have given role
	 * @param _role role to query
	 * @param _account to query
	 */
	function _checkRole(bytes32 _role, address _account) internal view {
		if (!_hasRole(_role, _account)) {
			revert AccessDenied({ role: _role, account: _account });
		}
	}

	/**
	 * @notice query admin role for given role
	 * @param _role role to query
	 * @return admin role
	 */
	function _getRoleAdmin(bytes32 _role) internal view returns (bytes32) {
		AccessControllStorage storage acls = LibAccessControlStorage.layout();
		return acls.roles[acls.owner][_role].adminRole;
	}

	/**
	 * @notice set role as admin role
	 * @param _role role to set
	 * @param _adminRole admin role to set
	 */
	function _setRoleAdmin(bytes32 _role, bytes32 _adminRole) internal {
		AccessControllStorage storage acls = LibAccessControlStorage.layout();
		bytes32 previousAdminRole = _getRoleAdmin(_role);
		acls.roles[acls.owner][_role].adminRole = _adminRole;
		emit RoleAdminChanged(acls.owner, _role, previousAdminRole, _adminRole);
	}
}
