// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

interface IDepositorBase {
    function createLock(uint256 _amount) external;
    function depositAll(address _user) external;
    function deposit(uint256 _amount, address _user) external;
    function transferGovernance(address _governance) external;
    function acceptGovernance() external;
    function shutdown(address receiver) external;
    function shutdown() external;
    function setSdTokenMinterOperator(address _minter) external;
    function name() external view returns (string memory);
    function version() external pure returns (string memory);
    function governance() external view returns (address);
    function futureGovernance() external view returns (address);
    function locker() external view returns (address);
    function token() external view returns (address);
    function minter() external view returns (address);
    function MAX_LOCK_DURATION() external view returns (uint256);
    function DENOMINATOR() external view returns (uint256);
}
