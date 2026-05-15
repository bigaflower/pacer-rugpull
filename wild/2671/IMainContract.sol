// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IMainContract {
    function withdraw(uint256 _amount, address _receiver) external;

    function changePreffixAndSuffix(
        string calldata _prefix,
        string calldata _suffix
    ) external;

    function setDefaultRoyalty(
        address _royaltyRecipient,
        uint _percentage
    ) external;

    function enableSwitchBack() external;

    function addFilterOperators(address[] calldata operators) external;

    function removeFilterOperators(address[] calldata operators) external;
}
