// SPDX-License-Identifier: MIT
/**
 * Copyright (C) 2024 uSmart
 */
pragma solidity ^0.8.9;

import { EnumerableSet } from "../../utils/EnumerableSet.sol";
import "./RoleData.sol";

struct AccessControllStorage {
	//owner => role => adminRole, members mapping
	address owner;
	mapping(address => mapping(bytes32 => RoleData)) roles;
}

library LibAccessControlStorage {
	bytes32 internal constant STORAGE_SLOT = keccak256("usmart.common.access-control.storage.v1");

	function layout() internal pure returns (AccessControllStorage storage acls_) {
		bytes32 position = STORAGE_SLOT;
		assembly {
			acls_.slot := position
		}
	}
}
