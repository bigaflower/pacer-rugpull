// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract ZnowFlakzToken {
    string public name = "Znow Flakz";
    string public symbol = "ZNOW";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    uint256 public constant MAX_SUPPLY = 25_000_000_000 * 1e18;

    address public owner;
    address public feeWallet;

    uint256 public constant OWNER_TOKENS = 7_500_000_000 * 1e18;
    uint256 public constant INITIAL_PUBLIC_RELEASE = 5_000_000_000 * 1e18;
    uint256 public constant PHASE_RELEASE_AMOUNT = 6_250_000_000 * 1e18;

    uint256 public nextReleaseTime1;
    uint256 public nextReleaseTime2;

    uint256 public maxWalletLimit = 125_000_000 * 1e18; // 0.5% of max supply

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier notExempt(address to) {
        require(to != owner && to != feeWallet, "Exempt");
        _;
    }

    constructor() {
        owner = 0xC8B47a0ADB22a79FcC8f66a1c7fAE977af07913E;
        feeWallet = 0xb13c6182A681413Cd3d207b654DF80EDd6BABBc2;

        totalSupply = OWNER_TOKENS + INITIAL_PUBLIC_RELEASE;

        balanceOf[owner] = OWNER_TOKENS;
        balanceOf[address(this)] = INITIAL_PUBLIC_RELEASE;

        nextReleaseTime1 = block.timestamp + 30 days;
        nextReleaseTime2 = block.timestamp + 60 days;

        emit Transfer(address(0), owner, OWNER_TOKENS);
        emit Transfer(address(0), address(this), INITIAL_PUBLIC_RELEASE);
    }

    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function _transfer(address from, address to, uint256 value) internal {
        require(balanceOf[from] >= value, "Insufficient balance");
        require(to != address(0), "Cannot send to zero address");

        uint256 fee = 0;
        if (from != owner && from != feeWallet && to != owner && to != feeWallet) {
            fee = (value * 5) / 1000; // 0.5%
        }

        uint256 amountAfterFee = value - fee;

        if (to != owner && to != feeWallet) {
            require(balanceOf[to] + amountAfterFee <= maxWalletLimit, "Exceeds max wallet");
        }

        balanceOf[from] -= value;
        balanceOf[to] += amountAfterFee;
        if (fee > 0) {
            balanceOf[feeWallet] += fee;
            emit Transfer(from, feeWallet, fee);
        }
        emit Transfer(from, to, amountAfterFee);
    }

    function approve(address spender, uint256 value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(allowance[from][msg.sender] >= value, "Allowance exceeded");
        allowance[from][msg.sender] -= value;
        _transfer(from, to, value);
        return true;
    }

    function releasePhaseTokens() public onlyOwner {
        if (block.timestamp >= nextReleaseTime1 && totalSupply < 18_750_000_000 * 1e18) {
            balanceOf[address(this)] += PHASE_RELEASE_AMOUNT;
            totalSupply += PHASE_RELEASE_AMOUNT;
            nextReleaseTime1 = type(uint256).max;
            emit Transfer(address(0), address(this), PHASE_RELEASE_AMOUNT);
        } else if (block.timestamp >= nextReleaseTime2 && totalSupply < MAX_SUPPLY) {
            balanceOf[address(this)] += PHASE_RELEASE_AMOUNT;
            totalSupply += PHASE_RELEASE_AMOUNT;
            nextReleaseTime2 = type(uint256).max;
            emit Transfer(address(0), address(this), PHASE_RELEASE_AMOUNT);
        } else {
            revert("Too early or already released");
        }
    }

    // Governance system
    struct Proposal {
        string description;
        uint256 voteCount;
        bool executed;
    }

    Proposal[] public proposals;
    mapping(address => mapping(uint256 => bool)) public hasVoted;

    function createProposal(string memory _desc) public onlyOwner {
        proposals.push(Proposal({description: _desc, voteCount: 0, executed: false}));
    }

    function vote(uint256 proposalId) public {
        require(proposalId < proposals.length, "Invalid proposal");
        require(!hasVoted[msg.sender][proposalId], "Already voted");
        require(balanceOf[msg.sender] > 0, "No voting power");

        proposals[proposalId].voteCount += balanceOf[msg.sender];
        hasVoted[msg.sender][proposalId] = true;
    }

    function getProposal(uint256 proposalId) public view returns (string memory desc, uint256 votes, bool executed) {
        Proposal memory p = proposals[proposalId];
        return (p.description, p.voteCount, p.executed);
    }

    function getMaxSupply() public pure returns (uint256) {
        return MAX_SUPPLY;
    }

    // Site reference
    function getOfficialSite() public pure returns (string memory) {
        return "https://www.ZnowFlakzToken.com";
    }
}