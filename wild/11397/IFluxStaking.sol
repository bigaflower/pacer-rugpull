// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.27;

interface IFluxStaking {
    struct UserRecord {
        uint160 shares;
        uint160 lockedFlux;
        uint128 rewardDebt;
        uint32 endTime;
    }

    function userRecords(uint256 _id) external returns (UserRecord memory);

    function MAX_DURATION() external returns (uint32);
    function tokenId() external returns (uint96);
    function batchClaimableAmount(uint160[] memory) external returns (uint256);
    function stake(uint32 _duration, uint160 _fluxAmount) external;
    function batchClaim(uint160[] memory _ids, address _receiver) external;
    function unstake(uint160 _tokenId, address _receiver) external;
}
