// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

import {ICassaPolicy} from "cassa-interfaces/ICassaPolicy.sol";

abstract contract CassaPolicySolvency is ICassaPolicy {
    uint256 private immutable _effectiveDate;
    uint256 private immutable _expirationDate;
    uint256 private _maxUpdateGap;

    constructor(uint256 __effectiveDate, uint256 __expirationDate, uint256 __maxUpdateGap) {
        _effectiveDate = __effectiveDate;
        _expirationDate = __expirationDate;
        _maxUpdateGap = __maxUpdateGap;
    }

    /// @notice Returns the assets data
    /// @return _assets Assets value
    /// @return _updatedAt Assets update timestamp
    function assets() public view virtual returns (uint256 _assets, uint256 _updatedAt);

    /// @notice Returns the liabilities data
    /// @return _liabilities Liabilities value
    /// @return _updatedAt Liabilities update timestamp
    function liabilities() public view virtual returns (uint256 _liabilities, uint256 _updatedAt);

    /// @inheritdoc ICassaPolicy
    function effectiveDate() public view returns (uint256 timestamp) {
        return _effectiveDate;
    }

    /// @inheritdoc ICassaPolicy
    function expirationDate() public view returns (uint256 timestamp) {
        return _expirationDate;
    }

    /// @notice Returns the max acceptable update gap between assets and liabilities
    /// @return gap Gap in seconds
    function maxUpdateGap() public view returns (uint256 gap) {
        return _maxUpdateGap;
    }

    /// @inheritdoc ICassaPolicy
    function settlementRatio() external view returns (uint256 setlRatio, bool isSettled, bool ok) {
        (uint256 solvRatio, uint256 updatedAt, uint256 updateGap) = _solvencyRatio();
        setlRatio = _settlementRatio(solvRatio);
        isSettled = updatedAt >= expirationDate();
        ok = updateGap <= maxUpdateGap();
        return (setlRatio, isSettled, ok);
    }

    /// @notice Returns the solvency ratio
    /// @return solvRatio Solvency ratio scaled by 1e18 (1e18 = 100%)
    /// @return updatedAt Solvency ratio update timestamp
    function solvencyRatio() external view returns (uint256 solvRatio, uint256 updatedAt) {
        (
            solvRatio,
            updatedAt,
            /* uint256 updateGap */
        ) = _solvencyRatio();
        return (solvRatio, updatedAt);
    }

    function _settlementRatio(uint256 solvRatio) internal pure virtual returns (uint256 setlRatio) {
        return 1e18 - Math.min(1e18, solvRatio);
    }

    function _solvencyRatio() internal view returns (uint256 solvRatio, uint256 updatedAt, uint256 updateGap) {
        (uint256 _assets, uint256 _assetsUpdatedAt) = assets();
        (uint256 _liabilities, uint256 _liabilitiesUpdatedAt) = liabilities();
        solvRatio = _liabilities == 0 ? 1e18 : Math.mulDiv(1e18, _assets, _liabilities, Math.Rounding.Floor);
        updatedAt = Math.min(_assetsUpdatedAt, _liabilitiesUpdatedAt);
        updateGap = Math.max(_assetsUpdatedAt, _liabilitiesUpdatedAt) - updatedAt;
        return (solvRatio, updatedAt, updateGap);
    }
}
