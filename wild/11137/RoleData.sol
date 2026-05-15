// SPDX-License-Identifier: MIT
/**
 * Copyright (C) 2024 uSmart
 */
pragma solidity ^0.8.9;

import { EnumerableSet } from "../../utils/EnumerableSet.sol";

struct RoleData {
	bytes32 adminRole;
	EnumerableSet.AddressSet members;
}
