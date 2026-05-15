// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface Love {

    function balanceOf(address _owner) external returns (uint256);
    function transfer(address _to, uint256 _value) external;
}

contract DropBox is Ownable(msg.sender) {

    function collect(uint256 value, Love lInt) public onlyOwner {
        lInt.transfer(owner(), value);
    }
}

contract WrappedLove is ERC20 {

    event DropBoxCreated(address indexed owner);
    event Wrapped(uint256 indexed value, address indexed owner);
    event Unwrapped(uint256 indexed value, address indexed owner);

    address constant lAddr = 0x45601D0497419Ec993552EF425927F08f73CE032;
    Love constant lInt = Love(lAddr);

    mapping(address => address) public dropBoxes;

    constructor() ERC20("Wrapped Love", unicode"W♥") {}

    function createDropBox() public {
        require(dropBoxes[msg.sender] == address(0), "Drop box already exists");

        dropBoxes[msg.sender] = address(new DropBox());
        
        emit DropBoxCreated(msg.sender);
    }

    function wrap(uint256 value) public {
        address dropBox = dropBoxes[msg.sender];

        require(dropBox != address(0), "You must create a drop box first"); 
        require(lInt.balanceOf(dropBox) >= value, "Not enough coins in drop box");

        DropBox(dropBox).collect(value, lInt);
        _mint(msg.sender, value);
        
        emit Wrapped(value, msg.sender);
    }

    function unwrap(uint256 value) public {
        require(balanceOf(msg.sender) >= value, "Not enough coins to unwrap");

        lInt.transfer(msg.sender, value);
        _burn(msg.sender, value);

        emit Unwrapped(value, msg.sender);
    }

    function decimals() public pure override returns (uint8) {
        return 0;
    }
}