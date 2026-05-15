pragma solidity ^0.8.4;

import "./DN404.sol";
import "solady/src/auth/Ownable.sol";
import "solady/src/utils/LibString.sol";
import "solady/src/utils/SafeTransferLib.sol";
import "solady/src/utils/MerkleProofLib.sol";
import "solady/src/utils/GasBurnerLib.sol";

contract Xtremeverse is DN404, Ownable {

    string private _name;
    string private _symbol;
    string private _baseURI;

    bytes32 private _gtdAllowlistRoot;
    bytes32 private _fcfsAllowlistRoot;
    uint256 private _gtdStartTime = 0;
    uint256 private _fcfsStartTime = 0;
    uint256 private _publicStartTime = 0;

    uint32 public totalMinted;

    uint32 public constant MAX_PER_WALLET = 1;
    uint32 public constant MAX_SUPPLY = 3000;
    uint96 public constant mintPrice = 0.06 ether;

    bool public gasBurnFactorLocked = false;
    uint32 public gasBurnFactor;

    error InvalidProof();
    error InvalidMint();
    error InvalidPrice();
    error TotalSupplyReached();
    error NotLive();
    error Locked();

    constructor() {
        _construct(tx.origin);
    }

    function _construct(address initialOwner) internal {
        _initializeOwner(initialOwner);
        _name = "Xtremeverse";
        _symbol = "XTREME";
    }

    function initialize(address mirror) public onlyOwner {
        _initializeDN404(0, address(0), mirror);
    }

    modifier checkPrice() {
        if (mintPrice != msg.value) {
            revert InvalidPrice();
        }
        _;
    }

    modifier checkAndUpdateTotalMinted() {
        uint256 newTotalMinted = uint256(totalMinted) + 1;
        if (newTotalMinted > MAX_SUPPLY) {
            revert TotalSupplyReached();
        }
        totalMinted = uint32(newTotalMinted);
        _;
    }

    modifier checkAndUpdateBuyerMintCount() {
        uint256 currentMintCount = _getAux(msg.sender);
        uint256 newMintCount = currentMintCount + 1;
        if (newMintCount > MAX_PER_WALLET) {
            revert InvalidMint();
        }
        _setAux(msg.sender, uint88(newMintCount));
        _;
    }

    /*
    mintType - 0 -> gtd, 1 -> fcfs, 2 -> public
    */
    function mint(uint8 mintType, bytes32[] calldata proof)
        public
        payable
        checkPrice
        checkAndUpdateBuyerMintCount
        checkAndUpdateTotalMinted
    {
        if (mintType == 0) {
            if (block.timestamp < _gtdStartTime) {
                revert NotLive();
            }
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            if (!MerkleProofLib.verifyCalldata(proof, _gtdAllowlistRoot, leaf)) {
                revert InvalidProof();
            }
        } else if (mintType == 1) {
            if (block.timestamp < _fcfsStartTime) {
                revert NotLive();
            }
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            if (!MerkleProofLib.verifyCalldata(proof, _fcfsAllowlistRoot, leaf)) {
                revert InvalidProof();
            }
        } else if (mintType == 2) {
            if (block.timestamp < _publicStartTime) {
                revert NotLive();
            }
        } else {
            revert InvalidMint();
        }
    
        _mint(msg.sender, 1 * _unit());
    }

    function batchAirdropMint(address[] memory addresses, uint256 nftAmount) 
        public onlyOwner
    {
        uint256 newMintCount = nftAmount * addresses.length;
        uint256 newTotalMinted = uint256(totalMinted) + newMintCount;
        if (newTotalMinted > MAX_SUPPLY) {
            revert TotalSupplyReached();
        }
        totalMinted = uint32(newTotalMinted);

        for (uint256 i = 0; i < addresses.length; i++) {
            _mint(addresses[i], nftAmount * _unit());
        }
    }

    function setMintStartTimes(
        uint256 __gtdStartTime,
        uint256 __fcfsStartTime,
        uint256 __publicStartTime
    ) external onlyOwner {
        _gtdStartTime = __gtdStartTime;
        _fcfsStartTime = __fcfsStartTime;
        _publicStartTime = __publicStartTime;
    }

    function setAllowlistRoots(
       bytes32 __gtdAllowlistRoot,
        bytes32 __fcfsAllowlistRoot
    ) external onlyOwner {
        _gtdAllowlistRoot = __gtdAllowlistRoot;
        _fcfsAllowlistRoot = __fcfsAllowlistRoot;
    }

    function setBaseURI(string calldata baseURI_) public onlyOwner {
        _baseURI = baseURI_;
    }

    function withdraw() public onlyOwner {
        SafeTransferLib.safeTransferAllETH(msg.sender);
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory result) {
        if (bytes(_baseURI).length != 0) {
            result = string(abi.encodePacked(_baseURI, LibString.toString(tokenId)));
        }
    }

    function ownedIds(address owner, uint256 begin, uint256 end) public view returns (uint256[] memory result) {
        return _ownedIds(owner, begin, end);
    }

    function balanceOfNFT(address owner) public view virtual returns (uint256) {
        return _balanceOfNFT(owner);
    }

    function _transfer(address from, address to, uint256 amount) internal virtual override {
        super._transfer(from, to, amount);
        if (from != to) _applyGasBurn(from);
    }

    function _transferFromNFT(address from, address to, uint256 id, address msgSender) internal virtual override
    {
        super._transferFromNFT(from, to, id, msgSender);
        if (from != to) _applyGasBurn(from);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual override {
        super._approve(owner, spender, amount);
        _applyGasBurn(owner);
    }

    function _approveNFT(address spender, uint256 id, address msgSender)
        internal
        virtual
        override
        returns (address owner)
    {
        _applyGasBurn(msgSender);
        return super._approveNFT(spender, id, msgSender);
    }

    function _setApprovalForAll(address operator, bool approved, address msgSender)
        internal
        virtual
        override
    {
        _applyGasBurn(msgSender);
        super._setApprovalForAll(operator, approved, msgSender);
    }

    function lockGasBurnFactor() public onlyOwner {
        gasBurnFactorLocked = true;
    }

    function setGasBurnFactor(uint32 gasBurnFactor_) public onlyOwner {
        if (gasBurnFactorLocked) revert Locked();
        gasBurnFactor = gasBurnFactor_;
    }

    function _applyGasBurn(address from) internal {
        unchecked {
            uint256 factor = gasBurnFactor;
            if (factor == 0) return;
            if (from == owner()) return;
            GasBurnerLib.burn(factor);
        }
    }
}