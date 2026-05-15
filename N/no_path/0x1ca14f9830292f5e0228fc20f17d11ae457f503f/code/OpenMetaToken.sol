// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";

/**
 * @dev An ERC20 token for OMETA.
 *      Besides the addition of voting capabilities, we make a couple of customisations:
 *       - Airdrop claim functionality via `claimTokens`. At creation time the tokens that
 *         should be available for the airdrop are transferred to the token contract address;
 *         airdrop claims are made from this balance.
 *       - Support for the owner (the DAO) to mint new tokens, up to 1 billion tokens.
 */
contract OpenMetaToken is ERC20, ERC20Permit, ERC20Votes, Ownable {
    using BitMaps for BitMaps.BitMap;

    bytes32 public merkleRoot;
    uint256 public claimPeriodEnds; // Timestamp
    uint256 public constant maxSupply = 1_000_000_000e18; // 1 billion OMETA
    BitMaps.BitMap private claimed;

    mapping(address => address) private transferFromToEnabled;

    bool private restrictedTransfersEnabled = true;

    event MerkleRootChanged(bytes32 merkleRoot);
    event Claim(address indexed claimant, uint256 amount);

    /**
     * @dev Constructor.
     * @param _claimPeriodEnds The timestamp at which tokens are no longer claimable.
     */
    constructor(uint256 _claimPeriodEnds) ERC20("Open Meta Token", "OMETA") ERC20Permit("Open Meta Token") {
        claimPeriodEnds = _claimPeriodEnds;

        // Transfer ownership to multi-sig wallet
        transferOwnership(address(0x9bf13CD856eaCCA29331909A600902F3908E54a7));
    }

    /**
     * @dev Claims airdropped tokens.
     * @param amount The amount of the claim being made.
     * @param delegate The address the tokenholder wants to delegate their votes to.
     * @param merkleProof A merkle proof proving the claim is valid.
     */
    function claimTokens(
        uint256 amount,
        address delegate,
        bytes32[] calldata merkleProof
    ) external {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount));
        (bool valid, uint256 index) = MerkleProof.verify(merkleProof, merkleRoot, leaf);
        require(valid, "OMETA: Valid proof required.");
        require(!isClaimed(index), "OMETA: Tokens already claimed.");

        claimed.set(index);
        emit Claim(msg.sender, amount);

        _delegate(msg.sender, delegate);
        _transfer(address(this), msg.sender, amount);
    }

    /**
     * @dev Allows the owner to sweep unclaimed tokens after the claim period ends.
     * @param dest The address to sweep the tokens to.
     */
    function sweep(address dest) external onlyOwner {
        require(block.timestamp > claimPeriodEnds, "OMETA: Claim period not yet ended");
        _transfer(address(this), dest, balanceOf(address(this)));
    }

    /**
     * @dev Returns true if the claim at the given index in the merkle tree has already been made.
     * @param index The index into the merkle tree.
     */
    function isClaimed(uint256 index) public view returns (bool) {
        return claimed.get(index);
    }

    /**
     * @dev Sets the merkle root. Only callable if the root is not yet set.
     * @param _merkleRoot The merkle root to set.
     */
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        require(merkleRoot == bytes32(0), "OMETA: Merkle root already set");
        merkleRoot = _merkleRoot;
        emit MerkleRootChanged(_merkleRoot);
    }

    /**
     * @dev Disables restrictions on transfers
     */
    function disableRestrictedTransfers() external onlyOwner {
        restrictedTransfersEnabled = false;
    }

    /**
     * @dev Adds an exception to allow transfers from an address to another address
     * @param from The address allowed to perform transfers to `to`
     * @param to The only address allowed to receive transfers from `from`
     */
    function addAllowedTransfersMapping(address from, address to) external onlyOwner {
        transferFromToEnabled[from] = to;
    }

    /**
     * @dev Mints new tokens. Cannot mint more than 1B tokens.
     * @param dest The address to mint the new tokens to.
     * @param amount The quantity of tokens to mint.
     */
    function mint(address dest, uint256 amount) external onlyOwner {
        require(amount + totalSupply() <= maxSupply, "OMETA: Mint exceeds maximum amount");

        _mint(dest, amount);
    }

    /**
     * @dev Overrides transfer function for controlling transfers when there are restrictions applied.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override(ERC20) {
        if (restrictedTransfersEnabled == true && sender != address(this) && msg.sender != owner())
            require(recipient == transferFromToEnabled[msg.sender], "OMETA: You are not allowed to perform transfers");
        super._transfer(sender, recipient, amount);
    }

    // The following functions are overrides required by Solidity.

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Votes) {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount) internal override(ERC20, ERC20Votes) {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount) internal override(ERC20, ERC20Votes) {
        super._burn(account, amount);
    }
}
