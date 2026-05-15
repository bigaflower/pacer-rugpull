// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface AyeAyeCoin {

    function coinBalanceOf(address _owner) external returns (uint256);
    function sendCoin(address _receiver, uint256 _amount) external;
}

contract DropBox is Ownable(msg.sender) {

    function collect(uint256 value, AyeAyeCoin aaInt) public onlyOwner {
        aaInt.sendCoin(owner(), value);
    }
}

contract WrappedAyeAyeCoin is ERC20 {

    event DropBoxCreated(address indexed owner);
    event ClaimedAndWrapped(uint256 indexed value, address indexed owner);
    event Wrapped(uint256 indexed value, address indexed owner);
    event Unwrapped(uint256 indexed value, address indexed owner);

    bytes constant claimSig = hex"5479f98b";
    address constant faucetAddr = 0xcD063B3081Ea55535E5b60a21eff7f14E785A877;
    address constant aaAddr = 0x3edDc7ebC7db94f54b72D8Ed1F42cE6A527305bB;
    AyeAyeCoin constant aaInt = AyeAyeCoin(aaAddr);

    mapping(address => address) public dropBoxes;

    constructor() ERC20("Wrapped AyeAyeCoin", "WAAC") {}

    function createDropBox() public {
        require(dropBoxes[msg.sender] == address(0), "Drop box already exists");

        dropBoxes[msg.sender] = address(new DropBox());
        
        emit DropBoxCreated(msg.sender);
    }

    function claimAndWrap(uint256 value) public {
        require(aaInt.coinBalanceOf(faucetAddr) >= value, "Not enough coins in faucet");

        for (uint256 i = 0; i < value; i++) {
            aaAddr.call(claimSig);
        }
        _mint(msg.sender, value);
        
        emit ClaimedAndWrapped(value, msg.sender);
    }

    function wrap(uint256 value) public {
        address dropBox = dropBoxes[msg.sender];

        require(dropBox != address(0), "You must create a drop box first"); 
        require(aaInt.coinBalanceOf(dropBox) >= value, "Not enough coins in drop box");

        DropBox(dropBox).collect(value, aaInt);
        _mint(msg.sender, value);
        
        emit Wrapped(value, msg.sender);
    }

    function unwrap(uint256 value) public {
        require(balanceOf(msg.sender) >= value, "Not enough coins to unwrap");

        aaInt.sendCoin(msg.sender, value);
        _burn(msg.sender, value);

        emit Unwrapped(value, msg.sender);
    }

    function decimals() public pure override returns (uint8) {
        return 0;
    }
}