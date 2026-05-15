// Sources flattened with hardhat v2.24.1 https://hardhat.org

// SPDX-License-Identifier: Apache-2.0 AND CC0-1.0 AND MIT AND UNLICENSED

// File @openzeppelin/contracts/utils/Context.sol@v4.8.3

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


// File @limitbreak/creator-token-standards/src/access/OwnablePermissions.sol@v5.0.0

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.4;

abstract contract OwnablePermissions is Context {
    function _requireCallerIsContractOwner() internal view virtual;
}


// File @limitbreak/creator-token-standards/src/utils/AutomaticValidatorTransferApproval.sol@v5.0.0

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title AutomaticValidatorTransferApproval
 * @author Limit Break, Inc.
 * @notice Base contract mix-in that provides boilerplate code giving the contract owner the
 *         option to automatically approve a 721-C transfer validator implementation for transfers.
 */
abstract contract AutomaticValidatorTransferApproval is OwnablePermissions {

    /// @dev Emitted when the automatic approval flag is modified by the creator.
    event AutomaticApprovalOfTransferValidatorSet(bool autoApproved);

    /// @dev If true, the collection's transfer validator is automatically approved to transfer holder's tokens.
    bool public autoApproveTransfersFromValidator;

    /**
     * @notice Sets if the transfer validator is automatically approved as an operator for all token owners.
     * 
     * @dev    Throws when the caller is not the contract owner.
     * 
     * @param autoApprove If true, the collection's transfer validator will be automatically approved to
     *                    transfer holder's tokens.
     */
    function setAutomaticApprovalOfTransfersFromValidator(bool autoApprove) external {
        _requireCallerIsContractOwner();
        autoApproveTransfersFromValidator = autoApprove;
        emit AutomaticApprovalOfTransferValidatorSet(autoApprove);
    }
}


// File @limitbreak/creator-token-standards/src/interfaces/ICreatorToken.sol@v5.0.0

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.4;

interface ICreatorToken {
    event TransferValidatorUpdated(address oldValidator, address newValidator);
    function getTransferValidator() external view returns (address validator);
    function setTransferValidator(address validator) external;
    function getTransferValidationFunction() external view returns (bytes4 functionSignature, bool isViewFunction);
}


// File @limitbreak/creator-token-standards/src/interfaces/ICreatorTokenLegacy.sol@v5.0.0

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.4;

interface ICreatorTokenLegacy {
    event TransferValidatorUpdated(address oldValidator, address newValidator);
    function getTransferValidator() external view returns (address validator);
    function setTransferValidator(address validator) external;
}


// File @limitbreak/creator-token-standards/src/interfaces/ITransferValidator.sol@v5.0.0

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.4;

interface ITransferValidator {
    function applyCollectionTransferPolicy(address caller, address from, address to) external view;
    function validateTransfer(address caller, address from, address to) external view;
    function validateTransfer(address caller, address from, address to, uint256 tokenId) external view;
    function validateTransfer(address caller, address from, address to, uint256 tokenId, uint256 amount) external;

    function beforeAuthorizedTransfer(address operator, address token, uint256 tokenId) external;
    function afterAuthorizedTransfer(address token, uint256 tokenId) external;
    function beforeAuthorizedTransfer(address operator, address token) external;
    function afterAuthorizedTransfer(address token) external;
    function beforeAuthorizedTransfer(address token, uint256 tokenId) external;
    function beforeAuthorizedTransferWithAmount(address token, uint256 tokenId, uint256 amount) external;
    function afterAuthorizedTransferWithAmount(address token, uint256 tokenId) external;
}


// File @limitbreak/creator-token-standards/src/interfaces/ITransferValidatorSetTokenType.sol@v5.0.0

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.4;

interface ITransferValidatorSetTokenType {
    function setTokenTypeOfCollection(address collection, uint16 tokenType) external;
}


// File @limitbreak/creator-token-standards/src/utils/TransferValidation.sol@v5.0.0

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title TransferValidation
 * @author Limit Break, Inc.
 * @notice A mix-in that can be combined with ERC-721 contracts to provide more granular hooks.
 * Openzeppelin's ERC721 contract only provides hooks for before and after transfer.  This allows
 * developers to validate or customize transfers within the context of a mint, a burn, or a transfer.
 */
abstract contract TransferValidation is Context {
    
    /// @dev Thrown when the from and to address are both the zero address.
    error ShouldNotMintToBurnAddress();

    /*************************************************************************/
    /*                      Transfers Without Amounts                        */
    /*************************************************************************/

    /// @dev Inheriting contracts should call this function in the _beforeTokenTransfer function to get more granular hooks.
    function _validateBeforeTransfer(address from, address to, uint256 tokenId) internal virtual {
        bool fromZeroAddress = from == address(0);
        bool toZeroAddress = to == address(0);

        if(fromZeroAddress && toZeroAddress) {
            revert ShouldNotMintToBurnAddress();
        } else if(fromZeroAddress) {
            _preValidateMint(_msgSender(), to, tokenId, msg.value);
        } else if(toZeroAddress) {
            _preValidateBurn(_msgSender(), from, tokenId, msg.value);
        } else {
            _preValidateTransfer(_msgSender(), from, to, tokenId, msg.value);
        }
    }

    /// @dev Inheriting contracts should call this function in the _afterTokenTransfer function to get more granular hooks.
    function _validateAfterTransfer(address from, address to, uint256 tokenId) internal virtual {
        bool fromZeroAddress = from == address(0);
        bool toZeroAddress = to == address(0);

        if(fromZeroAddress && toZeroAddress) {
            revert ShouldNotMintToBurnAddress();
        } else if(fromZeroAddress) {
            _postValidateMint(_msgSender(), to, tokenId, msg.value);
        } else if(toZeroAddress) {
            _postValidateBurn(_msgSender(), from, tokenId, msg.value);
        } else {
            _postValidateTransfer(_msgSender(), from, to, tokenId, msg.value);
        }
    }

    /// @dev Optional validation hook that fires before a mint
    function _preValidateMint(address caller, address to, uint256 tokenId, uint256 value) internal virtual {}

    /// @dev Optional validation hook that fires after a mint
    function _postValidateMint(address caller, address to, uint256 tokenId, uint256 value) internal virtual {}

    /// @dev Optional validation hook that fires before a burn
    function _preValidateBurn(address caller, address from, uint256 tokenId, uint256 value) internal virtual {}

    /// @dev Optional validation hook that fires after a burn
    function _postValidateBurn(address caller, address from, uint256 tokenId, uint256 value) internal virtual {}

    /// @dev Optional validation hook that fires before a transfer
    function _preValidateTransfer(address caller, address from, address to, uint256 tokenId, uint256 value) internal virtual {}

    /// @dev Optional validation hook that fires after a transfer
    function _postValidateTransfer(address caller, address from, address to, uint256 tokenId, uint256 value) internal virtual {}

    /*************************************************************************/
    /*                         Transfers With Amounts                        */
    /*************************************************************************/

    /// @dev Inheriting contracts should call this function in the _beforeTokenTransfer function to get more granular hooks.
    function _validateBeforeTransfer(address from, address to, uint256 tokenId, uint256 amount) internal virtual {
        bool fromZeroAddress = from == address(0);
        bool toZeroAddress = to == address(0);

        if(fromZeroAddress && toZeroAddress) {
            revert ShouldNotMintToBurnAddress();
        } else if(fromZeroAddress) {
            _preValidateMint(_msgSender(), to, tokenId, amount, msg.value);
        } else if(toZeroAddress) {
            _preValidateBurn(_msgSender(), from, tokenId, amount, msg.value);
        } else {
            _preValidateTransfer(_msgSender(), from, to, tokenId, amount, msg.value);
        }
    }

    /// @dev Inheriting contracts should call this function in the _afterTokenTransfer function to get more granular hooks.
    function _validateAfterTransfer(address from, address to, uint256 tokenId, uint256 amount) internal virtual {
        bool fromZeroAddress = from == address(0);
        bool toZeroAddress = to == address(0);

        if(fromZeroAddress && toZeroAddress) {
            revert ShouldNotMintToBurnAddress();
        } else if(fromZeroAddress) {
            _postValidateMint(_msgSender(), to, tokenId, amount, msg.value);
        } else if(toZeroAddress) {
            _postValidateBurn(_msgSender(), from, tokenId, amount, msg.value);
        } else {
            _postValidateTransfer(_msgSender(), from, to, tokenId, amount, msg.value);
        }
    }

    /// @dev Optional validation hook that fires before a mint
    function _preValidateMint(address caller, address to, uint256 tokenId, uint256 amount, uint256 value) internal virtual {}

    /// @dev Optional validation hook that fires after a mint
    function _postValidateMint(address caller, address to, uint256 tokenId, uint256 amount, uint256 value) internal virtual {}

    /// @dev Optional validation hook that fires before a burn
    function _preValidateBurn(address caller, address from, uint256 tokenId, uint256 amount, uint256 value) internal virtual {}

    /// @dev Optional validation hook that fires after a burn
    function _postValidateBurn(address caller, address from, uint256 tokenId, uint256 amount, uint256 value) internal virtual {}

    /// @dev Optional validation hook that fires before a transfer
    function _preValidateTransfer(address caller, address from, address to, uint256 tokenId, uint256 amount, uint256 value) internal virtual {}

    /// @dev Optional validation hook that fires after a transfer
    function _postValidateTransfer(address caller, address from, address to, uint256 tokenId, uint256 amount, uint256 value) internal virtual {}
}


// File @limitbreak/creator-token-standards/src/utils/CreatorTokenBase.sol@v5.0.0

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.4;






/**
 * @title CreatorTokenBase
 * @author Limit Break, Inc.
 * @notice CreatorTokenBaseV3 is an abstract contract that provides basic functionality for managing token 
 * transfer policies through an implementation of ICreatorTokenTransferValidator/ICreatorTokenTransferValidatorV2/ICreatorTokenTransferValidatorV3. 
 * This contract is intended to be used as a base for creator-specific token contracts, enabling customizable transfer 
 * restrictions and security policies.
 *
 * <h4>Features:</h4>
 * <ul>Ownable: This contract can have an owner who can set and update the transfer validator.</ul>
 * <ul>TransferValidation: Implements the basic token transfer validation interface.</ul>
 *
 * <h4>Benefits:</h4>
 * <ul>Provides a flexible and modular way to implement custom token transfer restrictions and security policies.</ul>
 * <ul>Allows creators to enforce policies such as account and codehash blacklists, whitelists, and graylists.</ul>
 * <ul>Can be easily integrated into other token contracts as a base contract.</ul>
 *
 * <h4>Intended Usage:</h4>
 * <ul>Use as a base contract for creator token implementations that require advanced transfer restrictions and 
 *   security policies.</ul>
 * <ul>Set and update the ICreatorTokenTransferValidator implementation contract to enforce desired policies for the 
 *   creator token.</ul>
 *
 * <h4>Compatibility:</h4>
 * <ul>Backward and Forward Compatible - V1/V2/V3 Creator Token Base will work with V1/V2/V3 Transfer Validators.</ul>
 */
abstract contract CreatorTokenBase is OwnablePermissions, TransferValidation, ICreatorToken {

    /// @dev Thrown when setting a transfer validator address that has no deployed code.
    error CreatorTokenBase__InvalidTransferValidatorContract();

    /// @dev The default transfer validator that will be used if no transfer validator has been set by the creator.
    address public constant DEFAULT_TRANSFER_VALIDATOR = address(0x721C008fdff27BF06E7E123956E2Fe03B63342e3);

    /// @dev Used to determine if the default transfer validator is applied.
    /// @dev Set to true when the creator sets a transfer validator address.
    bool private isValidatorInitialized;
    /// @dev Address of the transfer validator to apply to transactions.
    address private transferValidator;

    constructor() {
        _emitDefaultTransferValidator();
        _registerTokenType(DEFAULT_TRANSFER_VALIDATOR);
    }

    /**
     * @notice Sets the transfer validator for the token contract.
     *
     * @dev    Throws when provided validator contract is not the zero address and does not have code.
     * @dev    Throws when the caller is not the contract owner.
     *
     * @dev    <h4>Postconditions:</h4>
     *         1. The transferValidator address is updated.
     *         2. The "TransferValidatorUpdated" event is emitted.
     *
     * @param transferValidator_ The address of the transfer validator contract.
     */
    function setTransferValidator(address transferValidator_) public {
        _requireCallerIsContractOwner();

        bool isValidTransferValidator = transferValidator_.code.length > 0;

        if(transferValidator_ != address(0) && !isValidTransferValidator) {
            revert CreatorTokenBase__InvalidTransferValidatorContract();
        }

        emit TransferValidatorUpdated(address(getTransferValidator()), transferValidator_);

        isValidatorInitialized = true;
        transferValidator = transferValidator_;

        _registerTokenType(transferValidator_);
    }

    /**
     * @notice Returns the transfer validator contract address for this token contract.
     */
    function getTransferValidator() public view override returns (address validator) {
        validator = transferValidator;

        if (validator == address(0)) {
            if (!isValidatorInitialized) {
                validator = DEFAULT_TRANSFER_VALIDATOR;
            }
        }
    }

    /**
     * @dev Pre-validates a token transfer, reverting if the transfer is not allowed by this token's security policy.
     *      Inheriting contracts are responsible for overriding the _beforeTokenTransfer function, or its equivalent
     *      and calling _validateBeforeTransfer so that checks can be properly applied during token transfers.
     *
     * @dev Be aware that if the msg.sender is the transfer validator, the transfer is automatically permitted, as the
     *      transfer validator is expected to pre-validate the transfer.
     *
     * @dev Throws when the transfer doesn't comply with the collection's transfer policy, if the transferValidator is
     *      set to a non-zero address.
     *
     * @param caller  The address of the caller.
     * @param from    The address of the sender.
     * @param to      The address of the receiver.
     * @param tokenId The token id being transferred.
     */
    function _preValidateTransfer(
        address caller, 
        address from, 
        address to, 
        uint256 tokenId, 
        uint256 /*value*/) internal virtual override {
        address validator = getTransferValidator();

        if (validator != address(0)) {
            if (msg.sender == validator) {
                return;
            }

            ITransferValidator(validator).validateTransfer(caller, from, to, tokenId);
        }
    }

    /**
     * @dev Pre-validates a token transfer, reverting if the transfer is not allowed by this token's security policy.
     *      Inheriting contracts are responsible for overriding the _beforeTokenTransfer function, or its equivalent
     *      and calling _validateBeforeTransfer so that checks can be properly applied during token transfers.
     *
     * @dev Be aware that if the msg.sender is the transfer validator, the transfer is automatically permitted, as the
     *      transfer validator is expected to pre-validate the transfer.
     * 
     * @dev Used for ERC20 and ERC1155 token transfers which have an amount value to validate in the transfer validator.
     * @dev The "tokenId" for ERC20 tokens should be set to "0".
     *
     * @dev Throws when the transfer doesn't comply with the collection's transfer policy, if the transferValidator is
     *      set to a non-zero address.
     *
     * @param caller  The address of the caller.
     * @param from    The address of the sender.
     * @param to      The address of the receiver.
     * @param tokenId The token id being transferred.
     * @param amount  The amount of token being transferred.
     */
    function _preValidateTransfer(
        address caller, 
        address from, 
        address to, 
        uint256 tokenId, 
        uint256 amount,
        uint256 /*value*/) internal virtual override {
        address validator = getTransferValidator();

        if (validator != address(0)) {
            if (msg.sender == validator) {
                return;
            }

            ITransferValidator(validator).validateTransfer(caller, from, to, tokenId, amount);
        }
    }

    function _tokenType() internal virtual pure returns(uint16);

    function _registerTokenType(address validator) internal {
        if (validator != address(0)) {
            uint256 validatorCodeSize;
            assembly {
                validatorCodeSize := extcodesize(validator)
            }
            if(validatorCodeSize > 0) {
                try ITransferValidatorSetTokenType(validator).setTokenTypeOfCollection(address(this), _tokenType()) {
                } catch { }
            }
        }
    }

    /**
     * @dev  Used during contract deployment for constructable and cloneable creator tokens
     * @dev  to emit the "TransferValidatorUpdated" event signaling the validator for the contract
     * @dev  is the default transfer validator.
     */
    function _emitDefaultTransferValidator() internal {
        emit TransferValidatorUpdated(address(0), DEFAULT_TRANSFER_VALIDATOR);
    }
}


// File @limitbreak/permit-c/src/Constants.sol@v1.0.0

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.4;

/// @dev Constant bytes32 value of 0x000...000
bytes32 constant ZERO_BYTES32 = bytes32(0);

/// @dev Constant value of 0
uint256 constant ZERO = 0;
/// @dev Constant value of 1
uint256 constant ONE = 1;

/// @dev Constant value representing an open order in storage
uint8 constant ORDER_STATE_OPEN = 0;
/// @dev Constant value representing a filled order in storage
uint8 constant ORDER_STATE_FILLED = 1;
/// @dev Constant value representing a cancelled order in storage
uint8 constant ORDER_STATE_CANCELLED = 2;

/// @dev Constant value representing the ERC721 token type for signatures and transfer hooks
uint256 constant TOKEN_TYPE_ERC721 = 721;
/// @dev Constant value representing the ERC1155 token type for signatures and transfer hooks
uint256 constant TOKEN_TYPE_ERC1155 = 1155;
/// @dev Constant value representing the ERC20 token type for signatures and transfer hooks
uint256 constant TOKEN_TYPE_ERC20 = 20;

/// @dev Constant value to mask the upper bits of a signature that uses a packed "vs" value to extract "s"
bytes32 constant UPPER_BIT_MASK = 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

/// @dev EIP-712 typehash used for validating signature based stored approvals
bytes32 constant UPDATE_APPROVAL_TYPEHASH =
    keccak256("UpdateApprovalBySignature(uint256 tokenType,address token,uint256 id,uint256 amount,uint256 nonce,address operator,uint256 approvalExpiration,uint256 sigDeadline,uint256 masterNonce)");

/// @dev EIP-712 typehash used for validating a single use permit without additional data
bytes32 constant SINGLE_USE_PERMIT_TYPEHASH =
    keccak256("PermitTransferFrom(uint256 tokenType,address token,uint256 id,uint256 amount,uint256 nonce,address operator,uint256 expiration,uint256 masterNonce)");

/// @dev EIP-712 typehash used for validating a single use permit with additional data
string constant SINGLE_USE_PERMIT_TRANSFER_ADVANCED_TYPEHASH_STUB =
    "PermitTransferFromWithAdditionalData(uint256 tokenType,address token,uint256 id,uint256 amount,uint256 nonce,address operator,uint256 expiration,uint256 masterNonce,";

/// @dev EIP-712 typehash used for validating an order permit that updates storage as it fills
string constant PERMIT_ORDER_ADVANCED_TYPEHASH_STUB =
    "PermitOrderWithAdditionalData(uint256 tokenType,address token,uint256 id,uint256 amount,uint256 salt,address operator,uint256 expiration,uint256 masterNonce,";

/// @dev Pausable flag for stored approval transfers of ERC721 assets
uint256 constant PAUSABLE_APPROVAL_TRANSFER_FROM_ERC721 = 1 << 0;
/// @dev Pausable flag for stored approval transfers of ERC1155 assets
uint256 constant PAUSABLE_APPROVAL_TRANSFER_FROM_ERC1155 = 1 << 1;
/// @dev Pausable flag for stored approval transfers of ERC20 assets
uint256 constant PAUSABLE_APPROVAL_TRANSFER_FROM_ERC20 = 1 << 2;

/// @dev Pausable flag for single use permit transfers of ERC721 assets
uint256 constant PAUSABLE_PERMITTED_TRANSFER_FROM_ERC721 = 1 << 3;
/// @dev Pausable flag for single use permit transfers of ERC1155 assets
uint256 constant PAUSABLE_PERMITTED_TRANSFER_FROM_ERC1155 = 1 << 4;
/// @dev Pausable flag for single use permit transfers of ERC20 assets
uint256 constant PAUSABLE_PERMITTED_TRANSFER_FROM_ERC20 = 1 << 5;

/// @dev Pausable flag for order fill transfers of ERC1155 assets
uint256 constant PAUSABLE_ORDER_TRANSFER_FROM_ERC1155 = 1 << 6;
/// @dev Pausable flag for order fill transfers of ERC20 assets
uint256 constant PAUSABLE_ORDER_TRANSFER_FROM_ERC20 = 1 << 7;


// File erc721a/contracts/IERC721A.sol@v4.2.3

// Original license: SPDX_License_Identifier: MIT
// ERC721A Contracts v4.2.3
// Creator: Chiru Labs

pragma solidity ^0.8.4;

/**
 * @dev Interface of ERC721A.
 */
interface IERC721A {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by "from".
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the
     * ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    /**
     * The "quantity" minted with ERC2309 exceeds the safety limit.
     */
    error MintERC2309QuantityExceedsLimit();

    /**
     * The "extraData" cannot be set on an unintialized ownership slot.
     */
    error OwnershipNotInitializedForExtraData();

    // =============================================================
    //                            STRUCTS
    // =============================================================

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Stores the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
        // Arbitrary data similar to "startTimestamp" that can be set via {_extraData}.
        uint24 extraData;
    }

    // =============================================================
    //                         TOKEN COUNTERS
    // =============================================================

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() external view returns (uint256);

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * "interfaceId". See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // =============================================================
    //                            IERC721
    // =============================================================

    /**
     * @dev Emitted when "tokenId" token is transferred from "from" to "to".
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when "owner" enables "approved" to manage the "tokenId" token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when "owner" enables or disables
     * ("approved") "operator" to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in "owner"'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the "tokenId" token.
     *
     * Requirements:
     *
     * - "tokenId" must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers "tokenId" token from "from" to "to",
     * checking first that contract recipients are aware of the ERC721 protocol
     * to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - "from" cannot be the zero address.
     * - "to" cannot be the zero address.
     * - "tokenId" token must exist and be owned by "from".
     * - If the caller is not "from", it must be have been allowed to move
     * this token by either {approve} or {setApprovalForAll}.
     * - If "to" refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external payable;

    /**
     * @dev Equivalent to "safeTransferFrom(from, to, tokenId, '')".
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @dev Transfers "tokenId" from "from" to "to".
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom}
     * whenever possible.
     *
     * Requirements:
     *
     * - "from" cannot be the zero address.
     * - "to" cannot be the zero address.
     * - "tokenId" token must be owned by "from".
     * - If the caller is not "from", it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @dev Gives permission to "to" to transfer "tokenId" token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - "tokenId" must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external payable;

    /**
     * @dev Approve or remove "operator" as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
     *
     * Requirements:
     *
     * - The "operator" cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for "tokenId" token.
     *
     * Requirements:
     *
     * - "tokenId" must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the "operator" is allowed to manage all of the assets of "owner".
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for "tokenId" token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);

    // =============================================================
    //                           IERC2309
    // =============================================================

    /**
     * @dev Emitted when tokens in "fromTokenId" to "toTokenId"
     * (inclusive) is transferred from "from" to "to", as defined in the
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309) standard.
     *
     * See {_mintERC2309} for more details.
     */
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed from, address indexed to);
}


// File erc721a/contracts/ERC721A.sol@v4.2.3

// Original license: SPDX_License_Identifier: MIT
// ERC721A Contracts v4.2.3
// Creator: Chiru Labs

pragma solidity ^0.8.4;

/**
 * @dev Interface of ERC721 token receiver.
 */
interface ERC721A__IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

/**
 * @title ERC721A
 *
 * @dev Implementation of the [ERC721](https://eips.ethereum.org/EIPS/eip-721)
 * Non-Fungible Token Standard, including the Metadata extension.
 * Optimized for lower gas during batch mints.
 *
 * Token IDs are minted in sequential order (e.g. 0, 1, 2, 3, ...)
 * starting from "_startTokenId()".
 *
 * Assumptions:
 *
 * - An owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 * - The maximum token ID cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721A is IERC721A {
    // Bypass for a "--via-ir" bug (https://github.com/chiru-labs/ERC721A/pull/364).
    struct TokenApprovalRef {
        address value;
    }

    // =============================================================
    //                           CONSTANTS
    // =============================================================

    // Mask of an entry in packed address data.
    uint256 private constant _BITMASK_ADDRESS_DATA_ENTRY = (1 << 64) - 1;

    // The bit position of "numberMinted" in packed address data.
    uint256 private constant _BITPOS_NUMBER_MINTED = 64;

    // The bit position of "numberBurned" in packed address data.
    uint256 private constant _BITPOS_NUMBER_BURNED = 128;

    // The bit position of "aux" in packed address data.
    uint256 private constant _BITPOS_AUX = 192;

    // Mask of all 256 bits in packed address data except the 64 bits for "aux".
    uint256 private constant _BITMASK_AUX_COMPLEMENT = (1 << 192) - 1;

    // The bit position of "startTimestamp" in packed ownership.
    uint256 private constant _BITPOS_START_TIMESTAMP = 160;

    // The bit mask of the "burned" bit in packed ownership.
    uint256 private constant _BITMASK_BURNED = 1 << 224;

    // The bit position of the "nextInitialized" bit in packed ownership.
    uint256 private constant _BITPOS_NEXT_INITIALIZED = 225;

    // The bit mask of the "nextInitialized" bit in packed ownership.
    uint256 private constant _BITMASK_NEXT_INITIALIZED = 1 << 225;

    // The bit position of "extraData" in packed ownership.
    uint256 private constant _BITPOS_EXTRA_DATA = 232;

    // Mask of all 256 bits in a packed ownership except the 24 bits for "extraData".
    uint256 private constant _BITMASK_EXTRA_DATA_COMPLEMENT = (1 << 232) - 1;

    // The mask of the lower 160 bits for addresses.
    uint256 private constant _BITMASK_ADDRESS = (1 << 160) - 1;

    // The maximum "quantity" that can be minted with {_mintERC2309}.
    // This limit is to prevent overflows on the address data entries.
    // For a limit of 5000, a total of 3.689e15 calls to {_mintERC2309}
    // is required to cause an overflow, which is unrealistic.
    uint256 private constant _MAX_MINT_ERC2309_QUANTITY_LIMIT = 5000;

    // The "Transfer" event signature is given by:
    // "keccak256(bytes("Transfer(address,address,uint256)"))".
    bytes32 private constant _TRANSFER_EVENT_SIGNATURE =
        0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;

    // =============================================================
    //                            STORAGE
    // =============================================================

    // The next token ID to be minted.
    uint256 private _currentIndex;

    // The number of tokens burned.
    uint256 private _burnCounter;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned.
    // See {_packedOwnershipOf} implementation for details.
    //
    // Bits Layout:
    // - [0..159]   "addr"
    // - [160..223] "startTimestamp"
    // - [224]      "burned"
    // - [225]      "nextInitialized"
    // - [232..255] "extraData"
    mapping(uint256 => uint256) private _packedOwnerships;

    // Mapping owner address to address data.
    //
    // Bits Layout:
    // - [0..63]    "balance"
    // - [64..127]  "numberMinted"
    // - [128..191] "numberBurned"
    // - [192..255] "aux"
    mapping(address => uint256) private _packedAddressData;

    // Mapping from token ID to approved address.
    mapping(uint256 => TokenApprovalRef) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // =============================================================
    //                          CONSTRUCTOR
    // =============================================================

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _currentIndex = _startTokenId();
    }

    // =============================================================
    //                   TOKEN COUNTING OPERATIONS
    // =============================================================

    /**
     * @dev Returns the starting token ID.
     * To change the starting token ID, please override this function.
     */
    function _startTokenId() internal view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev Returns the next token ID to be minted.
     */
    function _nextTokenId() internal view virtual returns (uint256) {
        return _currentIndex;
    }

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than "_currentIndex - _startTokenId()" times.
        unchecked {
            return _currentIndex - _burnCounter - _startTokenId();
        }
    }

    /**
     * @dev Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view virtual returns (uint256) {
        // Counter underflow is impossible as "_currentIndex" does not decrement,
        // and it is initialized to "_startTokenId()".
        unchecked {
            return _currentIndex - _startTokenId();
        }
    }

    /**
     * @dev Returns the total number of tokens burned.
     */
    function _totalBurned() internal view virtual returns (uint256) {
        return _burnCounter;
    }

    // =============================================================
    //                    ADDRESS DATA OPERATIONS
    // =============================================================

    /**
     * @dev Returns the number of tokens in "owner"'s account.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return _packedAddressData[owner] & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens minted by "owner".
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> _BITPOS_NUMBER_MINTED) & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens burned by or on behalf of "owner".
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> _BITPOS_NUMBER_BURNED) & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the auxiliary data for "owner". (e.g. number of whitelist mint slots used).
     */
    function _getAux(address owner) internal view returns (uint64) {
        return uint64(_packedAddressData[owner] >> _BITPOS_AUX);
    }

    /**
     * Sets the auxiliary data for "owner". (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(address owner, uint64 aux) internal virtual {
        uint256 packed = _packedAddressData[owner];
        uint256 auxCasted;
        // Cast "aux" with assembly to avoid redundant masking.
        assembly {
            auxCasted := aux
        }
        packed = (packed & _BITMASK_AUX_COMPLEMENT) | (auxCasted << _BITPOS_AUX);
        _packedAddressData[owner] = packed;
    }

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * "interfaceId". See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        // The interface IDs are constants representing the first 4 bytes
        // of the XOR of all function selectors in the interface.
        // See: [ERC165](https://eips.ethereum.org/EIPS/eip-165)
        // (e.g. "bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)")
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
            interfaceId == 0x5b5e139f; // ERC165 interface ID for ERC721Metadata.
    }

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

    /**
     * @dev Returns the token collection name.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for "tokenId" token.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the "baseURI" and the "tokenId". Empty
     * by default, it can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return '';
    }

    // =============================================================
    //                     OWNERSHIPS OPERATIONS
    // =============================================================

    /**
     * @dev Returns the owner of the "tokenId" token.
     *
     * Requirements:
     *
     * - "tokenId" must exist.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return address(uint160(_packedOwnershipOf(tokenId)));
    }

    /**
     * @dev Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around over time.
     */
    function _ownershipOf(uint256 tokenId) internal view virtual returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnershipOf(tokenId));
    }

    /**
     * @dev Returns the unpacked "TokenOwnership" struct at "index".
     */
    function _ownershipAt(uint256 index) internal view virtual returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnerships[index]);
    }

    /**
     * @dev Initializes the ownership slot minted at "index" for efficiency purposes.
     */
    function _initializeOwnershipAt(uint256 index) internal virtual {
        if (_packedOwnerships[index] == 0) {
            _packedOwnerships[index] = _packedOwnershipOf(index);
        }
    }

    /**
     * Returns the packed ownership data of "tokenId".
     */
    function _packedOwnershipOf(uint256 tokenId) private view returns (uint256) {
        uint256 curr = tokenId;

        unchecked {
            if (_startTokenId() <= curr)
                if (curr < _currentIndex) {
                    uint256 packed = _packedOwnerships[curr];
                    // If not burned.
                    if (packed & _BITMASK_BURNED == 0) {
                        // Invariant:
                        // There will always be an initialized ownership slot
                        // (i.e. "ownership.addr != address(0) && ownership.burned == false")
                        // before an unintialized ownership slot
                        // (i.e. "ownership.addr == address(0) && ownership.burned == false")
                        // Hence, "curr" will not underflow.
                        //
                        // We can directly compare the packed value.
                        // If the address is zero, packed will be zero.
                        while (packed == 0) {
                            packed = _packedOwnerships[--curr];
                        }
                        return packed;
                    }
                }
        }
        revert OwnerQueryForNonexistentToken();
    }

    /**
     * @dev Returns the unpacked "TokenOwnership" struct from "packed".
     */
    function _unpackedOwnership(uint256 packed) private pure returns (TokenOwnership memory ownership) {
        ownership.addr = address(uint160(packed));
        ownership.startTimestamp = uint64(packed >> _BITPOS_START_TIMESTAMP);
        ownership.burned = packed & _BITMASK_BURNED != 0;
        ownership.extraData = uint24(packed >> _BITPOS_EXTRA_DATA);
    }

    /**
     * @dev Packs ownership data into a single uint256.
     */
    function _packOwnershipData(address owner, uint256 flags) private view returns (uint256 result) {
        assembly {
            // Mask "owner" to the lower 160 bits, in case the upper bits somehow aren't clean.
            owner := and(owner, _BITMASK_ADDRESS)
            // "owner | (block.timestamp << _BITPOS_START_TIMESTAMP) | flags".
            result := or(owner, or(shl(_BITPOS_START_TIMESTAMP, timestamp()), flags))
        }
    }

    /**
     * @dev Returns the "nextInitialized" flag set if "quantity" equals 1.
     */
    function _nextInitializedFlag(uint256 quantity) private pure returns (uint256 result) {
        // For branchless setting of the "nextInitialized" flag.
        assembly {
            // "(quantity == 1) << _BITPOS_NEXT_INITIALIZED".
            result := shl(_BITPOS_NEXT_INITIALIZED, eq(quantity, 1))
        }
    }

    // =============================================================
    //                      APPROVAL OPERATIONS
    // =============================================================

    /**
     * @dev Gives permission to "to" to transfer "tokenId" token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - "tokenId" must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) public payable virtual override {
        address owner = ownerOf(tokenId);

        if (_msgSenderERC721A() != owner)
            if (!isApprovedForAll(owner, _msgSenderERC721A())) {
                revert ApprovalCallerNotOwnerNorApproved();
            }

        _tokenApprovals[tokenId].value = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev Returns the account approved for "tokenId" token.
     *
     * Requirements:
     *
     * - "tokenId" must exist.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId].value;
    }

    /**
     * @dev Approve or remove "operator" as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
     *
     * Requirements:
     *
     * - The "operator" cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _operatorApprovals[_msgSenderERC721A()][operator] = approved;
        emit ApprovalForAll(_msgSenderERC721A(), operator, approved);
    }

    /**
     * @dev Returns if the "operator" is allowed to manage all of the assets of "owner".
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev Returns whether "tokenId" exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted. See {_mint}.
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return
            _startTokenId() <= tokenId &&
            tokenId < _currentIndex && // If within bounds,
            _packedOwnerships[tokenId] & _BITMASK_BURNED == 0; // and not burned.
    }

    /**
     * @dev Returns whether "msgSender" is equal to "approvedAddress" or "owner".
     */
    function _isSenderApprovedOrOwner(
        address approvedAddress,
        address owner,
        address msgSender
    ) private pure returns (bool result) {
        assembly {
            // Mask "owner" to the lower 160 bits, in case the upper bits somehow aren't clean.
            owner := and(owner, _BITMASK_ADDRESS)
            // Mask "msgSender" to the lower 160 bits, in case the upper bits somehow aren't clean.
            msgSender := and(msgSender, _BITMASK_ADDRESS)
            // "msgSender == owner || msgSender == approvedAddress".
            result := or(eq(msgSender, owner), eq(msgSender, approvedAddress))
        }
    }

    /**
     * @dev Returns the storage slot and value for the approved address of "tokenId".
     */
    function _getApprovedSlotAndAddress(uint256 tokenId)
        private
        view
        returns (uint256 approvedAddressSlot, address approvedAddress)
    {
        TokenApprovalRef storage tokenApproval = _tokenApprovals[tokenId];
        // The following is equivalent to "approvedAddress = _tokenApprovals[tokenId].value".
        assembly {
            approvedAddressSlot := tokenApproval.slot
            approvedAddress := sload(approvedAddressSlot)
        }
    }

    // =============================================================
    //                      TRANSFER OPERATIONS
    // =============================================================

    /**
     * @dev Transfers "tokenId" from "from" to "to".
     *
     * Requirements:
     *
     * - "from" cannot be the zero address.
     * - "to" cannot be the zero address.
     * - "tokenId" token must be owned by "from".
     * - If the caller is not "from", it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable virtual override {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        if (address(uint160(prevOwnershipPacked)) != from) revert TransferFromIncorrectOwner();

        (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedSlotAndAddress(tokenId);

        // The nested ifs save around 20+ gas over a compound boolean condition.
        if (!_isSenderApprovedOrOwner(approvedAddress, from, _msgSenderERC721A()))
            if (!isApprovedForAll(from, _msgSenderERC721A())) revert TransferCallerNotOwnerNorApproved();

        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner.
        assembly {
            if approvedAddress {
                // This is equivalent to "delete _tokenApprovals[tokenId]".
                sstore(approvedAddressSlot, 0)
            }
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as "tokenId" would have to be 2**256.
        unchecked {
            // We can directly increment and decrement the balances.
            --_packedAddressData[from]; // Updates: "balance -= 1".
            ++_packedAddressData[to]; // Updates: "balance += 1".

            // Updates:
            // - "address" to the next owner.
            // - "startTimestamp" to the timestamp of transfering.
            // - "burned" to "false".
            // - "nextInitialized" to "true".
            _packedOwnerships[tokenId] = _packOwnershipData(
                to,
                _BITMASK_NEXT_INITIALIZED | _nextExtraData(from, to, prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. "nextInitialized == false") .
            if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (_packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != _currentIndex) {
                        // Initialize the next slot to maintain correctness for "ownerOf(tokenId + 1)".
                        _packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev Equivalent to "safeTransferFrom(from, to, tokenId, '')".
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable virtual override {
        safeTransferFrom(from, to, tokenId, '');
    }

    /**
     * @dev Safely transfers "tokenId" token from "from" to "to".
     *
     * Requirements:
     *
     * - "from" cannot be the zero address.
     * - "to" cannot be the zero address.
     * - "tokenId" token must exist and be owned by "from".
     * - If the caller is not "from", it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     * - If "to" refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public payable virtual override {
        transferFrom(from, to, tokenId);
        if (to.code.length != 0)
            if (!_checkContractOnERC721Received(from, to, tokenId, _data)) {
                revert TransferToNonERC721ReceiverImplementer();
            }
    }

    /**
     * @dev Hook that is called before a set of serially-ordered token IDs
     * are about to be transferred. This includes minting.
     * And also called before burning one token.
     *
     * "startTokenId" - the first token ID to be transferred.
     * "quantity" - the amount to be transferred.
     *
     * Calling conditions:
     *
     * - When "from" and "to" are both non-zero, "from"'s "tokenId" will be
     * transferred to "to".
     * - When "from" is zero, "tokenId" will be minted for "to".
     * - When "to" is zero, "tokenId" will be burned by "from".
     * - "from" and "to" are never both zero.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token IDs
     * have been transferred. This includes minting.
     * And also called after one token has been burned.
     *
     * "startTokenId" - the first token ID to be transferred.
     * "quantity" - the amount to be transferred.
     *
     * Calling conditions:
     *
     * - When "from" and "to" are both non-zero, "from"'s "tokenId" has been
     * transferred to "to".
     * - When "from" is zero, "tokenId" has been minted for "to".
     * - When "to" is zero, "tokenId" has been burned by "from".
     * - "from" and "to" are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Private function to invoke {IERC721Receiver-onERC721Received} on a target contract.
     *
     * "from" - Previous owner of the given token ID.
     * "to" - Target address that will receive the token.
     * "tokenId" - Token ID to be transferred.
     * "_data" - Optional data to send along with the call.
     *
     * Returns whether the call correctly returned the expected magic value.
     */
    function _checkContractOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        try ERC721A__IERC721Receiver(to).onERC721Received(_msgSenderERC721A(), from, tokenId, _data) returns (
            bytes4 retval
        ) {
            return retval == ERC721A__IERC721Receiver(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert TransferToNonERC721ReceiverImplementer();
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    // =============================================================
    //                        MINT OPERATIONS
    // =============================================================

    /**
     * @dev Mints "quantity" tokens and transfers them to "to".
     *
     * Requirements:
     *
     * - "to" cannot be the zero address.
     * - "quantity" must be greater than 0.
     *
     * Emits a {Transfer} event for each mint.
     */
    function _mint(address to, uint256 quantity) internal virtual {
        uint256 startTokenId = _currentIndex;
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // "balance" and "numberMinted" have a maximum limit of 2**64.
        // "tokenId" has a maximum limit of 2**256.
        unchecked {
            // Updates:
            // - "balance += quantity".
            // - "numberMinted += quantity".
            //
            // We can directly add to the "balance" and "numberMinted".
            _packedAddressData[to] += quantity * ((1 << _BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - "address" to the owner.
            // - "startTimestamp" to the timestamp of minting.
            // - "burned" to "false".
            // - "nextInitialized" to "quantity == 1".
            _packedOwnerships[startTokenId] = _packOwnershipData(
                to,
                _nextInitializedFlag(quantity) | _nextExtraData(address(0), to, 0)
            );

            uint256 toMasked;
            uint256 end = startTokenId + quantity;

            // Use assembly to loop and emit the "Transfer" event for gas savings.
            // The duplicated "log4" removes an extra check and reduces stack juggling.
            // The assembly, together with the surrounding Solidity code, have been
            // delicately arranged to nudge the compiler into producing optimized opcodes.
            assembly {
                // Mask "to" to the lower 160 bits, in case the upper bits somehow aren't clean.
                toMasked := and(to, _BITMASK_ADDRESS)
                // Emit the "Transfer" event.
                log4(
                    0, // Start of data (0, since no data).
                    0, // End of data (0, since no data).
                    _TRANSFER_EVENT_SIGNATURE, // Signature.
                    0, // "address(0)".
                    toMasked, // "to".
                    startTokenId // "tokenId".
                )

                // The "iszero(eq(,))" check ensures that large values of "quantity"
                // that overflows uint256 will make the loop run out of gas.
                // The compiler will optimize the "iszero" away for performance.
                for {
                    let tokenId := add(startTokenId, 1)
                } iszero(eq(tokenId, end)) {
                    tokenId := add(tokenId, 1)
                } {
                    // Emit the "Transfer" event. Similar to above.
                    log4(0, 0, _TRANSFER_EVENT_SIGNATURE, 0, toMasked, tokenId)
                }
            }
            if (toMasked == 0) revert MintToZeroAddress();

            _currentIndex = end;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Mints "quantity" tokens and transfers them to "to".
     *
     * This function is intended for efficient minting only during contract creation.
     *
     * It emits only one {ConsecutiveTransfer} as defined in
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309),
     * instead of a sequence of {Transfer} event(s).
     *
     * Calling this function outside of contract creation WILL make your contract
     * non-compliant with the ERC721 standard.
     * For full ERC721 compliance, substituting ERC721 {Transfer} event(s) with the ERC2309
     * {ConsecutiveTransfer} event is only permissible during contract creation.
     *
     * Requirements:
     *
     * - "to" cannot be the zero address.
     * - "quantity" must be greater than 0.
     *
     * Emits a {ConsecutiveTransfer} event.
     */
    function _mintERC2309(address to, uint256 quantity) internal virtual {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();
        if (quantity > _MAX_MINT_ERC2309_QUANTITY_LIMIT) revert MintERC2309QuantityExceedsLimit();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are unrealistic due to the above check for "quantity" to be below the limit.
        unchecked {
            // Updates:
            // - "balance += quantity".
            // - "numberMinted += quantity".
            //
            // We can directly add to the "balance" and "numberMinted".
            _packedAddressData[to] += quantity * ((1 << _BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - "address" to the owner.
            // - "startTimestamp" to the timestamp of minting.
            // - "burned" to "false".
            // - "nextInitialized" to "quantity == 1".
            _packedOwnerships[startTokenId] = _packOwnershipData(
                to,
                _nextInitializedFlag(quantity) | _nextExtraData(address(0), to, 0)
            );

            emit ConsecutiveTransfer(startTokenId, startTokenId + quantity - 1, address(0), to);

            _currentIndex = startTokenId + quantity;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Safely mints "quantity" tokens and transfers them to "to".
     *
     * Requirements:
     *
     * - If "to" refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - "quantity" must be greater than 0.
     *
     * See {_mint}.
     *
     * Emits a {Transfer} event for each mint.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal virtual {
        _mint(to, quantity);

        unchecked {
            if (to.code.length != 0) {
                uint256 end = _currentIndex;
                uint256 index = end - quantity;
                do {
                    if (!_checkContractOnERC721Received(address(0), to, index++, _data)) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (index < end);
                // Reentrancy protection.
                if (_currentIndex != end) revert();
            }
        }
    }

    /**
     * @dev Equivalent to "_safeMint(to, quantity, '')".
     */
    function _safeMint(address to, uint256 quantity) internal virtual {
        _safeMint(to, quantity, '');
    }

    // =============================================================
    //                        BURN OPERATIONS
    // =============================================================

    /**
     * @dev Equivalent to "_burn(tokenId, false)".
     */
    function _burn(uint256 tokenId) internal virtual {
        _burn(tokenId, false);
    }

    /**
     * @dev Destroys "tokenId".
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - "tokenId" must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId, bool approvalCheck) internal virtual {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        address from = address(uint160(prevOwnershipPacked));

        (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedSlotAndAddress(tokenId);

        if (approvalCheck) {
            // The nested ifs save around 20+ gas over a compound boolean condition.
            if (!_isSenderApprovedOrOwner(approvedAddress, from, _msgSenderERC721A()))
                if (!isApprovedForAll(from, _msgSenderERC721A())) revert TransferCallerNotOwnerNorApproved();
        }

        _beforeTokenTransfers(from, address(0), tokenId, 1);

        // Clear approvals from the previous owner.
        assembly {
            if approvedAddress {
                // This is equivalent to "delete _tokenApprovals[tokenId]".
                sstore(approvedAddressSlot, 0)
            }
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as "tokenId" would have to be 2**256.
        unchecked {
            // Updates:
            // - "balance -= 1".
            // - "numberBurned += 1".
            //
            // We can directly decrement the balance, and increment the number burned.
            // This is equivalent to "packed -= 1; packed += 1 << _BITPOS_NUMBER_BURNED;".
            _packedAddressData[from] += (1 << _BITPOS_NUMBER_BURNED) - 1;

            // Updates:
            // - "address" to the last owner.
            // - "startTimestamp" to the timestamp of burning.
            // - "burned" to "true".
            // - "nextInitialized" to "true".
            _packedOwnerships[tokenId] = _packOwnershipData(
                from,
                (_BITMASK_BURNED | _BITMASK_NEXT_INITIALIZED) | _nextExtraData(from, address(0), prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. "nextInitialized == false") .
            if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (_packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != _currentIndex) {
                        // Initialize the next slot to maintain correctness for "ownerOf(tokenId + 1)".
                        _packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        emit Transfer(from, address(0), tokenId);
        _afterTokenTransfers(from, address(0), tokenId, 1);

        // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
        unchecked {
            _burnCounter++;
        }
    }

    // =============================================================
    //                     EXTRA DATA OPERATIONS
    // =============================================================

    /**
     * @dev Directly sets the extra data for the ownership data "index".
     */
    function _setExtraDataAt(uint256 index, uint24 extraData) internal virtual {
        uint256 packed = _packedOwnerships[index];
        if (packed == 0) revert OwnershipNotInitializedForExtraData();
        uint256 extraDataCasted;
        // Cast "extraData" with assembly to avoid redundant masking.
        assembly {
            extraDataCasted := extraData
        }
        packed = (packed & _BITMASK_EXTRA_DATA_COMPLEMENT) | (extraDataCasted << _BITPOS_EXTRA_DATA);
        _packedOwnerships[index] = packed;
    }

    /**
     * @dev Called during each token transfer to set the 24bit "extraData" field.
     * Intended to be overridden by the cosumer contract.
     *
     * "previousExtraData" - the value of "extraData" before transfer.
     *
     * Calling conditions:
     *
     * - When "from" and "to" are both non-zero, "from"'s "tokenId" will be
     * transferred to "to".
     * - When "from" is zero, "tokenId" will be minted for "to".
     * - When "to" is zero, "tokenId" will be burned by "from".
     * - "from" and "to" are never both zero.
     */
    function _extraData(
        address from,
        address to,
        uint24 previousExtraData
    ) internal view virtual returns (uint24) {}

    /**
     * @dev Returns the next extra data for the packed ownership data.
     * The returned result is shifted into position.
     */
    function _nextExtraData(
        address from,
        address to,
        uint256 prevOwnershipPacked
    ) private view returns (uint256) {
        uint24 extraData = uint24(prevOwnershipPacked >> _BITPOS_EXTRA_DATA);
        return uint256(_extraData(from, to, extraData)) << _BITPOS_EXTRA_DATA;
    }

    // =============================================================
    //                       OTHER OPERATIONS
    // =============================================================

    /**
     * @dev Returns the message sender (defaults to "msg.sender").
     *
     * If you are writing GSN compatible contracts, you need to override this function.
     */
    function _msgSenderERC721A() internal view virtual returns (address) {
        return msg.sender;
    }

    /**
     * @dev Converts a uint256 to its ASCII string decimal representation.
     */
    function _toString(uint256 value) internal pure virtual returns (string memory str) {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit), but
            // we allocate 0xa0 bytes to keep the free memory pointer 32-byte word aligned.
            // We will need 1 word for the trailing zeros padding, 1 word for the length,
            // and 3 words for a maximum of 78 digits. Total: 5 * 0x20 = 0xa0.
            let m := add(mload(0x40), 0xa0)
            // Update the free memory pointer to allocate.
            mstore(0x40, m)
            // Assign the "str" to the end.
            str := sub(m, 0x20)
            // Zeroize the slot after the string.
            mstore(str, 0)

            // Cache the end of the memory to calculate the length later.
            let end := str

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                str := sub(str, 1)
                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))
                // Keep dividing "temp" until zero.
                temp := div(temp, 10)
                // prettier-ignore
                if iszero(temp) { break }
            }

            let length := sub(end, str)
            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 0x20)
            // Store the length.
            mstore(str, length)
        }
    }
}


// File @limitbreak/creator-token-standards/src/erc721c/ERC721AC.sol@v5.0.0

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.4;




/**
 * @title ERC721AC
 * @author Limit Break, Inc.
 * @notice Extends Azuki's ERC721-A implementation with Creator Token functionality, which
 *         allows the contract owner to update the transfer validation logic by managing a security policy in
 *         an external transfer validation security policy registry.  See {CreatorTokenTransferValidator}.
 */
abstract contract ERC721AC is ERC721A, CreatorTokenBase, AutomaticValidatorTransferApproval {

    constructor(string memory name_, string memory symbol_) CreatorTokenBase() ERC721A(name_, symbol_) {}

    /**
     * @notice Overrides behavior of isApprovedFor all such that if an operator is not explicitly approved
     *         for all, the contract owner can optionally auto-approve the 721-C transfer validator for transfers.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool isApproved) {
        isApproved = super.isApprovedForAll(owner, operator);

        if (!isApproved) {
            if (autoApproveTransfersFromValidator) {
                isApproved = operator == address(getTransferValidator());
            }
        }
    }

    /**
     * @notice Indicates whether the contract implements the specified interface.
     * @dev Overrides supportsInterface in ERC165.
     * @param interfaceId The interface id
     * @return true if the contract implements the specified interface, false otherwise
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return 
        interfaceId == type(ICreatorToken).interfaceId || 
        interfaceId == type(ICreatorTokenLegacy).interfaceId || 
        super.supportsInterface(interfaceId);
    }

    /**
     * @notice Returns the function selector for the transfer validator's validation function to be called 
     * @notice for transaction simulation. 
     */
    function getTransferValidationFunction() external pure returns (bytes4 functionSignature, bool isViewFunction) {
        functionSignature = bytes4(keccak256("validateTransfer(address,address,address,uint256)"));
        isViewFunction = true;
    }

    /// @dev Ties the erc721a _beforeTokenTransfers hook to more granular transfer validation logic
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        for (uint256 i = 0; i < quantity;) {
            _validateBeforeTransfer(from, to, startTokenId + i);
            unchecked {
                ++i;
            }
        }
    }

    /// @dev Ties the erc721a _afterTokenTransfer hook to more granular transfer validation logic
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        for (uint256 i = 0; i < quantity;) {
            _validateAfterTransfer(from, to, startTokenId + i);
            unchecked {
                ++i;
            }
        }
    }

    function _msgSenderERC721A() internal view virtual override returns (address) {
        return _msgSender();
    }

    function _tokenType() internal pure override returns(uint16) {
        return uint16(TOKEN_TYPE_ERC721);
    }
}


// File @openzeppelin/contracts/access/Ownable.sol@v4.8.3

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * "onlyOwner", which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * "onlyOwner" functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account ("newOwner").
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account ("newOwner").
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File @openzeppelin/contracts/utils/introspection/IERC165.sol@v4.8.3

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * "interfaceId". See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


// File @openzeppelin/contracts/interfaces/IERC2981.sol@v4.8.3

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}


// File @openzeppelin/contracts/utils/introspection/ERC165.sol@v4.8.3

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * """solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * """
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}


// File @openzeppelin/contracts/token/common/ERC2981.sol@v4.8.3

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/common/ERC2981.sol)

pragma solidity ^0.8.0;


/**
 * @dev Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * Royalty is specified as a fraction of sale price. {_feeDenominator} is overridable but defaults to 10000, meaning the
 * fee is specified in basis points by default.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */
abstract contract ERC2981 is IERC2981, ERC165 {
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IERC2981
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view virtual override returns (address, uint256) {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[_tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) / _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - "receiver" cannot be the zero address.
     * - "feeNumerator" cannot be greater than the fee denominator.
     */
    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: invalid receiver");

        _defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Removes default royalty information.
     */
    function _deleteDefaultRoyalty() internal virtual {
        delete _defaultRoyaltyInfo;
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - "receiver" cannot be the zero address.
     * - "feeNumerator" cannot be greater than the fee denominator.
     */
    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: Invalid parameters");

        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        delete _tokenRoyaltyInfo[tokenId];
    }
}


// File @pythnetwork/pyth-sdk-solidity/IPythEvents.sol@v4.1.0

// Original license: SPDX_License_Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @title IPythEvents contains the events that Pyth contract emits.
/// @dev This interface can be used for listening to the updates for off-chain and testing purposes.
interface IPythEvents {
    /// @dev Emitted when the price feed with "id" has received a fresh update.
    /// @param id The Pyth Price Feed ID.
    /// @param publishTime Publish time of the given price update.
    /// @param price Price of the given price update.
    /// @param conf Confidence interval of the given price update.
    event PriceFeedUpdate(
        bytes32 indexed id,
        uint64 publishTime,
        int64 price,
        uint64 conf
    );

    /// @dev Emitted when the TWAP price feed with "id" has received a fresh update.
    /// @param id The Pyth Price Feed ID.
    /// @param startTime Start time of the TWAP.
    /// @param endTime End time of the TWAP.
    /// @param twapPrice Price of the TWAP.
    /// @param twapConf Confidence interval of the TWAP.
    /// @param downSlotsRatio Down slot ratio of the TWAP.
    event TwapPriceFeedUpdate(
        bytes32 indexed id,
        uint64 startTime,
        uint64 endTime,
        int64 twapPrice,
        uint64 twapConf,
        uint32 downSlotsRatio
    );
}


// File @pythnetwork/pyth-sdk-solidity/PythStructs.sol@v4.1.0

// Original license: SPDX_License_Identifier: Apache-2.0
pragma solidity ^0.8.0;

contract PythStructs {
    // A price with a degree of uncertainty, represented as a price +- a confidence interval.
    //
    // The confidence interval roughly corresponds to the standard error of a normal distribution.
    // Both the price and confidence are stored in a fixed-point numeric representation,
    // "x * (10^expo)", where "expo" is the exponent.
    //
    // Please refer to the documentation at https://docs.pyth.network/documentation/pythnet-price-feeds/best-practices for how
    // to how this price safely.
    struct Price {
        // Price
        int64 price;
        // Confidence interval around the price
        uint64 conf;
        // Price exponent
        int32 expo;
        // Unix timestamp describing when the price was published
        uint publishTime;
    }

    // PriceFeed represents a current aggregate price from pyth publisher feeds.
    struct PriceFeed {
        // The price ID.
        bytes32 id;
        // Latest available price
        Price price;
        // Latest available exponentially-weighted moving average price
        Price emaPrice;
    }

    struct TwapPriceFeed {
        // The price ID.
        bytes32 id;
        // Start time of the TWAP
        uint64 startTime;
        // End time of the TWAP
        uint64 endTime;
        // TWAP price
        Price twap;
        // Down slot ratio represents the ratio of price feed updates that were missed or unavailable
        // during the TWAP period, expressed as a fixed-point number between 0 and 1e6 (100%).
        // For example:
        //   - 0 means all price updates were available
        //   - 500_000 means 50% of updates were missed
        //   - 1_000_000 means all updates were missed
        // This can be used to assess the quality/reliability of the TWAP calculation.
        // Applications should define a maximum acceptable ratio (e.g. 100000 for 10%)
        // and revert if downSlotsRatio exceeds it.
        uint32 downSlotsRatio;
    }

    // Information used to calculate time-weighted average prices (TWAP)
    struct TwapPriceInfo {
        // slot 1
        int128 cumulativePrice;
        uint128 cumulativeConf;
        // slot 2
        uint64 numDownSlots;
        uint64 publishSlot;
        uint64 publishTime;
        uint64 prevPublishTime;
        // slot 3
        int32 expo;
    }
}


// File @pythnetwork/pyth-sdk-solidity/IPyth.sol@v4.1.0

// Original license: SPDX_License_Identifier: Apache-2.0
pragma solidity ^0.8.0;


/// @title Consume prices from the Pyth Network (https://pyth.network/).
/// @dev Please refer to the guidance at https://docs.pyth.network/documentation/pythnet-price-feeds/best-practices for how to consume prices safely.
/// @author Pyth Data Association
interface IPyth is IPythEvents {
    /// @notice Returns the price of a price feed without any sanity checks.
    /// @dev This function returns the most recent price update in this contract without any recency checks.
    /// This function is unsafe as the returned price update may be arbitrarily far in the past.
    ///
    /// Users of this function should check the "publishTime" in the price to ensure that the returned price is
    /// sufficiently recent for their application. If you are considering using this function, it may be
    /// safer / easier to use "getPriceNoOlderThan".
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getPriceUnsafe(
        bytes32 id
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the price that is no older than "age" seconds of the current time.
    /// @dev This function is a sanity-checked version of "getPriceUnsafe" which is useful in
    /// applications that require a sufficiently-recent price. Reverts if the price wasn't updated sufficiently
    /// recently.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getPriceNoOlderThan(
        bytes32 id,
        uint age
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the exponentially-weighted moving average price of a price feed without any sanity checks.
    /// @dev This function returns the same price as "getEmaPrice" in the case where the price is available.
    /// However, if the price is not recent this function returns the latest available price.
    ///
    /// The returned price can be from arbitrarily far in the past; this function makes no guarantees that
    /// the returned price is recent or useful for any particular application.
    ///
    /// Users of this function should check the "publishTime" in the price to ensure that the returned price is
    /// sufficiently recent for their application. If you are considering using this function, it may be
    /// safer / easier to use either "getEmaPrice" or "getEmaPriceNoOlderThan".
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getEmaPriceUnsafe(
        bytes32 id
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the exponentially-weighted moving average price that is no older than "age" seconds
    /// of the current time.
    /// @dev This function is a sanity-checked version of "getEmaPriceUnsafe" which is useful in
    /// applications that require a sufficiently-recent price. Reverts if the price wasn't updated sufficiently
    /// recently.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getEmaPriceNoOlderThan(
        bytes32 id,
        uint age
    ) external view returns (PythStructs.Price memory price);

    /// @notice Update price feeds with given update messages.
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// "getUpdateFee" with the length of the "updateData" array.
    /// Prices will be updated if they are more recent than the current stored prices.
    /// The call will succeed even if the update is not the most recent.
    /// @dev Reverts if the transferred fee is not sufficient or the updateData is invalid.
    /// @param updateData Array of price update data.
    function updatePriceFeeds(bytes[] calldata updateData) external payable;

    /// @notice Wrapper around updatePriceFeeds that rejects fast if a price update is not necessary. A price update is
    /// necessary if the current on-chain publishTime is older than the given publishTime. It relies solely on the
    /// given "publishTimes" for the price feeds and does not read the actual price update publish time within "updateData".
    ///
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// "getUpdateFee" with the length of the "updateData" array.
    ///
    /// "priceIds" and "publishTimes" are two arrays with the same size that correspond to senders known publishTime
    /// of each priceId when calling this method. If all of price feeds within "priceIds" have updated and have
    /// a newer or equal publish time than the given publish time, it will reject the transaction to save gas.
    /// Otherwise, it calls updatePriceFeeds method to update the prices.
    ///
    /// @dev Reverts if update is not needed or the transferred fee is not sufficient or the updateData is invalid.
    /// @param updateData Array of price update data.
    /// @param priceIds Array of price ids.
    /// @param publishTimes Array of publishTimes. "publishTimes[i]" corresponds to known "publishTime" of "priceIds[i]"
    function updatePriceFeedsIfNecessary(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64[] calldata publishTimes
    ) external payable;

    /// @notice Returns the required fee to update an array of price updates.
    /// @param updateData Array of price update data.
    /// @return feeAmount The required fee in Wei.
    function getUpdateFee(
        bytes[] calldata updateData
    ) external view returns (uint feeAmount);

    /// @notice Parse "updateData" and return price feeds of the given "priceIds" if they are all published
    /// within "minPublishTime" and "maxPublishTime".
    ///
    /// You can use this method if you want to use a Pyth price at a fixed time and not the most recent price;
    /// otherwise, please consider using "updatePriceFeeds". This method may store the price updates on-chain, if they
    /// are more recent than the current stored prices.
    ///
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// "getUpdateFee" with the length of the "updateData" array.
    ///
    ///
    /// @dev Reverts if the transferred fee is not sufficient or the updateData is invalid or there is
    /// no update for any of the given "priceIds" within the given time range.
    /// @param updateData Array of price update data.
    /// @param priceIds Array of price ids.
    /// @param minPublishTime minimum acceptable publishTime for the given "priceIds".
    /// @param maxPublishTime maximum acceptable publishTime for the given "priceIds".
    /// @return priceFeeds Array of the price feeds corresponding to the given "priceIds" (with the same order).
    function parsePriceFeedUpdates(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64 minPublishTime,
        uint64 maxPublishTime
    ) external payable returns (PythStructs.PriceFeed[] memory priceFeeds);

    /// @notice Parse time-weighted average price (TWAP) from two consecutive price updates for the given "priceIds".
    ///
    /// This method calculates TWAP between two data points by processing the difference in cumulative price values
    /// divided by the time period. It requires exactly two updates that contain valid price information
    /// for all the requested price IDs.
    ///
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// "getUpdateFee" with the updateData array.
    ///
    /// @dev Reverts if:
    /// - The transferred fee is not sufficient
    /// - The updateData is invalid or malformed
    /// - The updateData array does not contain exactly 2 updates
    /// - There is no update for any of the given "priceIds"
    /// - The time ordering between data points is invalid (start time must be before end time)
    /// @param updateData Array containing exactly two price updates (start and end points for TWAP calculation)
    /// @param priceIds Array of price ids to calculate TWAP for
    /// @return twapPriceFeeds Array of TWAP price feeds corresponding to the given "priceIds" (with the same order)
    function parseTwapPriceFeedUpdates(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds
    )
        external
        payable
        returns (PythStructs.TwapPriceFeed[] memory twapPriceFeeds);

    /// @notice Similar to "parsePriceFeedUpdates" but ensures the updates returned are
    /// the first updates published in minPublishTime. That is, if there are multiple updates for a given timestamp,
    /// this method will return the first update. This method may store the price updates on-chain, if they
    /// are more recent than the current stored prices.
    ///
    ///
    /// @dev Reverts if the transferred fee is not sufficient or the updateData is invalid or there is
    /// no update for any of the given "priceIds" within the given time range and uniqueness condition.
    /// @param updateData Array of price update data.
    /// @param priceIds Array of price ids.
    /// @param minPublishTime minimum acceptable publishTime for the given "priceIds".
    /// @param maxPublishTime maximum acceptable publishTime for the given "priceIds".
    /// @return priceFeeds Array of the price feeds corresponding to the given "priceIds" (with the same order).
    function parsePriceFeedUpdatesUnique(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64 minPublishTime,
        uint64 maxPublishTime
    ) external payable returns (PythStructs.PriceFeed[] memory priceFeeds);

    /// @dev Same as "parsePriceFeedUpdates", but also returns the Pythnet slot
    /// associated with each price update.
    /// @param updateData Array of price update data.
    /// @param priceIds Array of price ids.
    /// @param minPublishTime minimum acceptable publishTime for the given "priceIds".
    /// @param maxPublishTime maximum acceptable publishTime for the given "priceIds".
    /// @return priceFeeds Array of the price feeds corresponding to the given "priceIds" (with the same order).
    /// @return slots Array of the Pythnet slot corresponding to the given "priceIds" (with the same order).
    function parsePriceFeedUpdatesWithSlots(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64 minPublishTime,
        uint64 maxPublishTime
    )
        external
        payable
        returns (
            PythStructs.PriceFeed[] memory priceFeeds,
            uint64[] memory slots
        );
}


// File contracts/main-contracts/KingdomlyFeeContract.sol

// Original license: SPDX_License_Identifier: UNLICENSED
pragma solidity ^0.8.24;


error InsufficientUpdateFee(uint256 requiredFee);
error ContractNotVerified(address contractAddress);

contract KingdomlyFeeContract is Ownable {
    uint256 private cachedOneDollarInWei;
    uint256 private maxPriceAgeInSeconds;

    IPyth pyth;
    bytes32 ethUsdPriceId;

    constructor(address _pyth, bytes32 _ethUsdPriceId) Ownable() {
        pyth = IPyth(_pyth);
        ethUsdPriceId = _ethUsdPriceId;
        maxPriceAgeInSeconds = 60 * 60 * 24;
    }

    function getOneDollarInWei() public view returns (uint256) {
        try
            pyth.getPriceNoOlderThan(ethUsdPriceId, maxPriceAgeInSeconds)
        returns (PythStructs.Price memory price) {
            uint256 ethPrice18Decimals = (uint256(uint64(price.price)) *
                (10 ** 18)) / (10 ** uint8(uint32(-1 * price.expo)));
            uint256 oneDollarInWei = ((10 ** 18) * (10 ** 18)) /
                ethPrice18Decimals;

            return oneDollarInWei;
        } catch {
            return cachedOneDollarInWei;
        }
    }

    function updateOracleAndGetOneDollarInWei(
        bytes[] calldata pythPriceUpdate
    ) public payable returns (uint256) {
        uint256 updateFee = pyth.getUpdateFee(pythPriceUpdate);

        if (msg.value != updateFee) {
            revert InsufficientUpdateFee(updateFee);
        }

        pyth.updatePriceFeeds{value: msg.value}(pythPriceUpdate);

        cachedOneDollarInWei = getOneDollarInWei();

        return cachedOneDollarInWei;
    }

    function updateMaxPriceAgeInSeconds(
        uint256 _maxPriceAgeInSeconds
    ) public onlyOwner {
        maxPriceAgeInSeconds = _maxPriceAgeInSeconds;
    }
}


// File contracts/utils/IDelegateRegistry.sol

// Original license: SPDX_License_Identifier: CC0-1.0
pragma solidity >=0.8.13;

/**
 * @title IDelegateRegistry
 * @custom:version 2.0
 * @custom:author foobar (0xfoobar)
 * @notice A standalone immutable registry storing delegated permissions from one address to another
 */
interface IDelegateRegistry {
    /// @notice Delegation type, NONE is used when a delegation does not exist or is revoked
    enum DelegationType {
        NONE,
        ALL,
        CONTRACT,
        ERC721,
        ERC20,
        ERC1155
    }

    /// @notice Struct for returning delegations
    struct Delegation {
        DelegationType type_;
        address to;
        address from;
        bytes32 rights;
        address contract_;
        uint256 tokenId;
        uint256 amount;
    }

    /// @notice Emitted when an address delegates or revokes rights for their entire wallet
    event DelegateAll(address indexed from, address indexed to, bytes32 rights, bool enable);

    /// @notice Emitted when an address delegates or revokes rights for a contract address
    event DelegateContract(
        address indexed from, address indexed to, address indexed contract_, bytes32 rights, bool enable
    );

    /// @notice Emitted when an address delegates or revokes rights for an ERC721 tokenId
    event DelegateERC721(
        address indexed from,
        address indexed to,
        address indexed contract_,
        uint256 tokenId,
        bytes32 rights,
        bool enable
    );

    /// @notice Emitted when an address delegates or revokes rights for an amount of ERC20 tokens
    event DelegateERC20(
        address indexed from, address indexed to, address indexed contract_, bytes32 rights, uint256 amount
    );

    /// @notice Emitted when an address delegates or revokes rights for an amount of an ERC1155 tokenId
    event DelegateERC1155(
        address indexed from,
        address indexed to,
        address indexed contract_,
        uint256 tokenId,
        bytes32 rights,
        uint256 amount
    );

    /// @notice Thrown if multicall calldata is malformed
    error MulticallFailed();

    /**
     * -----------  WRITE -----------
     */

    /**
     * @notice Call multiple functions in the current contract and return the data from all of them if they all succeed
     * @param data The encoded function data for each of the calls to make to this contract
     * @return results The results from each of the calls passed in via data
     */
    function multicall(bytes[] calldata data) external payable returns (bytes[] memory results);

    /**
     * @notice Allow the delegate to act on behalf of "msg.sender" for all contracts
     * @param to The address to act as delegate
     * @param rights Specific subdelegation rights granted to the delegate, pass an empty bytestring to encompass all rights
     * @param enable Whether to enable or disable this delegation, true delegates and false revokes
     * @return delegationHash The unique identifier of the delegation
     */
    function delegateAll(address to, bytes32 rights, bool enable) external payable returns (bytes32 delegationHash);

    /**
     * @notice Allow the delegate to act on behalf of "msg.sender" for a specific contract
     * @param to The address to act as delegate
     * @param contract_ The contract whose rights are being delegated
     * @param rights Specific subdelegation rights granted to the delegate, pass an empty bytestring to encompass all rights
     * @param enable Whether to enable or disable this delegation, true delegates and false revokes
     * @return delegationHash The unique identifier of the delegation
     */
    function delegateContract(address to, address contract_, bytes32 rights, bool enable)
        external
        payable
        returns (bytes32 delegationHash);

    /**
     * @notice Allow the delegate to act on behalf of "msg.sender" for a specific ERC721 token
     * @param to The address to act as delegate
     * @param contract_ The contract whose rights are being delegated
     * @param tokenId The token id to delegate
     * @param rights Specific subdelegation rights granted to the delegate, pass an empty bytestring to encompass all rights
     * @param enable Whether to enable or disable this delegation, true delegates and false revokes
     * @return delegationHash The unique identifier of the delegation
     */
    function delegateERC721(address to, address contract_, uint256 tokenId, bytes32 rights, bool enable)
        external
        payable
        returns (bytes32 delegationHash);

    /**
     * @notice Allow the delegate to act on behalf of "msg.sender" for a specific amount of ERC20 tokens
     * @dev The actual amount is not encoded in the hash, just the existence of a amount (since it is an upper bound)
     * @param to The address to act as delegate
     * @param contract_ The address for the fungible token contract
     * @param rights Specific subdelegation rights granted to the delegate, pass an empty bytestring to encompass all rights
     * @param amount The amount to delegate, > 0 delegates and 0 revokes
     * @return delegationHash The unique identifier of the delegation
     */
    function delegateERC20(address to, address contract_, bytes32 rights, uint256 amount)
        external
        payable
        returns (bytes32 delegationHash);

    /**
     * @notice Allow the delegate to act on behalf of "msg.sender" for a specific amount of ERC1155 tokens
     * @dev The actual amount is not encoded in the hash, just the existence of a amount (since it is an upper bound)
     * @param to The address to act as delegate
     * @param contract_ The address of the contract that holds the token
     * @param tokenId The token id to delegate
     * @param rights Specific subdelegation rights granted to the delegate, pass an empty bytestring to encompass all rights
     * @param amount The amount of that token id to delegate, > 0 delegates and 0 revokes
     * @return delegationHash The unique identifier of the delegation
     */
    function delegateERC1155(address to, address contract_, uint256 tokenId, bytes32 rights, uint256 amount)
        external
        payable
        returns (bytes32 delegationHash);

    /**
     * ----------- CHECKS -----------
     */

    /**
     * @notice Check if "to" is a delegate of "from" for the entire wallet
     * @param to The potential delegate address
     * @param from The potential address who delegated rights
     * @param rights Specific rights to check for, pass the zero value to ignore subdelegations and check full delegations only
     * @return valid Whether delegate is granted to act on the from's behalf
     */
    function checkDelegateForAll(address to, address from, bytes32 rights) external view returns (bool);

    /**
     * @notice Check if "to" is a delegate of "from" for the specified "contract_" or the entire wallet
     * @param to The delegated address to check
     * @param contract_ The specific contract address being checked
     * @param from The cold wallet who issued the delegation
     * @param rights Specific rights to check for, pass the zero value to ignore subdelegations and check full delegations only
     * @return valid Whether delegate is granted to act on from's behalf for entire wallet or that specific contract
     */
    function checkDelegateForContract(address to, address from, address contract_, bytes32 rights)
        external
        view
        returns (bool);

    /**
     * @notice Check if "to" is a delegate of "from" for the specific "contract" and "tokenId", the entire "contract_", or the entire wallet
     * @param to The delegated address to check
     * @param contract_ The specific contract address being checked
     * @param tokenId The token id for the token to delegating
     * @param from The wallet that issued the delegation
     * @param rights Specific rights to check for, pass the zero value to ignore subdelegations and check full delegations only
     * @return valid Whether delegate is granted to act on from's behalf for entire wallet, that contract, or that specific tokenId
     */
    function checkDelegateForERC721(address to, address from, address contract_, uint256 tokenId, bytes32 rights)
        external
        view
        returns (bool);

    /**
     * @notice Returns the amount of ERC20 tokens the delegate is granted rights to act on the behalf of
     * @param to The delegated address to check
     * @param contract_ The address of the token contract
     * @param from The cold wallet who issued the delegation
     * @param rights Specific rights to check for, pass the zero value to ignore subdelegations and check full delegations only
     * @return balance The delegated balance, which will be 0 if the delegation does not exist
     */
    function checkDelegateForERC20(address to, address from, address contract_, bytes32 rights)
        external
        view
        returns (uint256);

    /**
     * @notice Returns the amount of a ERC1155 tokens the delegate is granted rights to act on the behalf of
     * @param to The delegated address to check
     * @param contract_ The address of the token contract
     * @param tokenId The token id to check the delegated amount of
     * @param from The cold wallet who issued the delegation
     * @param rights Specific rights to check for, pass the zero value to ignore subdelegations and check full delegations only
     * @return balance The delegated balance, which will be 0 if the delegation does not exist
     */
    function checkDelegateForERC1155(address to, address from, address contract_, uint256 tokenId, bytes32 rights)
        external
        view
        returns (uint256);

    /**
     * ----------- ENUMERATIONS -----------
     */

    /**
     * @notice Returns all enabled delegations a given delegate has received
     * @param to The address to retrieve delegations for
     * @return delegations Array of Delegation structs
     */
    function getIncomingDelegations(address to) external view returns (Delegation[] memory delegations);

    /**
     * @notice Returns all enabled delegations an address has given out
     * @param from The address to retrieve delegations for
     * @return delegations Array of Delegation structs
     */
    function getOutgoingDelegations(address from) external view returns (Delegation[] memory delegations);

    /**
     * @notice Returns all hashes associated with enabled delegations an address has received
     * @param to The address to retrieve incoming delegation hashes for
     * @return delegationHashes Array of delegation hashes
     */
    function getIncomingDelegationHashes(address to) external view returns (bytes32[] memory delegationHashes);

    /**
     * @notice Returns all hashes associated with enabled delegations an address has given out
     * @param from The address to retrieve outgoing delegation hashes for
     * @return delegationHashes Array of delegation hashes
     */
    function getOutgoingDelegationHashes(address from) external view returns (bytes32[] memory delegationHashes);

    /**
     * @notice Returns the delegations for a given array of delegation hashes
     * @param delegationHashes is an array of hashes that correspond to delegations
     * @return delegations Array of Delegation structs, return empty structs for nonexistent or revoked delegations
     */
    function getDelegationsFromHashes(bytes32[] calldata delegationHashes)
        external
        view
        returns (Delegation[] memory delegations);

    /**
     * ----------- STORAGE ACCESS -----------
     */

    /**
     * @notice Allows external contracts to read arbitrary storage slots
     */
    function readSlot(bytes32 location) external view returns (bytes32);

    /**
     * @notice Allows external contracts to read an arbitrary array of storage slots
     */
    function readSlots(bytes32[] calldata locations) external view returns (bytes32[] memory);
}


// File contracts/kingdomly/MegaCarrot.sol
// Original license: SPDX_License_Identifier: UNLICENSED

pragma solidity ^0.8.24;


// ██╗  ██╗██╗███╗   ██╗ ██████╗ ██████╗  ██████╗ ███╗   ███╗██╗  ██╗   ██╗
// ██║ ██╔╝██║████╗  ██║██╔════╝ ██╔══██╗██╔═══██╗████╗ ████║██║  ╚██╗ ██╔╝
// █████╔╝ ██║██╔██╗ ██║██║  ███╗██║  ██║██║   ██║██╔████╔██║██║   ╚████╔╝
// ██╔═██╗ ██║██║╚██╗██║██║   ██║██║  ██║██║   ██║██║╚██╔╝██║██║    ╚██╔╝
// ██║  ██╗██║██║ ╚████║╚██████╔╝██████╔╝╚██████╔╝██║ ╚═╝ ██║███████╗██║
// ╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚═════╝  ╚═════╝ ╚═╝     ╚═╝╚══════╝╚═╝

error MintInactive();
error Unauthorized(address caller);
error InvalidOperation(string reason);
error ExceedsMaxSupply(uint256 requested, uint256 available);
error InsufficientEther(uint256 required, uint256 provided);
error ExceedsMaxPerWallet(uint256 requested, uint256 allowed);
error ExceedsMintQuota(uint256 requested, uint256 allowed);

error ExceedsMaxMintGroupSupply(uint256 requested, uint256 available); // Remove when allowlist is off
error MintGroupInactive(uint256 mintId); // Remove when allowlist is off
error NotInPresale(address caller, uint256 mintId); // Remove when allowlist is off
error MintGroupDoesNotExist(uint256 mintId); // Remove when allowlist is off
error ArrayLengthMismatch(); // Remove when allowlist is off

error InvalidKingdomlyFeeContract();

contract MegaCarrot is ERC721AC, ERC2981, Ownable {
    event BatchMetadataUpdate(
        uint256 indexed fromTokenId,
        uint256 indexed toTokenId
    );
    event TokensMinted(
        address indexed recipient,
        uint256 amount,
        uint256 mintId
    );

    event TokensDelegateMinted(
        address indexed vault,
        address indexed hotWallet,
        uint256 amount,
        uint256 mintId
    );

    event SalePriceChanged(uint256 indexed mintId, uint256 newPrice);

    event MaxMintPerWalletChanged(
        uint256 newMaxMintPerWallet,
        uint256 mintGroupId
    );

    event PreSaleMintStatusChanged(bool status, uint256 mintGroupId);

    event PreSaleMintScheduledStartTimestampChanged(
        uint256 timestamp,
        uint256 mintGroupId
    );

    event KingdomlyFeeContractChanged(address feeContractAddress);

    struct BaseVariables {
        string name;
        string symbol;
        address ownerPayoutAddress;
        string initialBaseURI;
        uint256 maxSupply;
    }

    //Base variables
    mapping(address => uint256) private pendingBalances;
    uint256 public maxSupply;
    uint256 public immutable threeDollarsInCents;
    bool public contractMintLive = false;
    uint256 public scheduledMintLiveTimestamp = 0;
    string public baseURI;
    address public feeAddress;
    address public ownerPayoutAddress;

    address public kingdomlyAdmin;
    KingdomlyFeeContract public kingdomlyFeeContract;

    //Map pairings.
    mapping(uint256 => uint256) public maxMintPerWallet;
    mapping(uint256 => uint256) public mintPrice;
    mapping(uint256 => uint256) public maxSupplyPerMintGroup;
    mapping(uint256 => uint256) public mintGroupMints;
    mapping(address => mapping(uint256 => uint256)) private addressMints; // Added address mints for mint group cap
    mapping(uint256 => mapping(address => uint256)) public mintQuotas; // Changed presale checker to mintQuotas for individual addresses
    mapping(uint256 => bool) public contractPresaleActive;
    mapping(uint256 => uint256) public presaleScheduledStartTimestamp;

    uint256[] public activeMintGroups; //Array to get all active mint groups. Remove when allowlist is off

    constructor(
        //Base variables
        BaseVariables memory _baseVariables,
        //Allowlist variables
        uint256[] memory _maxMintPerWallet, // Turn into uint256 if allowlist is off
        uint256[] memory _maxSupplyPerMintGroup, // Remove if allowlist is off
        uint256[] memory _mintPrice, // Turn into uint256 if allowlist is off
        //Royalties variables
        uint96 _royaltyPercentage, // multipied by 100
        address _kingdomlyAdmin,
        KingdomlyFeeContract _kingdomlyFeeContract
    ) ERC721AC(_baseVariables.name, _baseVariables.symbol) Ownable() {
        //Error handler to check if map pairs each other. Remove if allowlist is off
        if (
            _maxMintPerWallet.length != _maxSupplyPerMintGroup.length &&
            _maxMintPerWallet.length != _mintPrice.length
        ) {
            revert ArrayLengthMismatch();
        }

        //Remove if allowlist is off
        uint256 totalMaxSupplyPerMintGroup = 0;
        for (uint256 i = 0; i < _maxSupplyPerMintGroup.length; i++) {
            totalMaxSupplyPerMintGroup += _maxSupplyPerMintGroup[i];
            maxSupplyPerMintGroup[i] = _maxSupplyPerMintGroup[i];
            maxMintPerWallet[i] = _maxMintPerWallet[i];
            mintPrice[i] = _mintPrice[i];
            mintGroupMints[i] = 0;
            activeMintGroups.push(i);
        }

        //Checker if max supply per mint group exceeds total max supply. Remove if allowlist is off
        if (totalMaxSupplyPerMintGroup > _baseVariables.maxSupply) {
            revert InvalidOperation({
                reason: "Max supply per mint group exceeds total max supply"
            });
        }

        //Base variables
        maxSupply = _baseVariables.maxSupply;
        baseURI = _baseVariables.initialBaseURI;
        ownerPayoutAddress = _baseVariables.ownerPayoutAddress;
        feeAddress = 0x10317Fa93da2a2e6d7B8e29D2BC2e6B95f2ECc84;

        // Setting up royalties and affiliate percentage
        _setDefaultRoyalty(
            _baseVariables.ownerPayoutAddress,
            _royaltyPercentage
        );

        // FEE Variables
        kingdomlyAdmin = _kingdomlyAdmin;

        kingdomlyFeeContract = _kingdomlyFeeContract;
        threeDollarsInCents = 300; // $3 * 100 = 300
    }

    // ###################### Modifiers ######################

    /**
     * @dev Ensures the caller is the Kingdomly Admin.
     */
    modifier isKingdomlyAdmin() {
        if (msg.sender != kingdomlyAdmin) {
            revert Unauthorized(msg.sender);
        }

        _;
    }

    //===================================START Allowlist Functions===================================//
    // Initializer for new mint groups for all maps
    function initializeNewMintGroup(uint256 mintId) internal {
        mintPrice[mintId] = 0;
        maxMintPerWallet[mintId] = 0;
        maxSupplyPerMintGroup[mintId] = 0;
        mintGroupMints[mintId] = 0;
        activeMintGroups.push(mintId);
    }

    function isMintGroupActive(uint256 mintId) private view returns (bool) {
        for (uint256 i = 0; i < activeMintGroups.length; i++) {
            if (activeMintGroups[i] == mintId) {
                return true;
            }
        }
        return false;
    }

    function mintLive() public view returns (bool) {
        if (!contractMintLive) {
            if (
                scheduledMintLiveTimestamp == 0 ||
                block.timestamp <= scheduledMintLiveTimestamp
            ) {
                return false;
            }
        }

        return true;
    }

    // Changes the max mint per mint group. Only the contract owner can call this function. Remove this function if allowlist is off
    function setNewMaxPerMintGroup(
        uint256 mintId,
        uint256 newMax
    ) public onlyOwner {
        //Checks if mintId already exists inside activeMintGroups. This allows the contract to adjust the mappings for new mint groups
        if (!isMintGroupActive(mintId)) {
            initializeNewMintGroup(mintId);
        }

        // Checker if new max exceeds total supply
        uint256 totalMaxMintPerMG = 0;
        for (uint256 i = 0; i < activeMintGroups.length; i++) {
            if (activeMintGroups[i] == mintId) {
                totalMaxMintPerMG += newMax; // Use the new max for the specified mintId
            } else {
                totalMaxMintPerMG += maxSupplyPerMintGroup[activeMintGroups[i]];
            }
        }

        if (totalMaxMintPerMG > maxSupply) {
            revert InvalidOperation({
                reason: "New supply per mint group exceeds total supply."
            });
        }

        maxSupplyPerMintGroup[mintId] = newMax;
    }

    // Changed add to presale to set mint quota for individual addresses.
    function setMintQuota(
        address[] memory addressToAdd,
        uint256 mintId,
        uint256[] memory _mintQuotas
    ) external onlyOwner {
        //Checks if mintId already exists inside activeMintGroups. This allows the contract to adjust the mappings for new mint groups
        if (!isMintGroupActive(mintId)) {
            initializeNewMintGroup(mintId);
        }

        for (uint256 i = 0; i < addressToAdd.length; i++) {
            mintQuotas[mintId][addressToAdd[i]] = _mintQuotas[i];
        }
    }

    // Control the presale status
    function stopOrStartpresaleMint(
        bool presaleStatus,
        uint256 mintId
    ) public onlyOwner {
        //Checks if mintId already exists inside activeMintGroups.
        if (!isMintGroupActive(mintId)) {
            revert MintGroupDoesNotExist({mintId: mintId});
        }
        contractPresaleActive[mintId] = presaleStatus;

        if (presaleStatus == false) {
            presaleScheduledStartTimestamp[mintId] = 0;
        }

        emit PreSaleMintStatusChanged(presaleStatus, mintId);
    }

    function schedulePresaleMintStart(
        uint256 startTimestamp,
        uint256 mintId
    ) public onlyOwner {
        if (!isMintGroupActive(mintId)) {
            revert MintGroupDoesNotExist({mintId: mintId});
        }
        presaleScheduledStartTimestamp[mintId] = startTimestamp;

        emit PreSaleMintScheduledStartTimestampChanged(startTimestamp, mintId);
    }

    //Checker whether presale is already active both on timestmap and the mapping
    function presaleActive(uint256 mintId) public view returns (bool) {
        if (!contractPresaleActive[mintId]) {
            if (
                presaleScheduledStartTimestamp[mintId] == 0 ||
                block.timestamp <= presaleScheduledStartTimestamp[mintId]
            ) {
                return false;
            }
        }

        return true;
    }

    //===================================END Allowlist Functions===================================//
    // Sets the maximum number of tokens that can be minted in a batch. Only the contract owner can call this function.
    function setMaxMintPerWallet(
        uint256 newMaxMintPerWallet,
        uint256 mintGroupId
    ) public onlyOwner {
        maxMintPerWallet[mintGroupId] = newMaxMintPerWallet;

        emit MaxMintPerWalletChanged(newMaxMintPerWallet, mintGroupId);
    }

    // Changes the price to mint a token. Only the contract owner can call this function.
    function changeSalePrice(
        uint256 newmintPrice,
        uint256 mintId
    ) public onlyOwner {
        //Checks if mintId already exists inside activeMintGroups. This allows the contract to adjust the mappings for new mint groups
        if (!isMintGroupActive(mintId)) {
            initializeNewMintGroup(mintId);
        }
        mintPrice[mintId] = newmintPrice;
        emit SalePriceChanged(mintId, newmintPrice);
    }

    //===================================START Airdrop Functions===================================//
    // Modified airdrop function to charge the owner threeDollarsEth per mint
    function airdropNFTs(
        address[] memory recipients,
        uint256[] memory amounts
    ) external payable onlyOwner returns (uint256 totalCharge) {
        if (recipients.length != amounts.length) {
            revert InvalidOperation({
                reason: "Mismatch between recipients and amounts"
            });
        }

        uint256 totalNFTToMint = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            totalNFTToMint += amounts[i];
        }

        totalCharge = quoteAirdropFees(totalNFTToMint);

        if (msg.value < totalCharge) {
            revert InvalidOperation({
                reason: "Not enough Ether sent for the airdrop charge"
            });
        }

        pendingBalances[feeAddress] += totalCharge; // Fee goes to the fee address

        for (uint256 j = 0; j < recipients.length; j++) {
            uint256 amount = amounts[j];
            if (totalSupply() + amount > maxSupply) {
                revert InvalidOperation({reason: "Airdrop exceeds max supply"});
            }

            _safeMint(recipients[j], amount); // Mint NFTs to recipients
        }

        _refundExcessEther(totalCharge);
    }

    //===================================END Airdrop Functions===================================//

    //===================================START Mint Functions===================================//

    function canMintCheck(
        uint256 amount,
        uint256 mintId,
        address minterAddress
    ) public view returns (bool, string memory) {
        if (
            amount + addressMints[minterAddress][mintId] >
            maxMintPerWallet[mintId]
        ) {
            return (false, "ExceedsMaxPerWallet");
        }

        if (amount == 0) {
            return (false, "InvalidOperation");
        }

        // Pre-conditions checks
        if (!mintLive()) {
            return (false, "MintInactive");
        }

        if (!contractPresaleActive[mintId]) {
            if (
                presaleScheduledStartTimestamp[mintId] == 0 ||
                block.timestamp <= presaleScheduledStartTimestamp[mintId]
            ) {
                return (false, "MintGroupInactive");
            }
        }

        if (mintId != 0) {
            if (mintQuotas[mintId][minterAddress] == 0) {
                return (false, "NotInPresale");
            }

            if (amount > mintQuotas[mintId][minterAddress]) {
                return (false, "ExceedsMintQuota");
            }
        }

        if (mintGroupMints[mintId] + amount > maxSupplyPerMintGroup[mintId]) {
            return (false, "ExceedsMaxMintGroupSupply");
        }

        if (totalSupply() + amount > maxSupply) {
            return (false, "ExceedsMaxSupply");
        }

        return (true, "");
    }

    // Cleaner and more efficient batchMint function
    function batchMint(
        uint256 amount,
        uint256 mintId // Remove if allowlist is off
    ) external payable returns (uint256 totalCostWithFee) {
        // Checker for connected wallet
        if (
            amount + addressMints[msg.sender][mintId] > maxMintPerWallet[mintId]
        ) {
            revert ExceedsMaxPerWallet({
                requested: amount,
                allowed: maxMintPerWallet[mintId] -
                    addressMints[msg.sender][mintId]
            });
        }

        addressMints[msg.sender][mintId] += amount;

        // NOTE: Checks and Effects should always be before (avoid reentrancy!)
        totalCostWithFee = _batchMint(msg.sender, amount, mintId);
        emit TokensMinted(msg.sender, amount, mintId);

        _refundExcessEther(totalCostWithFee);
    }

    //==================START Delegate Functions==================//
    address constant DELEGATE_REGISTRY =
        0x00000000000000447e69651d841bD8D104Bed493;

    function canDelegateMintCheck(
        uint256 amount,
        uint256 mintId,
        address vault,
        address minterAddress
    ) public view returns (bool, string memory) {
        if (
            !IDelegateRegistry(DELEGATE_REGISTRY).checkDelegateForContract(
                minterAddress,
                vault,
                address(this),
                ""
            )
        ) {
            return (false, "Unauthorized");
        }

        if (amount + addressMints[vault][mintId] > maxMintPerWallet[mintId]) {
            return (false, "ExceedsMaxPerWallet");
        }

        if (amount == 0) {
            return (false, "InvalidOperation");
        }

        // Pre-conditions checks
        if (!mintLive()) {
            return (false, "MintInactive");
        }

        if (!contractPresaleActive[mintId]) {
            if (
                presaleScheduledStartTimestamp[mintId] == 0 ||
                block.timestamp <= presaleScheduledStartTimestamp[mintId]
            ) {
                return (false, "MintGroupInactive");
            }
        }

        if (mintId != 0) {
            if (mintQuotas[mintId][vault] == 0) {
                return (false, "NotInPresale");
            }

            if (amount > mintQuotas[mintId][vault]) {
                return (false, "ExceedsMintQuota");
            }
        }

        if (mintGroupMints[mintId] + amount > maxSupplyPerMintGroup[mintId]) {
            return (false, "ExceedsMaxMintGroupSupply");
        }

        if (totalSupply() + amount > maxSupply) {
            return (false, "ExceedsMaxSupply");
        }

        return (true, "");
    }

    function delegatedMint(
        uint256 amount,
        uint256 mintId,
        address vault
    ) external payable returns (uint256 totalCostWithFee) {
        if (
            !IDelegateRegistry(DELEGATE_REGISTRY).checkDelegateForContract(
                msg.sender,
                vault,
                address(this),
                ""
            )
        ) {
            revert Unauthorized(vault);
        }

        // Checker for vault wallet
        if (amount + addressMints[vault][mintId] > maxMintPerWallet[mintId]) {
            revert ExceedsMaxPerWallet({
                requested: amount,
                allowed: maxMintPerWallet[mintId] - addressMints[vault][mintId]
            });
        }

        addressMints[vault][mintId] += amount;

        // NOTE: Checks and Effects should always be before (avoid reentrancy!)
        totalCostWithFee = _batchMint(vault, amount, mintId);
        emit TokensDelegateMinted(vault, msg.sender, amount, mintId);

        _refundExcessEther(totalCostWithFee);
    }

    //==================START Internal Mint Functions==================//
    function _batchMint(
        address delegatedCaller,
        uint256 amount,
        uint256 mintId
    ) internal returns (uint256) {
        if (amount == 0) {
            revert InvalidOperation({reason: "Amount must be greater than 0"});
        }

        // Pre-conditions checks
        if (!mintLive()) {
            revert MintInactive();
        }

        if (!contractPresaleActive[mintId]) {
            if (
                presaleScheduledStartTimestamp[mintId] == 0 ||
                block.timestamp <= presaleScheduledStartTimestamp[mintId]
            ) {
                revert MintGroupInactive({mintId: mintId});
            }
        }

        if (mintId != 0) {
            if (mintQuotas[mintId][delegatedCaller] == 0) {
                revert NotInPresale({caller: delegatedCaller, mintId: mintId});
            }

            if (amount > mintQuotas[mintId][delegatedCaller]) {
                revert ExceedsMintQuota({
                    requested: amount,
                    allowed: mintQuotas[mintId][delegatedCaller]
                });
            }
            mintQuotas[mintId][delegatedCaller] -= amount;
        }

        if (mintGroupMints[mintId] + amount > maxSupplyPerMintGroup[mintId]) {
            revert ExceedsMaxMintGroupSupply({
                requested: amount,
                available: maxSupplyPerMintGroup[mintId] -
                    mintGroupMints[mintId]
            });
        }

        if (totalSupply() + amount > maxSupply) {
            revert ExceedsMaxSupply({
                requested: amount,
                available: maxSupply - totalSupply()
            });
        }

        // Calculate fees, check if we have enough msg.value
        (
            uint256 totalCostWithFee,
            uint256 mintingCost,
            uint256 minterFee,
            uint256 creatorFee
        ) = quoteBatchMint(mintId, amount);

        if (msg.value < totalCostWithFee) {
            revert InsufficientEther({
                required: totalCostWithFee,
                provided: msg.value
            });
        }

        uint256 totalFee = minterFee + creatorFee;

        // Update balances
        pendingBalances[feeAddress] += totalFee;
        pendingBalances[ownerPayoutAddress] += mintingCost - creatorFee;

        // Finalize minting
        mintGroupMints[mintId] += amount;
        _safeMint(msg.sender, amount);

        return totalCostWithFee;
    }

    // @notice Quote the total cost of minting a batch of tokens
    // @dev This is the same price for both the owner and the delegate
    // @param mintId The mint group ID
    // @param amount The number of tokens to mint
    // @return totalCostWithFee The total cost of minting the batch, including the minter fee
    // @return mintingCost The base cost of minting without any fees
    // @return minterFee The fixed $3 fee per token minted
    // @return creatorFee The 3% fee calculated from the base minting cost
    function quoteBatchMint(
        uint256 mintId,
        uint256 amount
    )
        public
        view
        returns (
            uint256 totalCostWithFee,
            uint256 mintingCost,
            uint256 minterFee,
            uint256 creatorFee
        )
    {
        mintingCost = mintPrice[mintId] * amount;
        minterFee = threeDollarsEth() * amount; // $3 fee
        creatorFee = (mintingCost * 3) / 100; // 3% fee from creators
        totalCostWithFee = mintingCost + minterFee;
    }

    // @notice Quote the total cost of airdropping a batch of tokens
    // @param amount The number of tokens to mint
    // @return totalAirdropCostWithFee The total cost of minting the batch ($0.33 per nft)
    function quoteAirdropFees(
        uint256 amount
    ) public view returns (uint256 totalAirdropCostWithFee) {
        totalAirdropCostWithFee = (threeDollarsEth() * amount * 11) / 100; // UPDATE: Changed airdrop fees to be $0.33 instead.
    }

    //==================END Delegate Functions==================//

    //===================================END Mint Functions===================================//
    //===================================START Base Functions===================================//

    // Changes the minting status. Only the contract owner can call this function.
    function changeMintStatus(bool status) public onlyOwner {
        if (contractMintLive == status) {
            revert InvalidOperation({
                reason: "Mint status is already the one you entered"
            });
        }

        if (status == false) {
            scheduledMintLiveTimestamp = 0;
        }

        contractMintLive = status;
    }

    function setMintLiveTimestamp(uint256 timestamp) public onlyOwner {
        scheduledMintLiveTimestamp = timestamp;
    }

    // Sets the base URI for the token metadata. Only the contract owner can call this function.
    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
        emit BatchMetadataUpdate(1, type(uint256).max); // Signal that all token metadata has been updated
    }

    function _withdrawFor(address user) internal returns (uint256 payout) {
        payout = pendingBalances[user];
        pendingBalances[user] = 0;
        (bool success, ) = payable(user).call{value: payout}("");
        if (!success) {
            revert InvalidOperation({reason: "Withdraw Transfer Failed"});
        }
    }

    // Allows the contract owner to withdraw the funds that have been paid into the contract.
    function withdrawMintFunds() public {
        _withdrawFor(ownerPayoutAddress);
        _withdrawFor(feeAddress);
    }

    // Allows the fee address to withdraw their portion of the funds.
    function withdrawFeeFunds() public {
        _withdrawFor(feeAddress);
    }

    // Internal function to refund excess Ether sent in a transaction
    function _refundExcessEther(uint256 totalCharge) internal {
        uint256 excess = msg.value - totalCharge;
        if (excess > 0) {
            (bool success, ) = payable(msg.sender).call{value: excess}("");
            if (!success) {
                pendingBalances[msg.sender] += excess;
            }
        }
    }

    // Returns the base URI for the token metadata.
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    // Checks the balance pending withdrawal for the sender.
    function checkPendingBalance() public view returns (uint256) {
        return pendingBalances[msg.sender];
    }

    function checkPendingBalanceFor(
        address user
    ) public view returns (uint256) {
        return pendingBalances[user];
    }

    // Overrides the start token ID function from the ERC721A contract.
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721AC, ERC2981) returns (bool) {
        return
            ERC721AC.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }
    //===================================END Base Functions===================================//

    // ###################### Kingdomly Admin Functions ######################

    function setNewKingdomlyFeeContract(
        KingdomlyFeeContract _kingdomlyFeeContract
    ) external isKingdomlyAdmin {
        if (address(_kingdomlyFeeContract) == address(0)) {
            revert InvalidKingdomlyFeeContract();
        }

        kingdomlyFeeContract = _kingdomlyFeeContract;

        emit KingdomlyFeeContractChanged(address(_kingdomlyFeeContract));
    }

    function getKingdomlyFeeContract()
        external
        view
        returns (KingdomlyFeeContract)
    {
        return kingdomlyFeeContract;
    }

    // ###################### Fee Functions ######################

    function getOneDollarInWei() internal view returns (uint256) {
        return kingdomlyFeeContract.getOneDollarInWei();
    }

    function threeDollarsEth() public view returns (uint256) {
        return (getOneDollarInWei() * threeDollarsInCents) / 100;
    }

    // ###################### Royalty Functions ######################

    function _requireCallerIsContractOwner() internal view virtual override {
        _checkOwner();
    }

    function setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) external onlyOwner {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    // ###################### Owner Functions ######################

    function setOwnerPayoutAddress(
        address _ownerPayoutAddress
    ) external onlyOwner {
        ownerPayoutAddress = _ownerPayoutAddress;
    }
}
