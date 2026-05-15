// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IRegularPunksRenderer {
    function tokenURI(uint256 tokenId, uint256 seed) external view returns (string memory);

    /// @notice Renderer hook to emit ERC4906 metadata refresh on the collection.
    function notifyTrainingChange(uint256 tokenId) external;

    /// @notice Return stored body art metadata (ptr, mime, bg color).
    function getBodyArt(uint8 bodyKey, bool hoodie, bool training)
        external
        view
        returns (address ptr, string memory mime, string memory bgColor);

    /// @notice Return stored body art bytes for cloning/migration.
    function getBodyBytes(uint8 bodyKey, bool hoodie, bool training)
        external
        view
        returns (bytes memory);
}

