// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";

// --- Enums ---
enum MintStage { Team, Blendlist, FCFS, Public }

// --- Events ---
event Mint(address indexed minter, MintStage indexed stage, uint256 quantity, uint256 firstTokenId);

contract TectraContract is ERC721, Ownable, IERC2981, ReentrancyGuard {
    
    using Strings for uint256;
    
    constructor() ERC721("Tectra", "TCT") Ownable(msg.sender) {
        toggleMint();
        _mintTokensToCaller(teamSupply, MintStage.Team);
    }

    uint nextTokenId = 1;
    uint maxSupply = 4444;
    uint teamSupply = 144; 
    
    uint blendlistStageCap = 1444; 
    uint fcfsStageCap = 4344; 

    uint privateLimitPerWallet = 1; //Limit per wallet for blendlist and FCFS

    uint blendlistPrice = 0.018 ether;
    uint fcfsPrice = 0.025 ether;
    uint publicPrice = 0.025 ether;

    uint blendlistStartTime = 1749906000;
    uint fcfsStartTime = 1749909600;
    uint publicStartTime = 1749913200;
    uint tradeLockTimestamp = 1749913200;
    uint revealTimestamp = 1750006800;

    bool public isMintActive = false;
    bool public revealStatus = false;

    bytes32 private blendlistRoot;
    bytes32 private fcfsRoot;

    bytes4 private constant ERC2981_INTERFACE_ID = bytes4(0x2a55205a);

    address private royaltyReceiver = 0x2132800cF034b859A99642819C45c7277EB1fb34;
    address private withdrawAddress = 0xBe3E5F563735071eEE900802C5A4a9c3136fC5c3;

    uint256 private royaltyFraction = 500;

    string public revealedURI;
    string public unrevealedURI;

    mapping(address => uint) public mintedByAddress;
    mapping(address => uint) public blendlistMintedByAddress;
    mapping(address => uint) public fcfsMintedByAddress;

   

    function totalSupply() public view returns (uint) {
        return nextTokenId -1;
    }
    
    // --- Base URI ---    
   
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        string memory baseURI = _baseURI();

        if((revealStatus==false && block.timestamp < revealTimestamp)){
            return baseURI;
        }else{
            return bytes(baseURI).length > 0 ? string.concat(baseURI, tokenId.toString(), ".json") : "";
        }
    }


    function _baseURI() internal view override returns (string memory) {
            if (revealStatus == false && block.timestamp < revealTimestamp) {
                return unrevealedURI;
            }
            return revealedURI;
    }


    function setTokenURIs(string calldata _unrevealedURI, string calldata baseURI) public onlyOwner{
        unrevealedURI = _unrevealedURI;
        revealedURI = baseURI;
    }

     function toggleReveal() public onlyOwner{
        revealStatus = !revealStatus;
    }

    
    // --- Internal Core Minting Function ---

    function _mintTokensToCaller(uint256 _amount, MintStage _stage) internal {
        require(isMintActive, "Minting Stage is not active");
        require(_amount > 0, "Amount to mint must be greater than zero");
        require(totalSupply() + _amount <= maxSupply, "Mint amount exceeds max supply");

        uint256 firstTokenIdMinted = nextTokenId;

        for (uint256 i = 0; i < _amount; i++) {
            _safeMint(msg.sender, nextTokenId);
            mintedByAddress[msg.sender]++;
            nextTokenId++;
        }
        emit Mint(msg.sender, _stage, _amount, firstTokenIdMinted);
    }


    // --- Public Minting Functions ---

    function publicMint() public payable nonReentrant {
        require(block.timestamp >= publicStartTime, "Public stage has not started yet");
        require(msg.value >= publicPrice, "Insufficient funds");
        _mintTokensToCaller(1, MintStage.Public);
    }

    function blendlistMint(bytes32[] calldata _blendlistMerkleProof) public payable nonReentrant {
        require(block.timestamp >= blendlistStartTime && block.timestamp < fcfsStartTime, "blendlist stage has not started yet");
        require(checkBlendlistEligibility(getLeaf(msg.sender), _blendlistMerkleProof), "You are not eligible for this round");
        require(blendlistMintedByAddress[msg.sender] < privateLimitPerWallet, "This wallet is reached the max mintable amount for this stage");
        require(totalSupply() < blendlistStageCap, "This round is sold out");
        require(msg.value >= blendlistPrice, "Insufficient funds");
        _mintTokensToCaller(1, MintStage.Blendlist);
        blendlistMintedByAddress[msg.sender]++;
    }
    
    function fcfsMint(bytes32[] calldata _fcfsMerkleProof) public payable nonReentrant {
        require(block.timestamp >= fcfsStartTime && block.timestamp < publicStartTime, "FCFS stage has not started yet");
        require(checkFcfsEligibility(getLeaf(msg.sender), _fcfsMerkleProof), "You are not eligible for this round");
        require(fcfsMintedByAddress[msg.sender] < privateLimitPerWallet, "This wallet is reached the max mintable amount for this stage");
        require(totalSupply() < fcfsStageCap, "This round is sold out");
        require(msg.value >= fcfsPrice, "Insufficient funds");
        _mintTokensToCaller(1, MintStage.FCFS);
        fcfsMintedByAddress[msg.sender]++;
    }

    // Merkle Tree
    function setMerkleRoots(bytes32 _blendlistRoot, bytes32 _fcfsRoot) public onlyOwner {
        blendlistRoot = _blendlistRoot;
        fcfsRoot = _fcfsRoot;
    }

    function getLeaf(address _address) internal pure returns(bytes32 _leaf){
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(_address))));
        return leaf;
    }

    function checkBlendlistEligibility(bytes32 _leaf, bytes32[] calldata _merkleProof) internal view returns(bool blendlistEligibility){
        blendlistEligibility = MerkleProof.verify(_merkleProof, blendlistRoot, _leaf);
    }

    function checkFcfsEligibility(bytes32 _leaf, bytes32[] calldata _merkleProof) internal view returns(bool fcfsEligibility){
        fcfsEligibility = MerkleProof.verify(_merkleProof, fcfsRoot, _leaf);
    }
    
    function checkBothEligibility(address _address, bytes32[] calldata _blendlistMerkleProof, bytes32[] calldata _fcfsMerkleProof) public view returns(bool blendlistEligibility, bool fcfsEligibility){
        bytes32 leaf = getLeaf(_address);
        blendlistEligibility =  checkBlendlistEligibility(leaf, _blendlistMerkleProof);
        fcfsEligibility = checkFcfsEligibility(leaf, _fcfsMerkleProof);
        return(blendlistEligibility, fcfsEligibility);
    }


    // Trade lock functions

    function approve(address to, uint256 tokenId) public virtual override {
        require(block.timestamp >= tradeLockTimestamp, "LockableApprovalERC721: Approvals are currently locked due to trade lock");
        super.approve(to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(block.timestamp >= tradeLockTimestamp, "LockableApprovalERC721: Approvals are currently locked due to trade lock");
        super.setApprovalForAll(operator, approved);
    }
    
    // ERC2981 Royalty Functions

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, IERC165) returns (bool)
    {
        return interfaceId == ERC2981_INTERFACE_ID || super.supportsInterface(interfaceId);
    }

    function royaltyInfo(uint256 /*tokenId*/, uint256 salePrice) external view override returns (address receiver, uint256 royaltyAmount) {
        receiver = royaltyReceiver;
        royaltyAmount = (salePrice * royaltyFraction) / 10000;
    }


    function setRoyaltyInfo(address _receiver, uint256 _newRoyaltyFraction) public onlyOwner {
        require(_receiver != address(0), "ERC2981: invalid receiver");
        require(_newRoyaltyFraction <= 10000, "ERC2981: royalty fraction should be less than or equal to 10000 (100%)"); // Max 100%
        royaltyReceiver = _receiver;
        royaltyFraction = _newRoyaltyFraction;
    }


    // Owner Functions

    function toggleMint() public onlyOwner{
        isMintActive = !isMintActive;
    }

    function setTimes(
        uint _blendlistStartTime,
        uint _fcfsStartTime,
        uint _publicStartTime
    ) public onlyOwner {
        blendlistStartTime = _blendlistStartTime;
        fcfsStartTime = _fcfsStartTime;
        publicStartTime = _publicStartTime;
    }

    function setLimitationTimestamps(uint256 _tradelockTimestamp, uint256 _revealTimestamp) public onlyOwner {
        tradeLockTimestamp = _tradelockTimestamp;
        revealTimestamp = _revealTimestamp;
    }

    function withdrawFunds() public onlyOwner nonReentrant {
        address _address = withdrawAddress;
        (bool success, ) = _address.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

}
