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

import {IAggregatorV3} from "./IAggregatorV3.sol";

interface IOracle is IAggregatorV3 {
    function getRoundDetails(uint80)
        external
        view
        returns (uint80 roundId, uint256 balance, uint256 interest, uint256 totalSupply, uint256 updatedAt);

    function latestRoundDetails()
        external
        view
        returns (uint80 roundId, uint256 balance, uint256 interest, uint256 totalSupply, uint256 updatedAt);

    function nextPrice() external view returns (int256);
}
