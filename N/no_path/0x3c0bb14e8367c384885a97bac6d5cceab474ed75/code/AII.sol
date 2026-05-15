// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
//          .    .    .       .        . . .    . . . .    . . .    . . . .    . . .    . . . .
//          .    .    .       .        .        .     .    .        .     .    .   .    .   .
//          .    . . .        .        . .      . . . .    . . .    . . . .    . . .    . . .
//          .    .    .       .        .        .   .      .        .         .   .    .   .
//          .    .    .       . . . .  . . . .  .    .     .        .         .    .   .    .

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract AIIdiot is ERC20, ERC20Permit, Ownable, ERC20Burnable {
    address public pairAddress;
    address public uniswapV2RouterAddress;
    uint256 initTime;

    constructor(
        address _closedAIWallet,
        address _uniswapV2RouterAddress,
        address _idiotsWallet
    ) ERC20("AIIdiot", "AII") ERC20Permit("AIIdiot") Ownable(msg.sender) {
        uniswapV2RouterAddress = _uniswapV2RouterAddress;
        _mint(address(this), 1000000000 * 10 ** decimals());
        _transfer(address(this), _closedAIWallet, (totalSupply() * 10) / 100);
        _transfer(address(this), _idiotsWallet, (totalSupply() * 10) / 100);
    }

    function getPairAddress(address token) internal view returns (address) {
        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(
            uniswapV2RouterAddress
        );
        return
            IUniswapV2Factory(uniswapV2Router.factory()).getPair(
                token,
                uniswapV2Router.WETH()
            );
    }

    function addLiquidity() external payable onlyOwner {
        _approve(
            address(this),
            uniswapV2RouterAddress,
            balanceOf(address(this)) * 100
        );
        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(
            uniswapV2RouterAddress
        );
        uniswapV2Router.addLiquidityETH{value: msg.value}(
            address(this),
            balanceOf(address(this)),
            balanceOf(address(this)),
            msg.value,
            super.owner(),
            block.timestamp + 10 * 60
        );
        initTime = block.timestamp;
        address poolAddress = getPairAddress(address(this));
        pairAddress = poolAddress;
        initTime = block.timestamp;
    }

    function transfer(
        address _recipient,
        uint256 _amount
    ) public override returns (bool) {
        address _sender = msg.sender;
        if (
            _recipient == pairAddress &&
            block.timestamp - initTime < 4 * 60 * 60
        ) {
            uint256 taxAmount = (_amount * 10) / 100;
            uint256 netAmount = _amount - taxAmount;
            super.transfer(_recipient, netAmount);
            if (taxAmount > 0) {
                super.burn(taxAmount);
                return true;
            }
        } else {
            super.transfer(_recipient, _amount);
            return true;
        }
        return true;
    }

    function transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    ) public override returns (bool) {
        if (
            _recipient == pairAddress &&
            block.timestamp - initTime < 4 * 60 * 60
        ) {
            uint256 taxAmount = (_amount * 10) / 100;
            uint256 netAmount = _amount - taxAmount;
            super.transferFrom(_sender, _recipient, netAmount);
            if (taxAmount > 0) {
                // burn tax amount
                super.burnFrom(_sender, taxAmount);
                return true;
            }
        } else {
            super.transferFrom(_sender, _recipient, _amount);
            return true;
        }
        return true;
    }
}
