// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

contract DGoldVote is ERC20, Ownable, ERC20Permit, ERC20Votes {
  error NullAddress();
  error Unauthorized();
  

  //uint public maxSupply;
  // Staking Contract
  address private stakingAddress;
    constructor()
        ERC20("DGold Vote", "DVote")
        ERC20Permit("DGold Vote")
    {
     
        //transferOwnership(0x1CdaC19722f3c3515cF27617EaBa34c008BF3f01);
    }

    modifier onlyStakingAddress {
        require(msg.sender == stakingAddress, "Unauthorized: Only callable through the Staking contract");
        _;
    }
    //set staking address
    function setStakingAddress(address _staking) external onlyOwner {
      if(_staking == address(0)) revert NullAddress();
      stakingAddress = _staking;
    }

   function mint(address account, uint256 amount)
        external
       onlyStakingAddress
    {
        _mint(account,amount);
    }
  
    function burn(address account, uint256 amount)
        external
        onlyStakingAddress
    {
        _burn(account, amount);
    }

    //Governance tokens not transferrable
     // Make token non-transferrable
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20) {
        // Allow minting (from == 0) and burning (to == 0) only
        if (from != address(0) && to != address(0)) {
            revert("Transfers are not allowed");
        }
        super._beforeTokenTransfer(from, to, amount);
    }
    // The following functions are overrides required by Solidity.


   function _afterTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal override(ERC20, ERC20Votes) {
    super._afterTokenTransfer(from, to, amount);
  }
  
   function _mint(address to, uint256 amount) internal override(ERC20, ERC20Votes) {
    super._mint(to, amount);
  }

  function _burn(address account, uint256 amount) internal override(ERC20, ERC20Votes) {
    super._burn(account, amount);
  }

}
interface IDGoldVote {
  function burn(address account, uint256 amount) external;
  function mint(address account, uint256 amount) external;
  function balanceOf(address account) external view returns (uint256);
  function allowance(address owner, address spender) external view  returns (uint256);
}