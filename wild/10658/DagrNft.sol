// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DAGRNft is ERC721A, Ownable {
    mapping(address => bool) public isWhitelisted;
    string private baseTokenURI;

    // ---- owner enumeration index (O(balance) reads) ----
    mapping(address => uint256[]) private _ownedTokens;
    mapping(uint256 => uint256) private _ownedTokensIndex; // tokenId => index in owner's array

    constructor() ERC721A("DAGrow PASS", "DAGrowPASS") Ownable(msg.sender) {}

    function addToWhitelist(address user) external onlyOwner {
        isWhitelisted[user] = true;
    }

    function removeFromWhitelist(address user) external onlyOwner {
        isWhitelisted[user] = false;
    }

    function mintTo(address to, uint256 quantity) external returns (uint256) {
        require(isWhitelisted[msg.sender], "Not whitelisted");
        uint256 startTokenId = _nextTokenId();
        _mint(to, quantity);
        return startTokenId;
    }

    // ---------- READ: get all IDs owned by an address (O(balance)) ----------
    function tokensOfOwner(address owner) external view returns (uint256[] memory) {
        uint256 len = _ownedTokens[owner].length;
        uint256[] memory result = new uint256[](len);
        for (uint256 i = 0; i < len; i++) {
            result[i] = _ownedTokens[owner][i];
        }
        return result;
    }

    // ---------- INTERNAL: keep owner index in sync ----------
  function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override {
        // call base implementation first (defensive)
        super._afterTokenTransfers(from, to, startTokenId, quantity);

        // Update enumeration for each token moved/minted/burned
        for (uint256 i = 0; i < quantity; i++) {
            uint256 tokenId = startTokenId + i;

            if (from != address(0)) {
                _removeTokenFromOwnerEnumeration(from, tokenId);
            }
            if (to != address(0)) {
                _addTokenToOwnerEnumeration(to, tokenId);
            } else {
                // burn path: clear index for safety
                delete _ownedTokensIndex[tokenId];
            }
        }
    }

    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        _ownedTokensIndex[tokenId] = _ownedTokens[to].length;
        _ownedTokens[to].push(tokenId);
    }

    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        uint256 length = _ownedTokens[from].length;
        if (length == 0) {
            return; // defensive: nothing to remove
        }
        uint256 lastIndex = length - 1;
        uint256 index = _ownedTokensIndex[tokenId];

        if (index != lastIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastIndex];
            _ownedTokens[from][index] = lastTokenId;
            _ownedTokensIndex[lastTokenId] = index;
        }
        _ownedTokens[from].pop();

        // CLEAR the index for the removed token to avoid stale entries
        delete _ownedTokensIndex[tokenId];
    }

   
    // ---------- URI ----------
    function setBaseURI(string memory uri) external onlyOwner {
        baseTokenURI = uri;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json"))
            : "";
    }
}
