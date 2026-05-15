// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";

contract haildraconis is ERC721A, Ownable {

    string public baseTokenURI = "https://ipfs.io/ipfs/bafybeieaw3y26geatinfpl7dj2xmcqj5jrebiliuf2jkqxzu7opkaoclim/";
    uint public TOTAL_SUPPLY = 5555;
    uint public PRICE = 0.01 ether;
    bool public isPaused = true;
    uint public MAX_PER_MINT = 20;
    mapping(address => uint) public freeMints;

    struct RevshareWallet {
        address wallet;
        uint256 percent;
    }

    RevshareWallet[] public revshareWallets;
    uint256 public totalPercent;

    constructor() ERC721A("hailDraconis", "DRACONIS") Ownable(msg.sender) {
    }
    
    function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory base = _baseURI();
        return bytes(base).length > 0 ? string(abi.encodePacked(base, _toString(tokenId), ".json")) : "";
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function treasuryMint(uint256 _count) public onlyOwner {
        require(totalSupply() + _count <= TOTAL_SUPPLY, "Not enough NFTs left");
        _safeMint(msg.sender, _count);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI (string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setPaused(bool newPaused) public onlyOwner {
        isPaused = newPaused;
    }

    function setPrice(uint256 newPrice) public onlyOwner {
        PRICE = newPrice;
    }

    function setMaxPerMint(uint newMax) public onlyOwner {
        MAX_PER_MINT = newMax;
    }

    function setFreeMints(address _user, uint256 _amount) public onlyOwner {
        freeMints[_user] = _amount;
    }

    function setFreeMintsBatch(address[] memory _addresses, uint256 _amount) public onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            freeMints[_addresses[i]] = _amount;
        }
    }

    function mintNFTs(uint256 _count) public payable {
        require(!isPaused, "Cannot mint at this time");
        require(_count > 0 && _count <= MAX_PER_MINT, "Invalid mint count");
        require(totalSupply() + _count <= TOTAL_SUPPLY, "Not enough NFTs left!");

        uint freeAvailable = freeMints[msg.sender];
        uint freeUsed = 0;
        uint paidCount = 0;

        if (freeAvailable >= _count) {
            freeUsed = _count;
            paidCount = 0;
        } else {
            freeUsed = freeAvailable;
            paidCount = _count - freeAvailable;
        }

        if (freeUsed > 0) {
            freeMints[msg.sender] = freeAvailable - freeUsed;
        }

        if (paidCount > 0) {
            require(msg.value >= paidCount * PRICE, "Not enough ETH sent");
        } else {
            require(msg.value == 0, "No ETH required for free mint");
        }

        _safeMint(msg.sender, _count);
    }

    function tokensOfOwner(address owner) external view returns (uint256[] memory) {
        uint256 balance = balanceOf(owner);
        uint256[] memory tokenIds = new uint256[](balance);

        uint256 count = 0;
        uint256 supply = _nextTokenId(); // ERC721A tracks the next token ID to mint
        address currentOwner;

        for (uint256 i = _startTokenId(); i < supply; i++) {
            // Check ownership more efficiently
            currentOwner = _ownershipOf(i).addr;
            if (currentOwner == owner) {
                tokenIds[count] = i;
                count++;
                if (count == balance) {
                    break;
                }
            }
        }
        return tokenIds;
    }

    function addRevshareWallet(address _wallet, uint256 _percent) public onlyOwner {
        require(_wallet != address(0), "Invalid wallet");
        require(_percent > 0, "Percent must be > 0");
        require(totalPercent + _percent <= 100, "Total percent exceeds 100");

        revshareWallets.push(RevshareWallet(_wallet, _percent));
        totalPercent += _percent;
    }

    function updateRevshareWallet(uint256 _index, address _wallet, uint256 _percent) public onlyOwner {
        require(_index < revshareWallets.length, "Invalid index");
        require(_wallet != address(0), "Invalid wallet");

        totalPercent = totalPercent - revshareWallets[_index].percent + _percent;
        require(totalPercent <= 100, "Total percent exceeds 100");

        revshareWallets[_index].wallet = _wallet;
        revshareWallets[_index].percent = _percent;
    }

    function removeRevshareWallet(uint256 _index) public onlyOwner {
        require(_index < revshareWallets.length, "Invalid index");

        totalPercent -= revshareWallets[_index].percent;
        revshareWallets[_index] = revshareWallets[revshareWallets.length - 1];
        revshareWallets.pop();
    }
        
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");

        if (revshareWallets.length == 0) {
            payable(owner()).transfer(balance);
            return;
        }

        uint256 distributed = 0;

        for (uint256 i = 0; i < revshareWallets.length; i++) {
            uint256 share = (balance * revshareWallets[i].percent) / 100;
            distributed += share;
            payable(revshareWallets[i].wallet).transfer(share);
        }

        uint256 remainder = balance - distributed;
        if (remainder > 0) {
            payable(owner()).transfer(remainder);
        }
    }
}