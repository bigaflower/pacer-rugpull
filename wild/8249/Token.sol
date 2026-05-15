/*

#####################################
Token generated with ❤️ on 20lab.app
#####################################

*/


// SPDX-License-Identifier: No License
pragma solidity 0.8.19;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract Suncoin is ERC20, ERC20Burnable, Ownable {
      
    constructor()
        ERC20(unicode"Suncoin", unicode"SNC") 
    {
        address supplyRecipient = 0x3D7C170F40d4E578993e690b5c46D97f83BBc386;
        
        _mint(supplyRecipient, 21000000000 * (10 ** decimals()) / 10);
        _transferOwnership(0x3D7C170F40d4E578993e690b5c46D97f83BBc386);
    }
    
    receive() external payable {}

    function decimals() public pure override returns (uint8) {
        return 10;
    }
    
    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        override
    {
        super._afterTokenTransfer(from, to, amount);
    }
}
