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

/// @dev Fees are 18-decimal places. For example: 20 * 10**18 = 20%
uint256 constant FEE_MULTIPLIER = 10 ** 18;
uint256 constant HUNDRED_PCT = 100 * FEE_MULTIPLIER;

uint256 constant AFTER_HOURS_DISABLED = type(uint256).max;

uint8 constant ROLE_INVESTOR = 0;
uint8 constant ROLE_INVESTOR_BETA = 1;
uint8 constant ROLE_RESERVES = 7;
uint8 constant ROLE_ENTITLEMENTS = 8;
uint8 constant ROLE_TELLER = 9;
uint8 constant ROLE_ORACLE = 10;
uint8 constant ROLE_MESSENGER = 11;
uint8 constant ROLE_CCTP = 12;
uint8 constant ROLE_CUSTODIAN_CENTRAL = 18;
uint8 constant ROLE_CUSTODIAN_DECENTRAL = 19;
uint8 constant ROLE_TOKEN_MINTER = 20;
uint8 constant ROLE_FUND_ADMIN = type(uint8).max;
