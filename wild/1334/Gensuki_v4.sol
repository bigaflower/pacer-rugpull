// SPDX-License-Identifier: MIT

// Developer : Zeno, Twitter : @0xZenoUsman

pragma solidity >=0.7.0 <0.9.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol"; // Import ERC2981
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; 
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract Erc721AMintable is ERC721A, Ownable, ReentrancyGuard, DefaultOperatorFilterer, ERC2981 {
    using SafeERC20 for IERC20;
    string public baseURI;
    string public notRevealedUri;
    bool public paused = false;
    bool public appendJson = true;
    address payable public constant platformWallet = payable(0xd64328482A8A5BC6520BaeA10f8C864ee736e970); // Address to receive 
    uint256 public platformFeePercentage = 250; // Platform fee as basis points (2.5%
    mapping(address => bool) public allowedPaymentTokens;
    mapping(address => bool) public isPayee;
    bool public referralEnabled;
    address public referralAddress;
    uint256 public referralFeeBP; 
    uint256 public maxSupply;
    bool public isRandom;
    uint256[] public phaseIds;
    mapping(uint256 => bool) public phaseExists;
    mapping(uint256 => uint256) public phaseStartTokenId;
    mapping(uint256 => uint256) public phaseStartIndex;
    mapping(uint256 => bool) public phaseRevealed;
    mapping(uint256 => Phase) public phases;
    mapping(uint256 => mapping(address => uint256)) public mintedPerPhase;
   struct Payee {
    uint256 shares;
    uint256 releasedETH;
}

    mapping(address => Payee) public payees;
    address[] public payeeList;
    uint256 public totalShares;

mapping(address => mapping(address => uint256)) public erc20Released;
mapping(address => uint256) public totalERC20Released;
uint256 public totalETHReleased;
mapping(address => uint256) public ethCredit;
mapping(address => mapping(address => uint256)) public erc20Credit;

    mapping(uint256 => uint256) public phaseMinted;
    address[] public allowedERC20List;
   modifier onlyPayee() {
    require(isPayee[msg.sender], "Caller is not a payee");
    _;
}

    // payee => token => claimed

      enum PhaseType {
        PUBLIC,
        WL
    }

     struct Phase {
        bool active;
        PhaseType phaseType;

        uint256 price; // 18 decimals
        uint256 maxPerWallet;
        uint256 maxSupply; // 0 = unlimited

        bytes32 merkleRoot;

        bool allowERC20;
        address[] allowedTokens;

        uint256 startTime; // 0 = none
        uint256 endTime;   // 0 = none
    }

    event Minted(
    address indexed minter,
    uint256 indexed phaseId,
    uint256 quantity,
    address paymentToken,
    uint256 totalPrice
);

constructor(
    string memory name_,
    string memory symbol_,
    uint256 maxSupply_,
    bool referralEnabled_,
    address referralAddress_,
    uint256 referralFeeBP_,
    address _royaltyWallet,
    uint96 _royaltyPercentage,
    address[] memory initialAllowedERC20,
    string memory baseURI_
) ERC721A(name_, symbol_) Ownable(msg.sender) {
    require(referralFeeBP_ <= platformFeePercentage, "Referral too high");
    baseURI = baseURI_;
    maxSupply = maxSupply_;
    setRoyaltyInfo(_royaltyWallet, _royaltyPercentage); 
    referralEnabled = referralEnabled_;
    referralAddress = referralAddress_;
    referralFeeBP = referralFeeBP_;

    // ✅ Initialize allowed ERC20 tokens (mapping + iterable list)
    for (uint256 i; i < initialAllowedERC20.length; i++) {
        address token = initialAllowedERC20[i];
        require(token != address(0), "Zero token");

        if (!allowedPaymentTokens[token]) {
            allowedPaymentTokens[token] = true;
            allowedERC20List.push(token);
        }
    }
}


   function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
    
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }


   function setPhase(
    uint256 id,
    bool active,
    PhaseType phaseType,
    uint256 price,
    uint256 maxPerWallet,
    uint256 maxSupply_,
    bytes32 merkleRoot,
    bool allowERC20,
    address[] calldata allowedTokens,
    uint256 startTime,
    uint256 endTime
) external onlyOwner {

    require(!phaseExists[id], "Phase already exists");
    require(endTime == 0 || endTime > startTime, "Invalid time");

    if (allowERC20) {
        for (uint256 i = 0; i < allowedTokens.length; i++) {
            require(
                allowedPaymentTokens[allowedTokens[i]],
                "Phase token not globally allowed"
            );
        }
    } else {
        require(allowedTokens.length == 0, "ERC20 disabled for phase");
    }

    phases[id] = Phase(
        active,
        phaseType,
        price,
        maxPerWallet,
        maxSupply_,
        merkleRoot,
        allowERC20,
        allowedTokens,
        startTime,
        endTime
    );

    phaseIds.push(id);
    phaseExists[id] = true;
}


function updatePhase(
    uint256 id,
    bool active,
    uint256 price,
    uint256 maxPerWallet,
    uint256 maxSupply_,
    bytes32 merkleRoot,
    uint256 startTime,
    uint256 endTime,
    bool allowERC20,
    address[] calldata allowedTokens
) external onlyOwner {
    require(phaseExists[id], "Phase not exist");
    require(endTime == 0 || endTime > startTime, "Invalid time");

    // ✅ Validate ERC20 configuration against global allow-list
    if (allowERC20) {
        for (uint256 i = 0; i < allowedTokens.length; i++) {
            require(
                allowedPaymentTokens[allowedTokens[i]],
                "Phase token not globally allowed"
            );
        }
    } else {
        require(allowedTokens.length == 0, "ERC20 disabled for phase");
    }

    Phase storage p = phases[id];

    p.active = active;
    p.price = price;
    p.maxPerWallet = maxPerWallet;
    p.maxSupply = maxSupply_;
    p.merkleRoot = merkleRoot;
    p.startTime = startTime;
    p.endTime = endTime;
    p.allowERC20 = allowERC20;
    p.allowedTokens = allowedTokens;
}

function getPhase(uint256 id) external view returns (Phase memory) {
        return phases[id];
    }

    /*//////////////////////////////////////////////////////////////
                                MINT
    //////////////////////////////////////////////////////////////*/

  function mint(
    uint256 phaseId,
    uint256 quantity,
    bytes32[] calldata proof,
    address paymentToken
) external payable nonReentrant {
    require(!paused, "Paused");
    require(phaseExists[phaseId], "Phase not exist");

    Phase memory p = phases[phaseId];
    require(p.active, "Inactive");
    require(quantity > 0, "Zero");

    if (p.startTime != 0) require(block.timestamp >= p.startTime, "Not started");
    if (p.endTime != 0) require(block.timestamp <= p.endTime, "Ended");

    if (p.phaseType == PhaseType.WL) {
        require(
            MerkleProof.verify(
                proof,
                p.merkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Not whitelisted"
        );
    }

   if (p.maxPerWallet > 0) {
    require(
        mintedPerPhase[phaseId][msg.sender] + quantity <= p.maxPerWallet,
        "Wallet limit"
    );
}

    // Phase supply
    if (p.maxSupply > 0) {
        require(
            phaseMinted[phaseId] + quantity <= p.maxSupply,
            "Phase sold out"
        );
    }

    // Global supply
    require(
        totalSupply() + quantity <= maxSupply,
        "Max supply"
    );

    // =========================
    // PAYMENT TYPE CHECK (FIX)
    // =========================
    if (paymentToken == address(0)) {
        // ETH mint
        require(
            !p.allowERC20 || p.allowedTokens.length == 0,
            "ERC20-only phase"
        );
    } else {
        // ERC20 mint
        require(p.allowERC20, "ETH-only phase");
    }

    _processPayment(p.price * quantity, p, paymentToken);

   // set phase start token
if (phaseMinted[phaseId] == 0) {
    phaseStartTokenId[phaseId] = totalSupply() + 1;
}
    mintedPerPhase[phaseId][msg.sender] += quantity;
    phaseMinted[phaseId] += quantity;

    _safeMint(msg.sender, quantity);
    emit Minted(msg.sender, phaseId, quantity, paymentToken, p.price * quantity);
}



    function _processPayment(
    uint256 amount,
    Phase memory p,
    address token
) internal {
    if (amount > 0) {
    require(totalShares > 0, "Payees not set");
}
    if (amount == 0) return;

    uint256 platformFee = (amount * platformFeePercentage) / 10000;
    uint256 referralFee = 0;

    if (
        referralEnabled &&
        referralAddress != address(0) &&
        referralAddress != owner()
    ) {
        referralFee = (amount * referralFeeBP) / 10000;
        platformFee -= referralFee;
    }

    uint256 remainder = amount - platformFee - referralFee;

    // =========================
    // ETH PAYMENT
    // =========================
    if (token == address(0)) {
        require(msg.value >= amount, "ETH low");

        if (referralFee > 0) {
            (bool r,) = referralAddress.call{value: referralFee}("");
            require(r, "Referral ETH failed");
        }

        (bool pSent,) = platformWallet.call{value: platformFee}("");
        require(pSent, "Platform ETH failed");

        // refund excess ETH
        if (msg.value > amount) {
            (bool refund,) =
                msg.sender.call{value: msg.value - amount}("");
            require(refund, "Refund failed");
        }

        // remainder stays in contract for split
        return;
    }

    // =========================
    // ERC20 PAYMENT
    // =========================
    require(p.allowERC20, "ERC20 disabled");
    require(allowedPaymentTokens[token], "Token not allowed");

    // token must be allowed for this phase
    if (p.allowedTokens.length > 0) {
        bool allowed;
        for (uint256 i; i < p.allowedTokens.length; i++) {
            if (p.allowedTokens[i] == token) {
                allowed = true;
                break;
            }
        }
        require(allowed, "Token not in phase");
    }

    uint8 decimals = IERC20Metadata(token).decimals();

require(decimals <= 18, "Unsupported decimals");

uint256 div = 10 ** (18 - decimals);

require(amount % div == 0, "Bad token decimals");

uint256 totalTokenAmount = amount / div;
require(totalTokenAmount > 0, "ERC20 amount zero");

uint256 platformFeeToken = (totalTokenAmount * platformFeePercentage) / 10000;
uint256 referralFeeToken = (totalTokenAmount * referralFeeBP) / 10000;
uint256 remainderToken = totalTokenAmount - platformFeeToken - referralFeeToken;

IERC20 erc20 = IERC20(token);

// safety checks
require(
    erc20.balanceOf(msg.sender) >= totalTokenAmount,
    "ERC20 balance low"
);
require(
    erc20.allowance(msg.sender, address(this)) >= totalTokenAmount,
    "ERC20 allowance low"
);

// transfers
erc20.safeTransferFrom(msg.sender, platformWallet, platformFeeToken);

if (referralFeeToken > 0) {
    erc20.safeTransferFrom(
        msg.sender,
        referralAddress,
        referralFeeToken
    );
}

erc20.safeTransferFrom(
    msg.sender,
    address(this),
    remainderToken
);
}

function _normalizeERC20(address token, uint256 amount)
internal
view
returns (uint256)
{
    uint8 decimals = IERC20Metadata(token).decimals();
    require(decimals <= 18, "Unsupported decimals");

    return amount * (10 ** (18 - decimals));
}

function _denormalizeERC20(address token, uint256 amount)
internal
view
returns (uint256)
{
    uint8 decimals = IERC20Metadata(token).decimals();
    require(decimals <= 18, "Unsupported decimals");

    return amount / (10 ** (18 - decimals));
}

function addPayees(
    address[] calldata accounts,
    uint256[] calldata shares_
) external onlyOwner {

    require(accounts.length == shares_.length, "Length mismatch");
    require(payeeList.length + accounts.length <= 250, "Too many payees");
    require(totalSupply() == 0, "Mint already started");

    uint256 addedShares;

    uint256 currentETH =
        address(this).balance + totalETHReleased;

    for (uint256 i; i < accounts.length; ++i) {

        address account = accounts[i];
        uint256 share = shares_[i];

        require(account != address(0), "Zero address");
        require(share > 0, "Zero share");
        require(!isPayee[account], "Already payee");

        isPayee[account] = true;

        payees[account].shares = share;

        payeeList.push(account);

        addedShares += share;

        // snapshot current ETH revenue
        ethCredit[account] = currentETH;

        // snapshot ERC20 revenue
        for(uint256 j; j < allowedERC20List.length; ++j){
            address token = allowedERC20List[j];

           erc20Credit[account][token] =
    _normalizeERC20(
        token,
        IERC20(token).balanceOf(address(this)) +
        totalERC20Released[token]
    );
        }
    }

    totalShares += addedShares;

    require(totalShares <= 10000, "Shares exceed 100%");
}

    /*//////////////////////////////////////////////////////////////
                        CLAIMS
    //////////////////////////////////////////////////////////////*/

function releasableETH(address account) public view returns (uint256) {

    if(!isPayee[account]) return 0;

    uint256 totalReceived =
        address(this).balance + totalETHReleased;

    uint256 earned =
        ( (totalReceived - ethCredit[account]) *
          payees[account].shares ) / totalShares;

    return earned - payees[account].releasedETH;
}

function claimETH() external nonReentrant {

    require(isPayee[msg.sender], "Not payee");

    uint256 payment = releasableETH(msg.sender);

    require(payment > 0, "Nothing to claim");

    payees[msg.sender].releasedETH += payment;
    totalETHReleased += payment;

    (bool success,) = msg.sender.call{value: payment}("");
    require(success, "ETH transfer failed");
}




function releasableERC20(
    address token,
    address account
) public view returns (uint256) {
    require(token != address(0), "Invalid token");
    require(allowedPaymentTokens[token], "Token not allowed");

    if(!isPayee[account]) return 0;

    uint256 totalReceived =
        _normalizeERC20(
            token,
            IERC20(token).balanceOf(address(this)) +
            totalERC20Released[token]
        );

    uint256 earned =
        ((totalReceived - erc20Credit[account][token]) *
         payees[account].shares) / totalShares;

    return earned - erc20Released[account][token];
}


function getPayeesDetails()
    external
    view
    returns (address[] memory accounts, uint256[] memory shares_)
{
    uint256 len = payeeList.length;

    accounts = new address[](len);
    shares_ = new uint256[](len);

    for (uint256 i = 0; i < len; i++) {

        address account = payeeList[i];

        accounts[i] = account;
        shares_[i] = payees[account].shares;
    }
}


function claimERC20(address token) external nonReentrant {
    require(token != address(0), "Invalid token");
    require(isPayee[msg.sender], "Not payee");
    require(allowedPaymentTokens[token], "Token not allowed");

    uint256 payment = releasableERC20(token, msg.sender);

    require(payment > 0, "Nothing to claim");

    erc20Released[msg.sender][token] += payment;

    uint256 transferAmount =
        _denormalizeERC20(token, payment);

    totalERC20Released[token] += transferAmount;

    IERC20(token).safeTransfer(msg.sender, transferAmount);
}

    /// @dev use it for giveaway and team mint
  function airdropBatch(uint256 _mintAmount, address[] calldata destinations)
    public
    onlyOwner
    nonReentrant
{
    uint256 totalToMint = _mintAmount * destinations.length;
    require(totalSupply() + totalToMint <= maxSupply, "max NFT limit exceeded");

    for (uint256 i = 0; i < destinations.length; i++) {
        _safeMint(destinations[i], _mintAmount);
    }
}


    /// @notice returns metadata link of tokenid
   function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721AMetadata: URI query for nonexistent token"
        );

        uint256 tokenPhaseId = 0;
bool found;

for (uint256 i; i < phaseIds.length; i++) {

    uint256 phaseId = phaseIds[i];
    uint256 start = phaseStartTokenId[phaseId];
    uint256 supply = phaseMinted[phaseId];

    if (start == 0) continue;

    if (tokenId >= start && tokenId < start + supply) {
        tokenPhaseId = phaseId;
        found = true;
        break;
    }
}

if (!found || !phaseRevealed[tokenPhaseId]) {
    return notRevealedUri;
}

        string memory currentBaseURI = _baseURI();
        uint256 metadataId = tokenId;

if (isRandom) {

    for (uint256 i; i < phaseIds.length; i++) {

    uint256 phaseId = phaseIds[i];

    uint256 start = phaseStartTokenId[phaseId];
    uint256 supply = phaseMinted[phaseId];

    if (start == 0) continue;

    if (tokenId >= start && tokenId < start + supply) {

        uint256 index = phaseStartIndex[phaseId];

        if (index != 0) {

            uint256 relative = tokenId - start;

            metadataId =
                start +
                ((relative + index) % supply);
        }

        break;
    }
}
}

string memory tokenIdStr = _toString(metadataId);

        // Append ".json" only if appendJson is true
        if (appendJson) {
            return string(abi.encodePacked(currentBaseURI, tokenIdStr, ".json"));
        } else {
            return string(abi.encodePacked(currentBaseURI, tokenIdStr));
        }
    }

function setPhaseRandomStartIndex(uint256 phaseId) external onlyOwner {

    require(isRandom, "Random disabled");
    require(phaseStartIndex[phaseId] == 0, "Already set");

    uint256 supply = phaseMinted[phaseId];
    require(supply > 0, "No mint yet");

    uint256 random = uint256(
        keccak256(
            abi.encodePacked(
                blockhash(block.number - 1),
                block.prevrandao,
                block.timestamp,
                address(this),
                phaseId,
                supply
            )
        )
    );

    phaseStartIndex[phaseId] = random % supply;
}

function setRandomEnabled(bool _state) external onlyOwner {
    isRandom = _state;
}

    /// @notice return the number minted by an address
    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getUserMintedInPhase(uint256 phaseId, address user)
    external
    view
    returns (uint256)
{
    require(phaseExists[phaseId], "Invalid phase");

    return mintedPerPhase[phaseId][user];
}

function getUserRemainingMint(uint256 phaseId, address user)
    external
    view
    returns (uint256)
{
    Phase memory p = phases[phaseId];

    uint256 minted = mintedPerPhase[phaseId][user];

   if (p.maxPerWallet == 0) {
    return type(uint256).max;
}

if (minted >= p.maxPerWallet) return 0;

return p.maxPerWallet - minted;
}

function getPhaseCount() external view returns (uint256) {
    return phaseIds.length;
}

function getAllPhaseIds() external view returns (uint256[] memory) {
    return phaseIds;
}

function getPhaseMintStats(uint256 phaseId)
    external
    view
    returns (
        uint256 minted,
        uint256 phaseMaxSupply,
        uint256 remaining
    )
{
    require(phaseExists[phaseId], "Invalid phase");

    Phase memory p = phases[phaseId];

    minted = phaseMinted[phaseId];
    phaseMaxSupply = p.maxSupply;

    if (p.maxSupply == 0) {
        remaining = type(uint256).max;
    } else {
        remaining = p.maxSupply - minted;
    }
}

    /// @notice return the tokens owned by an address
    function tokensOfOwner(address owner) public view returns (uint256[] memory) {
        unchecked {
            uint256 tokenIdsIdx;
            address currOwnershipAddr;
            uint256 tokenIdsLength = balanceOf(owner);
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            TokenOwnership memory ownership;
            for (uint256 i = _startTokenId(); tokenIdsIdx != tokenIdsLength; ++i) {
                ownership = _ownershipAt(i);
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            return tokenIds;
        }
    }

    //only owner
    function revealPhase(uint256 phaseId, bool state) external onlyOwner {
    require(phaseExists[phaseId], "Invalid phase");
    phaseRevealed[phaseId] = state;
}
      /// @dev cut the supply if we don't sell out
    function setMaxsupply(uint256 _newsupply) public onlyOwner {
        maxSupply = _newsupply;
    }
     

     /// @dev apply json extenion if required
     function setAppendJson(bool _appendJson) external onlyOwner {
        appendJson = _appendJson;
    }


    /// @dev set the base uri for the collection
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    /// @dev set the not revealed uri for the collection
    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }


    /// @dev to pause and unpause your contract(use booleans true or false)
    function pause(bool _state) public onlyOwner {
        paused = _state;
    }



    // Operator-filter-registry overrides
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
     
    /// @notice Sets royalty information for the contract
    /// @param receiver The address to receive royalty payments
    /// @param feeNumerator Royalty amount in basis points (e.g., 500 for 5%)
    function setRoyaltyInfo(address receiver, uint96 feeNumerator) public onlyOwner {
        require(feeNumerator <= 2000); // max 20%
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    
    /// @dev withdraw funds from contract
   function withdraw() public payable onlyOwner nonReentrant {
      uint256 balance = address(this).balance;
      payable(_msgSenderERC721A()).transfer(balance);
   }

   function rescueERC20(address token) external onlyOwner {
    uint256 balance = IERC20(token).balanceOf(address(this));
    IERC20(token).safeTransfer(owner(), balance);
}

    /// @notice Overrides ERC721 supportsInterface to include ERC2981 support
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
