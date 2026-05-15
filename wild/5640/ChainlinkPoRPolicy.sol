// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/interfaces/AggregatorV3Interface.sol";

import {CassaPolicySolvency} from "../CassaPolicySolvency.sol";

contract ChainlinkPoRPolicy is CassaPolicySolvency {
    AggregatorV3Interface internal _porFeed;
    IERC20 internal _token;

    uint256 internal _lastLiabilities;
    uint256 internal _lastLiabilitiesUpdatedAt;

    constructor(
        uint256 __effectiveDate,
        uint256 __expirationDate,
        uint256 __maxUpdateGap,
        address __porFeed,
        address __token
    ) CassaPolicySolvency(__effectiveDate, __expirationDate, __maxUpdateGap) {
        _porFeed = AggregatorV3Interface(__porFeed);
        _token = IERC20(__token);
        _lastLiabilitiesUpdatedAt = type(uint256).max;
    }

    /// @notice Returns the PoR feed
    /// @return __porFeed PoR feed address
    function porFeed() external view returns (address __porFeed) {
        return address(_porFeed);
    }

    /// @notice Returns the target token
    /// @return __token Token address
    function token() external view returns (address __token) {
        return address(_token);
    }

    /// @notice Returns the latest stored liability data
    /// @return __lastLiabilities Liabilities value
    /// @return __lastLiabilitiesUpdatedAt Liabilities update timestamp
    function lastLiabilities() public view returns (uint256 __lastLiabilities, uint256 __lastLiabilitiesUpdatedAt) {
        return (_lastLiabilities, _lastLiabilitiesUpdatedAt);
    }

    /// @notice Replaces the stored liability data with the latest if it's closer in time, does nothing otherwise
    function update() external {
        (_lastLiabilities, _lastLiabilitiesUpdatedAt) = liabilities();
    }

    /// @inheritdoc CassaPolicySolvency
    function assets() public view override returns (uint256 __assets, uint256 __updatedAt) {
        (
            /* uint80 roundId */,
            int256 answer,
            /* uint256 startedAt */,
            uint256 updatedAt,
            /* uint80 answeredInRound */
        ) = _porFeed.latestRoundData();
        return (SafeCast.toUint256(answer), updatedAt);
    }

    /// @inheritdoc CassaPolicySolvency
    function liabilities() public view override returns (uint256 __liabilities, uint256 __updatedAt) {
        (/* uint256 assets */, uint256 assetsUpdatedAt) = assets();
        (uint256 newLiabilities, uint256 newLiabilitiesUpdatedAt) = _liabilities();

        uint256 gapToLast = assetsUpdatedAt > _lastLiabilitiesUpdatedAt
            ? assetsUpdatedAt - _lastLiabilitiesUpdatedAt
            : _lastLiabilitiesUpdatedAt - assetsUpdatedAt;
        uint256 gapToNew = newLiabilitiesUpdatedAt - assetsUpdatedAt;

        if (gapToLast < gapToNew) {
            return (_lastLiabilities, _lastLiabilitiesUpdatedAt);
        } else {
            return (newLiabilities, newLiabilitiesUpdatedAt);
        }
    }

    function _liabilities() internal view returns (uint256 __liabilities, uint256 __updatedAt) {
        return (_token.totalSupply(), block.timestamp);
    }
}
