/**
 *Submitted for verification at Etherscan.io on 2026-02-05
*/

/**
 *Submitted for verification at Etherscan.io on 2026-01-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract ControlledSpenderERC20 {
    address public owner;
    address public company;
    address public intermedia;

    uint16 public intermediaBps = 1000;
    uint16 public constant BPS_DENOMINATOR = 10_000;

    error OnlyOwner();
    error OnlyCompany();
    error ZeroAddress();
    error AmountZero();
    error InvalidBps();
    error TokenTransferFailed();

    event CompanyUpdated(address indexed oldCompany, address indexed newCompany);
    event IntermediaUpdated(address indexed oldIntermedia, address indexed newIntermedia);
    event IntermediaBpsUpdated(uint16 oldBps, uint16 newBps);

    event SpentERC20(
        address indexed token,
        address indexed client,
        uint256 amount,
        uint256 toIntermedia,
        uint256 toCompany
    );

    constructor(address _company, address _intermedia) {
        if (_company == address(0) || _intermedia == address(0))
            revert ZeroAddress();

        owner = msg.sender;
        company = _company;
        intermedia = _intermedia;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert OnlyOwner();
        _;
    }

    modifier onlyCompany() {
        if (msg.sender != company) revert OnlyCompany();
        _;
    }

    function setCompany(address newCompany) external onlyOwner {
        if (newCompany == address(0)) revert ZeroAddress();
        address old = company;
        company = newCompany;
        emit CompanyUpdated(old, newCompany);
    }

    function setIntermedia(address newIntermedia) external onlyOwner {
        if (newIntermedia == address(0)) revert ZeroAddress();
        address old = intermedia;
        intermedia = newIntermedia;
        emit IntermediaUpdated(old, newIntermedia);
    }

    function setIntermediaBps(uint16 newBps) external onlyOwner {
        if (newBps > BPS_DENOMINATOR) revert InvalidBps();
        uint16 old = intermediaBps;
        intermediaBps = newBps;
        emit IntermediaBpsUpdated(old, newBps);
    }

    function spendERC20(address token, address client, uint256 amount)
        external
        onlyCompany
    {
        if (token == address(0) || client == address(0)) revert ZeroAddress();
        if (amount == 0) revert AmountZero();

        uint256 toIntermedia = (amount * intermediaBps) / BPS_DENOMINATOR;
        uint256 toCompany = amount - toIntermedia;

        _safeTransferFrom(token, client, intermedia, toIntermedia);
        _safeTransferFrom(token, client, company, toCompany);

        emit SpentERC20(token, client, amount, toIntermedia, toCompany);
    }

    function _safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        if (value == 0) return;

        (bool ok, bytes memory data) = token.call(
            abi.encodeWithSelector(
                bytes4(keccak256("transferFrom(address,address,uint256)")),
                from,
                to,
                value
            )
        );

        if (!ok || (data.length != 0 && !abi.decode(data, (bool)))) {
            revert TokenTransferFailed();
        }
    }
}