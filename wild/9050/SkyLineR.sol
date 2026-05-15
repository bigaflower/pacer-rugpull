// SPDX-License-Identifier: MIT
pragma solidity 0.8.31;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Skyline is ERC20, ERC20Burnable, ERC20Permit, Ownable {
    // 800 Quadrillion with 18 decimals
    uint256 public constant MAX_SUPPLY = 800_000_000_000_000_000 * 10**18;
    
    // Fee Settings (200 bps = 2%)
    uint16 public feeBasisPoints = 200;
    address public feeRecipient;
    mapping(address => bool) public isExcludedFromFees;

    constructor(address initialOwner, address _feeRecipient) 
        ERC20("Skyline", "SkyLineR") 
        ERC20Permit("Skyline") 
        Ownable(initialOwner) 
    {
        feeRecipient = _feeRecipient;
        isExcludedFromFees[initialOwner] = true;
        isExcludedFromFees[feeRecipient] = true;
        isExcludedFromFees[address(this)] = true;

        // Mint full 800 quadrillion supply to owner
        _mint(initialOwner, MAX_SUPPLY);
    }

    /**
     * @dev Overriding _update to include Trade Fee logic.
     * This ensures the 2% fee works on every transfer.
     */
    function _update(address from, address to, uint256 amount) internal virtual override {
        if (from == address(0) || to == address(0) || isExcludedFromFees[from] || isExcludedFromFees[to]) {
            super._update(from, to, amount);
            return;
        }

        uint256 fee = (amount * feeBasisPoints) / 10000;
        uint256 amountAfterFee = amount - fee;

        if (fee > 0) {
            super._update(from, feeRecipient, fee);
        }
        super._update(from, to, amountAfterFee);
    }

    // Standard Owner Functions
    function setFeeBasisPoints(uint16 _newFee) external onlyOwner {
        require(_newFee <= 1000, "Fee too high"); // Max 10%
        feeBasisPoints = _newFee;
    }
}
