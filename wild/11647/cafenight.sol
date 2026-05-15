// SPDX-License-Identifier: MIT
/**
*Submitted for verification at Etherscan.io on 2024-04-03
*/
 
pragma solidity ^0.8.25;
 
import "@openzeppelin/contracts/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "https://github.com/limitbreakinc/creator-token-contracts/blob/main/contracts/access/OwnableBasic.sol";
import "https://github.com/limitbreakinc/creator-token-contracts/blob/main/contracts/erc721c/ERC721AC.sol";
import "https://github.com/limitbreakinc/creator-token-contracts/blob/main/contracts/programmable-royalties/BasicRoyalties.sol";
 
error AlreadyReservedTokens();
error CallerNotOffsetter();
error FunctionLocked();
error InsufficientValue();
error InsufficientMints();
error InsufficientSupply();
error InvalidSignature();
error NoContractMinting();
error ProvenanceHashAlreadySet();
error ProvenanceHashNotSet();
error TokenOffsetAlreadySet();
error TokenOffsetNotSet();
error WithdrawFailed();
 
interface Offsetable {
    function setOffset(uint256 randomness) external;
}


contract Cafe_Terrace_at_Night is ERC721AC, BasicRoyalties, Ownable, OwnableBasic {
     string private _baseTokenURI;
    uint256 public publicMintPrice = 0.029 ether;
    uint256 public constant RESERVED = 10;
    uint256 public MAX_SUPPLY = 110;
    uint256 public mintStartTime;
    uint256 public mintDuration;
    bool public publicMintActive;

     //mappings 
      mapping(bytes4 => bool) public functionLocked;
    mapping(address => bool) public minter;

    

     constructor(address initialOwner, address royaltyReceiver, uint96 royaltyFeeNumerator, address _minter) ERC721AC("Cafe Terrace at Night", "Cafe Terrace at Night") 
        BasicRoyalties(royaltyReceiver, royaltyFeeNumerator) Ownable(initialOwner){
            minter[_minter] = true;
     }

    struct MintConfig {
        bool enablePublic;
        uint256 durationHours;
        uint256 publicPrice;
    }

    function enableMint(MintConfig calldata config) external onlyOwner {
        publicMintActive = config.enablePublic;

        if (config.enablePublic) {
            mintStartTime = block.timestamp;
            mintDuration = config.durationHours * 1 hours;
        }

        if (config.publicPrice > 0) publicMintPrice = config.publicPrice;

    }
    


     modifier lockable() {
        if (functionLocked[msg.sig]) revert FunctionLocked();
        _;
     }
    

     modifier onlyMinter() {
        require(minter[msg.sender] == true, "You're not a minter");
        _;
     }

           
     
        function reserve(address to) external lockable onlyOwner {
        if (_totalMinted() >= RESERVED) revert AlreadyReservedTokens();
        _mint(to, RESERVED);
       }

        function secondaryReserve(address to, uint256 _quantity)  external onlyOwner {
            require(_totalMinted() + _quantity <= MAX_SUPPLY, "supply exceed");
        _mint(to, _quantity);
        }

        function cardMint(address to, uint256 _quantity)  external onlyMinter {
        require(
            block.timestamp <= mintStartTime + mintDuration,
            "Minting period ended"
        );
        require(_totalMinted() + _quantity <= MAX_SUPPLY, "supply exceed");
        _mint(to, _quantity);
        }

       function publicMint(address to, uint256 _quantity) external payable {
       require(
            publicMintActive && block.timestamp <= mintStartTime + mintDuration,
            "Public minting inactive or ended"
        );
        require(_totalMinted() + _quantity <= MAX_SUPPLY, "supply exceed");
        uint256 totalCost = _quantity * publicMintPrice;
        require(msg.value >= totalCost, "Insufficient ETH");
        _mint(to, _quantity);
        if (msg.value > totalCost) {
            payable(msg.sender).transfer(msg.value - totalCost);
        }
        }

        function setMaxSupply(uint256 _newsupply) public onlyOwner{
            MAX_SUPPLY = _newsupply;
        }

     function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner{
        _requireCallerIsContractOwner();
        _setDefaultRoyalty(receiver, feeNumerator);
        }

     function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) public onlyOwner{
        _requireCallerIsContractOwner();
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
     }
       

     function assignMinterRole(address _minter) external onlyOwner {
        minter[_minter] = true;
     }

     function revokeMinterRole(address _minter) external onlyOwner {
        minter[_minter] = false;
     }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721AC, ERC2981)
        returns (bool)
    {
        return
            ERC721AC.supportsInterface(interfaceId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        Strings.toString(tokenId)
                    )
                )
                : "";
    }

     function numberMinted(address account) external view returns (uint256) {
        return _numberMinted(account);
     }

     function lockFunction(bytes4 id) external onlyOwner {
        functionLocked[id] = true;
     }

    function setBaseURI(string calldata _newBaseURI)
        external
        lockable
        onlyOwner
    {
        _baseTokenURI = _newBaseURI;
    }


    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        if (!success) revert WithdrawFailed();
    }
}