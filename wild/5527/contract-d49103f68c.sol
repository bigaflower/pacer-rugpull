// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts@5.0.2/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts@5.0.2/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts@5.0.2/token/ERC20/extensions/ERC20Permit.sol";

contract PerkUP is ERC20, ERC20Pausable, ERC20Permit {
    address constant initialOwner = 0x5dF592D644097B357b0C6B263Cf167b4212E3fF5;

    constructor()
        ERC20("PerkUP", "UP")
        ERC20Permit("PerkUP")
    {
        _mint(initialOwner, 5000000000 * 10 ** decimals());
    }

    function pause() public  {
        if(msg.sender == initialOwner) {
            _pause();
        }
    }

    function unpause() public {
        if(msg.sender == initialOwner) {
            _unpause();
        }
    }

    function mint(address to, uint256 amount) public {
        if(msg.sender == initialOwner) {
            _mint(to, amount);
        }
        
    }

    // The following functions are overrides required by Solidity.

    function _update(address from, address to, uint256 value)
        internal
        override(ERC20, ERC20Pausable)
    {
        super._update(from, to, value);
    }
}
