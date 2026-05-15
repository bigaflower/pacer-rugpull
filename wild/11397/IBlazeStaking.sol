// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.27;

interface IBlazeDiamonHands {
    function participate() external;
    function claimRewards() external;
    function getClaimableRewards(address user) external returns (uint256);
}

interface IBlazeStaking {
    struct StakeInfo {
        uint256 amount;
        uint256 shares;
        uint16 stakeDurationInDays;
        uint32 startTimestamp;
        uint32 maturityTimestamp;
        StakeStatus status;
    }

    enum StakeStatus {
        ACTIVE,
        COMPLETED
    }

    function getAvailableRewardsForClaim(address _user) external returns (uint256);
    function stakeBlaze(uint256 _amount, uint256 _durationInDays) external;
    function unstakeBlaze(address _user, uint256 _id) external;
    function claimFeeRewards() external;
    function distributeFeeRewardsForAll() external;
    function getLastDistributionAddress() external returns (IBlazeDiamonHands);
    function getStakeInfoByUserStakeId(address __user, uint256 __userStakeId) external returns (StakeInfo memory);
}
