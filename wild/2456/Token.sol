// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ICreatorToken.sol";

contract FrankysDinner is ERC721, ERC2981, ICreatorToken, Ownable {

    // =============================================================
    //                        STORAGE
    // =============================================================

    /// @dev Incremental token ID counter
    uint256 private _tokenIdCounter;

    /// @dev Base token URI for metadata
    string private _baseTokenURI;

    /// @dev Contract-level metadata URI (OpenSea)
    string private contractUri;

    /// @dev Transfer Security Validator (Limit Break style)
    address public validator;

    /// @dev Auto-approve validator to prevent operator bypass
    bool public autoApproveTransfersFromValidator = true;

    /// @dev Maximum supply of tokens
    uint256 public constant MAX_SUPPLY = 1069;

    /// @dev Controls whether burning is enabled
    bool public canBurn = false;


    // =============================================================
    //                         ERRORS
    // =============================================================

    error ValidatorCallFailed();
    error MaxSupplyReached();
    error BurnDisabled();

    // =============================================================
    //                     INTERFACE IDS
    // =============================================================

    bytes4 private constant _INTERFACE_ID_ICREATOR_TOKEN_LEGACY = 0xa07d229a;
    bytes4 private constant _INTERFACE_ID_ICREATOR_TOKEN = 0xad0d7f6c;

    // =============================================================
    //                         EVENTS
    // =============================================================

    event ContractURIUpdated();

    // =============================================================
    //                       CONSTRUCTOR
    // =============================================================

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        address royaltyReceiver_,
        uint96 royaltyFeeNumerator_
    ) ERC721(name_, symbol_) Ownable(msg.sender) {
        _baseTokenURI = baseURI_;
        _tokenIdCounter = 1;

        _setDefaultRoyalty(royaltyReceiver_, royaltyFeeNumerator_);
    }

    // =============================================================
    //                          MINTING
    // =============================================================

    /// @notice Mint a single token to `to`
    function mint(address to) external onlyOwner returns (uint256) {

        if (_tokenIdCounter > MAX_SUPPLY) revert MaxSupplyReached();

        uint256 tokenId = _tokenIdCounter++;
        _safeMint(to, tokenId);
        return tokenId;
    }

    /// @notice Mint specific token IDs to multiple recipients
    function airdrop(
        address[] calldata recipients,
        uint256[] calldata tokenIds
    ) external onlyOwner {
        require(recipients.length == tokenIds.length, "Length mismatch");

        for (uint256 i = 0; i < recipients.length; i++) {
            uint256 tokenId = tokenIds[i];

            require(tokenId <= MAX_SUPPLY, "Exceeds max supply");
            require(_ownerOf(tokenId) == address(0), "Token already minted");
            _safeMint(recipients[i], tokenId);

            if (tokenId >= _tokenIdCounter) {
                _tokenIdCounter = tokenId + 1;
            }
        }
    }

    // =============================================================
    //                          BURNING
    // =============================================================

    /// @notice Enable or disable burning
    function setCanBurn(bool enabled) external onlyOwner {
        canBurn = enabled;
    }

    /// @notice Burn a token (if enabled)
    function burn(uint256 tokenId) external {
        if (!canBurn) revert BurnDisabled();

        address owner = ownerOf(tokenId);

        require(
            msg.sender == owner ||
            isApprovedForAll(owner, msg.sender) ||
            getApproved(tokenId) == msg.sender,
            "Not authorized to burn"
        );

        _burn(tokenId);
    }

    // =============================================================
    //              TRANSFER VALIDATION (ERC721C)
    // =============================================================

    /// @dev Auto-approve validator as operator
    function isApprovedForAll(address owner,address operator) public view override returns (bool) {
    
        bool approved = super.isApprovedForAll(owner, operator);

        if (!approved && autoApproveTransfersFromValidator) {
            approved = operator == validator;
        }

        return approved;
    }


    /// @dev Enforce validator on transfers
    function _update(
    address to,
    uint256 tokenId,
    address auth
) internal override returns (address) {
    address from = _ownerOf(tokenId);
    address previousOwner = super._update(to, tokenId, auth);

    // Skip minting and burning
    if (from != address(0) && to != address(0)) {
        address v = validator;
        require(v != address(0), "Validator not set");

        (bool success, bytes memory returndata) = v.staticcall(
            abi.encodeWithSignature(
                "validateTransfer(address,address,address,uint256)",
                auth,
                from,
                to,
                tokenId
            )
        );

        if (!success) revert ValidatorCallFailed();

        // Enforce boolean return if present
        if (returndata.length == 32) {
            if (!abi.decode(returndata, (bool))) {
                revert ValidatorCallFailed();
            }
        }
    }

    return previousOwner;
}


    // =============================================================
    //                 VALIDATOR CONFIGURATION
    // =============================================================

    /// @notice Set transfer security validator
    function setTransferValidator(address newValidator) external onlyOwner {
        emit TransferValidatorUpdated(validator, newValidator);
        validator = newValidator;
    }

    /// @notice Return active transfer validator
    function getTransferValidator() public view returns (address) {
        return validator;
    }

    /// @notice ERC721C validation function declaration
    function getTransferValidationFunction() external view returns (bytes4 functionSignature, bool isViewFunction) {
        functionSignature = bytes4(keccak256("validateTransfer(address,address,address,uint256)"));
        isViewFunction = true;
    }

    /// @notice Enable or disable auto-approval for validator
    function setAutoApproveValidator(bool enabled) external onlyOwner {
        autoApproveTransfersFromValidator = enabled;
    }

    // =============================================================
    //                        ROYALTIES
    // =============================================================

    function setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    // =============================================================
    //                         METADATA
    // =============================================================

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        _requireOwned(tokenId);
        return string(
            abi.encodePacked(_baseTokenURI, Strings.toString(tokenId))
        );
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        _baseTokenURI = newBaseURI;
    }

    function contractURI() public view returns (string memory) {
        return contractUri;
    }

    function setContractURI(string memory uri_) public onlyOwner {
        contractUri = uri_;
        emit ContractURIUpdated();
    }

    // =============================================================
    //                    INTERFACE SUPPORT
    // =============================================================

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC2981)
        returns (bool)
    {
        return (
            interfaceId == _INTERFACE_ID_ICREATOR_TOKEN_LEGACY ||
            interfaceId == _INTERFACE_ID_ICREATOR_TOKEN ||
            interfaceId == type(ICreatorToken).interfaceId ||
            super.supportsInterface(interfaceId)
        );
    }
}
