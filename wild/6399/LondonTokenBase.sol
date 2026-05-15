// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./Ownable.sol";
import "./ERC721.sol";
import "./ERC2981PerTokenRoyalties.sol";
import "./OnchainFileStorage.sol";

/// @custom:security-contact contact@verse.works
contract LondonTokenBase is
    ERC721,
    Ownable,
    ERC2981PerTokenRoyalties,
    OnchainFileStorage
{
    constructor() ERC721("", "VERSE", "") {}

    /**
     * @dev Initializes key parameters of the contract, ensuring it's only done once.
     * @param uri_ The base URI for token metadata.
     * @param minter_ The address with the ability to mint new tokens.
     * @param gatewayManager_ The address of the gateway manager.
     * @param contractName_ The name of the contract.
     * @param royaltyValue_ The royalty value for each token.
     * @param owner_ The initial owner of the contract.
     */
    function initialize(
        string memory uri_,
        address minter_,
        address gatewayManager_,
        string memory contractName_,
        uint256 royaltyValue_,
        address owner_
    ) public {
        require(bytes(_name).length == 0, "Already initialized");
        _name = contractName_;
        _baseUri = uri_;
        mintingManager = minter_;
        gatewayManager = gatewayManager_;
        _setTokenRoyalty(owner_, royaltyValue_);
        creator = owner_;
        _transferOwnership(owner_);
    }

    /** @notice The total number of tokens in existence. */
    uint256 public totalSupply;

    /** @notice Address of the creator of the tokens. */
    address public creator;

    /** @notice Address responsible for minting new tokens. */
    address public mintingManager;

    /** @notice Address responsible for managing gateways. */
    address public gatewayManager;

    /** @notice Stores payloads for each token by their ID. */
    mapping(uint256 => string) public _payloads;

    /** @notice Name of the artist associated with the tokens. */
    string public artistName;

    /** @notice Description of the project for which the tokens are minted. */
    string public projectDescription;

    /** @notice Year of the token creation or release. */
    string public year;

    /** @notice Licensing information for the token. */
    string public license;

    /**
     * @dev Sets Artist Name for the collection.
     *
     */
    function setArtistName(string memory artistName_) public onlyOwner {
        artistName = artistName_;
    }

    /**
     * @dev Sets Collection Name for the collection.
     *
     */
    function setCollectionName(string memory name_) public onlyOwner {
        _name = name_;
    }

    /**
     * @dev Sets Description for the collection.
     *
     */
    function setDescription(string memory description_) public onlyOwner {
        projectDescription = description_;
    }

    /**
     * @dev Sets Year for the collection.
     *
     */
    function setYear(string memory year_) public onlyOwner {
        year = year_;
    }

    /**
     * @dev Sets License for the collection.
     *
     */
    function setLicense(string memory license_) public onlyOwner {
        license = license_;
    }

    /**
     * @dev Creates a token with `id`, and assigns them to `to`.
     * Method emits two transfer events.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function mint(address to, uint256 tokenId) public onlyMinter {
        require(to != address(0), "mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _balances[to] += 1;
        totalSupply += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), creator, tokenId);
        emit Transfer(creator, to, tokenId);
    }

    /**
     * @dev Creates a token with `id`, and assigns them to `to`.
     * Method emits two transfer events.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function mintWithPayload(
        address to,
        uint256 tokenId,
        string memory payload
    ) public onlyMinter {
        require(to != address(0), "mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _balances[to] += 1;
        totalSupply += 1;
        _owners[tokenId] = to;
        _payloads[tokenId] = payload;

        emit Transfer(address(0), creator, tokenId);
        emit Transfer(creator, to, tokenId);
    }

    /**
     * @dev Creates a token with `id`, and assigns them to `to`.
     * Method emits two transfer events.
     *
     * Emits a {Transfer} events for intermediate artist.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function mintBatch(
        address[] memory to,
        uint256[] memory tokenIds
    ) public onlyMinter {
        require(tokenIds.length == to.length, "Arrays length mismatch");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            mint(to[i], tokenIds[i]);
        }
    }

    /**
     * @dev Creates a token with `id`, and assigns them to `to`.
     * Method emits two transfer events.
     *
     * Emits a {Transfer} events for intermediate artist.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function mintBatchWithPayload(
        address[] memory to,
        uint256[] memory tokenIds,
        string[] memory payloads
    ) public onlyMinter {
        require(tokenIds.length == to.length, "Arrays length mismatch");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            mintWithPayload(to[i], tokenIds[i], payloads[i]);
        }
    }

    /**
     * @dev Modifier for Minter role.
     *
     */
    modifier onlyMinter() {
        require(msg.sender == mintingManager, "Permission denied");
        _;
    }

    /**
     * @dev Modified for Gateway Manager role.
     *
     */
    modifier onlyGatewayManager() {
        require(msg.sender == gatewayManager, "Permission denied");
        _;
    }

    /**
     * @dev Updates the token URI.
     *
     */
    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    /**
     * @dev Returns payload for the token.
     *
     */
    function getPayload(uint256 tokenId) public view returns (string memory) {
        return _payloads[tokenId];
    }

    /**
     * @dev Sets the payload for a given token ID.
     * @param tokenId The ID of the token.
     * @param payload The payload to be stored.
     */
    function setPayload(uint256 tokenId, string memory payload) public onlyOwner {
        _payloads[tokenId] = payload;
    }

    /**
     * @dev Checks for supported interface.
     *
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721, ERC2981Base) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev Sets royalties for `tokenId` and `tokenRecipient` with royalty value `royaltyValue`.
     *
     */
    function setRoyalties(
        address royaltyRecipient,
        uint256 royaltyValue
    ) public onlyOwner {
        _setTokenRoyalty(royaltyRecipient, royaltyValue);
    }

    /**
     * @dev Sets new minter for the contract.
     *
     */
    function setMintingManager(address minter_) public onlyOwner {
        mintingManager = minter_;
    }

    /**
     * @dev Sets new gateway manager for the contract.
     *
     */
    function setGatewayManager(address gatewayManager_) public onlyOwner {
        gatewayManager = gatewayManager_;
    }

    /**
     * @dev Sets base URI for metadata.
     *
     */
    function setURI(string memory newuri) public onlyGatewayManager {
        _setURI(newuri);
    }
}
