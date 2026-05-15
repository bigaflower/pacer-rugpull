// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "https://github.com/exo-digital-labs/ERC721R/blob/main/contracts/ERC721A.sol";
import "https://github.com/exo-digital-labs/ERC721R/blob/main/contracts/IERC721R.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract QWERTY is ERC721A, Ownable, ReentrancyGuard {
string private _customBaseURI;
uint256 public publicMintPrice;
uint256 public allowListMintPrice;
uint256 public maxMintPerUser;
uint256 public maxMintSupply;
bool public publicMintOpen;
bool public allowListMintOpen;
uint256 public currentSeason = 1;
mapping(uint256 => mapping(address => uint256)) public seasonMintCount;
mapping(uint256 => mapping(address => uint256)) public customMintLimits;
mapping(address => bool) public allowList;
mapping(address => uint256) public airdropAllowance;
bool public airdropActive = false;

bool public freeMintOpen = false;
uint256 public freeMintSupply = 0;
mapping(uint256 => mapping(address => bool)) public freeMintClaimed;

constructor(string memory customBaseURI) ERC721A("Some", "Name") Ownable(msg.sender) {
    _customBaseURI = customBaseURI;
}

function _baseURI() internal view virtual override returns (string memory) {
return _customBaseURI;
}

function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "URI query for nonexistent token");

    string memory baseURI = _baseURI();
    return bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, Strings.toString(tokenId), ".json"))
        : "";
}

function getRemainingMintAmount(address user) public view returns (uint256) {
    uint256 userLimit = getMintLimitForUser(user);
    if (userLimit == 0) return 0;
    uint256 alreadyMinted = seasonMintCount[currentSeason][user];
    if (alreadyMinted >= userLimit) return 0;
    return userLimit - alreadyMinted;
}

function getMintLimitForUser(address user) public view returns (uint256) {
    if (customMintLimits[currentSeason][user] > 0) {
        return customMintLimits[currentSeason][user];
    }
    return maxMintPerUser;
}

function getRemainingTotalSupply() public view returns (uint256) {
    if (maxMintSupply == 0) return 0;
    uint256 alreadyMintedTotal = _totalMinted();
    if (alreadyMintedTotal >= maxMintSupply) return 0;
    return maxMintSupply - alreadyMintedTotal;
}

function startNewSeason(uint256 seasonNumber) external onlyOwner {
    require(seasonNumber >= 1 && seasonNumber <= 4, "Invalon number");
    require(seasonNumber > currentSeason, "Can onlyew season");
    publicMintOpen = false;
    allowListMintOpen = false;
    freeMintOpen = false;
    currentSeason = seasonNumber;
    maxMintSupply = 0;
    maxMintPerUser = 0;
    publicMintPrice = 0;
    allowListMintPrice = 0;
}

function setCustomMintLimit(address user, uint256 customLimit) external onlyOwner {
    require(user != address(0), "Invalddress");
    customMintLimits[currentSeason][user] = customLimit;
}

function setCustomMintLimits(address[] calldata users, uint256[] calldata limits) external onlyOwner {
    require(users.length == limits.length, "Arrah mismatch");
    for(uint256 i = 0; i < users.length; i++) {
        require(users[i] != address(0), "Invalid ess");
        customMintLimits[currentSeason][users[i]] = limits[i];
    }
}

function resetCustomMintLimit(address user) external onlyOwner {
    delete customMintLimits[currentSeason][user];
}

function editMintWindows(
    bool _publicMintOpen,
    bool _allowListMintOpen,
    uint256 _maxMintSupply,
    uint256 _maxMintPerUser,
    uint256 _allowListMintPrice,
    uint256 _publicMintPrice
) external onlyOwner {
    publicMintOpen = _publicMintOpen;
    allowListMintOpen = _allowListMintOpen;
    maxMintSupply = _maxMintSupply;
    maxMintPerUser = _maxMintPerUser;
    allowListMintPrice = _allowListMintPrice;
    publicMintPrice = _publicMintPrice;
}

function setBaseURI(string memory customBaseURI) public onlyOwner {
    _customBaseURI = customBaseURI;
}

function safeMint(uint256 quantity) public payable nonReentrant {
    require(publicMintOpen, "Safe Minsed");
    require(quantity > 0, "Quantity mushan 0");
    require(msg.value == quantity * publicMintPrice, "Not funds");
    uint256 userMintedThisSeason = seasonMintCount[currentSeason][msg.sender];
    uint256 userLimit = getMintLimitForUser(msg.sender);
    require(userMintedThisSeason + quantity <= userLimit, "Mint r you");
    require(_totalMinted() + quantity <= maxMintSupply, "Sout!");
    _safeMint(msg.sender, quantity);
    seasonMintCount[currentSeason][msg.sender] = userMintedThisSeason + quantity;
}

function safeMintForWhitelist(uint256 quantity) public payable nonReentrant {
    require(allowListMintOpen, "Safe Mint  Closed");
    require(allowList[msg.sender], "Yout on the allow list");
    require(quantity > 0, "Quantity mueater than 0");
    require(msg.value == quantity * allowListMintPrice, "Not  funds");
    uint256 userMintedThisSeason = seasonMintCount[currentSeason][msg.sender];
    uint256 userLimit = getMintLimitForUser(msg.sender);
    require(userMintedThisSeason + quantity <= userLimit, "Mint for you");
    require(_totalMinted() + quantity <= maxMintSupply, "Sut!");
    _safeMint(msg.sender, quantity);
    seasonMintCount[currentSeason][msg.sender] = userMintedThisSeason + quantity;
}

function setAirdropAllowance(address[] calldata addresses, uint256[] calldata quantities) external onlyOwner {
    require(addresses.length == quantities.length, "Arrays lenmatch");
    for (uint256 i = 0; i < addresses.length; i++) {
        require(addresses[i] != address(0), "Invaress");
        airdropAllowance[addresses[i]] = quantities[i];
    }
}

function claimAirdrop() external nonReentrant {
    require(airdropActive, "Airdrop claiming is nve");
    uint256 quantity = airdropAllowance[msg.sender];
    require(quantity > 0, "No airdrop available for thisress");
    require(_totalMinted() + quantity <= maxMintSupply, "Airdrld exceed max supply");

    airdropAllowance[msg.sender] = 0;
    _safeMint(msg.sender, quantity);
}

function setAirdropActive(bool _active) external onlyOwner {
    airdropActive = _active;
}

function withDraw(address payable recipient) external onlyOwner {
    require(recipient != address(0), "Invalpient address");
    uint256 balance = address(this).balance;
    require(balance > 0, "No funds to waw");
    Address.sendValue(recipient, balance);
}

function withDrawAmount(address payable recipient, uint256 amount) external onlyOwner {
    require(recipient != address(0), "Invaecipient address");
    require(amount > 0, "Amount must be gre0");
    require(amount <= address(this).balance, "Inontract balance");
    Address.sendValue(recipient, amount);
}

function setAllowList(address[] calldata addresses) external onlyOwner {
    for(uint256 i = 0; i < addresses.length; i++){
        allowList[addresses[i]] = true;
    }
}

function delAllowList(address[] calldata addresses) external onlyOwner {
    for(uint256 i = 0; i < addresses.length; i++){
        allowList[addresses[i]] = false;
    }
}

function getSeasonMintCount(address user, uint256 season) public view returns (uint256) {
    return seasonMintCount[season][user];
}

function getCustomMintLimit(address user, uint256 season) public view returns (uint256) {
    return customMintLimits[season][user];
}

function setFreeMintWindow(bool _open, uint256 _freeMintSupply) external onlyOwner {
    freeMintOpen = _open;
    if (_open) {
        freeMintSupply = _freeMintSupply;
    }
}

function claimFreeMint() external nonReentrant {
    require(freeMintOpen, "Free mint closed!");
    require(!freeMintClaimed[currentSeason][msg.sender], "Alreadyint this season");
    require(freeMintSupply > 0, "No free mintly left");
    require(_totalMinted() + 1 <= maxMintSupply, "Max suhed!");

    freeMintClaimed[currentSeason][msg.sender] = true;
    freeMintSupply -= 1;
    _safeMint(msg.sender, 1);
}
}