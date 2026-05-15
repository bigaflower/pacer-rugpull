// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * Merch VIP Pass: Mints NFTs as VIP passes for merchandise drops.
 *
 * Each mint portal (drop) works independently:
 * - Owner sets each drop: URI (base/metadata for that portal), max supply.
 * - Owner sets each drop's own spend tokens: setDropSpendingToken(dropId, erc20, cost) — cost per NFT in that token.
 * - Users mint from a drop by paying with one of that drop's allowed ERC20s at that drop's cost.
 * - Burns work like other ERC721s: owner or approved operator (e.g. Burn-to-Earn contract) can call burnForShipping. Owner can set the connected Burn-to-Earn contract via setBurnToEarnContract for reference/integration.
 */
contract MerchVIPPass {
    address public owner;
    /// @dev Burn-to-Earn contract address (set by owner). Used to connect Merch with Burn-to-Earn; readable by frontends/other contracts.
    address public burnToEarnContract;

    // --- ERC721 state ---
    string public name;
    string public symbol;
    uint256 private _nextTokenId;
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // --- Drops (Merch Drop 1 through 20) ---
    uint256 public constant MAX_DROPS = 20;
    struct Drop {
        string uri;
        uint256 maxSupply;
        uint256 mintedCount;
    }
    mapping(uint256 => Drop) public drops; // dropId 1..20
    mapping(uint256 => uint256) private _tokenIdToDropId; // which drop a token belongs to
    mapping(uint256 => string) private _dropSizeOptions; // dropId => comma-separated sizes (e.g. S,M,L,XL), empty = none

    // --- Per-drop spending tokens: dropId => erc20 => cost (in that token's smallest unit) ---
    mapping(uint256 => mapping(address => uint256)) private _costForDropToken; // dropId => erc20 => cost, 0 = not accepted
    mapping(uint256 => address[]) private _dropSpendingTokenList; // dropId => list of tokens for this drop
    mapping(uint256 => mapping(address => bool)) private _isInDropSpendingList; // dropId => erc20 => in list
    address[] private _spendingTokenList; // global list for withdrawAllTrackedTokens
    mapping(address => bool) private _isInSpendingList;

    // --- Burn + shipping: private, only-owner view ---
    struct Order {
        address shippingAddress;
        uint256 tokenId;
        uint256 quantity;
        string size;
    }
    Order[] private _orders;

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event DropSet(uint256 indexed dropId, string uri, uint256 maxSupply);
    event DropSizeOptionsSet(uint256 indexed dropId, string sizes);
    event DropSpendingTokenSet(uint256 indexed dropId, address indexed token, uint256 cost);
    event Minted(address indexed to, uint256 indexed dropId, uint256 tokenId, address paymentToken, uint256 cost);
    event BurnedForShipping(address indexed from, uint256 indexed tokenId, address shippingAddress);
    event WithdrewETH(address indexed to, uint256 amount);
    event WithdrewERC20(address indexed token, address indexed to, uint256 amount);
    event BurnToEarnContractSet(address indexed contract_);

    error OnlyOwner();
    error InvalidDropId();
    error InvalidQuantity();
    error DropNotConfigured();
    error ExceedsMaxSupply();
    error TokenNotAccepted();
    error InsufficientPayment();
    error NotTokenOwner();
    error NotOwnerOrApproved();
    error InvalidReceiver();
    error WrongFrom();
    error NonexistentToken();

    modifier onlyOwner() {
        if (msg.sender != owner) revert OnlyOwner();
        _;
    }

    constructor(string memory _name, string memory _symbol) {
        owner = msg.sender;
        name = _name;
        symbol = _symbol;
        _nextTokenId = 1;
    }

    // ---------- Owner: per-drop spending tokens ----------
    /// @dev Set or update the cost for an ERC20 on a specific drop. Cost in that token's smallest unit per NFT.
    function setDropSpendingToken(uint256 dropId, address erc20, uint256 cost) external onlyOwner {
        if (dropId == 0 || dropId > MAX_DROPS) revert InvalidDropId();
        _costForDropToken[dropId][erc20] = cost;
        if (cost > 0 && !_isInDropSpendingList[dropId][erc20]) {
            _dropSpendingTokenList[dropId].push(erc20);
            _isInDropSpendingList[dropId][erc20] = true;
        }
        if (cost > 0 && !_isInSpendingList[erc20]) {
            _spendingTokenList.push(erc20);
            _isInSpendingList[erc20] = true;
        }
        emit DropSpendingTokenSet(dropId, erc20, cost);
    }

    /// @dev View: get cost for a specific ERC20 on a drop (0 = not accepted for that drop).
    function getCostForDropToken(uint256 dropId, address erc20) external view returns (uint256) {
        return _costForDropToken[dropId][erc20];
    }

    /// @dev View: list of spending token addresses configured for a drop.
    function getDropSpendingTokenList(uint256 dropId) external view returns (address[] memory) {
        return _dropSpendingTokenList[dropId];
    }

    /// @dev View: all tokens ever used (for withdrawAllTrackedTokens).
    function getSpendingTokenList() external view returns (address[] memory) {
        return _spendingTokenList;
    }

    // ---------- Owner: drops (Merch Drop 1..20) ----------
    /// @dev Set or update a drop. dropId 1..20.
    function setDrop(uint256 dropId, string calldata uri, uint256 maxSupply) external onlyOwner {
        if (dropId == 0 || dropId > MAX_DROPS) revert InvalidDropId();
        drops[dropId] = Drop({ uri: uri, maxSupply: maxSupply, mintedCount: drops[dropId].mintedCount });
        emit DropSet(dropId, uri, maxSupply);
    }

    /// @dev Set size options for a drop. Pass comma-separated values (e.g. "S,M,L,XL"). Empty string = no size options for that drop; mint portal will not show size.
    function setDropSizeOptions(uint256 dropId, string calldata sizes) external onlyOwner {
        if (dropId == 0 || dropId > MAX_DROPS) revert InvalidDropId();
        _dropSizeOptions[dropId] = sizes;
        emit DropSizeOptionsSet(dropId, sizes);
    }

    /// @dev View: size options for a drop (comma-separated string; empty = none).
    function getDropSizeOptions(uint256 dropId) external view returns (string memory) {
        return _dropSizeOptions[dropId];
    }

    /// @dev Set the Burn-to-Earn contract address this Merch contract connects with. For integration/reference; burns still use standard approval (owner or approved can call burnForShipping).
    function setBurnToEarnContract(address _contract) external onlyOwner {
        burnToEarnContract = _contract;
        emit BurnToEarnContractSet(_contract);
    }

    // ---------- Owner: withdraw ----------
    /// @dev Withdraw any ETH sent to this contract to the owner.
    function withdrawETH() external onlyOwner {
        uint256 balance = address(this).balance;
        if (balance == 0) return;
        (bool ok,) = owner.call{ value: balance }("");
        if (!ok) revert();
        emit WithdrewETH(owner, balance);
    }

    /// @dev Withdraw ERC20 tokens held by this contract to the owner.
    function withdrawERC20(address token, uint256 amount) external onlyOwner {
        if (amount == 0) return;
        IERC20(token).transfer(owner, amount);
        emit WithdrewERC20(token, owner, amount);
    }

    /// @dev Withdraw full balance of each tracked spending token to the owner (no args needed).
    function withdrawAllTrackedTokens() external onlyOwner {
        for (uint256 i = 0; i < _spendingTokenList.length; i++) {
            address token = _spendingTokenList[i];
            uint256 balance = IERC20(token).balanceOf(address(this));
            if (balance > 0) {
                IERC20(token).transfer(owner, balance);
                emit WithdrewERC20(token, owner, balance);
            }
        }
    }

    /// @dev Withdraw full balance of each listed ERC20 to the owner. Pass in token addresses to sweep (e.g. [QUINE, USDC]).
    function withdrawAllTokens(address[] calldata tokens) external onlyOwner {
        for (uint256 i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            uint256 balance = IERC20(token).balanceOf(address(this));
            if (balance > 0) {
                IERC20(token).transfer(owner, balance);
                emit WithdrewERC20(token, owner, balance);
            }
        }
    }

    // ---------- User: mint VIP pass (pay with ERC20) ----------
    uint256 public constant MAX_MINT_PER_TX = 5;

    /// @dev Mint quantity (1 to 5) NFTs from the given drop, paying cost * quantity in the specified ERC20.
    function mint(uint256 dropId, address paymentToken, uint256 quantity) external {
        if (dropId == 0 || dropId > MAX_DROPS) revert InvalidDropId();
        if (quantity == 0 || quantity > MAX_MINT_PER_TX) revert InvalidQuantity();
        Drop storage d = drops[dropId];
        if (bytes(d.uri).length == 0) revert DropNotConfigured();
        if (d.mintedCount + quantity > d.maxSupply) revert ExceedsMaxSupply();

        uint256 costPerOne = _costForDropToken[dropId][paymentToken];
        if (costPerOne == 0) revert TokenNotAccepted();
        uint256 totalCost = costPerOne * quantity;

        IERC20(paymentToken).transferFrom(msg.sender, owner, totalCost);

        for (uint256 i = 0; i < quantity; i++) {
            uint256 tokenId = _nextTokenId++;
            _tokenIdToDropId[tokenId] = dropId;
            d.mintedCount++;
            _mint(msg.sender, tokenId);
            emit Minted(msg.sender, dropId, tokenId, paymentToken, costPerOne);
        }
    }

    // ---------- Burn (owner or approved operator, same as other ERC721s) ----------
    /// @dev Burn a VIP pass and record shipping and size. Callable by token owner or approved address (e.g. Burn-to-Earn). Chosen size is stored in Order; owner reads via getOrder/getRecentOrders.
    function burnForShipping(uint256 tokenId, address shippingAddress, uint256 quantity, string calldata size) external {
        address tokenOwner = ownerOf(tokenId);
        if (tokenOwner != msg.sender && getApproved(tokenId) != msg.sender && !isApprovedForAll(tokenOwner, msg.sender)) revert NotOwnerOrApproved();
        if (quantity == 0) quantity = 1;
        _orders.push(Order({ shippingAddress: shippingAddress, tokenId: tokenId, quantity: quantity, size: size }));
        emit BurnedForShipping(tokenOwner, tokenId, shippingAddress);
        _burn(tokenId);
    }

    // ---------- Owner: view recent orders (addresses NOT public) ----------
    function getOrderCount() external view onlyOwner returns (uint256) {
        return _orders.length;
    }

    /// @dev Get order by index. Only callable by owner. Returns shippingAddress, tokenId, quantity, size.
    function getOrder(uint256 index) external view onlyOwner returns (address shippingAddress, uint256 tokenId, uint256 quantity, string memory size) {
        Order storage o = _orders[index];
        return (o.shippingAddress, o.tokenId, o.quantity, o.size);
    }

    /// @dev Get a slice of recent orders (e.g. last N). Only owner. Returns addresses, tokenIds, quantities, sizes.
    function getRecentOrders(uint256 offset, uint256 limit) external view onlyOwner returns (address[] memory addresses, uint256[] memory tokenIds, uint256[] memory quantities, string[] memory sizes) {
        uint256 n = _orders.length;
        if (offset >= n) {
            return (new address[](0), new uint256[](0), new uint256[](0), new string[](0));
        }
        uint256 end = offset + limit;
        if (end > n) end = n;
        uint256 len = end - offset;
        addresses = new address[](len);
        tokenIds = new uint256[](len);
        quantities = new uint256[](len);
        sizes = new string[](len);
        for (uint256 i = 0; i < len; i++) {
            Order storage o = _orders[offset + i];
            addresses[i] = o.shippingAddress;
            tokenIds[i] = o.tokenId;
            quantities[i] = o.quantity;
            sizes[i] = o.size;
        }
    }

    // ---------- ERC721 ----------
    function balanceOf(address account) public view returns (uint256) {
        if (account == address(0)) revert InvalidReceiver();
        return _balances[account];
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        address o = _owners[tokenId];
        if (o == address(0)) revert NonexistentToken();
        return o;
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        ownerOf(tokenId); // revert if not minted
        uint256 dropId = _tokenIdToDropId[tokenId];
        return drops[dropId].uri;
    }

    function getApproved(uint256 tokenId) public view returns (address) {
        ownerOf(tokenId);
        return _tokenApprovals[tokenId];
    }

    function isApprovedForAll(address account, address operator) public view returns (bool) {
        return _operatorApprovals[account][operator];
    }

    function approve(address to, uint256 tokenId) public {
        address o = ownerOf(tokenId);
        if (to == o) revert InvalidReceiver();
        if (msg.sender != o && !isApprovedForAll(o, msg.sender)) revert NotOwnerOrApproved();
        _tokenApprovals[tokenId] = to;
        emit Approval(o, to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public {
        if (msg.sender == operator) revert InvalidReceiver();
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(address from, address to, uint256 tokenId) public {
        if (to == address(0)) revert InvalidReceiver();
        if (ownerOf(tokenId) != from) revert WrongFrom();
        if (msg.sender != from && msg.sender != getApproved(tokenId) && !isApprovedForAll(from, msg.sender)) revert NotOwnerOrApproved();
        _tokenApprovals[tokenId] = address(0);
        _balances[from]--;
        _balances[to]++;
        _owners[tokenId] = to;
        emit Transfer(from, to, tokenId);
    }

    function _mint(address to, uint256 tokenId) private {
        if (to == address(0)) revert InvalidReceiver();
        if (_owners[tokenId] != address(0)) revert InvalidReceiver();
        _balances[to]++;
        _owners[tokenId] = to;
        emit Transfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) private {
        address o = _owners[tokenId];
        if (o == address(0)) revert NonexistentToken();
        _tokenApprovals[tokenId] = address(0);
        _balances[o]--;
        delete _owners[tokenId];
        emit Transfer(o, address(0), tokenId);
    }

    // ---------- Views for drops (for UI) ----------
    function getDropInfo(uint256 dropId) external view returns (string memory uri, uint256 maxSupply, uint256 mintedCount) {
        Drop storage d = drops[dropId];
        return (d.uri, d.maxSupply, d.mintedCount);
    }

    function getTokenDropId(uint256 tokenId) external view returns (uint256) {
        return _tokenIdToDropId[tokenId];
    }
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}