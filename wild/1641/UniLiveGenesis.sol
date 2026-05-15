// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract UniLiveGenesisNavigator is ERC721Enumerable, Ownable {
    using Strings for uint256;

    // Config
    uint256 public constant MAX_SUPPLY = 2100;
    uint256 public mintPrice = 0 ether;          // start free (set nonzero later if desired)
    bool public publicMintEnabled = false;       // false = whitelist only, true = public

    string private baseTokenURI;
    bytes32 public merkleRoot;                   // whitelist merkle root
    mapping(address => bool) public hasMinted;   // 1 per wallet

    constructor(string memory _baseTokenURI) 
        ERC721("UniLive Genesis Navigator", "UGN") 
        Ownable(msg.sender) {
        baseTokenURI = _baseTokenURI;
    }

    // ----- Mint (1 per tx & per wallet) -----
    function mint(bytes32[] calldata merkleProof) external payable {
        require(totalSupply() < MAX_SUPPLY, "Max supply reached");
        require(!hasMinted[msg.sender], "Already minted");
        require(msg.value == mintPrice, "Incorrect ETH amount to mint");

        if (!publicMintEnabled) {
            // whitelist phase
            require(_isWhitelisted(msg.sender, merkleProof), "Not whitelisted");
        }

        hasMinted[msg.sender] = true; // effects
        _safeMint(msg.sender, totalSupply() + 1); // interaction (internal)
    }

    // ----- Admin -----
    function setBaseURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setMintPrice(uint256 _newPrice) external onlyOwner {
        mintPrice = _newPrice;
    }

    function togglePublicMint(bool _enabled) external onlyOwner {
        publicMintEnabled = _enabled;
    }

    function setMerkleRoot(bytes32 _root) external onlyOwner {
        merkleRoot = _root;
    }

    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    // ----- Internals -----
    function _isWhitelisted(address account, bytes32[] calldata merkleProof) internal view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(account));
        return MerkleProof.verify(merkleProof, merkleRoot, leaf);
    }

    // ----- Token URI -----
    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

}
