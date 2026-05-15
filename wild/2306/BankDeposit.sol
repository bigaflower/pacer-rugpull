/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BankDeposit {
    error ZeroAddress();

    event NewBankDeposit(address indexed sorareAddress, uint256 amount);

    address public immutable hotWallet;

    constructor(address _hotWallet) {
        if (_hotWallet == address(0)) revert ZeroAddress();

        hotWallet = _hotWallet;
    }

    function deposit(address _sorareAddress) public payable {
        require(msg.value > 0, "Amount must be greater than 0");

        payable(hotWallet).transfer(msg.value);

        emit NewBankDeposit(_sorareAddress, msg.value);
    }
}
