// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <brecht@loopring.org>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        uint256 encodedLen = 4 * ((len + 2) / 3);
        bytes memory result = new bytes(encodedLen + 32);
        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for { let i := 0 } lt(i, len) { } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)
                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}

interface IERC721Gate {
    function ownerOf(uint256 tokenId) external view returns (address);
}

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) return "0";
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) { digits++; temp /= 10; }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) return "0x00";
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) { length++; temp >>= 8; }
        return toHexString(value, length);
    }

    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) { return msg.sender; }
    function _msgData() internal view virtual returns (bytes calldata) { return msg.data; }
}

abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() { _transferOwnership(_msgSender()); }

    modifier onlyOwner() { _checkOwner(); _; }

    function owner() public view virtual returns (address) { return _owner; }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner { _transferOwnership(address(0)); }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    constructor() { _status = _NOT_ENTERED; }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    function transferFrom(address from, address to, uint256 tokenId) external;

    function approve(address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool _approved) external;

    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    string private _name;
    string private _symbol;

    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    function name() public view virtual override returns (string memory) { return _name; }
    function symbol() public view virtual override returns (string memory) { return _symbol; }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    function _baseURI() internal view virtual returns (string memory) { return ""; }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    function _safeMint(address to, uint256 tokenId, bytes memory data) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data)
        private returns (bool)
    {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly { revert(add(32, reason), mload(reason)) }
                }
            }
        } else {
            return true;
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual {}
    function _afterTokenTransfer(address from, address to, uint256 tokenId) internal virtual {}
}

interface IERC721Enumerable is IERC721 {
    function totalSupply() external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
    function tokenByIndex(uint256 index) external view returns (uint256);
}

abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;
    mapping(uint256 => uint256) private _ownedTokensIndex;
    uint256[] private _allTokens;
    mapping(uint256 => uint256) private _allTokensIndex;

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];
            _ownedTokens[from][tokenIndex] = lastTokenId;
            _ownedTokensIndex[lastTokenId] = tokenIndex;
        }

        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        uint256 lastTokenId = _allTokens[lastTokenIndex];
        _allTokens[tokenIndex] = lastTokenId;
        _allTokensIndex[lastTokenId] = tokenIndex;

        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

abstract contract Pausable is Context {
    event Paused(address account);
    event Unpaused(address account);

    bool private _paused;

    constructor() { _paused = false; }

    function paused() public view virtual returns (bool) { return _paused; }

    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

contract EthertowerPreICOPositions is ERC721Enumerable, ReentrancyGuard, Pausable, Ownable {
    uint256 public price = 20000000000000000; // 0.02 ETH
    uint256 public constant supplyCap = 999;

    address public gateNft;

    constructor(address gateNft_) ERC721("Ethertower Pre-ICO Positions", "ETHTW-PRE-ICO-POS") {
        gateNft = gateNft_;
    }

    function setGateNft(address gateNft_) external onlyOwner {
        gateNft = gateNft_;
    }

    function tokenURI(uint256 tokenId) public pure override returns (string memory) {
        string memory svgOutput;
        svgOutput = '<svg width="1843" height="1843" viewBox="0 0 1843 1843" fill="none" xmlns="http://www.w3.org/2000/svg"><rect width="1844" height="1844" transform="matrix(1 0 0 -1 -0.164062 1843.41)" fill="#F9F9F9"/><g width="417" height="100" viewBox="0 0 417 100" fill="none" xmlns="http://www.w3.org/2000/svg" transform="translate(118 118) scale(1.2)"><rect x="5.60547" y="6.4906" width="8" height="88" fill="#871F23"/><rect x="21.6055" y="22.4906" width="8" height="72" fill="#871F23"/><rect x="37.6055" y="38.4906" width="8" height="40" fill="#871F23"/><rect x="85.6055" y="6.4906" width="8" height="88" fill="#871F23"/><rect x="69.6055" y="22.4906" width="8" height="56" fill="#871F23"/><rect x="53.6055" y="38.4906" width="8" height="24" fill="#871F23"/><rect x="93.6055" y="6.4906" width="8" height="88" transform="rotate(90 93.6055 6.4906)" fill="#871F23"/><rect x="77.6055" y="22.4906" width="8" height="56" transform="rotate(90 77.6055 22.4906)" fill="#871F23"/><rect x="61.6055" y="38.4906" width="8" height="24" transform="rotate(90 61.6055 38.4906)" fill="#871F23"/><rect x="93.6055" y="86.4906" width="8" height="72" transform="rotate(90 93.6055 86.4906)" fill="#871F23"/><rect x="77.6055" y="70.4906" width="8" height="40" transform="rotate(90 77.6055 70.4906)" fill="#871F23"/><path d="M123.488 79.9906V20.3542H162.275V29.4103H134.291V45.6007H160.265V54.6568H134.291V70.9345H162.507V79.9906H123.488ZM180.911 20.3542V79.9906H170.37V20.3542H180.911ZM209.092 80.8642C204.608 80.8642 200.735 79.9324 197.474 78.0687C194.232 76.1857 191.737 73.5261 189.99 70.09C188.243 66.6345 187.369 62.5675 187.369 57.889C187.369 53.2882 188.243 49.2503 189.99 45.7754C191.757 42.2811 194.222 39.5633 197.386 37.622C200.551 35.6613 204.268 34.6809 208.539 34.6809C211.296 34.6809 213.897 35.1274 216.343 36.0204C218.808 36.894 220.983 38.2529 222.866 40.0971C224.768 41.9414 226.263 44.2903 227.35 47.144C228.437 49.9783 228.981 53.3561 228.981 57.2775V60.5098H192.32V53.4047H218.876C218.857 51.3857 218.42 49.59 217.566 48.0176C216.712 46.4257 215.518 45.1736 213.984 44.2612C212.47 43.3488 210.704 42.8926 208.685 42.8926C206.53 42.8926 204.637 43.4167 203.006 44.465C201.376 45.4939 200.104 46.8528 199.192 48.5417C198.299 50.2112 197.842 52.0458 197.823 54.0453V60.2477C197.823 62.849 198.299 65.0815 199.25 66.9451C200.201 68.7894 201.531 70.2065 203.239 71.1966C204.948 72.1672 206.947 72.6525 209.238 72.6525C210.771 72.6525 212.159 72.439 213.402 72.0119C214.644 71.5654 215.722 70.9151 216.634 70.0609C217.547 69.2067 218.236 68.1487 218.702 66.8869L228.544 67.9934C227.923 70.5948 226.739 72.8661 224.991 74.8074C223.264 76.7292 221.051 78.224 218.352 79.2917C215.654 80.34 212.567 80.8642 209.092 80.8642ZM274.109 35.2633L258.181 79.9906H246.533L230.605 35.2633H241.845L252.124 68.4885H252.59L262.898 35.2633H274.109ZM290.533 80.8933C287.699 80.8933 285.146 80.3886 282.874 79.3791C280.623 78.3502 278.837 76.836 277.517 74.8365C276.216 72.837 275.566 70.3715 275.566 67.4402C275.566 64.9165 276.031 62.8296 276.963 61.1795C277.895 59.5294 279.167 58.2094 280.778 57.2193C282.389 56.2292 284.204 55.4818 286.223 54.9771C288.262 54.453 290.368 54.0744 292.542 53.8415C295.163 53.5697 297.289 53.327 298.919 53.1135C300.55 52.8805 301.734 52.5311 302.472 52.0652C303.229 51.5799 303.607 50.8325 303.607 49.823V49.6483C303.607 47.4546 302.957 45.756 301.656 44.5524C300.356 43.3488 298.482 42.747 296.036 42.747C293.455 42.747 291.406 43.31 289.892 44.4359C288.397 45.5619 287.388 46.8916 286.864 48.4253L277.022 47.0275C277.798 44.3097 279.079 42.0384 280.865 40.2136C282.651 38.3694 284.835 36.9911 287.417 36.0787C289.999 35.1469 292.853 34.6809 295.978 34.6809C298.133 34.6809 300.278 34.9333 302.414 35.438C304.549 35.9428 306.5 36.7775 308.267 37.9423C310.033 39.0877 311.45 40.6504 312.518 42.6305C313.605 44.6106 314.149 47.0858 314.149 50.0559V79.9906H304.015V73.8464H303.666C303.025 75.0888 302.122 76.2536 300.958 77.3407C299.812 78.4085 298.366 79.2723 296.619 79.9324C294.891 80.573 292.862 80.8933 290.533 80.8933ZM293.27 73.1476C295.386 73.1476 297.221 72.7302 298.774 71.8954C300.327 71.0413 301.521 69.9153 302.355 68.5176C303.209 67.1199 303.637 65.596 303.637 63.9459V58.6753C303.307 58.947 302.744 59.1994 301.948 59.4324C301.171 59.6653 300.298 59.8692 299.327 60.0439C298.356 60.2186 297.395 60.3739 296.444 60.5098C295.493 60.6457 294.668 60.7621 293.969 60.8592C292.397 61.0727 290.989 61.4222 289.747 61.9075C288.504 62.3928 287.524 63.0723 286.806 63.9459C286.087 64.8 285.728 65.9066 285.728 67.2655C285.728 69.2067 286.437 70.6724 287.854 71.6625C289.271 72.6525 291.076 73.1476 293.27 73.1476ZM338.886 80.7768C335.372 80.7768 332.227 79.8741 329.451 78.0687C326.675 76.2633 324.482 73.6426 322.87 70.2065C321.259 66.7704 320.454 62.5967 320.454 57.6852C320.454 52.7155 321.269 48.5223 322.9 45.1057C324.55 41.6696 326.772 39.078 329.568 37.3308C332.363 35.5642 335.479 34.6809 338.915 34.6809C341.536 34.6809 343.691 35.1274 345.38 36.0204C347.069 36.894 348.408 37.952 349.398 39.1944C350.388 40.4174 351.155 41.5725 351.699 42.6596H352.135V20.3542H362.706V79.9906H352.339V72.9437H351.699C351.155 74.0308 350.369 75.1859 349.34 76.4089C348.311 77.6125 346.952 78.6414 345.263 79.4956C343.574 80.3497 341.449 80.7768 338.886 80.7768ZM341.827 72.1284C344.06 72.1284 345.962 71.5266 347.535 70.323C349.107 69.1 350.301 67.4013 351.116 65.2271C351.932 63.0529 352.339 60.5195 352.339 57.627C352.339 54.7344 351.932 52.2205 351.116 50.0851C350.32 47.9496 349.136 46.2898 347.564 45.1057C346.011 43.9215 344.098 43.3294 341.827 43.3294C339.478 43.3294 337.517 43.9409 335.945 45.1639C334.373 46.3869 333.188 48.0758 332.392 50.2307C331.597 52.3855 331.199 54.8509 331.199 57.627C331.199 60.4224 331.597 62.917 332.392 65.1106C333.208 67.2849 334.402 69.0029 335.974 70.2647C337.566 71.5072 339.517 72.1284 341.827 72.1284ZM390.988 80.8642C386.621 80.8642 382.835 79.9032 379.632 77.9814C376.429 76.0595 373.944 73.3708 372.177 69.9153C370.43 66.4598 369.557 62.4219 369.557 57.8017C369.557 53.1814 370.43 49.1338 372.177 45.6589C373.944 42.184 376.429 39.4856 379.632 37.5638C382.835 35.6419 386.621 34.6809 390.988 34.6809C395.356 34.6809 399.142 35.6419 402.345 37.5638C405.548 39.4856 408.023 42.184 409.77 45.6589C411.537 49.1338 412.42 53.1814 412.42 57.8017C412.42 62.4219 411.537 66.4598 409.77 69.9153C408.023 73.3708 405.548 76.0595 402.345 77.9814C399.142 79.9032 395.356 80.8642 390.988 80.8642ZM391.047 72.4196C393.415 72.4196 395.395 71.7692 396.987 70.4686C398.579 69.1485 399.763 67.3819 400.54 65.1689C401.335 62.9558 401.733 60.4904 401.733 57.7726C401.733 55.0353 401.335 52.5602 400.54 50.3471C399.763 48.1147 398.579 46.3384 396.987 45.0183C395.395 43.6982 393.415 43.0382 391.047 43.0382C388.62 43.0382 386.601 43.6982 384.99 45.0183C383.398 46.3384 382.204 48.1147 381.408 50.3471C380.632 52.5602 380.243 55.0353 380.243 57.7726C380.243 60.4904 380.632 62.9558 381.408 65.1689C382.204 67.3819 383.398 69.1485 384.99 70.4686C386.601 71.7692 388.62 72.4196 391.047 72.4196Z" fill="black"/></g><g width="417" height="100" viewBox="0 0 417 100" fill="none" xmlns="http://www.w3.org/2000/svg" transform="translate(1415 1415) scale(0.5)"><circle cx="311.615" cy="311.794" r="310" fill="white"/><path d="M311.571 51.8645L478.115 329.813H145.026L284.224 234.098L311.571 51.8645Z" fill="#7E7E7E"/><path d="M311.303 407.916L477.812 329.825H145.026L311.303 407.916Z" fill="black"/><path d="M478.125 329.688L311.303 407.74V566.428L478.125 329.688Z" fill="#771D20"/><path d="M145 329.812L311.303 407.576V566.208L145 329.812Z" fill="#FF2931"/><path d="M311.615 51.8645V253.177L145.115 329.74L311.615 51.8645Z" fill="#DADADA"/><path d="M311.615 51.8645V253.177L478.115 329.74L311.615 51.8645Z" fill="#565656"/></g><g width="417" height="100" viewBox="0 0 417 100" fill="none" xmlns="http://www.w3.org/2000/svg" transform="translate(125 1405) scale(0.044)"><rect width="7297.04" height="7297.04" fill="white"/><path d="M320.146 4375.52V2920.97H1266.17V3141.85H583.64V3536.74H1217.16V3757.62H583.64V4154.64H1271.85V4375.52H320.146ZM7014.71 3648.25C7014.71 3804.97 6985.35 3939.2 6926.64 4050.95C6868.4 4162.21 6788.85 4247.44 6688 4306.63C6587.62 4365.81 6473.75 4395.41 6346.38 4395.41C6219.01 4395.41 6104.9 4365.81 6004.05 4306.63C5903.67 4246.97 5824.13 4161.5 5765.42 4050.24C5707.18 3938.49 5678.06 3804.5 5678.06 3648.25C5678.06 3491.52 5707.18 3357.53 5765.42 3246.26C5824.13 3134.52 5903.67 3049.05 6004.05 2989.87C6104.9 2930.68 6219.01 2901.09 6346.38 2901.09C6473.75 2901.09 6587.62 2930.68 6688 2989.87C6788.85 3049.05 6868.4 3134.52 6926.64 3246.26C6985.35 3357.53 7014.71 3491.52 7014.71 3648.25ZM6749.79 3648.25C6749.79 3537.92 6732.51 3444.89 6697.94 3369.13C6663.85 3292.9 6616.5 3235.37 6555.9 3196.54C6495.29 3157.24 6425.45 3137.59 6346.38 3137.59C6267.31 3137.59 6197.47 3157.24 6136.86 3196.54C6076.26 3235.37 6028.67 3292.9 5994.11 3369.13C5960.02 3444.89 5942.97 3537.92 5942.97 3648.25C5942.97 3758.57 5960.02 3851.85 5994.11 3928.08C6028.67 4003.83 6076.26 4061.36 6136.86 4100.66C6197.47 4139.49 6267.31 4158.9 6346.38 4158.9C6425.45 4158.9 6495.29 4139.49 6555.9 4100.66C6616.5 4061.36 6663.85 4003.83 6697.94 3928.08C6732.51 3851.85 6749.79 3758.57 6749.79 3648.25Z" fill="black"/></g></svg>';

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Ethertower Pre-ICO Position #',
                        toString(tokenId),
                        '", "description": "", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(svgOutput)),
                        '"}'
                    )
                )
            )
        );

        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    function claim(uint256 tokenId) public payable nonReentrant {
        require(tokenId > 0 && tokenId <= supplyCap, "Token ID invalid");
        require(price <= msg.value, "Ether value sent is not correct");
        require(!paused(), "Pausable: paused");
        require(!_exists(tokenId), "Already minted");

        address g = gateNft;
        require(g != address(0), "Gate not set");
        require(IERC721Gate(g).ownerOf(tokenId) == _msgSender(), "Not owner of gate tokenId");

        _safeMint(_msgSender(), tokenId);
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function pause(bool val) public onlyOwner {
        if (val) { _pause(); }
        else { _unpause(); }
    }

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) return "0";
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) { digits++; temp /= 10; }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}