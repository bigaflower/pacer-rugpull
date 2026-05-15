// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IRegularPunksStats {
    /// @notice Current stats (including any live training gains) for a tokenId.
    function currentStats(uint256 tokenId)
        external
        view
        returns (uint16 attack, uint16 defense, uint16 agility);

    /// @notice JSON fragment for stats + training status for a tokenId.
    function statAttributesJson(uint256 tokenId) external view returns (string memory);

    /// @notice Legacy helper: base stats-only JSON from a seed (no training).
    function statAttributesJsonFromSeed(uint256 seed) external view returns (string memory);

    /// @notice Start training a specific stat (staking contract only).
    function startTraining(uint256 tokenId, uint8 statIndex) external;

    /// @notice Change the training stat (settles previous, continues training).
    function changeTrainingStat(uint256 tokenId, uint8 statIndex) external;

    /// @notice Finish training and settle accrued gains (staking contract only).
    function finishTraining(uint256 tokenId) external;

    /// @notice View current training status.
    function trainingStatus(uint256 tokenId)
        external
        view
        returns (bool active, uint8 statIndex, uint64 startTime);

    /// @notice Next level timestamp estimate for the active training session.
    /// Returns (active, statIndex, nextTimestamp, currentStatValue).
    /// nextTimestamp is 0 if not training or already capped.
    function nextLevelTimestamp(uint256 tokenId)
        external
        view
        returns (bool active, uint8 statIndex, uint256 nextTimestamp, uint16 currentStatValue);
}

