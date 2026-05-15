// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IAdmin {
    /// @notice Returns the admin address
    /// @return _admin The admin address
    function admin() external returns (address _admin);
}
