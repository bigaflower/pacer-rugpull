// SPDX-License-Identifier: MIT

/*  Combined Fully Onchain Media Renderer
    for the ERC721 Forever Library contract on Ethereum Mainnet.

    Deployed on Ethereum Mainnet. Merges and extends the original
    FullyOnchainImageFLRenderer and FullyOnchainAudioFLRenderer
    into a single, media-agnostic contract.

    Supports any file type that can be served via a base64 data URI:
    - Image-only tokens (PNG, JPEG, SVG, GIF, WebP, etc.)
    - Audio tokens (MP3, WAV, OGG, FLAC, etc.)
    - Video tokens (MP4, WebM, etc.)
    - HTML/interactive tokens
    - Any other format supported by the animation_url metadata field

    Media type detection:
    - If animationFileName is empty → image-only metadata (no animation_url)
    - If animationFileName is set   → image + animation_url with the specified MIME type

    Changes from the original mainnet renderers:
    - Combined image and audio rendering into one media-agnostic contract
    - animation_url MIME type is configurable (no longer hardcoded to audio/mp3)
    - Media Type trait is artist-configurable for maximum flexibility
    - Updated IForeverLibrary interface to match the ERC721 MintData struct
    - Replaced ownerOf() checks with creator-based access control
    - Implements tokenURI() to satisfy the ERC721 IExternalRenderer interface
    - JSON-safe string escaping for titles, descriptions, and artist names
    - Descriptive error messages for better UX on block explorers
    - Updated Solidity version to ^0.8.24
    - Replaced hardcoded admin address with immutable ADMIN
*/

pragma solidity ^0.8.24;

import "./base64.sol";
import "./IFileStore.sol";
import "./LibString.sol";
import "./DateTime.sol";

interface IForeverLibrary {
    struct MintData {
        address creator;
        uint64 timestamp;
        uint64 blockNumber;
        bytes32 metadataHash;
        string tokenURI;
    }

    function getMintData(uint256 _tokenId) external view returns (MintData memory);
}

contract FullyOnchainFLRenderer {

    IFileStore public fileStore;
    IForeverLibrary public FL;

    address public immutable ADMIN;
    bool lockedAddress;

    constructor() {
        // EthFS FileStore — deterministic deployment address on Ethereum Mainnet
        fileStore = IFileStore(0xFe1411d6864592549AdE050215482e4385dFa0FB);
        ADMIN = msg.sender;
    }

    struct tokenDataStruct {
        address artistAddress;
        string artistName;
        string title;
        string animationFileName;   // EthFS filename for animation_url content (empty = image-only)
        string animationMimeType;   // Full MIME type, e.g. "audio/mp3", "video/mp4", "text/html"
        string imageFileName;       // EthFS filename for the cover/preview image
        string imageFileType;       // Image format for data URI, e.g. "png", "svg+xml", "jpeg"
        string mediaTypeTrait;      // Artist-defined trait, e.g. "Fully onchain audio", "Fully onchain video"
        string description;
        bool locked;
    }

    mapping(uint256 => tokenDataStruct) public tokenData;

    // =========================================================================
    //                          Admin: set FL address
    // =========================================================================

    function setForeverLibraryAddress(address _FL) public {
        require(msg.sender == ADMIN, "Only admin can set FL address");
        require(!lockedAddress, "FL address is permanently locked");
        require(_FL != address(0), "FL address cannot be zero");
        FL = IForeverLibrary(_FL);
        lockedAddress = true;
    }

    // =========================================================================
    //                          Access control
    // =========================================================================

    /// @dev Uses creator-based access control rather than ownerOf() so that
    ///      the original artist retains control over their renderer data
    ///      even if the token is transferred to a new owner.
    modifier onlyArtist(uint256 _tokenId) {
        require(address(FL) != address(0), "FL address not set");
        address creator = FL.getMintData(_tokenId).creator;
        require(creator != address(0), "Token does not exist");

        bool isFirstTimeSetup = tokenData[_tokenId].artistAddress == address(0);
        bool isExistingArtist = msg.sender == tokenData[_tokenId].artistAddress
            && tokenData[_tokenId].artistAddress != address(0);

        require(
            (msg.sender == creator && isFirstTimeSetup) || isExistingArtist,
            isFirstTimeSetup
                ? "Only the token creator can perform first-time setup"
                : "Only the registered artist can modify this token"
        );
        _;
    }

    // =========================================================================
    //                          Data management
    // =========================================================================

    /// @notice Set metadata for a token. Works for any media type.
    ///
    /// @param _tokenId            The token ID in the Forever Library contract
    /// @param _title              Display name of the work
    /// @param _artistName         Artist name shown in traits
    /// @param _animationFileName  EthFS filename for animation_url file (pass "" for image-only)
    /// @param _animationMimeType  Full MIME type for animation_url (e.g. "audio/mp3", "video/mp4")
    /// @param _imageFileName      EthFS filename for the cover/preview image
    /// @param _imageFileType      Image format for the data URI prefix (e.g. "png", "jpeg", "svg+xml")
    /// @param _mediaTypeTrait     Value for the "Media Type" trait (e.g. "Fully onchain audio")
    /// @param _description        Description shown in metadata
    function setData(
        uint256 _tokenId,
        string memory _title,
        string memory _artistName,
        string memory _animationFileName,
        string memory _animationMimeType,
        string memory _imageFileName,
        string memory _imageFileType,
        string memory _mediaTypeTrait,
        string memory _description
    ) public onlyArtist(_tokenId) {
        require(!tokenData[_tokenId].locked, "Token data is permanently locked");
        require(bytes(_imageFileName).length > 0, "Image filename is required");
        require(bytes(_imageFileType).length > 0, "Image file type is required");
        if (bytes(_animationFileName).length > 0) {
            require(bytes(_animationMimeType).length > 0, "Animation MIME type required when animation file is set");
        }

        tokenData[_tokenId].title             = _title;
        tokenData[_tokenId].artistName        = _artistName;
        tokenData[_tokenId].animationFileName = _animationFileName;
        tokenData[_tokenId].animationMimeType = _animationMimeType;
        tokenData[_tokenId].imageFileName     = _imageFileName;
        tokenData[_tokenId].imageFileType     = _imageFileType;
        tokenData[_tokenId].mediaTypeTrait    = _mediaTypeTrait;
        tokenData[_tokenId].description       = _description;
        tokenData[_tokenId].artistAddress     = msg.sender;
    }

    function lockData(uint256 _tokenId) public onlyArtist(_tokenId) {
        require(!tokenData[_tokenId].locked, "Token data is already locked");
        tokenData[_tokenId].locked = true;
    }

    // =========================================================================
    //                          Read helpers
    // =========================================================================

    /// @notice Returns true if this token has an animation file configured.
    function hasAnimation(uint256 _tokenId) public view returns (bool) {
        return bytes(tokenData[_tokenId].animationFileName).length > 0;
    }

    function getImage(uint256 _tokenId) public view returns (string memory) {
        string memory name = tokenData[_tokenId].imageFileName;
        require(bytes(name).length > 0, "No image file set for this token");
        return fileStore.getFile(name).read();
    }

    function getAnimation(uint256 _tokenId) public view returns (string memory) {
        string memory name = tokenData[_tokenId].animationFileName;
        require(bytes(name).length > 0, "No animation file set for this token");
        return fileStore.getFile(name).read();
    }

    // =========================================================================
    //                          JSON string escaping
    // =========================================================================

    /// @dev Escapes characters that would break JSON strings: \ " and control
    ///      characters (0x00–0x1F). Produces valid JSON per RFC 8259.
    function escapeJSON(string memory _input) internal pure returns (string memory) {
        bytes memory input = bytes(_input);
        if (input.length == 0) return _input;

        // Worst case: every character needs escaping (\uXXXX = 6 chars)
        // For typical strings, most chars pass through unchanged.
        bytes memory buffer = new bytes(input.length * 6);
        uint256 cursor;

        for (uint256 i = 0; i < input.length; i++) {
            bytes1 char = input[i];

            if (char == 0x22) {
                // Double quote → \"
                buffer[cursor++] = 0x5C; // backslash
                buffer[cursor++] = 0x22; // "
            } else if (char == 0x5C) {
                // Backslash → \\
                buffer[cursor++] = 0x5C;
                buffer[cursor++] = 0x5C;
            } else if (char == 0x0A) {
                // Newline → \n
                buffer[cursor++] = 0x5C;
                buffer[cursor++] = 0x6E; // n
            } else if (char == 0x0D) {
                // Carriage return → \r
                buffer[cursor++] = 0x5C;
                buffer[cursor++] = 0x72; // r
            } else if (char == 0x09) {
                // Tab → \t
                buffer[cursor++] = 0x5C;
                buffer[cursor++] = 0x74; // t
            } else if (uint8(char) < 0x20) {
                // Other control characters → \u00XX
                buffer[cursor++] = 0x5C; // backslash
                buffer[cursor++] = 0x75; // u
                buffer[cursor++] = 0x30; // 0
                buffer[cursor++] = 0x30; // 0
                uint8 val = uint8(char);
                buffer[cursor++] = _hexChar(val >> 4);
                buffer[cursor++] = _hexChar(val & 0x0F);
            } else {
                // Normal character — pass through
                buffer[cursor++] = char;
            }
        }

        // Trim buffer to actual length
        bytes memory result = new bytes(cursor);
        for (uint256 j = 0; j < cursor; j++) {
            result[j] = buffer[j];
        }
        return string(result);
    }

    /// @dev Returns the hex character for a nibble (0–15).
    function _hexChar(uint8 _nibble) internal pure returns (bytes1) {
        return _nibble < 10
            ? bytes1(_nibble + 0x30)        // '0'–'9'
            : bytes1(_nibble - 10 + 0x61);  // 'a'–'f'
    }

    // =========================================================================
    //                          Trait generation
    // =========================================================================

    function generateTraits(uint256 _tokenId) public view returns (string memory) {
        string memory artistName = escapeJSON(tokenData[_tokenId].artistName);

        IForeverLibrary.MintData memory mintData = FL.getMintData(_tokenId);
        (uint256 year, uint256 month, uint256 day) = DateTime.timestampToDate(mintData.timestamp);

        address artistAddress = mintData.creator;

        // Use artist-defined media type trait, falling back to a default
        string memory mediaType = bytes(tokenData[_tokenId].mediaTypeTrait).length > 0
            ? escapeJSON(tokenData[_tokenId].mediaTypeTrait)
            : "Fully onchain image";

        string memory traits = string(
            abi.encodePacked(
                '{"trait_type": "Artist", "value": "',
                artistName,
                '"}, ',
                '{"trait_type": "Media Type", "value": "',
                mediaType,
                '"},',
                '{"trait_type": "Creation Date", "value": "',
                LibString.toString(year), '-', LibString.toString(month), '-', LibString.toString(day),
                '"},',
                '{"trait_type": "Creator", "value": "',
                LibString.toHexStringChecksummed(artistAddress),
                '"}'
            )
        );
        return traits;
    }

    // =========================================================================
    //                          Metadata (ERC721 tokenURI)
    // =========================================================================

    /// @notice Generates the full on-chain JSON metadata.
    ///         Automatically includes animation_url when an animation file is set.
    ///         Implements the IExternalRenderer interface expected by the ERC721 FL contract.
    function tokenURI(uint256 _tokenId) public view returns (string memory) {
        string memory title = escapeJSON(tokenData[_tokenId].title);
        string memory description = escapeJSON(tokenData[_tokenId].description);

        string memory imgPrefix = string.concat(
            "data:image/", tokenData[_tokenId].imageFileType, ";base64,"
        );

        bytes memory json;

        if (hasAnimation(_tokenId)) {
            // Build the animation data URI from the stored MIME type
            // e.g. "data:audio/mp3;base64,", "data:video/mp4;base64,", "data:text/html;base64,"
            string memory animPrefix = string.concat(
                "data:", tokenData[_tokenId].animationMimeType, ";base64,"
            );

            json = abi.encodePacked(
                '{"name":"', title,
                '","image": "', imgPrefix, getImage(_tokenId),
                '","animation_url":"', animPrefix, getAnimation(_tokenId),
                '","description":"', description,
                '","attributes": [', generateTraits(_tokenId), ']}'
            );
        } else {
            // Image-only: no animation_url
            json = abi.encodePacked(
                '{"name":"', title,
                '","image": "', imgPrefix, getImage(_tokenId),
                '","description":"', description,
                '","attributes": [', generateTraits(_tokenId), ']}'
            );
        }

        return string(
            abi.encodePacked("data:application/json;base64,", Base64.encode(json))
        );
    }
}
