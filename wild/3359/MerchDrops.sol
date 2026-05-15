// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * Merch VIP Pass – ERC721 NFT mintable per drop with ERC20 payment.
 * - Implements ERC721 Enumerable so wallets (e.g. MetaMask) can discover and list tokens.
 * - Owner sets drops (uri, maxSupply) and accepted payment tokens + cost per drop.
 * - mint(dropId, paymentToken, quantity): transfers (cost * quantity) of paymentToken from msg.sender to this contract, then mints quantity NFTs.
 * - burnForShipping: callable by BurnToEarn contract only; records order for owner to ship.
 */
contract MerchDrops {
    error DropNotConfigured();
    error ExceedsMaxSupply();
    error InsufficientPayment();
    error InvalidDropId();
    error InvalidQuantity();
    error InvalidReceiver();
    error InvalidOrderIndex();
    error NonexistentToken();
    error NotOwnerOrApproved();
    error NotTokenOwner();
    error OnlyOwner();
    error NotBurnToEarnContract();
    error TokenNotAccepted();
    error WrongFrom();

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event BurnToEarnContractSet(address indexed contract_);
    event OrderRecorded(uint256 indexed orderIndex, string shippingAddress, uint256 tokenId, uint256 quantity, string size);

    string public name;
    string public symbol;
    address public owner;
    address public burnToEarnContract;

    uint256 private _nextTokenId = 1;

    struct Drop {
        string uri;
        uint256 maxSupply;
        uint256 mintedCount;
    }
    mapping(uint256 => Drop) public drops;
    mapping(uint256 => string) public dropSizeOptions;
    mapping(uint256 => mapping(address => uint256)) public costForDropToken;
    mapping(uint256 => address[]) private _dropSpendingTokensList;
    mapping(uint256 => mapping(address => bool)) private _dropTokenSet;

    struct Order {
        string shippingAddress;
        uint256 tokenId;
        uint256 quantity;
        string size;
    }
    Order[] private _orders;
    mapping(uint256 => uint256) public tokenDropId;
    /// @dev What the minter specified at mint time (for fulfillment/shipping).
    mapping(uint256 => string) public tokenMintSize;
    mapping(uint256 => uint256) public tokenMintQuantity;

    mapping(uint256 => address) private _ownerOf;
    mapping(uint256 => address) private _getApproved;
    mapping(address => uint256) private _balanceOf;
    mapping(address => mapping(address => bool)) private _isApprovedForAll;

    uint256[] private _allTokens;
    mapping(uint256 => uint256) private _allTokensIndex;
    mapping(address => uint256[]) private _ownedTokens;
    mapping(uint256 => uint256) private _ownedTokensIndex;

    modifier onlyOwner() {
        if (msg.sender != owner) revert OnlyOwner();
        _;
    }

    modifier onlyBurnToEarn() {
        if (msg.sender != burnToEarnContract || burnToEarnContract == address(0)) revert NotBurnToEarnContract();
        _;
    }

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
        owner = msg.sender;
    }

    function setBurnToEarnContract(address _contract) external onlyOwner {
        burnToEarnContract = _contract;
        emit BurnToEarnContractSet(_contract);
    }

    function setDrop(uint256 dropId, string calldata uri, uint256 maxSupply) external onlyOwner {
        if (dropId == 0) revert InvalidDropId();
        drops[dropId] = Drop({ uri: uri, maxSupply: maxSupply, mintedCount: drops[dropId].mintedCount });
    }

    function setDropSizeOptions(uint256 dropId, string calldata sizes) external onlyOwner {
        dropSizeOptions[dropId] = sizes;
    }

    mapping(address => bool) private _tracked;

    function setDropSpendingToken(uint256 dropId, address erc20, uint256 cost) external onlyOwner {
        if (!_dropTokenSet[dropId][erc20] && erc20 != address(0)) {
            _dropSpendingTokensList[dropId].push(erc20);
            _dropTokenSet[dropId][erc20] = true;
            if (!_tracked[erc20]) {
                _trackedTokens.push(erc20);
                _tracked[erc20] = true;
            }
        }
        costForDropToken[dropId][erc20] = cost;
    }

    function getDropInfo(uint256 dropId) external view returns (string memory uri, uint256 maxSupply, uint256 mintedCount) {
        Drop storage d = drops[dropId];
        return (d.uri, d.maxSupply, d.mintedCount);
    }

    function getDropSizeOptions(uint256 dropId) external view returns (string memory) {
        return dropSizeOptions[dropId];
    }

    function getCostForDropToken(uint256 dropId, address erc20) external view returns (uint256) {
        return costForDropToken[dropId][erc20];
    }

    function getDropSpendingTokenList(uint256 dropId) external view returns (address[] memory) {
        return _dropSpendingTokensList[dropId];
    }

    function getTokenDropId(uint256 tokenId) external view returns (uint256) {
        return tokenDropId[tokenId];
    }

    /// @dev Transfers (cost * quantity) of paymentToken from msg.sender to this contract, then mints quantity NFTs. Records size and quantity per token for fulfillment.
    function mint(uint256 dropId, address paymentToken, uint256 quantity, string calldata size) external {
        if (dropId == 0) revert InvalidDropId();
        Drop storage d = drops[dropId];
        if (bytes(d.uri).length == 0 || d.maxSupply == 0) revert DropNotConfigured();
        if (quantity == 0 || quantity > 100) revert InvalidQuantity();

        uint256 cost = costForDropToken[dropId][paymentToken];
        if (cost == 0) revert TokenNotAccepted();
        uint256 totalCost = cost * quantity;
        if (totalCost == 0) revert InsufficientPayment();

        if (d.mintedCount + quantity > d.maxSupply) revert ExceedsMaxSupply();

        // Pull payment from user to this contract (transferFrom)
        (bool ok, bytes memory data) = paymentToken.call(
            abi.encodeWithSelector(
                0x23b872dd, // transferFrom(address,address,uint256)
                msg.sender,
                address(this),
                totalCost
            )
        );
        if (!ok) revert InsufficientPayment();
        if (data.length >= 32 && !abi.decode(data, (bool))) revert InsufficientPayment();

        for (uint256 i = 0; i < quantity; i++) {
            uint256 tokenId = _nextTokenId++;
            tokenDropId[tokenId] = dropId;
            tokenMintSize[tokenId] = size;
            tokenMintQuantity[tokenId] = quantity;
            d.mintedCount += 1;
            _mint(msg.sender, tokenId);
        }
    }

    function _mint(address to, uint256 tokenId) internal {
        if (to == address(0)) revert InvalidReceiver();
        if (_ownerOf[tokenId] != address(0)) revert WrongFrom();
        _ownerOf[tokenId] = to;
        _balanceOf[to] += 1;
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
        _ownedTokensIndex[tokenId] = _ownedTokens[to].length;
        _ownedTokens[to].push(tokenId);
        emit Transfer(address(0), to, tokenId);
    }

    function burnForShipping(uint256 tokenId, string calldata shippingAddress, uint256 quantity, string calldata size) external onlyBurnToEarn {
        _orders.push(Order({ shippingAddress: shippingAddress, tokenId: tokenId, quantity: quantity, size: size }));
        emit OrderRecorded(_orders.length - 1, shippingAddress, tokenId, quantity, size);
    }

    function getOrder(uint256 index) external view returns (string memory shippingAddress, uint256 tokenId, uint256 quantity, string memory size) {
        if (index >= _orders.length) revert InvalidOrderIndex();
        Order storage o = _orders[index];
        return (o.shippingAddress, o.tokenId, o.quantity, o.size);
    }

    function getOrderCount() external view returns (uint256) {
        return _orders.length;
    }

    function getRecentOrders(uint256 offset, uint256 limit) external view returns (
        string[] memory shippingAddresses,
        uint256[] memory tokenIds,
        uint256[] memory quantities,
        string[] memory sizes
    ) {
        uint256 n = _orders.length;
        if (offset >= n) {
            return (new string[](0), new uint256[](0), new uint256[](0), new string[](0));
        }
        uint256 end = offset + limit;
        if (end > n) end = n;
        uint256 len = end - offset;
        shippingAddresses = new string[](len);
        tokenIds = new uint256[](len);
        quantities = new uint256[](len);
        sizes = new string[](len);
        for (uint256 i = 0; i < len; i++) {
            Order storage o = _orders[offset + i];
            shippingAddresses[i] = o.shippingAddress;
            tokenIds[i] = o.tokenId;
            quantities[i] = o.quantity;
            sizes[i] = o.size;
        }
    }

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == 0x01ffc9a7   // IERC165
            || interfaceId == 0x80ac58cd   // IERC721
            || interfaceId == 0x5b5e139f   // IERC721Metadata
            || interfaceId == 0x780e9d63;  // IERC721Enumerable
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balanceOf[account];
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        address o = _ownerOf[tokenId];
        if (o == address(0)) revert NonexistentToken();
        return o;
    }

    /// @dev If drop uri ends with ".json", use it for every token (single metadata for whole drop). Else append tokenId.json to folder uri.
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        if (_ownerOf[tokenId] == address(0)) revert NonexistentToken();
        uint256 did = tokenDropId[tokenId];
        string memory base = drops[did].uri;
        if (bytes(base).length == 0) return "";
        uint256 len = bytes(base).length;
        if (len >= 5 && _endsWithJson(base)) {
            return base;
        }
        if (len > 0 && bytes(base)[len - 1] == "/") {
            return string(abi.encodePacked(base, _uint2str(tokenId), ".json"));
        }
        return string(abi.encodePacked(base, "/", _uint2str(tokenId), ".json"));
    }

    function _endsWithJson(string memory s) internal pure returns (bool) {
        bytes memory b = bytes(s);
        if (b.length < 5) return false;
        return b[b.length - 1] == "n" && b[b.length - 2] == "o" && b[b.length - 3] == "s" && b[b.length - 4] == "j" && b[b.length - 5] == ".";
    }

    function _uint2str(uint256 v) internal pure returns (string memory) {
        if (v == 0) return "0";
        uint256 j = v;
        uint256 len;
        while (j != 0) { len++; j /= 10; }
        bytes memory b = new bytes(len);
        while (v != 0) {
            len--;
            b[len] = bytes1(uint8(48 + v % 10));
            v /= 10;
        }
        return string(b);
    }

    function getApproved(uint256 tokenId) external view returns (address) {
        if (_ownerOf[tokenId] == address(0)) revert NonexistentToken();
        return _getApproved[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) external {
        _isApprovedForAll[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address account, address operator) external view returns (bool) {
        return _isApprovedForAll[account][operator];
    }

    function approve(address to, uint256 tokenId) external {
        address o = ownerOf(tokenId);
        if (to == o) revert InvalidReceiver();
        if (msg.sender != o && !_isApprovedForAll[o][msg.sender]) revert NotOwnerOrApproved();
        _getApproved[tokenId] = to;
        emit Approval(o, to, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) external {
        if (from != _ownerOf[tokenId]) revert WrongFrom();
        if (to == address(0)) revert InvalidReceiver();
        if (msg.sender != from && msg.sender != _getApproved[tokenId] && !_isApprovedForAll[from][msg.sender]) revert NotOwnerOrApproved();
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) external {
        safeTransferFrom(from, to, tokenId, bytes(""));
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public {
        if (from != _ownerOf[tokenId]) revert WrongFrom();
        if (to == address(0)) revert InvalidReceiver();
        if (msg.sender != from && msg.sender != _getApproved[tokenId] && !_isApprovedForAll[from][msg.sender]) revert NotOwnerOrApproved();
        _transfer(from, to, tokenId);
        if (to.code.length > 0) {
            bytes4 selector = 0x150b7a02; // onERC721Received(address,address,uint256,bytes)
            (bool ok, bytes memory ret) = to.call(abi.encodeWithSelector(selector, msg.sender, from, tokenId, data));
            if (!ok || ret.length < 4 || abi.decode(ret, (bytes4)) != selector) revert InvalidReceiver();
        }
    }

    function _transfer(address from, address to, uint256 tokenId) internal {
        _removeTokenFromOwnerEnumeration(from, tokenId);
        _addTokenToOwnerEnumeration(to, tokenId);
        _ownerOf[tokenId] = to;
        _balanceOf[from] -= 1;
        _balanceOf[to] += 1;
        _getApproved[tokenId] = address(0);
        emit Transfer(from, to, tokenId);
    }

    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        uint256 lastIndex = _ownedTokens[from].length - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];
        if (tokenIndex != lastIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastIndex];
            _ownedTokens[from][tokenIndex] = lastTokenId;
            _ownedTokensIndex[lastTokenId] = tokenIndex;
        }
        _ownedTokens[from].pop();
        delete _ownedTokensIndex[tokenId];
    }

    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        _ownedTokensIndex[tokenId] = _ownedTokens[to].length;
        _ownedTokens[to].push(tokenId);
    }

    function totalSupply() external view returns (uint256) {
        return _allTokens.length;
    }

    function tokenByIndex(uint256 index) external view returns (uint256) {
        if (index >= _allTokens.length) revert NonexistentToken();
        return _allTokens[index];
    }

    function tokenOfOwnerByIndex(address owner_, uint256 index) external view returns (uint256) {
        if (index >= _ownedTokens[owner_].length) revert NonexistentToken();
        return _ownedTokens[owner_][index];
    }

    function getSpendingTokenList() external view returns (address[] memory) {
        return _dropSpendingTokensList[1];
    }

    address[] private _trackedTokens;

    function withdrawERC20(address token, uint256 amount) external onlyOwner {
        (bool ok,) = token.call(abi.encodeWithSelector(0xa9059cbb, owner, amount));
        require(ok, "transfer failed");
    }

    function withdrawETH() external onlyOwner {
        (bool ok,) = owner.call{ value: address(this).balance }("");
        require(ok, "send failed");
    }

    function withdrawAllTokens(address[] calldata tokens) external onlyOwner {
        for (uint256 i = 0; i < tokens.length; i++) {
            address t = tokens[i];
            uint256 bal = _erc20Balance(t);
            if (bal > 0) {
                (bool ok,) = t.call(abi.encodeWithSelector(0xa9059cbb, owner, bal));
                require(ok, "transfer failed");
            }
        }
    }

    function withdrawAllTrackedTokens() external onlyOwner {
        for (uint256 i = 0; i < _trackedTokens.length; i++) {
            address t = _trackedTokens[i];
            uint256 bal = _erc20Balance(t);
            if (bal > 0) {
                (bool ok,) = t.call(abi.encodeWithSelector(0xa9059cbb, owner, bal));
                require(ok, "transfer failed");
            }
        }
    }

    function _erc20Balance(address token) internal view returns (uint256) {
        (bool ok, bytes memory data) = token.staticcall(abi.encodeWithSelector(0x70a08231, address(this)));
        if (!ok || data.length < 32) return 0;
        return abi.decode(data, (uint256));
    }

    receive() external payable {}
}