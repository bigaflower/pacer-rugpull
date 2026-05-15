// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.5.0
pragma solidity ^0.8.27;

import {ERC1155} from "@openzeppelin/contracts@5.5.0/token/ERC1155/ERC1155.sol";
import {ERC1155Burnable} from "@openzeppelin/contracts@5.5.0/token/ERC1155/extensions/ERC1155Burnable.sol";
import {ERC1155Supply} from "@openzeppelin/contracts@5.5.0/token/ERC1155/extensions/ERC1155Supply.sol";
import {Ownable} from "@openzeppelin/contracts@5.5.0/access/Ownable.sol";
import {Strings} from "@openzeppelin/contracts@5.5.0/utils/Strings.sol";

contract WhatsOnYourPlateToken is ERC1155, Ownable, ERC1155Burnable, ERC1155Supply {
    using Strings for uint256;
    
    constructor(address initialOwner) ERC1155("") Ownable(initialOwner) {}

    bool public claimActive = false;
    string public contractUri = "";
    error SoulboundToken();

    //MINTING
    function mint(address account, uint256 id, uint256 amount, bytes memory data)
        public
        onlyOwner
    {
        _mint(account, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyOwner
    {
        _mintBatch(to, ids, amounts, data);
    }

    function airdrop(address[] calldata recipients, uint256 id, uint256 amount) 
        external 
        onlyOwner 
    {
        for (uint256 i = 0; i < recipients.length; i++) {
            _mint(recipients[i], id, amount, "");
        }
    }

    function claimToken2(uint256 amount) public {
        require(claimActive, "Claim is not active");
        require(balanceOf(msg.sender, 1) >= amount, "Insufficient Token 1 balance");
        
        _burn(msg.sender, 1, amount);
        _mint(msg.sender, 2, amount, "");
    }

    function toggleClaim(bool _state) external onlyOwner {
        claimActive = _state;
    }

    // The following functions are overrides required by Solidity.
    function _update(
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory values
) internal override(ERC1155, ERC1155Supply) {
    
    // Check if this is a transfer (not a mint or burn)
    if (from != address(0) && to != address(0)) {
        for (uint256 i = 0; i < ids.length; i++) {
            if (ids[i] == 2) {
                //token 2 is a soulbound token
                revert SoulboundToken();
            }
        }
    }

    // Continue with the standard update logic
    super._update(from, to, ids, values);
}

    //APPROVALS
    function setApprovalForAll(address operator, bool approved) public override {
        // If you want to allow a specific contract (like a staking or bridge contract), 
        // you can add a check here. Otherwise, just revert.
        revert("Marketplace approvals are disabled for this collection.");
    }

    function isApprovedForAll(address, address) public view override returns (bool) {
        return false;
    }

    //METADATA
    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function uri(uint256 id) public view override returns (string memory) {
        string memory baseURI = super.uri(id);
        return bytes(baseURI).length > 0 
            ? string(abi.encodePacked(baseURI, id.toString())) 
            : "";
    }

    function contractURI() public view returns (string memory) {
        return contractUri;
    }

    function setContractUri(string memory newUri) public onlyOwner {
        contractUri = newUri;
    }

}