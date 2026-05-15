// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract PerkVault is ERC721, Ownable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;
    using Strings for uint256;

    // State variables
    uint256 private _tokenIdCounter = 1;
    uint256 public maxSupply;
    
    IERC20 public immutable USDC;
    
    // Metadata
    string private _baseTokenURI;
    string private _contractName;
    string private _contractSymbol;
    
    // Whitelist for authorized minter addresses 
    mapping(address => bool) public authorizedMinters;
    
    // Constants
    uint256 public constant MAX_MINT_PER_TX = 100;
    
    // Events
    event NFTMinted(address indexed recipient, uint256 indexed tokenId, uint256 quantity);
    event MinterAuthorized(address indexed minter, bool authorized);
    event USDCWithdrawn(address indexed to, uint256 amount);
    event ContractPaused();
    event ContractUnpaused();
    event BaseURIUpdated(string newBaseURI);
    event MaxSupplyUpdated(uint256 newMaxSupply);
    event NameUpdated(string newName);
    event SymbolUpdated(string newSymbol);
    
    // Errors
    error UnauthorizedCaller();
    error InvalidRecipient();
    error InvalidQuantity();
    error MaxSupplyReached();
    error MaxSupplyExceeded();
    error QuantityTooHigh();

    /**
     * @dev Constructor for Ethereum Mainnet deployment
     * @param _name Token name
     * @param _symbol Token symbol
     * @param _owner Contract owner address
     * @param _maxSupply Maximum number of NFTs that can be minted
     * @param _initialBaseURI Initial base URI for token metadata
     */
    constructor(
        string memory _name,
        string memory _symbol,
        address _owner,
        uint256 _maxSupply,
        string memory _initialBaseURI
    ) ERC721(_name, _symbol) Ownable(_owner) {
        require(_owner != address(0), "Invalid owner address");
        
        // Ethereum Mainnet USDC address (6 decimals)
        USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
        
        maxSupply = _maxSupply;
        _baseTokenURI = _initialBaseURI;
        _contractName = _name;
        _contractSymbol = _symbol;
    }

    /**
     * @dev Main mint function that authorized minters will call
     * @param _to Address to receive the NFT
     * @param _quantity Number of NFTs to mint
     */
    function mintNFT(address _to, uint256 _quantity) external nonReentrant whenNotPaused {
        // Only authorized minters can call this function
        if (!authorizedMinters[msg.sender]) {
            revert UnauthorizedCaller();
        }
        
        _mintInternal(_to, _quantity);
    }

    /**
     * @dev Owner mint function - allows contract owner to mint NFTs (works even when paused)
     * @param _to Address to receive the NFT
     * @param _quantity Number of NFTs to mint
     */
    function ownerMint(address _to, uint256 _quantity) external onlyOwner {
        _mintInternal(_to, _quantity);
    }

    /**
     * @dev Internal mint logic with all validations
     */
    function _mintInternal(address _to, uint256 _quantity) private {
        if (_to == address(0)) revert InvalidRecipient();
        if (_quantity == 0) revert InvalidQuantity();
        if (_quantity > MAX_MINT_PER_TX) revert QuantityTooHigh();
        
        // Check max supply if set
        if (maxSupply > 0) {
            if (_tokenIdCounter > maxSupply) revert MaxSupplyReached();
            if (_tokenIdCounter + _quantity - 1 > maxSupply) revert MaxSupplyExceeded();
        }
        
        uint256 startTokenId = _tokenIdCounter;
        
        // Mint NFTs
        for (uint256 i = 0; i < _quantity; i++) {
            uint256 tokenId = _tokenIdCounter;
            _tokenIdCounter++;
            _safeMint(_to, tokenId);
        }
        
        emit NFTMinted(_to, startTokenId, _quantity);
    }

    /**
     * @dev Authorize or revoke a minter address
     * @param _minter Minter address to authorize/revoke
     * @param _authorized True to authorize, false to revoke
     */
    function setMinterAuthorization(address _minter, bool _authorized) external onlyOwner {
        authorizedMinters[_minter] = _authorized;
        emit MinterAuthorized(_minter, _authorized);
    }

    /**
     * @dev Batch authorize or revoke multiple minter addresses
     * @param _minters Array of minter addresses
     * @param _authorized True to authorize, false to revoke
     */
    function batchSetMinterAuthorization(address[] calldata _minters, bool _authorized) external onlyOwner {
        for (uint256 i = 0; i < _minters.length; i++) {
            authorizedMinters[_minters[i]] = _authorized;
            emit MinterAuthorized(_minters[i], _authorized);
        }
    }

    /**
     * @dev Set base URI for token metadata
     * @param baseURI_ New base URI
     */
    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseTokenURI = baseURI_;
        emit BaseURIUpdated(baseURI_);
    }

    /**
     * @dev Update the collection name
     * @param newName New collection name
     */
    function updateName(string memory newName) external onlyOwner {
        _contractName = newName;
        emit NameUpdated(newName);
    }

    /**
     * @dev Update the collection symbol
     * @param newSymbol New collection symbol
     */
    function updateSymbol(string memory newSymbol) external onlyOwner {
        _contractSymbol = newSymbol;
        emit SymbolUpdated(newSymbol);
    }

    /**
     * @dev Update max supply (can only decrease or set if currently unlimited)
     * @param _newMaxSupply New maximum supply (must be >= current supply)
     */
    function setMaxSupply(uint256 _newMaxSupply) external onlyOwner {
        require(_newMaxSupply >= _tokenIdCounter - 1, "Max supply below current supply");
        require(maxSupply == 0 || _newMaxSupply <= maxSupply, "Can only decrease max supply");
        
        maxSupply = _newMaxSupply;
        emit MaxSupplyUpdated(_newMaxSupply);
    }

    /**
     * @dev Pause the contract - stops authorized minting but allows owner functions
     */
    function pauseContract() external onlyOwner {
        _pause();
        emit ContractPaused();
    }

    /**
     * @dev Unpause the contract - allows authorized minting again
     */
    function unpauseContract() external onlyOwner {
        _unpause();
        emit ContractUnpaused();
    }

    /**
     * @dev Withdraw all USDC from the contract to owner
     */
    function withdrawAllUSDC() external onlyOwner {
        uint256 balance = USDC.balanceOf(address(this));
        require(balance > 0, "No USDC to withdraw");
        
        USDC.safeTransfer(owner(), balance);
        emit USDCWithdrawn(owner(), balance);
    }

    /**
     * @dev Withdraw specific amount of USDC from the contract to owner
     * @param _amount Amount of USDC to withdraw (in USDC's smallest unit - 6 decimals)
     */
    function withdrawUSDC(uint256 _amount) external onlyOwner {
        require(_amount > 0, "Amount must be greater than 0");
        require(USDC.balanceOf(address(this)) >= _amount, "Insufficient USDC balance");
        
        USDC.safeTransfer(owner(), _amount);
        emit USDCWithdrawn(owner(), _amount);
    }

    /**
     * @dev Withdraw USDC to a specific address
     * @param _to Address to send USDC to
     * @param _amount Amount of USDC to withdraw
     */
    function withdrawUSDCTo(address _to, uint256 _amount) external onlyOwner {
        require(_to != address(0), "Invalid recipient address");
        require(_amount > 0, "Amount must be greater than 0");
        require(USDC.balanceOf(address(this)) >= _amount, "Insufficient USDC balance");
        
        USDC.safeTransfer(_to, _amount);
        emit USDCWithdrawn(_to, _amount);
    }

    // View functions
    
    /**
     * @dev Override to return custom base URI
     */
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev Returns the token URI for a given token ID
     * @param tokenId Token ID to get URI for
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 
            ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
            : "";
    }

    /**
     * @dev Override name() to return updatable name
     */
    function name() public view override returns (string memory) {
        return _contractName;
    }

    /**
     * @dev Override symbol() to return updatable symbol
     */
    function symbol() public view override returns (string memory) {
        return _contractSymbol;
    }

    /**
     * @dev Get current USDC balance of the contract
     */
    function getUSDCBalance() external view returns (uint256) {
        return USDC.balanceOf(address(this));
    }

    /**
     * @dev Get total number of NFTs minted
     */
    function totalSupply() external view returns (uint256) {
        return _tokenIdCounter - 1;
    }

    /**
     * @dev Get next token ID that will be minted
     */
    function nextTokenId() external view returns (uint256) {
        return _tokenIdCounter;
    }

    /**
     * @dev Check if an address is an authorized minter
     */
    function isMinterAuthorized(address _minter) external view returns (bool) {
        return authorizedMinters[_minter];
    }

    /**
     * @dev Get the current base URI
     */
    function baseURI() external view returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev Check how many more NFTs can be minted (returns max uint256 if unlimited)
     */
    function remainingSupply() external view returns (uint256) {
        if (maxSupply == 0) return type(uint256).max; // Unlimited
        uint256 minted = _tokenIdCounter - 1;
        if (minted >= maxSupply) return 0;
        return maxSupply - minted;
    }

    /**
     * @dev Get contract version and network info
     */
    function getContractInfo() external pure returns (
        string memory version,
        string memory network,
        address usdcAddress
    ) {
        return (
            "1.0.0",
            "Ethereum Mainnet",
            0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
        );
    }
}