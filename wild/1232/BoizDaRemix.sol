// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title BoizDaRemix - Fully Onchain NFT
/// @notice 8,888 supply, free mint, 1 per wallet, 2.5% royalties
contract BoizDaRemix {
    event Transfer(address indexed from, address indexed to, uint256 indexed id);
    event Approval(address indexed owner, address indexed spender, uint256 indexed id);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    string public constant name = "BoizDaRemix";
    string public constant symbol = "BOIZ";
    uint256 public constant MAX_SUPPLY = 8888;
    uint256 public constant DEV_RESERVE = 250;
    uint256 public constant ROYALTY_BPS = 250;

    uint256 public totalSupply;
    uint256 public devMinted;
    address public owner;
    address public royaltyReceiver;
    bool public publicMintOpen;

    mapping(uint256 => address) internal _ownerOf;
    mapping(address => uint256) internal _balanceOf;
    mapping(uint256 => address) public getApproved;
    mapping(address => mapping(address => bool)) public isApprovedForAll;
    mapping(address => bool) public hasMinted;

    error NotOwner();
    error NotAuthorized();
    error InvalidRecipient();
    error AlreadyMinted();
    error NotMinted();
    error MaxSupply();
    error MintClosed();
    error DevMax();

    constructor() {
        owner = msg.sender;
        royaltyReceiver = msg.sender;
    }

    // ============ ERC721 ============

    function ownerOf(uint256 id) public view returns (address o) {
        require((o = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address o) public view returns (uint256) {
        require(o != address(0), "ZERO");
        return _balanceOf[o];
    }

    function approve(address spender, uint256 id) public {
        address o = _ownerOf[id];
        require(msg.sender == o || isApprovedForAll[o][msg.sender], "NO_AUTH");
        getApproved[id] = spender;
        emit Approval(o, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public {
        isApprovedForAll[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(address from, address to, uint256 id) public {
        require(from == _ownerOf[id], "WRONG_FROM");
        require(to != address(0), "INVALID");
        require(msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id], "NO_AUTH");
        unchecked { _balanceOf[from]--; _balanceOf[to]++; }
        _ownerOf[id] = to;
        delete getApproved[id];
        emit Transfer(from, to, id);
    }

    function safeTransferFrom(address from, address to, uint256 id) public {
        transferFrom(from, to, id);
    }

    function safeTransferFrom(address from, address to, uint256 id, bytes calldata) public {
        transferFrom(from, to, id);
    }

    function supportsInterface(bytes4 i) public pure returns (bool) {
        return i == 0x01ffc9a7 || i == 0x80ac58cd || i == 0x5b5e139f || i == 0x2a55205a;
    }

    // ============ MINT ============

    function mint() external {
        require(publicMintOpen, "CLOSED");
        require(totalSupply < MAX_SUPPLY, "MAX");
        require(!hasMinted[msg.sender], "MINTED");
        hasMinted[msg.sender] = true;
        _mint(msg.sender, ++totalSupply);
    }

    function devMint(uint256 amount) external {
        require(msg.sender == owner, "NO_AUTH");
        require(devMinted + amount <= DEV_RESERVE, "DEV_MAX");
        for (uint256 i = 0; i < amount;) {
            _mint(msg.sender, ++totalSupply);
            unchecked { devMinted++; i++; }
        }
    }

    function devMintTo(address to, uint256 amount) external {
        require(msg.sender == owner, "NO_AUTH");
        require(devMinted + amount <= DEV_RESERVE, "DEV_MAX");
        for (uint256 i = 0; i < amount;) {
            _mint(to, ++totalSupply);
            unchecked { devMinted++; i++; }
        }
    }

    function _mint(address to, uint256 id) internal {
        _balanceOf[to]++;
        _ownerOf[id] = to;
        emit Transfer(address(0), to, id);
    }

    // ============ OWNER ============

    function setPublicMintOpen(bool open) external {
        require(msg.sender == owner, "NO_AUTH");
        publicMintOpen = open;
    }

    function setRoyaltyReceiver(address r) external {
        require(msg.sender == owner, "NO_AUTH");
        royaltyReceiver = r;
    }

    function transferOwnership(address newOwner) external {
        require(msg.sender == owner, "NO_AUTH");
        owner = newOwner;
    }

    // ============ ROYALTY ============

    function royaltyInfo(uint256, uint256 salePrice) external view returns (address, uint256) {
        return (royaltyReceiver, (salePrice * ROYALTY_BPS) / 10000);
    }

    // ============ METADATA ============

    function tokenURI(uint256 id) public view returns (string memory) {
        require(_ownerOf[id] != address(0), "NOT_MINTED");
        return string(abi.encodePacked(
            'data:application/json;base64,',
            base64(abi.encodePacked(
                '{"name":"BoizDaRemix #', _toString(id),
                '","description":"BoizDaRemix - 8888 fully onchain characters",',
                '"image":"data:image/svg+xml;base64,', base64(bytes(_svg(id))),
                '","attributes":', _attrs(id), '}'
            ))
        ));
    }

    function _attrs(uint256 id) internal pure returns (string memory) {
        return string(abi.encodePacked(
            '[{"trait_type":"Base","value":"', _baseName(_base(id)), '"},',
            '{"trait_type":"Expression","value":"', _exprName(_expr(id)), '"},',
            '{"trait_type":"Overlay","value":"', _overlayName(_overlay(id)), '"},',
            '{"trait_type":"Background","value":"', _bgName(_bg(id)), '"}]'
        ));
    }

    // ============ TRAITS ============

    function _hash(uint256 id, uint256 idx) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked("BOIZ", id, idx)));
    }

    function _base(uint256 id) internal pure returns (uint256) {
        uint256 r = _hash(id, 0) % 10000;
        if (r < 1400) return 0;
        if (r < 2800) return 1;
        if (r < 4200) return 2;
        if (r < 5400) return 3;
        if (r < 6400) return 4;
        if (r < 7200) return 5;
        if (r < 7900) return 6;
        if (r < 8500) return 7;
        if (r < 9000) return 8;
        if (r < 9400) return 9;
        if (r < 9700) return 10;
        return 11;
    }

    function _expr(uint256 id) internal pure returns (uint256) { return _hash(id, 1) % 8; }
    function _overlay(uint256 id) internal pure returns (uint256) { return _hash(id, 2) % 10; }
    function _bg(uint256 id) internal pure returns (uint256) { return _hash(id, 3) % 4; }
    function _body(uint256 id) internal pure returns (uint256) { return _hash(id, 4) % 8; }
    function _head(uint256 id) internal pure returns (uint256) { return _hash(id, 5) % 8; }
    function _eye(uint256 id) internal pure returns (uint256) { return _hash(id, 6) % 8; }

    function _baseName(uint256 i) internal pure returns (string memory) {
        string[12] memory n = ["Solid","Leopard","Cheetah","Trippy","Zombie","Robot","Gold","DMT","Camo","Tiger","Dalmatian","Plasma"];
        return n[i];
    }

    function _exprName(uint256 i) internal pure returns (string memory) {
        string[8] memory n = ["Neutral","Wide","Narrow","Wink","Dead","Angry","Surprised","Laser"];
        return n[i];
    }

    function _overlayName(uint256 i) internal pure returns (string memory) {
        string[10] memory n = ["None","Tears","Cigarette","Glasses","Halo","Horns","Crown","Hat Down Only","Hat Liquidated","Laser Eyes"];
        return n[i];
    }

    function _bgName(uint256 i) internal pure returns (string memory) {
        string[4] memory n = ["Dark","Purple","Blue","Teal"];
        return n[i];
    }

    // ============ SVG ============

    function _svg(uint256 id) internal pure returns (string memory) {
        return string(abi.encodePacked(
            _svgStart(id),
            _svgEnd(id)
        ));
    }

    function _svgStart(uint256 id) internal pure returns (string memory) {
        string[4] memory bgc = ["#0a0a0a","#1a1a2e","#0c0032","#0f4c75"];
        string[8] memory bdc = ["#ff4d2e","#4a90d9","#50c878","#9b59b6","#f39c12","#1abc9c","#e74c3c","#3498db"];
        string[8] memory hdc = ["#e8e4e0","#d4cfc9","#f0ebe5","#c9c4be","#ddd8d2","#b8b3ad","#f5f0ea","#ccc7c1"];
        
        return string(abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 400">',
            _getDefs(_base(id)),
            '<rect width="400" height="400" fill="', bgc[_bg(id)], '"/>',
            _bgLines(id),
            '<path d="M150 280 L140 380 L260 380 L250 280 Q200 300 150 280" fill="', bdc[_body(id)], '"/>',
            '<path d="M140 150 L145 90 L175 65 L225 65 L255 90 L260 150 L255 220 L230 255 L170 255 L145 220 Z" fill="', hdc[_head(id)], '"/>'
        ));
    }

    function _svgEnd(uint256 id) internal pure returns (string memory) {
        string[8] memory eyc = ["#5b7fff","#ff6b6b","#50c878","#9b59b6","#ffd93d","#ff8c42","#00d4ff","#ff00ff"];
        
        return string(abi.encodePacked(
            _baseOverlay(_base(id)),
            _eyes(_expr(id), eyc[_eye(id)]),
            '<path d="M200 180 Q215 200 200 230 Q185 200 200 180" fill="#ffd93d"/>',
            _overlayStr(_overlay(id)),
            '</svg>'
        ));
    }

    function _getDefs(uint256 baseIdx) internal pure returns (string memory) {
        if (baseIdx == 3) return '<defs><linearGradient id="g1" x1="0%" y1="0%" x2="100%" y2="100%"><stop offset="0%" stop-color="#ff00ff" stop-opacity="0.3"/><stop offset="100%" stop-color="#ffff00" stop-opacity="0.3"/></linearGradient></defs>';
        if (baseIdx == 6) return '<defs><linearGradient id="g2"><stop offset="0%" stop-color="#ffd700"/><stop offset="100%" stop-color="#daa520"/></linearGradient></defs>';
        if (baseIdx == 11) return '<defs><radialGradient id="g3"><stop offset="0%" stop-color="#ff00ff" stop-opacity="0.4"/><stop offset="100%" stop-color="#ff6600" stop-opacity="0.2"/></radialGradient></defs>';
        return '';
    }

    function _bgLines(uint256 id) internal pure returns (string memory) {
        string memory r = '';
        for (uint256 i = 0; i < 5; i++) {
            uint256 s = _hash(id, 10 + i);
            r = string(abi.encodePacked(r,
                '<line x1="', _toString(s % 400), '" y1="', _toString((s >> 8) % 400),
                '" x2="', _toString((s >> 4) % 400), '" y2="', _toString((s >> 12) % 400),
                '" stroke="#333" stroke-width="2" opacity="0.5"/>'
            ));
        }
        return r;
    }

    function _baseOverlay(uint256 i) internal pure returns (string memory) {
        if (i == 3) return '<rect x="120" y="60" width="160" height="200" fill="url(#g1)" rx="40"/>';
        if (i == 6) return '<rect x="120" y="60" width="160" height="200" fill="url(#g2)" rx="40"/>';
        if (i == 11) return '<rect x="120" y="60" width="160" height="200" fill="url(#g3)" rx="40"/>';
        if (i == 1) return '<circle cx="150" cy="100" r="8" fill="#5a4a3a" opacity="0.6"/><circle cx="240" cy="95" r="7" fill="#5a4a3a" opacity="0.6"/>';
        if (i == 4) return '<rect x="120" y="60" width="160" height="200" fill="#2d5a27" opacity="0.4" rx="40"/>';
        return '';
    }

    function _eyes(uint256 e, string memory c) internal pure returns (string memory) {
        if (e == 1) return string(abi.encodePacked('<ellipse cx="165" cy="145" rx="22" ry="28" fill="',c,'"/><ellipse cx="235" cy="145" rx="22" ry="28" fill="',c,'"/>'));
        if (e == 2) return string(abi.encodePacked('<ellipse cx="165" cy="145" rx="18" ry="8" fill="',c,'"/><ellipse cx="235" cy="145" rx="18" ry="8" fill="',c,'"/>'));
        if (e == 3) return string(abi.encodePacked('<ellipse cx="165" cy="145" rx="18" ry="22" fill="',c,'"/><line x1="220" y1="145" x2="250" y2="145" stroke="',c,'" stroke-width="6"/>'));
        if (e == 4) return string(abi.encodePacked('<line x1="153" y1="133" x2="177" y2="157" stroke="',c,'" stroke-width="6"/><line x1="177" y1="133" x2="153" y2="157" stroke="',c,'" stroke-width="6"/><line x1="223" y1="133" x2="247" y2="157" stroke="',c,'" stroke-width="6"/><line x1="247" y1="133" x2="223" y2="157" stroke="',c,'" stroke-width="6"/>'));
        if (e == 5) return string(abi.encodePacked('<ellipse cx="165" cy="145" rx="18" ry="22" fill="',c,'"/><ellipse cx="235" cy="145" rx="18" ry="22" fill="',c,'"/><line x1="145" y1="115" x2="180" y2="120" stroke="#333" stroke-width="4"/><line x1="255" y1="115" x2="220" y2="120" stroke="#333" stroke-width="4"/>'));
        if (e == 6) return string(abi.encodePacked('<circle cx="165" cy="145" r="24" fill="',c,'"/><circle cx="165" cy="145" r="10" fill="#000"/><circle cx="235" cy="145" r="24" fill="',c,'"/><circle cx="235" cy="145" r="10" fill="#000"/>'));
        if (e == 7) return '<ellipse cx="165" cy="145" rx="18" ry="22" fill="#ff0000"/><line x1="165" y1="145" x2="50" y2="195" stroke="#ff0000" stroke-width="4" opacity="0.8"/><ellipse cx="235" cy="145" rx="18" ry="22" fill="#ff0000"/><line x1="235" y1="145" x2="350" y2="195" stroke="#ff0000" stroke-width="4" opacity="0.8"/>';
        return string(abi.encodePacked('<ellipse cx="165" cy="145" rx="18" ry="22" fill="',c,'"/><ellipse cx="235" cy="145" rx="18" ry="22" fill="',c,'"/>'));
    }

    function _overlayStr(uint256 i) internal pure returns (string memory) {
        if (i == 1) return '<ellipse cx="165" cy="175" rx="4" ry="12" fill="#87ceeb" opacity="0.8"/><ellipse cx="235" cy="180" rx="4" ry="15" fill="#87ceeb" opacity="0.8"/>';
        if (i == 2) return '<rect x="200" y="220" width="50" height="6" fill="#f5f5dc"/><rect x="245" y="220" width="8" height="6" fill="#ff6347"/>';
        if (i == 3) return '<rect x="140" y="130" width="45" height="35" fill="#1a1a1a" rx="5"/><rect x="215" y="130" width="45" height="35" fill="#1a1a1a" rx="5"/><line x1="185" y1="147" x2="215" y2="147" stroke="#1a1a1a" stroke-width="4"/>';
        if (i == 4) return '<ellipse cx="200" cy="55" rx="50" ry="12" fill="none" stroke="#ffd700" stroke-width="6" opacity="0.8"/>';
        if (i == 5) return '<path d="M150 80 Q140 40 120 30" stroke="#8b0000" stroke-width="12" fill="none"/><path d="M250 80 Q260 40 280 30" stroke="#8b0000" stroke-width="12" fill="none"/>';
        if (i == 6) return '<path d="M140 65 L150 40 L170 55 L200 30 L230 55 L250 40 L260 65 Z" fill="#ffd700" stroke="#daa520" stroke-width="2"/>';
        if (i == 7) return '<ellipse cx="200" cy="75" rx="75" ry="15" fill="#1a1a1a"/><rect x="145" y="35" width="110" height="40" fill="#1a1a1a" rx="5"/><text x="200" y="62" font-family="monospace" font-size="12" font-weight="bold" fill="#ff0000" text-anchor="middle">DOWN ONLY</text>';
        if (i == 8) return '<ellipse cx="200" cy="75" rx="75" ry="15" fill="#8b0000"/><rect x="145" y="35" width="110" height="40" fill="#8b0000" rx="5"/><text x="200" y="62" font-family="monospace" font-size="10" font-weight="bold" fill="#fff" text-anchor="middle">LIQUIDATED</text>';
        if (i == 9) return '<ellipse cx="165" cy="145" rx="18" ry="22" fill="#ff0000"/><line x1="165" y1="145" x2="50" y2="195" stroke="#ff0000" stroke-width="4"/><ellipse cx="235" cy="145" rx="18" ry="22" fill="#ff0000"/><line x1="235" y1="145" x2="350" y2="195" stroke="#ff0000" stroke-width="4"/>';
        return '';
    }

    // ============ UTILS ============

    function _toString(uint256 v) internal pure returns (string memory) {
        if (v == 0) return "0";
        uint256 t = v;
        uint256 d;
        while (t != 0) { d++; t /= 10; }
        bytes memory b = new bytes(d);
        while (v != 0) { b[--d] = bytes1(uint8(48 + v % 10)); v /= 10; }
        return string(b);
    }

    function base64(bytes memory data) internal pure returns (string memory) {
        bytes memory T = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
        uint256 len = data.length;
        if (len == 0) return "";
        uint256 eLen = 4 * ((len + 2) / 3);
        bytes memory r = new bytes(eLen + 32);
        assembly {
            let tPtr := add(T, 1)
            let rPtr := add(r, 32)
            for { let i := 0 } lt(i, len) { } {
                i := add(i, 3)
                let inp := and(mload(add(data, i)), 0xffffff)
                let o := mload(add(tPtr, and(shr(18, inp), 0x3F)))
                o := shl(8, o)
                o := add(o, and(mload(add(tPtr, and(shr(12, inp), 0x3F))), 0xFF))
                o := shl(8, o)
                o := add(o, and(mload(add(tPtr, and(shr(6, inp), 0x3F))), 0xFF))
                o := shl(8, o)
                o := add(o, and(mload(add(tPtr, and(inp, 0x3F))), 0xFF))
                o := shl(224, o)
                mstore(rPtr, o)
                rPtr := add(rPtr, 4)
            }
            switch mod(len, 3)
            case 1 { mstore(sub(rPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(rPtr, 1), shl(248, 0x3d)) }
            mstore(r, eLen)
        }
        return string(r);
    }
}