// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// ████████╗██╗░░██╗███████╗  ░█████╗░██╗██████╗░░█████╗░██╗░░░░░███████╗
// ╚══██╔══╝██║░░██║██╔════╝  ██╔══██╗██║██╔══██╗██╔══██╗██║░░░░░██╔════╝
// ░░░██║░░░███████║█████╗░░  ██║░░╚═╝██║██████╔╝██║░░╚═╝██║░░░░░█████╗░░
// ░░░██║░░░██╔══██║██╔══╝░░  ██║░░██╗██║██╔══██╗██║░░██╗██║░░░░░██╔══╝░░
// ░░░██║░░░██║░░██║███████╗  ╚█████╔╝██║██║░░██║╚█████╔╝███████╗███████╗
// ░░░╚═╝░░░╚═╝░░╚═╝╚══════╝  ░╚════╝░╚═╝╚═╝░░╚═╝░╚════╝░╚══════╝╚══════╝

// Powered by https://nalikes.com

contract OnlyInTheCircle is ERC721AQueryable, Ownable {
    
    using Strings for uint256;
    
    uint256 public maxSupply = 444;

    mapping(address => bool) public freeMintClaimed;

    bytes32 public merkleRoot;
    
    string public baseURI;
    string public uriSuffix = ".json";
    
    bool public paused = true;
    bool public tradingLock = true;
    

    constructor() Ownable(msg.sender) ERC721A("Circle Pass", "CIRCLE") {}

    //******************************* MODIFIERS

    modifier notPaused() {
        require(!paused, "The contract is paused!");
        _;
    }

    modifier noBots() {
        require(_msgSender() == tx.origin, "No bots!");
        _;
    }

    modifier mintCompliance(uint256 quantity) {
        require(_totalMinted() + quantity <= maxSupply, "Max Supply Exceeded.");
        _;
    }

    //******************************* OVERRIDES

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        require(!tradingLock || from == address(0), "Trading is locked!");
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    //******************************* MINT

    function mint(bytes32[] calldata proof) external noBots notPaused mintCompliance(1) {
        require(!freeMintClaimed[_msgSender()], "Already claimed!");

        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(MerkleProof.verify(proof, merkleRoot, leaf), "Not a valid proof!");

        freeMintClaimed[_msgSender()] = true;
        _safeMint(_msgSender(), 1);
    }

    function mintAdmin(address to, uint256 quantity) external onlyOwner mintCompliance(quantity) {
        _safeMint(to, quantity);
    }

    //******************************* ADMIN

    function setMaxSupply(uint256 _supply) external onlyOwner {
        require(_supply >= _totalMinted() && _supply <= maxSupply, "Invalid Max Supply.");
        maxSupply = _supply;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function setUriSuffix(string memory _uriSuffix) external onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function setTradingLock(bool _state) external onlyOwner {
        tradingLock = _state;
    }

    //******************************* VIEWS

    function tokenURI(uint256 _tokenId) public view virtual override (ERC721A, IERC721A) returns (string memory) {
        require(_exists(_tokenId), "URI query for nonexistent token");

        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, _tokenId.toString(), uriSuffix)) : "";    
    }
}