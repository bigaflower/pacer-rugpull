// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address a) external view returns (uint256);
}

contract tGtOperatorAirdrop {
    IERC20 public immutable tGt;
    address public immutable operator;

    event BatchMessage(
        bytes32 indexed batchId,
        address indexed operator,
        uint256 amountEach,
        uint256 count,
        string message
    );

    error NotOperator();
    error Empty();
    error InsufficientBalance();
    error SendFail();

    constructor(address _tGt) {
        tGt = IERC20(_tGt);
        operator = 0xeEe4956b8fe87E64D98c60FF21F55b0342f3fE2C; // senin operator cüzdanın
    }

    modifier onlyOperator() {
        if (msg.sender != operator) revert NotOperator();
        _;
    }

    /**
     * @notice Contract balance'ından batch airdrop + tek mesaj event
     * @dev Önce bu kontrata tGt TRANSFER ederek fonla. Approve gerekmez.
     */
    function airdrop(
        address[] calldata recipients,
        uint256 amountEach,
        string calldata message
    ) external onlyOperator {
        uint256 n = recipients.length;
        if (n == 0) revert Empty();

        uint256 total = amountEach * n;
        if (tGt.balanceOf(address(this)) < total) revert InsufficientBalance();

        bytes32 batchId = keccak256(
            abi.encodePacked(block.chainid, msg.sender, block.number, total, n, message)
        );

        emit BatchMessage(batchId, msg.sender, amountEach, n, message);

        for (uint256 i = 0; i < n; ) {
            if (!tGt.transfer(recipients[i], amountEach)) revert SendFail();
            unchecked { ++i; }
        }
    }

    /**
     * @notice Kalan tGt’yi operatöre geri çekmek için (opsiyonel ama pratik)
     */
    function sweep(uint256 amount) external onlyOperator {
        if (!tGt.transfer(operator, amount)) revert SendFail();
    }
}