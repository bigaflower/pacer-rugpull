// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.4.0
pragma solidity ^0.8.27;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Burnable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import {ERC721Pausable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Onchaingmbadge is ERC721, ERC721Pausable, Ownable, ERC721Burnable {
    uint256 private _nextTokenId;
    
    // Mint ücreti: 1 Native Token (1 ether = 10^18 wei)
    uint256 public constant MINT_PRICE = 0.00033 ether;
    
    // Ücret alıcı adresi
    address payable public constant FEE_RECEIVER = payable(0x7500A83DF2aF99B2755c47B6B321a8217d876a85);
    
    // Sabit IPFS adresi
    string private constant _IPFS_URI = "https://bafybeicgm7ap5oacns4qolnhkgl5neks5b6ngdyurz5yleexkwubz222fi.ipfs.w3s.link";

    constructor(address initialOwner)
        ERC721("ONCHAINGM ETHEREUM BADGE", "OEB")
        Ownable(initialOwner)
    {}

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    // Herkesin mint edebileceği fonksiyon - ücret direkt alıcıya gönderilir
    function publicMint() public payable whenNotPaused {
        require(msg.value >= MINT_PRICE, "Insufficient payment Native Token required.");
        
        // Mint ücretini direkt alıcı adrese gönder
        (bool success, ) = FEE_RECEIVER.call{value: msg.value}("");
        require(success, "Transfer failed");
        
        uint256 tokenId = _nextTokenId++;
        _safeMint(msg.sender, tokenId);
    }

    // Kontrat sahibinin ücretsiz mint yapabilmesi için
    function safeMint(address to) public onlyOwner {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
    }

    // IPFS linkini döndüren fonksiyon
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        return _IPFS_URI;
    }

    // The following functions are overrides required by Solidity.
    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721, ERC721Pausable)
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }
}