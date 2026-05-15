// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "ERC20.sol";
import "IERC20.sol";
import "Ownable.sol";

import "ITokenSaleFactoryMin.sol";

contract Token is Ownable, ERC20 {

    ITokenSaleFactoryMin internal immutable _tokenSaleFactory;
    mapping(address => bool) internal _restrictedAddresses;

    constructor(string memory name_, string memory symbol_, uint256 initSupply) ERC20(name_, symbol_) {
        _tokenSaleFactory = ITokenSaleFactoryMin(msg.sender);
        _mint(msg.sender, initSupply);
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        if (to == address(0)) {
            _burn(owner, amount);
        } else {
            _transfer(owner, to, amount);
        }
        return true;
    }

    function addRestricted(address[] calldata restrictedAddresses) external onlyOwner {
        for (uint256 i = 0; i < restrictedAddresses.length; i++) {
            _restrictedAddresses[restrictedAddresses[i]] = true;
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        if (!_tokenSaleFactory.isFinished(address(this))) {
            require(!_restrictedAddresses[from] && !_restrictedAddresses[to], "TSF: tokensale didn't finished yet");

            if (from != address(_tokenSaleFactory) && to != address(_tokenSaleFactory)) {
                _tokenSaleFactory.onTransfer(from, amount);
            }
        }
    }
}