// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IPresale {
    struct PresaleParams {
            address owner;
            address token;
            uint256 softcap;
            uint256 hardcap;
            uint256 startTs;
            uint256 finishTs;
            uint256 duration;
            uint256 liqPercent;
            uint256 cliffPeriod;
            uint256 vestingPeriod;
            uint256 status;
            uint256 sold;
            uint256 maxEth;
            uint256 maxBag;
            uint256 fee;
    }

    function transferOwnership(address _newOwner) external;
    function owner() external view returns (address);
    function rescueERC20(address _address) external;
    function setupPresale(PresaleParams memory params) external;
    function buyTokens(uint256 _amount) external payable;
    //should we offer or force token vesting??
    function claimTokens() external;
    function getRefund() external;
    function getPresaleDetails() external view returns(PresaleParams memory); 
    function finishPresale() external; 
    function claimEth() external;
    function getClaimableTokens(address user) external view returns(uint256,uint256,uint256,uint256);
    function refundPresale() external;
}
