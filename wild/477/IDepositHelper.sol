
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

interface IDepositHelper {

    // --- View functions ---
    function DEPOSIT_ADDRESS() external view returns (address);
    function rewardToken() external view returns (address);
    function manager() external view returns (address);
    function owner() external view returns (address);
    function rewardNotifier() external view returns (address);
    function MAX_GAUGE_WEIGHT() external view returns (uint16);
    function isApprovedGauge(address _gauge) external view returns (bool);

    function getCurrentWeights() external view returns (address[] memory, uint16[] memory);
    function currentWeightOfGauge(address _gauge) external view returns (uint16);
    
    function getLastReward() external view returns (address[] memory gauges, uint256[] memory amounts, uint256 epoch);
    function rewardHistoryLength() external view returns (uint256);
    function getRewardByIndex(uint256 _index) external view returns (address[] memory gauges, uint256[] memory amounts, uint256 epoch);

    // --- External functions ---
    function notifyReward(uint256 _amount) external;

    function setWeights(address[] memory _gauges, uint16[] memory _weights) external;
    function setExcludeAddresses(address[] memory _excludeAddresses) external;
    function setManager(address _manager) external;
    function setRewardToken(address _rewardToken) external;
    function setRewardNotifier(address _rewardNotifier) external;
    function addApprovedGauge(address _gauge) external;
    function removeApprovedGauge(address _gauge) external;

    function execute(address to, uint256 value, bytes calldata data) external returns (bytes memory);
}