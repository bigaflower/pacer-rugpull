// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts@4.9.5/access/Ownable.sol";
import "@openzeppelin/contracts@4.9.5/security/Pausable.sol";
import "@openzeppelin/contracts@4.9.5/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts@4.9.5/token/common/ERC2981.sol";
import "@openzeppelin/contracts@4.9.5/utils/Counters.sol";
import "@openzeppelin/contracts@4.9.5/token/ERC721/IERC721.sol";

/**
 * @title SeabirdsArtForge
 * @dev AI-powered NFT minter with Seabirds ownership validation and 24h cooldown.
 */
contract SeabirdsArtForge is ERC721URIStorage, ERC2981, Ownable, Pausable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    /// @notice Original Seabirds ERC721 collection
    IERC721 public immutable seabirdsContract;

    /// @notice Last mint timestamp per wallet
    mapping(address => uint256) public lastMintTimestamp;

    /// @notice Fixed cooldown: 24 hours (in seconds)
    uint256 public constant MINT_COOLDOWN = 86400;

    /**
     * @param seabirdsAddress Address of the official Seabirds ERC721 collection
     * @param royaltyReceiver Receiver address for ERC2981 royalties
     * @param royaltyFee Numerator for royalties (e.g. 500 = 5%, 750 = 7.5%)
     */
    constructor(
        address seabirdsAddress,
        address royaltyReceiver,
        uint96 royaltyFee
    ) ERC721("Seabirds Art Forge", "SBART") Ownable() {
        require(seabirdsAddress != address(0), "Invalid Seabirds contract");
        require(royaltyReceiver != address(0), "Invalid royalty receiver");

        seabirdsContract = IERC721(seabirdsAddress);

        // Set default royalties for all tokens
        _setDefaultRoyalty(royaltyReceiver, royaltyFee);
    }

    /**
     * @dev Mint a new artwork using a metadataURI produced by the backend.
     *
     * Requirements:
     * - Caller must own at least 1 Seabirds NFT.
     * - Caller must respect the 24h cooldown between mints.
     * - Contract must not be paused.
     *
     * @param metadataURI Full token URI (e.g. ipfs://CID)
     */
    function mintArtwork(string memory metadataURI)
        external
        whenNotPaused
        returns (uint256)
    {
        require(bytes(metadataURI).length > 0, "Invalid metadataURI");

        // Require at least one Seabirds NFT
        require(
            seabirdsContract.balanceOf(msg.sender) > 0,
            "Caller does not own a Seabirds NFT"
        );

        // Enforce 24h cooldown
        uint256 lastMint = lastMintTimestamp[msg.sender];
        require(
            block.timestamp >= lastMint + MINT_COOLDOWN,
            "Mint cooldown active (24h required)"
        );

        // Update cooldown timestamp
        lastMintTimestamp[msg.sender] = block.timestamp;

        // Increment and mint
        _tokenIdCounter.increment();
        uint256 newId = _tokenIdCounter.current();

        _safeMint(msg.sender, newId);
        _setTokenURI(newId, metadataURI);

        return newId;
    }

    /// @notice Pause minting (owner only)
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpause minting (owner only)
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @inheritdoc ERC721URIStorage
    function _burn(uint256 tokenId)
        internal
        virtual
        override(ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    /// @inheritdoc ERC721URIStorage
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    /// @inheritdoc ERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721URIStorage, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}