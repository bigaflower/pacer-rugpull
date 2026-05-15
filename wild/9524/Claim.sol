// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Airdrop is Ownable {
    using SafeERC20 for IERC20;

    IERC20 public immutable projectToken;
    bytes32 public immutable merkleRoot;

    // Track claimed status
    mapping(address => bool) public hasClaimed;

    // Custom errors
    error AlreadyClaimed();
    error InvalidProof();

    event Claimed(address indexed account, uint256 amount);
    
    constructor(
        address _token,
        bytes32 _merkleRoot
    ) Ownable(msg.sender) {
        projectToken = IERC20(_token);
        merkleRoot = _merkleRoot;
    }

    function claim(uint256 amount, bytes32[] calldata merkleProof) external {
        if (hasClaimed[msg.sender]) revert AlreadyClaimed();

        bytes32 node = keccak256(abi.encodePacked(msg.sender, amount));
        if (!MerkleProof.verify(merkleProof, merkleRoot, node)) revert InvalidProof();
        
        hasClaimed[msg.sender] = true;
        projectToken.safeTransfer(msg.sender, amount);
        
        emit Claimed(msg.sender, amount);
    }

    function withdrawUnclaimed() external onlyOwner {
        uint256 balance = projectToken.balanceOf(address(this));
        projectToken.safeTransfer(owner(), balance);
    }
}