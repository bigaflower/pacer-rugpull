// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "lib/openzeppelin-contracts/contracts/utils/Nonces.sol";
import "lib/openzeppelin-contracts/contracts/utils/Pausable.sol";

contract GaiaToken is
    ERC20,
    ERC20Burnable,
    ERC20Permit,
    ERC20Votes,
    Ownable,
    Pausable
{
    uint256 public constant TOTAL_SUPPLY = 1_000_000_000 * 10 ** 18;

    constructor(
        address initialOwner
    )
        ERC20("Gaia Token", "GAIA")
        ERC20Permit("Gaia Token")
        Ownable(initialOwner)
    {
        _mint(initialOwner, TOTAL_SUPPLY);
    }

    function _update(
        address from,
        address to,
        uint256 value
    ) internal override(ERC20, ERC20Votes) whenNotPaused {
        super._update(from, to, value);
    }

    function nonces(
        address owner
    ) public view override(ERC20Permit, Nonces) returns (uint256) {
        return super.nonces(owner);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function consumeNonce() external {
        _useNonce(msg.sender);
    }

    function renounceOwnership() public view override onlyOwner {
        revert("Ownership cannot be renounced");
    }
}
