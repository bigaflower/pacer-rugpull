// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
 * ╔═══════════════════════════════════════════════════════════════════════════╗
 * ║                                                                           ║
 * ║    ████████╗██████╗  █████╗ ███╗   ██╗███████╗██████╗  ██████╗ ███╗   ██╗ ║
 * ║    ╚══██╔══╝██╔══██╗██╔══██╗████╗  ██║██╔════╝██╔══██╗██╔═══██╗████╗  ██║ ║
 * ║       ██║   ██████╔╝███████║██╔██╗ ██║███████╗██████╔╝██║   ██║██╔██╗ ██║ ║
 * ║       ██║   ██╔══██╗██╔══██║██║╚██╗██║╚════██║██╔═══╝ ██║   ██║██║╚██╗██║ ║
 * ║       ██║   ██║  ██║██║  ██║██║ ╚████║███████║██║     ╚██████╔╝██║ ╚████║ ║
 * ║       ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚══════╝╚═╝      ╚═════╝ ╚═╝  ╚═══╝ ║
 * ║                                  DEX                                      ║
 * ╠═══════════════════════════════════════════════════════════════════════════╣
 * ║                                                                           ║
 * ║                        made by CaptainY                                   ║
 * ║                                                                           ║
 * ║              onchain puzzle NFT w/ animated SVG art                       ║
 * ║              solve 4 levels to hit singularity                            ║
 * ║                                                                           ║
 * ╚═══════════════════════════════════════════════════════════════════════════╝
 */

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface ITranspondexRenderer {
    function render(uint256 id, uint8 level, uint16 hue, uint32 attempts, uint256 completionRank, bytes32 seed) external pure returns (string memory);
    function getAttributes(uint8 level, uint16 hue, uint32 attempts, uint256 completionRank, bytes32 seed) external pure returns (string memory);
}

/// @title Transpondex
/// @author CaptainY
/// @notice Onchain puzzle NFT - solve 4 levels to hit singularity
contract Transpondex is ERC721, Ownable {
    using Strings for uint256;

    // ═══════════════════════════════════════════════════════════════
    // CONSTANTS
    // ═══════════════════════════════════════════════════════════════
    uint256 public constant MAX_SUPPLY = 1000;
    uint256 public constant TEAM_RESERVE = 34;
    uint256 public constant MAX_PER_WALLET = 3;
    uint256 public constant PRICE = 0.001 ether;

    // ═══════════════════════════════════════════════════════════════
    // STATE
    // ═══════════════════════════════════════════════════════════════
    struct TokenState {
        uint8 level;            // 0-4, 4 = singularity
        uint16 hue;             // color (0-359)
        uint32 attempts;        // wrong guesses only
        uint64 completedAt;     // timestamp
        uint256 completionRank; // finish order
        bytes32 seed;           // unique puzzle seed
        address solver;         // who completed it
    }

    mapping(uint256 => TokenState) public tokens;
    mapping(address => uint256) public mintedPerWallet;

    uint256 public totalMinted;
    uint256 public totalCompleted;
    uint256 public teamMinted;
    
    bool public mintActive;
    ITranspondexRenderer public renderer;

    // ═══════════════════════════════════════════════════════════════
    // EVENTS
    // ═══════════════════════════════════════════════════════════════
    event Minted(uint256 indexed tokenId, address indexed minter, bytes32 seed);
    event LevelUp(uint256 indexed tokenId, uint8 newLevel, uint32 attempts);
    event WrongAnswer(uint256 indexed tokenId, uint32 attempts);
    event Completed(uint256 indexed tokenId, address indexed solver, uint256 rank, uint32 attempts);
    event MintStarted();
    event MintPaused();

    // ═══════════════════════════════════════════════════════════════
    // ERRORS
    // ═══════════════════════════════════════════════════════════════
    error MintNotActive();
    error SoldOut();
    error MaxPerWallet();
    error BadPayment();
    error NotOwner();
    error BadLevel();
    error BadInput();
    error TeamReserveExceeded();
    error NoRenderer();
    error RefundFailed();

    // ═══════════════════════════════════════════════════════════════
    // CONSTRUCTOR
    // ═══════════════════════════════════════════════════════════════
    constructor(address _renderer) ERC721("Transpondex", "TRSPNDX") Ownable(msg.sender) {
        renderer = ITranspondexRenderer(_renderer);
    }

    // ═══════════════════════════════════════════════════════════════
    // MINT - PUBLIC
    // ═══════════════════════════════════════════════════════════════
    function mint(uint256 qty) external payable {
        if (!mintActive) revert MintNotActive();
        if (totalMinted + qty > MAX_SUPPLY) revert SoldOut();
        if (mintedPerWallet[msg.sender] + qty > MAX_PER_WALLET) revert MaxPerWallet();
        
        uint256 cost = PRICE * qty;
        if (msg.value < cost) revert BadPayment();

        for (uint256 i = 0; i < qty; i++) {
            _mintOne(msg.sender);
        }
        mintedPerWallet[msg.sender] += qty;

        // Refund overpayment
        if (msg.value > cost) {
            (bool success,) = msg.sender.call{value: msg.value - cost}("");
            if (!success) revert RefundFailed();
        }
    }

    function _mintOne(address to) internal {
        uint256 id = ++totalMinted;
        bytes32 seed = keccak256(abi.encodePacked(id, address(this), block.prevrandao, block.timestamp));
        tokens[id] = TokenState(0, uint16(uint256(seed) % 360), 0, 0, 0, seed, address(0));
        _mint(to, id);
        emit Minted(id, to, seed);
    }

    // ═══════════════════════════════════════════════════════════════
    // SIGNAL PROTOCOLS - 4 LEVELS
    // ═══════════════════════════════════════════════════════════════

    /// @notice Level 0 → 1: Ping frequency alignment
    /// @param id Token ID
    /// @param freq Frequency guess (0-359)
    function ping(uint256 id, uint16 freq) external {
        TokenState storage t = tokens[id];
        if (ownerOf(id) != msg.sender) revert NotOwner();
        if (t.level != 0) revert BadLevel();
        if (freq >= 360) revert BadInput();
        
        if (freq != uint16(uint256(t.seed) % 360)) {
            t.attempts++;
            emit WrongAnswer(id, t.attempts);
            return;
        }
        t.level = 1;
        emit LevelUp(id, 1, t.attempts);
    }

    /// @notice Level 1 → 2: Sync tracking beacon
    /// @param id Token ID
    /// @param beacon Beacon guess (0-3)
    function sync(uint256 id, uint8 beacon) external {
        TokenState storage t = tokens[id];
        if (ownerOf(id) != msg.sender) revert NotOwner();
        if (t.level != 1) revert BadLevel();
        if (beacon > 3) revert BadInput();
        
        if (beacon != uint8((uint256(t.seed) >> 8) % 4)) {
            t.attempts++;
            emit WrongAnswer(id, t.attempts);
            return;
        }
        t.level = 2;
        emit LevelUp(id, 2, t.attempts);
    }

    /// @notice Level 2 → 3: Scan orbital body
    /// @param id Token ID
    /// @param body Body index guess (0 to planetCount-1)
    function scan(uint256 id, uint8 body) external {
        TokenState storage t = tokens[id];
        if (ownerOf(id) != msg.sender) revert NotOwner();
        if (t.level != 2) revert BadLevel();
        
        uint8 cnt = uint8(((uint256(t.seed) >> 16) % 4) + 3);
        if (body >= cnt) revert BadInput();
        
        if (body != uint8((uint256(t.seed) >> 24) % cnt)) {
            t.attempts++;
            emit WrongAnswer(id, t.attempts);
            return;
        }
        t.level = 3;
        emit LevelUp(id, 3, t.attempts);
    }

    /// @param id Token ID
    /// @param signal Proof hash
    function transmit(uint256 id, bytes32 signal) external {
        TokenState storage t = tokens[id];
        if (ownerOf(id) != msg.sender) revert NotOwner();
        if (t.level != 3) revert BadLevel();
        
        if (signal != keccak256(abi.encodePacked(id, t.seed, t.hue, uint16(400), uint16(400)))) {
            t.attempts++;
            emit WrongAnswer(id, t.attempts);
            return;
        }
        t.level = 4;
        t.completedAt = uint64(block.timestamp);
        t.solver = msg.sender;
        t.completionRank = ++totalCompleted;
        emit LevelUp(id, 4, t.attempts);
        emit Completed(id, msg.sender, totalCompleted, t.attempts);
    }

    // ═══════════════════════════════════════════════════════════════
    // VIEW FUNCTIONS
    // ═══════════════════════════════════════════════════════════════

    /// @notice Decode transmission signal for verification (Level 3 answer)
    function decodeTransmission(uint256 id) external view returns (bytes32) {
        TokenState storage t = tokens[id];
        return keccak256(abi.encodePacked(id, t.seed, t.hue, uint16(400), uint16(400)));
    }

    // ═══════════════════════════════════════════════════════════════
    // METADATA
    // ═══════════════════════════════════════════════════════════════
    function tokenURI(uint256 id) public view override returns (string memory) {
        require(_ownerOf(id) != address(0), "Token does not exist");
        if (address(renderer) == address(0)) revert NoRenderer();
        
        TokenState storage t = tokens[id];
        
        string memory svg = renderer.render(id, t.level, t.hue, t.attempts, t.completionRank, t.seed);
        string memory attrs = renderer.getAttributes(t.level, t.hue, t.attempts, t.completionRank, t.seed);
        
        string memory json = string(abi.encodePacked(
            '{"name":"Transpondex #', id.toString(),
            '","description":"Onchain puzzle NFT by CaptainY. Solve 4 levels to hit singularity. THEY SEE YOU.",',
            '"attributes":', attrs,
            ',"image":"data:image/svg+xml;base64,', Base64.encode(bytes(svg)), '"}'
        ));
        
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
    }

    // ═══════════════════════════════════════════════════════════════
    // ADMIN - OWNER ONLY
    // ═══════════════════════════════════════════════════════════════

    /// @notice Mint team reserve to owner wallet
    function teamMint(uint256 qty) external onlyOwner {
        if (teamMinted + qty > TEAM_RESERVE) revert TeamReserveExceeded();
        if (totalMinted + qty > MAX_SUPPLY) revert SoldOut();
        
        for (uint256 i = 0; i < qty; i++) {
            _mintOne(owner());
        }
        teamMinted += qty;
    }

    /// @notice Start public mint
    function startMint() external onlyOwner {
        mintActive = true;
        emit MintStarted();
    }

    /// @notice Pause public mint
    function pauseMint() external onlyOwner {
        mintActive = false;
        emit MintPaused();
    }

    /// @notice Update renderer contract
    function setRenderer(address _renderer) external onlyOwner {
        renderer = ITranspondexRenderer(_renderer);
    }

    /// @notice Withdraw contract balance
    function withdraw() external onlyOwner {
        (bool success,) = owner().call{value: address(this).balance}("");
        require(success, "Withdraw failed");
    }
}
