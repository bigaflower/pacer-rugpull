// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ArkOfGenesis is ERC20, Ownable {
    // ---- Pagrindiniai adresai (checksummed!) ----
    address public constant ARK_MAIN = 0x79671ff028dc29032cCd82728BB29216135040aE;
    address public constant ARK_MARKETING = 0xfFd36BF556d312b957DbE2979B989beb914ad905;
    address public constant ARK_LIQUIDITY = 0x274C16d9812BAf3f1e79617Fe7781903dAaf50D0;
    address public constant ARK_RESERVE = 0x9dCa5483b62B692cc9131dc7f123723BF309cf98;
    address public constant ARK_TEAM = 0x0a8926CD3EF898c5E39608149F7e17eEc9F015D3;
    address public constant ARK_PARTNERS = 0x6C7e5f1788B6d6B3d023b8c857eFD1b8b78139ee;

    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    uint256 public constant TOTAL_SUPPLY = 20_000_000_000 * 1e18;
    uint256 public constant PRESALE_SUPPLY = 8_000_000_000 * 1e18;
    uint256 public constant TEAM_SUPPLY = 3_400_000_000 * 1e18;
    uint256 public constant MARKETING_SUPPLY = 2_400_000_000 * 1e18;
    uint256 public constant LIQUIDITY_SUPPLY = 1_600_000_000 * 1e18;
    uint256 public constant PARTNERS_SUPPLY = 1_600_000_000 * 1e18;
    uint256 public constant RESERVE_SUPPLY = 3_000_000_000 * 1e18;

    struct Gate {
        uint256 targetAmount;
        uint256 raisedAmount;
        bool isOpen;
    }

    mapping(uint8 => Gate) public gates;
    uint8 public currentGate = 1;
    uint8 public constant TOTAL_GATES = 15;

    uint256 public constant BURN_PERCENT = 1;
    event GateProgress(uint8 gate, uint256 raised, uint256 target);
    event GateOpened(uint8 gate, uint256 burnedTokens);

    uint256 public teamCliff = 90 days;
    uint256 public teamVestingDuration = 270 days;
    uint256 public teamStart;
    uint256 public teamClaimed;

    constructor() ERC20("Ark of Genesis", "AOGX") Ownable(_msgSender()) {
        _mint(address(this), TOTAL_SUPPLY);

        _transfer(address(this), ARK_MAIN, PRESALE_SUPPLY);
        _transfer(address(this), ARK_MARKETING, MARKETING_SUPPLY);
        _transfer(address(this), ARK_LIQUIDITY, LIQUIDITY_SUPPLY);
        _transfer(address(this), ARK_RESERVE, RESERVE_SUPPLY);
        _transfer(address(this), ARK_PARTNERS, PARTNERS_SUPPLY);

        teamStart = block.timestamp + teamCliff;
    }

    function setGateTarget(uint8 gateId, uint256 targetAmountUSD) external onlyOwner {
        require(gateId > 0 && gateId <= TOTAL_GATES, "Invalid Gate ID");
        gates[gateId].targetAmount = targetAmountUSD;
    }

    function updateGate(uint256 amountRaisedUSD) external onlyOwner {
        Gate storage gate = gates[currentGate];
        require(!gate.isOpen, "Gate already opened");

        gate.raisedAmount += amountRaisedUSD;
        emit GateProgress(currentGate, gate.raisedAmount, gate.targetAmount);

        if (gate.raisedAmount >= (gate.targetAmount * 99 / 100)) {
            _burnForGate();
        }
    }

    function _burnForGate() internal {
        uint256 burnAmount = (PRESALE_SUPPLY / TOTAL_GATES) * BURN_PERCENT / 100;
        _transfer(ARK_MAIN, BURN_ADDRESS, burnAmount);

        gates[currentGate].isOpen = true;
        emit GateOpened(currentGate, burnAmount);

        if (currentGate < TOTAL_GATES) {
            currentGate++;
        }
    }

    function claimTeamTokens() external {
        require(block.timestamp >= teamStart, "Cliff not reached");
        uint256 vested = _vestedAmount();
        uint256 claimable = vested - teamClaimed;
        require(claimable > 0, "Nothing to claim");

        teamClaimed += claimable;
        _transfer(address(this), ARK_TEAM, claimable);
    }

    function _vestedAmount() internal view returns (uint256) {
        if (block.timestamp < teamStart) {
            return 0;
        } else if (block.timestamp >= teamStart + teamVestingDuration) {
            return TEAM_SUPPLY;
        } else {
            return (TEAM_SUPPLY * (block.timestamp - teamStart)) / teamVestingDuration;
        }
    }

    function emergencyWithdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    receive() external payable {}
}