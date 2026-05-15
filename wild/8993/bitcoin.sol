/*
This contract facilitates the wrapping/unwrapping of the first ERC20 meme coin from 2015. Address: 0x1130547436810DB920FA73681c946feA15E9b758
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "ERC20.sol";
import "Ownable.sol";

interface btcToken {
    function balanceOf(address owner) external returns (uint256);
    function transfer(address to, uint256 value) external;
}

contract DropBox is Ownable(msg.sender) {
    function collect(uint256 value, btcToken btcInt) public onlyOwner {
        btcInt.transfer(owner(), value);
    }
}

contract wrappedbitcoin is ERC20 {

    event DropBoxCreated(address indexed owner);
    event Wrapped(uint256 indexed value, address indexed owner);
    event Unwrapped(uint256 indexed value, address indexed owner);

    btcToken btcInt = btcToken(0x1130547436810DB920FA73681c946feA15E9b758);

    mapping(address => address) public dropBoxes;

    constructor() ERC20("bitcoin", "btc") {}

    function createDropBox() public {
        require(dropBoxes[msg.sender] == address(0), "Drop box already exists.");

        dropBoxes[msg.sender] = address(new DropBox());
        
        emit DropBoxCreated(msg.sender);
    }
    function wrap(uint256 value) public {
        address dropBox = dropBoxes[msg.sender];

        require(dropBox != address(0), "You must create a drop box first."); 
        require(btcInt.balanceOf(dropBox) >= value, "Not enough btc in drop box.");

        DropBox(dropBox).collect(value, btcInt);
        _mint(msg.sender, value);
        
        emit Wrapped(value, msg.sender);
    }

    function unwrap(uint256 value) public {
        require(balanceOf(msg.sender) >= value, "Not enough tokens to unwrap.");

        btcInt.transfer(msg.sender, value);
        _burn(msg.sender, value);

        emit Unwrapped(value, msg.sender);
    }

    function decimals() public pure override returns (uint8) {
        return 8;
    }

}

/*
ABI to interact with the original btc token: 0x1130547436810DB920FA73681c946feA15E9b758

[
    {
        "constant": false,
        "inputs": [
            {
                "name": "_to",
                "type": "address"
            },
            {
                "name": "_value",
                "type": "uint256"
            }
        ],
        "name": "transfer",
        "outputs": [
            {
                "name": "",
                "type": "bool"
            }
        ],
        "payable": false,
        "stateMutability": "nonpayable",
        "type": "function"
    },

{
        "constant": true,
        "inputs": [
            {
                "name": "_owner",
                "type": "address"
            }
        ],
        "name": "balanceOf",
        "outputs": [
            {
                "name": "balance",
                "type": "uint256"
            }
        ],
        "payable": false,
        "stateMutability": "view",
        "type": "function"
    }

]
*/