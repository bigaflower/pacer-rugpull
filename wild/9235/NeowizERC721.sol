// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "./libs/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./libs/@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "./libs/@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "./libs/@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "./libs/@openzeppelin/contracts/access/Ownable.sol";
import "./libs/@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./libs/@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./libs/@openzeppelin/contracts/interfaces/IERC1363Receiver.sol";
import "./libs/@openzeppelin/contracts/interfaces/IERC1363Spender.sol";
import "./metatx/ERC2771ContextFromStorage.sol";
import "./erc721-permits/ERC721WithPermit.sol";
import "./interfaces/INeowizERC721.sol";

/**
 * @title NeowiERC721
 * @notice The minting process goes as follows.
 *   0. setBaseURI
 *   1. teamMint: The contract owner can call anytime even during the minting round. It is usually called before the first minting round starts.
 *   2. privateMint, publicMint: The total mintable amount in the last round is (round.maxMint + leftover amounts in the previous rounds).
 *   3. mintResidue: The owner should mint all to reveal the collection.
 *   4. requestRandomSeed: To reveal, the contract owner should call this function to get the random seed.
 */
abstract contract NeowizERC721 is
    INeowizERC721,
    IERC1363Receiver,
    IERC1363Spender,
    ERC721Burnable,
    ERC721Royalty,
    ERC721WithPermit,
    ERC2771ContextFromStorage,
    ReentrancyGuard,
    Ownable
{
    error NotExistingRound();
    error ZeroMaxTotalSupply();
    error WrongSaleRound();
    error RoundNotStarted();
    error InvalidTimestamp();
    error RoundEnded();
    error NotPublic();
    error NotPrivate();
    error NotSoldout();
    error NotAllRoundsFinished();
    error IncorrectProof();
    error NotEnoughFund();
    error NotEnoughERC20Fund();
    error PriceNotSet();
    error MaxMintExceeded(uint256 round);
    error MaxMintPerAccountExceeded(uint256 round, address account);
    error MaxTotalSupplyExceeded();
    error MaxTotalTeamMintExceeded();
    error AlreadyRevealed();
    error InvalidCollectorRatio();
    error AddressZero();

    address public immutable team;

    // base uri for nfts
    string private baseURI;

    // Valid currentRound starts from 1, and default is 0.
    uint256 private _currentRound;

    // The next token ID to be team-minted.
    uint256 private _currentTeamIndex;

    // The next token ID to be minted.
    uint256 private _currentIndex;

    // The number of tokens burned.
    uint256 private _burnCounter;

    // Operator
    address private _operator;

    uint256 public numRounds;
    mapping(uint256 => Round) public rounds;

    address public payment;
    uint256 public randomSeed;
    bool public revealed;
    string public unrevealedURI;
    uint256 public immutable TEAM_SUPPLY;
    uint256 public immutable MAX_TOTAL_SUPPLY;

    struct SalesInfo {
        address collector1;
        address collector2;
        uint16 collector1Ratio;
    }
    SalesInfo public salesInfo;

    uint16 public constant ratioDenominator = 10000;

    enum SaleState {
        PRIVATE,
        PUBLIC
    }

    /**
     * @dev In a round, users can mint until `round.totalMinted` == `round.maxMint`.
     * If it is the last round, users can mint more than maxMint until totalSupply() == MAX_TOTAL_SUPPLY.
     * `numberMinted` is necessary to allow users to mint multiple times in a round,
     * as long as they have minted less than `MAX_MINT_PER_ACCOUNT` in the round.;
     * @param state The minting round proceeds like CLOSED -> OG -> WL -> PUBLIC_0 -> PUBLIC_1.
     * However, any rounds may be omitted, i.e. a minting with only WL round is possible.
     */
    struct Round {
        mapping(address => uint256) numberMinted;
        uint256 maxMintPerAccount;
        uint256 maxMint;
        uint256 totalMinted;
        uint256 price;
        SaleState state;
        bytes32 merkleRoot;
        uint64 startTs;
        uint64 endTs;
    }

    /// @param _name name in ERC721
    /// @param _symbol symbol in ERC721
    /// @param _maxTotalSupply The max number of NFTs to be minted
    /// @param _teamSupply The reserved quantity for team
    /// @param _team address of team
    /// @param _payment address of ERC20 token to be paid when minting NFT. address(0) is ETH.
    /// @param _unrevealedURI ipfs uri when NFT has not yet revealed
    /// @param _trustedForwarder address of ERC2771 forwarder
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _maxTotalSupply,
        uint256 _teamSupply,
        address _team,
        address _payment,
        string memory _unrevealedURI,
        address _trustedForwarder,
        SalesInfo memory _salesInfo
    ) ERC721(_name, _symbol) ERC2771ContextFromStorage(_trustedForwarder) {
        if (_salesInfo.collector1 == address(0) || _salesInfo.collector2 == address(0)) {
            revert AddressZero();
        }
        if (_maxTotalSupply == 0) {
            revert ZeroMaxTotalSupply();
        }
        if (_salesInfo.collector1Ratio > ratioDenominator) {
            revert InvalidCollectorRatio();
        }
        MAX_TOTAL_SUPPLY = _maxTotalSupply;
        TEAM_SUPPLY = _currentIndex = _teamSupply;
        team = _team;
        payment = _payment;
        unrevealedURI = _unrevealedURI;
        salesInfo = _salesInfo;
    }

    modifier onlyOperator() {
        require(
            operator() == _msgSender() || owner() == _msgSender(),
            "NeowizERC721: caller is not the operator or owner"
        );
        _;
    }

    modifier whenSoldout() {
        if (totalMinted() < MAX_TOTAL_SUPPLY) {
            revert NotSoldout();
        }
        _;
    }

    modifier inRound(uint256 _round) {
        Round storage round = rounds[_round];
        if (numRounds < _round) {
            revert WrongSaleRound();
        }
        if (block.timestamp < round.startTs) {
            revert RoundNotStarted();
        }
        if (round.endTs <= block.timestamp) {
            revert RoundEnded();
        }
        _;
    }

    modifier isPublic(uint256 _round) {
        if (rounds[_round].state != SaleState.PUBLIC) {
            revert NotPublic();
        }
        _;
    }

    modifier isPrivate(uint256 _round) {
        SaleState state = rounds[_round].state;
        if (state != SaleState.PRIVATE) {
            revert NotPrivate();
        }
        _;
    }

    modifier checkRound(uint256 _roundId) {
        if (numRounds < _roundId) {
            revert NotExistingRound();
        }
        _;
    }

    /// @dev onlyOwner
    function setOperator(address newOperator) external onlyOwner {
        require(newOperator != address(0), "NeowizERC721: new operator is the zero address");
        _setOperator(newOperator);
    }

    /// @dev onlyOwner
    function setTrustedForwarder(address _forwarder) external onlyOwner {
        _trustedForwarder = _forwarder;
        emit NewTrustedForwarder(_forwarder);
    }

    function burn(uint256 tokenId) public override(INeowizERC721, ERC721Burnable) {
        super.burn(tokenId);
        _burnCounter++;
    }

    /// @dev onlyOperator
    function setPayment(address _payment) external onlyOperator {
        payment = _payment;
        emit PaymentUpdated(_payment);
    }

    /// @dev onlyOperator
    function setUnRevealedURI(string memory _unrevealedURI) external onlyOperator {
        unrevealedURI = _unrevealedURI;
        emit UnrevealedURIUpdated(_unrevealedURI);
    }

    /// @notice Add a minting round
    /// @dev onlyOperator
    /// @param _state private or public
    /// @param _maxMintPerAccount The max amount of tokens one account can mint in this round
    /// @param _maxMint The max amount of tokens reserved in this round
    /// @param _price The unit price per token
    /// @param _merkleRoot This is useful only in a private round
    /// @param _startTs The timestamp when this round starts
    /// @param _endTs The timestamp when this round ends
    function addRound(
        SaleState _state,
        uint256 _maxMintPerAccount,
        uint256 _maxMint,
        uint256 _price,
        bytes32 _merkleRoot,
        uint256 _startTs,
        uint256 _endTs
    ) external onlyOperator {
        if (_endTs < _startTs) {
            revert InvalidTimestamp();
        }
        if (_startTs < rounds[numRounds].endTs) {
            revert InvalidTimestamp();
        }

        Round storage r = rounds[++numRounds];
        r.state = _state;
        r.maxMintPerAccount = _maxMintPerAccount;
        r.maxMint = _maxMint;
        r.price = _price;
        r.merkleRoot = _merkleRoot;
        r.startTs = uint64(_startTs);
        r.endTs = uint64(_endTs);

        emit RoundAdded(
            numRounds,
            uint256(_state),
            _maxMintPerAccount,
            _maxMint,
            _price,
            _merkleRoot,
            _startTs,
            _endTs
        );
    }

    /// @dev onlyOperator
    function updateState(uint256 _roundId, SaleState _state) external checkRound(_roundId) onlyOperator {
        Round storage r = rounds[_roundId];
        r.state = _state;

        emit StateUpdated(_roundId, uint256(_state));
    }

    /// @dev onlyOperator
    function updateMaxMint(uint256 _roundId, uint256 _maxMint) external checkRound(_roundId) onlyOperator {
        Round storage r = rounds[_roundId];
        r.maxMint = _maxMint;
        emit MaxMintUpdated(_roundId, _maxMint);
    }

    /// @dev onlyOperator
    function updateMaxMintPerAccount(
        uint256 _roundId,
        uint256 _maxMintPerAccount
    ) external checkRound(_roundId) onlyOperator {
        Round storage r = rounds[_roundId];
        r.maxMintPerAccount = _maxMintPerAccount;
        emit MaxMintPerAccountUpdated(_roundId, _maxMintPerAccount);
    }

    /// @dev onlyOperator
    function updatePrice(uint256 _roundId, uint256 _price) external checkRound(_roundId) onlyOperator {
        Round storage r = rounds[_roundId];
        r.price = _price;
        emit PriceUpdated(_roundId, _price);
    }

    /// @dev onlyOperator
    function updateMerkleRoot(uint256 _roundId, bytes32 _merkleRoot) external checkRound(_roundId) onlyOperator {
        Round storage r = rounds[_roundId];
        r.merkleRoot = _merkleRoot;
        emit MerkleRootUpdated(_roundId, _merkleRoot);
    }

    /// @dev onlyOperator
    /// @param _startTs _startTs must >= endTs of the previous round
    /// @param _endTs _endTs must <= startTs of the next round
    function updateRoundTimestamp(
        uint256 _roundId,
        uint256 _startTs,
        uint256 _endTs
    ) external checkRound(_roundId) onlyOperator {
        if (_endTs < _startTs) {
            revert InvalidTimestamp();
        }
        Round storage r = rounds[_roundId];

        if (_roundId < numRounds && rounds[_roundId + 1].startTs < _endTs) {
            revert InvalidTimestamp();
        }

        if (1 < _roundId && _startTs < rounds[_roundId - 1].endTs) {
            revert InvalidTimestamp();
        }

        r.startTs = uint64(_startTs);
        r.endTs = uint64(_endTs);

        emit RoundTimestampUpdated(_roundId, _startTs, _endTs);
    }

    /// @dev onlyOperator
    function setBaseURI(string memory _uri) external onlyOperator {
        require(bytes(_uri).length > 0, "wrong base uri");
        baseURI = _uri;
        emit BaseURIUpdated(_uri);
    }

    /// @notice Sets the contract-wide ERC-2981 royalty info.
    /// @dev onlyOwner
    /// @param receiver Royalty receiver address
    /// @param feeBasisPoints The fee rate is equal to `feeBasisPoint / ERC2981._feeDenominator()`
    function setRoyaltyInfo(address receiver, uint96 feeBasisPoints) external onlyOwner {
        _setDefaultRoyalty(receiver, feeBasisPoints);
        emit RoyaltyInfoUpdated(receiver, feeBasisPoints);
    }

    /// @notice Mint unminted nfts to `team` before the reveal. This excludes the team amount.
    /// @dev onlyOperator
    /// @param _quantity Given type(uint256).max, mint all remainders except for the team amount.
    function mintResidue(uint256 _quantity) external onlyOperator {
        // Check
        if (_quantity == type(uint256).max) {
            _quantity = _notTeamResidue();
        }
        if (block.timestamp < rounds[numRounds].endTs) {
            revert NotAllRoundsFinished();
        }
        if (_notTeamResidue() < _quantity) {
            revert MaxTotalSupplyExceeded();
        }

        // Effect
        _currentIndex += _quantity;

        // Interaction
        _mintNotTeamQuantity(team, _quantity);
    }

    /// @notice Mint to `team`
    /// @dev onlyOperator
    /// @param _quantity The number of tokens to mint.
    function teamMint(uint256 _quantity) external onlyOperator {
        if (_quantity == type(uint256).max) {
            _quantity = TEAM_SUPPLY - totalTeamMinted();
        }
        if (TEAM_SUPPLY < totalTeamMinted() + _quantity) {
            revert MaxTotalTeamMintExceeded();
        }

        _currentTeamIndex += _quantity;

        _mintTeamQuantity(team, _quantity);
    }

    /// @notice Mint a public drop
    /// @param _quantity The number of tokens to mint.
    /// @param _round The round id
    /// @param _payment The payment token address
    /// @param _price The price of one nft
    function publicMint(uint256 _quantity, uint256 _round, address _payment, uint256 _price) external payable {
        _publicMint(_msgSender(), false, _quantity, _round, _payment, _price);
    }

    function _publicMint(
        address _from,
        bool _isPaid,
        uint256 _quantity,
        uint256 _round,
        address _payment,
        uint256 _price
    ) internal inRound(_round) isPublic(_round) {
        Round storage round = rounds[_round];
        require(_payment == address(payment), "payment is different");
        require(_price == round.price, "round price is different");

        if (!_isPaid) {
            _payMintFee(_from, round.price * _quantity);
        }
        _mintInRound(_round, _from, _quantity);
    }

    /// @notice Mint a private drop
    /// @dev Private round only allows whitelisted users.
    /// @param _merkleProof The proof for the leaf of the whitelist.
    /// @param _quantity The number of tokens to mint.
    /// @param _round The round id
    /// @param _payment The payment token address
    /// @param _price The price of one nft
    function privateMint(
        bytes32[] calldata _merkleProof,
        uint256 _quantity,
        uint256 _round,
        address _payment,
        uint256 _price
    ) external payable {
        _privateMint(_msgSender(), false, _merkleProof, _quantity, _round, _payment, _price);
    }

    function _privateMint(
        address _from,
        bool _isPaid,
        bytes32[] memory _merkleProof,
        uint256 _quantity,
        uint256 _round,
        address _payment,
        uint256 _price
    ) internal inRound(_round) isPrivate(_round) {
        Round storage round = rounds[_round];
        require(_payment == address(payment), "payment is different");
        require(_price == round.price, "round price is different");

        checkValidity(_merkleProof, rounds[_round].merkleRoot, _from);
        if (!_isPaid) {
            _payMintFee(_from, round.price * _quantity);
        }
        _mintInRound(_round, _from, _quantity);
    }

    /// @notice Mint a public drop with ERC20 permit signature
    /// @param _quantity The number of tokens to mint.
    /// @param _round The round id
    /// @param _payment The payment token address
    /// @param _price The price of one nft
    /// @param v ERC20Permit signature v from the`owner`
    /// @param r ERC20Permit signature r from the`owner`
    /// @param s ERC20Permit signature s from the`owner`
    function publicMintWithPermit(
        uint256 _quantity,
        uint256 _round,
        address _payment,
        uint256 _price,
        uint256 _deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        _permitPayment(_price * _quantity, _deadline, v, r, s);
        _publicMint(_msgSender(), false, _quantity, _round, _payment, _price);
    }

    /// @notice Mint a private drop with ERC20 permit signature
    /// @dev Private round only allows whitelisted users.
    /// @param _merkleProof The proof for the leaf of the whitelist.
    /// @param _quantity The number of tokens to mint.
    /// @param _round The round id
    /// @param _payment The payment token address
    /// @param _price The price of one nft
    /// @param v ERC20Permit signature v from the`owner`
    /// @param r ERC20Permit signature r from the`owner`
    /// @param s ERC20Permit signature s from the`owner`
    function privateMintWithPermit(
        bytes32[] calldata _merkleProof,
        uint256 _quantity,
        uint256 _round,
        address _payment,
        uint256 _price,
        uint256 _deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable {
        _permitPayment(_price * _quantity, _deadline, v, r, s);
        _privateMint(_msgSender(), false, _merkleProof, _quantity, _round, _payment, _price);
    }

    /// @notice Check the given merkle proof is valid
    /// @dev   All leaf nodes are hashed using keccak256
    /// @param _merkleProof The proof for the leaf of the whitelist.
    /// @param _root The merkle root
    /// @param _to The address to be checked
    function checkValidity(bytes32[] memory _merkleProof, bytes32 _root, address _to) public pure {
        bytes32 leaf = keccak256(abi.encodePacked(_to));
        if (!MerkleProof.verify(_merkleProof, _root, leaf)) {
            revert IncorrectProof();
        }
    }

    /// @notice Withdraw the minting revenue
    /// @dev onlyOperator
    /// @param _amount the amount to send
    function withdraw(uint256 _amount) external onlyOperator nonReentrant {
        uint256 amount = _amount;
        if (amount == type(uint256).max) {
            amount = payment == address(0) ? address(this).balance : IERC20(payment).balanceOf(address(this));
        }
        uint256 amount1 = (amount * salesInfo.collector1Ratio) / ratioDenominator;
        uint256 amount2 = amount - amount1;
        if (address(payment) == address(0)) {
            (bool success, ) = payable(salesInfo.collector1).call{value: amount1}("");
            require(success);
            (success, ) = payable(salesInfo.collector2).call{value: amount2}("");
            require(success);
        } else {
            IERC20(payment).transfer(salesInfo.collector1, amount1);
            IERC20(payment).transfer(salesInfo.collector2, amount2);
        }
    }

    // ************* internal functions *************
    function _setOperator(address newOperator) internal virtual {
        _operator = newOperator;
        emit NewOperator(newOperator);
    }

    /**
     * @notice It is allowed to set the random seed after all tokens are minted.
     */
    function _setRandomSeed(uint256 _randomSeed) internal {
        if (revealed) {
            revert AlreadyRevealed();
        }
        randomSeed = _randomSeed % (MAX_TOTAL_SUPPLY - TEAM_SUPPLY);
        revealed = true;

        emit Revealed();
    }

    function _permitPayment(uint256 value, uint256 _deadline, uint8 v, bytes32 r, bytes32 s) internal {
        IERC20Permit(payment).permit(_msgSender(), address(this), value, _deadline, v, r, s);
    }

    function _payMintFee(address _payer, uint256 _amount) internal {
        if (payment != address(0)) {
            if (IERC20(payment).balanceOf(_payer) < _amount) {
                revert NotEnoughERC20Fund();
            }
            IERC20(payment).transferFrom(_payer, address(this), _amount);
        } else {
            if (msg.value < _amount) {
                revert NotEnoughFund();
            }
        }
    }

    /// @dev tokenId is guaranteed to be less than `MAX_TOTAL_SUPPLY`.
    function _mintInRound(uint256 _round, address _to, uint256 _quantity) internal {
        // check
        Round storage round = rounds[_round];

        if (round.maxMintPerAccount < round.numberMinted[_to] + _quantity) {
            revert MaxMintPerAccountExceeded(_round, _to);
        }

        // Skip round.maxMint check if it is the last round
        if (_round != numRounds && round.maxMint < (round.totalMinted + _quantity)) {
            revert MaxMintExceeded(_round);
        }

        if (_notTeamResidue() < _quantity) {
            revert MaxTotalSupplyExceeded();
        }

        // effect
        round.numberMinted[_to] += _quantity;
        round.totalMinted += _quantity;
        _currentIndex += _quantity;

        // interaction
        _mintNotTeamQuantity(_to, _quantity);
    }

    function _transfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721WithPermit) {
        super._transfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721Royalty) {
        super._burn(tokenId);
    }

    /// @dev Before this, increase _currentTeamIndex and check all validations
    function _mintTeamQuantity(address _to, uint256 _quantity) private {
        uint256 startId = _currentTeamIndex - _quantity;
        for (uint256 i = startId; i < startId + _quantity; i++) {
            _safeMint(_to, i);
        }
    }

    /// @dev Before this, increase _currentIndex and check all validations
    function _mintNotTeamQuantity(address _to, uint256 _quantity) private {
        uint256 startId = _currentIndex - _quantity;
        for (uint256 i = startId; i < startId + _quantity; i++) {
            _safeMint(_to, i);
        }
    }

    // ************* view functions *************
    /// @notice Query if a contract implements an interface
    /// @param interfaceId The interface identifier, as specified in ERC-165
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721Royalty, ERC721WithPermit) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @notice Returns the address of operator
     */
    function operator() public view virtual returns (address) {
        return _operator;
    }

    /// @notice Returns whether the NFT is revealed
    function isRevealed() public view override returns (bool) {
        return revealed;
    }

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() public view returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented more than `_currentIndex` times.
        unchecked {
            return totalMinted() - _burnCounter;
        }
    }

    /**
     * @notice Returns the total amount of tokens minted in the contract.
     */
    function totalMinted() public view returns (uint256) {
        unchecked {
            return _currentIndex - TEAM_SUPPLY + _currentTeamIndex;
        }
    }

    /**
     * @notice Returns the total amount of tokens minted by the team.
     */
    function totalTeamMinted() public view returns (uint256) {
        return _currentTeamIndex;
    }

    /**
     * @notice Returns the current round number
     */
    function currentRound() public view returns (uint256) {
        Round storage r;
        for (uint256 i = 1; i <= numRounds; i++) {
            r = rounds[i];
            if (r.startTs <= block.timestamp && block.timestamp < r.endTs) {
                return i;
            }
        }

        return 0;
    }

    /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    /// @dev Throws if `_tokenId` is not a valid NFT.
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        if (!revealed) {
            return unrevealedURI;
        }

        uint256 shiftedId;
        if (tokenId < TEAM_SUPPLY) {
            shiftedId = tokenId;
        } else {
            shiftedId = ((tokenId - TEAM_SUPPLY + randomSeed) % (MAX_TOTAL_SUPPLY - TEAM_SUPPLY)) + TEAM_SUPPLY;
        }

        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, Strings.toString(shiftedId))) : "";
    }

    /// @notice Returns how many tokens the account minted in the round
    function numberMintedInRound(address _account, uint256 _round) external view returns (uint256) {
        return rounds[_round].numberMinted[_account];
    }

    function _notTeamResidue() internal view returns (uint256) {
        unchecked {
            return MAX_TOTAL_SUPPLY - _currentIndex;
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    event TransferReceived(address token, address operator, address from, uint256 amount, bytes data);
    event ApprovalReceived(address token, address owner, uint256 amount, bytes data);

    modifier onlyPayment() {
        require(msg.sender == address(payment), "only ERC1363 payment");
        _;
    }

    function onTransferReceived(
        address _sender,
        address _from,
        uint256 _amount,
        bytes calldata _data
    ) external override onlyPayment returns (bytes4) {
        emit TransferReceived(msg.sender, _sender, _from, _amount, _data);

        bytes4 selector = bytes4(_data[:4]);
        bytes calldata data = _data[4:];
        if (selector == this.publicMint.selector) {
            (uint256 _quantity, uint256 _round, address _payment, uint256 _price) = abi.decode(
                data,
                (uint256, uint256, address, uint256)
            );
            require(_quantity * _price == _amount, "onTransferReceived: invalid amount");

            _publicMint(_from, true, _quantity, _round, _payment, _price);
        } else if (selector == this.privateMint.selector) {
            (bytes32[] memory _merkleProof, uint256 _quantity, uint256 _round, address _payment, uint256 _price) = abi
                .decode(data, (bytes32[], uint256, uint256, address, uint256));
            require(_quantity * _price == _amount, "onTransferReceived: invalid amount");

            _privateMint(_from, true, _merkleProof, _quantity, _round, _payment, _price);
        } else {
            revert("onTransferReceived: function selector not supported");
        }
        return this.onTransferReceived.selector;
    }

    function onApprovalReceived(
        address _owner,
        uint256 _amount,
        bytes calldata _data
    ) external override onlyPayment returns (bytes4) {
        emit ApprovalReceived(msg.sender, _owner, _amount, _data);

        bytes4 selector = bytes4(_data[:4]);
        bytes memory data = _data[4:];
        if (selector == this.publicMint.selector) {
            (uint256 _quantity, uint256 _round, address _payment, uint256 _price) = abi.decode(
                data,
                (uint256, uint256, address, uint256)
            );
            _publicMint(_owner, false, _quantity, _round, _payment, _price);
        } else if (selector == this.privateMint.selector) {
            (bytes32[] memory _merkleProof, uint256 _quantity, uint256 _round, address _payment, uint256 _price) = abi
                .decode(data, (bytes32[], uint256, uint256, address, uint256));
            _privateMint(_owner, false, _merkleProof, _quantity, _round, _payment, _price);
        } else {
            revert("onApprovalReceived: function selector not supported");
        }
        return this.onApprovalReceived.selector;
    }

    function _msgSender() internal view virtual override(Context, ERC2771ContextFromStorage) returns (address sender) {
        return super._msgSender();
    }

    function _msgData() internal view virtual override(Context, ERC2771ContextFromStorage) returns (bytes calldata) {
        return super._msgData();
    }
}
