// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
 * @title Gauge Weight Claims
 * @notice Distributes ALVA rewards for gauge weight voting.
 *
 * Off-chain, for each proposalId (e.g. a week), you compute a Merkle tree of leaves:
 *   leaf = keccak256(abi.encodePacked(proposalId, index, account, amount));
 *
 * - proposalId: uint256 identifying a specific epoch / week.
 * - index:      uint256 unique per leaf within that proposal.
 * - account:    address that should receive the tokens.
 * - amount:     uint256 amount of tokens assigned to that account for that proposal.
 */
contract GaugeWeightClaims is Ownable2Step {
    IERC20 public immutable ALVA;

    // proposalId => merkleRoot
    mapping(uint256 => bytes32) public merkleRoots;

    // proposalId => root version (increments each time root is set, starts at 0)
    mapping(uint256 => uint256) public rootVersions;

    // proposalId => whether any claims have been made (prevents root overwriting)
    mapping(uint256 => bool) public hasClaims;

    // proposalId => (wordIndex => bitmask) for claimed indices
    mapping(uint256 => mapping(uint256 => uint256)) private claimedBitMap;

    event MerkleRootSet(uint256 indexed proposalId, bytes32 indexed merkleRoot, uint256 indexed version);
    event Claimed(
        uint256 indexed proposalId,
        uint256 indexed index,
        address indexed account,
        uint256 amount
    );

    constructor(address _ALVA, address initialOwner) Ownable(initialOwner) {
        require(_ALVA != address(0), "ALVA zero address");
        ALVA = IERC20(_ALVA);
    }

    // ---------------- Admin functions ---------------- //

    /**
     * @notice Set or update merkle root for a proposal.
     * @param proposalId The proposal ID
     * @param merkleRoot The merkle root to set
     * @param version Must be greater than current version. Prevents overwriting with older roots.
     * @dev Once claims have been made for a proposal, the root cannot be changed.
     *      Version must always increment to prevent setting an older root.
     */
    /**
     * @notice Set or update merkle root for a proposal.
     * @param proposalId The proposal ID
     * @param merkleRoot The merkle root to set
     * @param version Must be greater than current version. Prevents overwriting with older roots.
     * @dev Once claims have been made for a proposal, the root cannot be changed.
     *      Version must always increment to prevent setting an older root.
     */
    function setMerkleRoot(
        uint256 proposalId,
        bytes32 merkleRoot,
        uint256 version
    ) external onlyOwner {
        require(proposalId != 0, "proposalId zero");
        require(merkleRoot != bytes32(0), "Root cannot be zero");
        
        uint256 currentVersion = rootVersions[proposalId];
        require(version > currentVersion, "Version must be greater than current");
        
        // Prevent overwriting if any claims have been made for this proposal
        require(!hasClaims[proposalId], "Cannot overwrite root after claims have been made");
        
        merkleRoots[proposalId] = merkleRoot;
        rootVersions[proposalId] = version;
        emit MerkleRootSet(proposalId, merkleRoot, version);
    }
    
    /**
     * @notice Get the current root version for a proposal
     * @param proposalId The proposal ID
     * @return The current version number (0 if never set)
     */
    function getRootVersion(uint256 proposalId) external view returns (uint256) {
        return rootVersions[proposalId];
    }

    function rescueTokens(address to, uint256 amount) external onlyOwner {
        require(to != address(0), "Zero address");
        ALVA.transfer(to, amount);
    }

    // ---------------- Claim tracking ---------------- //

    function _isClaimed(
        uint256 proposalId,
        uint256 index
    ) internal view returns (bool) {
        uint256 wordIndex = index / 256;
        uint256 bitIndex = index % 256;
        uint256 word = claimedBitMap[proposalId][wordIndex];
        uint256 mask = (1 << bitIndex);
        return word & mask == mask;
    }

    function isClaimed(
        uint256 proposalId,
        uint256 index
    ) external view returns (bool) {
        return _isClaimed(proposalId, index);
    }

    function _setClaimed(uint256 proposalId, uint256 index) internal {
        uint256 wordIndex = index / 256;
        uint256 bitIndex = index % 256;
        claimedBitMap[proposalId][wordIndex] |= (1 << bitIndex);
    }

    // ---------------- Internal claim core ---------------- //

    function _claim(
        uint256 proposalId,
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) internal {
        bytes32 root = merkleRoots[proposalId];
        require(root != bytes32(0), "Root not set");
        require(!_isClaimed(proposalId, index), "Already claimed");

        bytes32 node = keccak256(
            abi.encodePacked(proposalId, index, account, amount)
        );

        require(MerkleProof.verify(merkleProof, root, node), "Invalid proof");

        _setClaimed(proposalId, index);
        
        // Mark that claims have been made for this proposal (prevents root overwriting)
        hasClaims[proposalId] = true;

        require(ALVA.transfer(account, amount), "ALVA transfer failed");

        emit Claimed(proposalId, index, account, amount);
    }

    // ---------------- Public single-claim ---------------- //

    function claim(
        uint256 proposalId,
        uint256 index,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external {
        address account = msg.sender;
        _claim(proposalId, index, account, amount, merkleProof);
    }

    // ---------------- Public batch-claim ---------------- //

    /**
     * @notice Batch claim for multiple proposals / weeks.
     *         Reverts entirely if ANY individual claim would revert.
     *
     * Frontend should only include entries where isClaimed(...) == false.
     * All claims must be for msg.sender.
     */
    function batchClaim(
        uint256[] calldata proposalIds,
        uint256[] calldata indices,
        uint256[] calldata amounts,
        bytes32[][] calldata merkleProofs
    ) external {
        address account = msg.sender;
        uint256 len = proposalIds.length;
        require(
            len == indices.length &&
                len == amounts.length &&
                len == merkleProofs.length,
            "Length mismatch"
        );

        for (uint256 i = 0; i < len; i++) {
            _claim(
                proposalIds[i],
                indices[i],
                account,
                amounts[i],
                merkleProofs[i]
            );
        }
    }
}
