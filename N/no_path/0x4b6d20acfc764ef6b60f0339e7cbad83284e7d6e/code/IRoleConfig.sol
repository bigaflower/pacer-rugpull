// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

interface IRoleConfig {
    function isMinter(address _user) external view returns (bool);
    function isBurner(address _user) external view returns (bool);
    function isAdmin(address _user) external view returns (bool);
}
