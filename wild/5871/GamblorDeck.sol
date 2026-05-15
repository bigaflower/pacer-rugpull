// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@limitbreak/creator-token-contracts/contracts/erc721c/ERC721AC.sol";
import "@limitbreak/creator-token-contracts/contracts/programmable-royalties/BasicRoyalties.sol";
import "@limitbreak/creator-token-contracts/contracts/access/OwnableBasic.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./PhaseMint.sol";
import "./Signature.sol";
import "./abstract/LockRegistry.sol";

contract GamblorDeckNFT is
    ERC721AC,
    BasicRoyalties,
    OwnableBasic,
    ReentrancyGuard,
    PhaseMint,
    Signature,
    LockRegistry
{
    using SafeERC20 for IERC20;

    string public baseURI;
    uint256 public supply;
    bool public burnEnabled;

    event MetadataUpdate(uint256 tokenId);
    event BatchMetadataUpdate(uint256 fromTokenId, uint256 toTokenId);
    event TokenWithdrawn(
        address indexed token,
        address indexed to,
        uint256 amount
    );
    event EthWithdrawn(address indexed to, uint256 amount);

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseUri,
        uint256 _supply,
        address _signer,
        address _owner,
        address _royaltyReceiver,
        uint96 _royaltyFeeNumerator
    )
        ERC721AC(_name, _symbol)
        BasicRoyalties(_royaltyReceiver, _royaltyFeeNumerator)
    {
        require(_supply > 0, "Supply must be greater than 0");
        require(_signer != address(0), "Invalid signer");
        require(_owner != address(0), "Invalid owner");
        require(bytes(_baseUri).length > 0, "Invalid base URI");

        baseURI = _baseUri;
        supply = _supply;
        _transferOwnership(_owner);
        _setSigner(_signer);
        burnEnabled = false;
    }

    // ---------- Mint ----------
    function mint(
        address _to,
        uint256 _amount,
        bytes32 _phaseID,
        uint256 _price,
        uint256 _maxPerTx,
        uint256 _maxPerUser,
        uint256 _maxPerPhase,
        bytes32 _nonce,
        bytes memory _signature
    ) external payable nonReentrant {
        require(msg.sender == tx.origin, "No contract interaction");
        require(_amount > 0, "Amount must be greater than 0");
        require(totalSupply() + _amount <= supply, "Exceeds max supply");
        require(msg.value >= _price * _amount, "Insufficient funds");
        require(isValidNonce(_nonce), "Invalid nonce");

        _invalidateNonce(_nonce);

        bytes32 message = getMessageHash(
            _to,
            _amount,
            _phaseID,
            _price,
            _maxPerTx,
            _maxPerUser,
            _maxPerPhase,
            _nonce
        );
        require(_verifySignature(message, _signature), "Invalid signature");

        _mintPhase(
            _to,
            _amount,
            _phaseID,
            _maxPerTx,
            _maxPerUser,
            _maxPerPhase
        );

        // ERC721A batch mint
        _safeMint(_to, _amount);
    }

    // ---------- Mint with ERC20----------
    function mintWithToken(
        address paymentToken,
        address _to,
        uint256 _amount,
        bytes32 _phaseID,
        uint256 _price,
        uint256 _maxPerTx,
        uint256 _maxPerUser,
        uint256 _maxPerPhase,
        bytes32 _nonce,
        bytes memory _signature
    ) external nonReentrant {
        require(msg.sender == tx.origin, "No contract interaction");
        require(paymentToken != address(0), "paymentToken=0");
        require(_amount > 0, "Amount must be > 0");
        require(totalSupply() + _amount <= supply, "Exceeds max supply");
        require(isValidNonce(_nonce), "Invalid nonce");

        // Prevent replay: include token + price in the signed message
        bytes32 message = getMessageHashWithToken(
            paymentToken,
            _to,
            _amount,
            _phaseID,
            _price,
            _maxPerTx,
            _maxPerUser,
            _maxPerPhase,
            _nonce
        );
        require(_verifySignature(message, _signature), "Invalid signature");

        // Mark nonce used
        _invalidateNonce(_nonce);

        // Phase limits
        _mintPhase(
            _to,
            _amount,
            _phaseID,
            _maxPerTx,
            _maxPerUser,
            _maxPerPhase
        );

        // Collect payment
        uint256 totalCost = _price * _amount;
        IERC20(paymentToken).safeTransferFrom(
            msg.sender,
            address(this),
            totalCost
        );

        // ERC721A batch mint
        _safeMint(_to, _amount);
    }

    // --- Messages Check ---

    function getMessageHash(
        address _to,
        uint256 _amount,
        bytes32 _phaseID,
        uint256 _price,
        uint256 _maxPerTx,
        uint256 _maxPerUser,
        uint256 _maxPerPhase,
        bytes32 _nonce
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    _to,
                    _amount,
                    _phaseID,
                    _price,
                    _maxPerTx,
                    _maxPerUser,
                    _maxPerPhase,
                    _nonce
                )
            );
    }

    function getMessageHashWithToken(
        address paymentToken,
        address _to,
        uint256 _amount,
        bytes32 _phaseID,
        uint256 _price,
        uint256 _maxPerTx,
        uint256 _maxPerUser,
        uint256 _maxPerPhase,
        bytes32 _nonce
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    paymentToken,
                    _to,
                    _amount,
                    _phaseID,
                    _price,
                    _maxPerTx,
                    _maxPerUser,
                    _maxPerPhase,
                    _nonce
                )
            );
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    // ---------- Burn ----------
    function burn(uint256 tokenId) external {
        require(burnEnabled, "Burn disabled");
        address owner = ownerOf(tokenId); // reverts if non-existent
        require(
            msg.sender == owner ||
                isApprovedForAll(owner, msg.sender) ||
                getApproved(tokenId) == msg.sender,
            "Burn not approved"
        );
        _burn(tokenId);
    }

    // ---------- Admin ----------
    function setBaseURI(string memory _baseUri) external {
        _requireCallerIsContractOwner();
        baseURI = _baseUri;
    }

    function setSigner(address _signer) external {
        _requireCallerIsContractOwner();
        _setSigner(_signer);
    }

    function setSupply(uint256 _newSupply) external {
        _requireCallerIsContractOwner();
        require(_newSupply >= totalSupply(), "New supply < total");
        supply = _newSupply;
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external {
        _requireCallerIsContractOwner();
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) external {
        _requireCallerIsContractOwner();
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    function setBurnEnabled(bool _enabled) external {
        _requireCallerIsContractOwner();
        burnEnabled = _enabled;
    }

    // ---------- Locking ----------
    function lockToken(uint256[] memory tokenIds) external {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _lockId(tokenIds[i]);
        }
    }

    function unlockToken(uint256[] memory tokenIds) external {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _unlockId(tokenIds[i]);
        }
    }

    function freeToken(uint256 tokenId, address lockerAddress) external {
        _freeId(tokenId, lockerAddress);
    }

    // ---------- Withdrawals  ----------
    function withdrawToken(
        address token,
        address to
    ) external nonReentrant returns (uint256 amount) {
        _requireCallerIsContractOwner();
        require(to != address(0), "to=0");
        amount = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransfer(to, amount);
        emit TokenWithdrawn(token, to, amount);
    }

    function withdrawETH(
        address payable to
    ) external nonReentrant returns (uint256 amount) {
        _requireCallerIsContractOwner();
        require(to != address(0), "to=0");
        amount = address(this).balance;
        (bool ok, ) = to.call{value: amount}("");
        require(ok, "ETH transfer failed");
        emit EthWithdrawn(to, amount);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721AC, ERC2981) returns (bool) {
        if (interfaceId == 0x49064906) return true;

        return
            ERC721AC.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    function _ownerOf(
        uint256 tokenId
    ) internal view override returns (address) {
        return ownerOf(tokenId); // internal for LockRegistry
    }

    /**
     * @dev Overrides the normal `transferFrom` to include lock check
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A) {
        require(isUnlocked(tokenId), "Token is locked");
        super.transferFrom(from, to, tokenId);
    }
    /**
     @dev Overrides the normal `safeTransferFrom` to include lock check   
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A) {
        require(isUnlocked(tokenId), "Token is locked");
        super.safeTransferFrom(from, to, tokenId);
    }

    /**
     @dev Overrides the `safeTransferFrom` with data to include lock check   
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(ERC721A) {
        require(isUnlocked(tokenId), "Token is locked");
        super.safeTransferFrom(from, to, tokenId, data);
    }
}
