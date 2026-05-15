// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// import "./openzeppelin/ERC721.sol";
import "./openzeppelin/ERC2981.sol";
import "./openzeppelin/Strings.sol";
import "./openzeppelin/IERC721Receiver.sol";
import "./openzeppelin/EnumerableSet.sol";

import "./kbt/KBT721.sol";
import "./IMainContract.sol";

contract GUMain is KBT721, ERC2981, IERC721Receiver {
    using Strings for uint;
    using Strings for address;
    using EnumerableSet for EnumerableSet.AddressSet;

    bool public isSwitchBackEnabled = false;
    address public originalGuContractAddress;
    IERC721 public originalGuContract;

    string private _uriPrefix = "https://rising.genuineundead.com/api/nft/";
    string private _uriSuffix = ".json";

    mapping(uint => string) private _tokenImages;
    event TokenEngraved(uint indexed tokenId, string base64Image);

    EnumerableSet.AddressSet private _filterOperators;

    constructor(
        address _originalGuContractAddress
    ) KBT721("Genuine Undead V2", "GUV2") {
        _setDefaultRoyalty(address(this), 500);

        originalGuContractAddress = _originalGuContractAddress;
        originalGuContract = IERC721(originalGuContractAddress);
    }

    // region modifiers
    modifier onlyAllowedOperator(address operator) {
        require(
            operator == _msgSender() || !checkFilterOperator(_msgSender()),
            "Operator is not allowed"
        );
        _;
    }

    modifier onlyAllowedOperatorApproval(address operator) {
        require(!checkFilterOperator(operator), "Operator is not allowed");
        _;
    }
    //endregion

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC2981, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // region IMainContract functions

    function withdraw(uint _amount, address _receiver) external onlyOwner {
        require(_amount <= address(this).balance, "Insufficient balance");
        payable(_receiver).transfer(_amount);
    }

    function changePreffixAndSuffix(
        string calldata _prefix,
        string calldata _suffix
    ) external onlyOwner {
        _uriPrefix = _prefix;
        _uriSuffix = _suffix;
    }

    function setDefaultRoyalty(
        address _royaltyRecipient,
        uint _percentage
    ) external onlyOwner {
        _setDefaultRoyalty(_royaltyRecipient, uint96(_percentage));
    }

    function enableSwitchBack() external onlyOwner {
        isSwitchBackEnabled = true;
    }

    //endregion

    // region ERC2981 functions

    function getDefaultRoyaltyInfo()
        public
        view
        returns (address receiver, uint feeNumerator)
    {
        (receiver, feeNumerator) = royaltyInfo(0, 10000);
    }

    // endregion

    // region tokenURI

    function _baseURI() internal view virtual override returns (string memory) {
        return _uriSuffix;
    }

    function tokenURI(
        uint tokenId
    ) public view virtual override returns (string memory) {
        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(_uriPrefix, tokenId.toString(), baseURI)
                )
                : "";
    }

    // endregion

    // region NFT Swap

    function swapNFTs(uint[] memory tokenIds) external {
        bool tempIsApprovedForAll = originalGuContract.isApprovedForAll(
            msg.sender,
            address(this)
        );

        for (uint i = 0; i < tokenIds.length; i++) {
            uint tokenId = tokenIds[i];
            address currentOwner = originalGuContract.ownerOf(tokenId);
            require(
                currentOwner == msg.sender,
                "Mint has failed, sender is not the holder of the whole tokens"
            );
        }

        if (!tempIsApprovedForAll) {
            for (uint i = 0; i < tokenIds.length; i++) {
                uint tokenId = tokenIds[i];
                address approvedAddress = originalGuContract.getApproved(
                    tokenId
                );
                require(
                    approvedAddress == address(this),
                    string(
                        abi.encodePacked(
                            "Mint has failed, sender has not approved the current contract as a spender for the tokens. Approved Address: ",
                            approvedAddress.toHexString(),
                            ", Contract Address: ",
                            address(this).toHexString()
                        )
                    )
                );
            }
        }

        for (uint i = 0; i < tokenIds.length; i++) {
            uint tokenId = tokenIds[i];

            originalGuContract.safeTransferFrom(
                msg.sender,
                address(this),
                tokenId,
                ""
            );

            _mint(msg.sender, tokenId);
        }
    }

    // endregion

    // region SwitchBack

    function switchBackNFTs(uint[] memory tokenIds) external {
        require(isSwitchBackEnabled == true, "SwitchBack is not enabled");

        for (uint i = 0; i < tokenIds.length; i++) {
            uint tokenId = tokenIds[i];
            address currentOwner = ownerOf(tokenId);
            require(
                currentOwner == msg.sender,
                "SwitchBack has failed, sender is not the holder of the whole tokens"
            );
        }

        for (uint i = 0; i < tokenIds.length; i++) {
            uint tokenId = tokenIds[i];
            _burn(tokenId);

            originalGuContract.safeTransferFrom(
                address(this),
                msg.sender,
                tokenId,
                ""
            );
        }
    }

    // endregion

    // region Engrave

    function engraveToken(uint tokenId, string calldata base64Image) external {
        require(
            ownerOf(tokenId) == msg.sender,
            "Caller is not the owner of the token"
        );
        _tokenImages[tokenId] = base64Image;

        emit TokenEngraved(tokenId, base64Image);
    }

    function getEngravedData(uint tokenId) public view returns (string memory) {
        return _tokenImages[tokenId];
    }

    // endregion

    // region Filter Operators

    function checkFilterOperator(address operator) private view returns (bool) {
        return _filterOperators.contains(operator);
    }

    function getFilteredOperators() external view returns (address[] memory) {
        return _filterOperators.values();
    }

    function addFilterOperators(
        address[] calldata operators
    ) external onlyOwner {
        for (uint256 i; i < operators.length; ) {
            _filterOperators.add(operators[i]);
            unchecked {
                ++i;
            }
        }
    }

    function removeFilterOperators(
        address[] calldata operators
    ) external onlyOwner {
        for (uint256 i; i < operators.length; ) {
            _filterOperators.remove(operators[i]);
            unchecked {
                ++i;
            }
        }
    }

    // endregion

    // region Override following method to auto restrict marketplace contract

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    //endregion

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    receive() external payable {}
}
