// SPDX-License-Identifier: MIT
pragma solidity =0.8.12;

contract Ownable {
    // Mapping to track owner addresses
    mapping(address => bool) private _owners;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OwnerAdded(address indexed newOwner);
    event OwnerRemoved(address indexed removedOwner);

    constructor (address owner_) {
        _owners[owner_] = true;
        emit OwnerAdded(owner_);
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "Available only for owners");
        _;
    }

    function isOwner(address userAddress) public view returns (bool) {
        return _owners[userAddress];
    }

    function addOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner cannot be zero address");
        require(!_owners[newOwner], "Address is already an owner");
        _owners[newOwner] = true;
        emit OwnerAdded(newOwner);
    }

    function removeOwner(address ownerToRemove) external onlyOwner {
        require(_owners[ownerToRemove], "Address is not an owner");
        require(msg.sender != ownerToRemove, "Owners cannot remove themselves");
        _owners[ownerToRemove] = false;
        emit OwnerRemoved(ownerToRemove);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner cannot be zero address");
        emit OwnershipTransferred(msg.sender, newOwner);
        _owners[msg.sender] = false;
        _owners[newOwner] = true;
    }
}

