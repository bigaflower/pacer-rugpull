// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC20Burnable } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import { ERC20Votes } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import { ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import { Ownable2Step } from "@openzeppelin/contracts/access/Ownable2Step.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Nonces } from "@openzeppelin/contracts/utils/Nonces.sol";

contract GovernanceToken is ERC20, ERC20Burnable, ERC20Permit, ERC20Votes, Ownable2Step {
    uint256 public constant TOTAL_SUPPLY = 10_000_000_000 * 1e18;
    mapping(address => bool) public whitelist;
    uint256 public transferAllowedTimestamp;
    event NewTransferAllowedTimestamp(uint256 newTimestamp);

    constructor(address initialOwner,string memory name, string memory symbol,uint256 _transferAllowedTimestamp) 
        ERC20(name, symbol)
        ERC20Permit(name)
        Ownable(initialOwner)
    {
        _mint(initialOwner, TOTAL_SUPPLY);
         transferAllowedTimestamp = _transferAllowedTimestamp;
         whitelist[msg.sender] = true;
    }

    function addToWhitelist(address _account) public onlyOwner {
        whitelist[_account] = true;
    }

    function removeFromWhitelist(address _account) public onlyOwner {
        whitelist[_account] = false;
    }

    function setTransferAllowedTimestamp(uint256 newTimestamp) public onlyOwner {
        require(transferAllowedTimestamp > block.timestamp, "not allowed");
        transferAllowedTimestamp = newTimestamp;
        emit NewTransferAllowedTimestamp(newTimestamp);
    }


    function _update(address from, address to, uint256 amount) internal override(ERC20, ERC20Votes) {
        require(
            block.timestamp >= transferAllowedTimestamp || whitelist[from],
            "not allowed"
        );
        super._update(from, to, amount);
    }
    
    
    function mint(address _account, uint256 _amount) public onlyOwner {
        _mint(_account, _amount);
    }


    function nonces(address owner)
        public
        view
        override(ERC20Permit, Nonces)
        returns (uint256)
    {
        return super.nonces(owner);
    }
}