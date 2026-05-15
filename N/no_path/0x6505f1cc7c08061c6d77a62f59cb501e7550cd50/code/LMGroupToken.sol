// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.22;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @custom:security-contact support@lmgxtoken.com
contract LMGroupToken is ERC20, ERC20Permit, Ownable {
    uint8 private constant _decimals = 18;
    uint256 public constant PublicSale = 40_000_000 * (10 ** _decimals);
    uint256 public constant LiquidityPool = 15_000_000 * (10 ** _decimals);
    uint256 public constant LegalAndRegulation = 10_000_000 * (10 ** _decimals);
    uint256 public constant ProductDevelopment = 10_000_000 * (10 ** _decimals);
    uint256 public constant BusinessDevelopment = 10_000_000 * (10 ** _decimals);
    uint256 public constant ContingencyReserve = 5_000_000 * (10 ** _decimals);
    uint256 public constant TeamAndAdvisors = 5_000_000 * (10 ** _decimals);
    uint256 public constant OperationalExpenses = 5_000_000 * (10 ** _decimals);

    constructor()
        ERC20("LMGroupToken", "LMGX")
        ERC20Permit("LMGroupToken")
        Ownable(0xD3E9c895510fcfD018bF27d3487372C7f29c1867)
    {
        _mint(0x299503c36705b192853F7d1969b2621Ece86c298, PublicSale);
        _mint(0xFA428Ea946422baCCc805A7Dd0a31B808e53535b, LiquidityPool);
        _mint(0x7457A471688c7A2CB94b98bd8CF0A4e439D04Ef6, LegalAndRegulation);
        _mint(0x2f9BFd70C108BCa11b0c7877C2e6409AC6a9C47E, ProductDevelopment);
        _mint(0xABc6545f945aA83685B501F5065CB8AefBD7D6DB, BusinessDevelopment);
        _mint(0x5b0d140575310DeEF80fBD5BeBA84746414da400, ContingencyReserve);
        _mint(0x466A4b16a298965bf2C8E0FE69F6f1D850570607, TeamAndAdvisors);
        _mint(0x2F3030BaA1Dd5863bD3A600a522ed8B7372C277b, OperationalExpenses);
    }
}