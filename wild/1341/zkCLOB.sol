// SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract zkCLOB is ERC20, Ownable(msg.sender) {
    mapping (address => bool) public isExcludedFromEnable;
    bool    public  tradingEnabled;

    error TradingNotEnabled();
    error TradingAlreadyEnabled();

    event TradingEnabled();
    event ExcludedFromEnable(address indexed account, bool isExcluded);

    constructor () ERC20("zkCLOB", "Z") {
        isExcludedFromEnable[owner()] = true;
        isExcludedFromEnable[address(0xdead)] = true;
        isExcludedFromEnable[address(this)] = true;

        super._update(address(0), owner(), 100e6 * (10 ** decimals()));
    }

    function _update(address from, address to, uint256 value) internal override {
        bool isExcluded = isExcludedFromEnable[from] || isExcludedFromEnable[to];

        if (!isExcluded && !tradingEnabled) {
            revert TradingNotEnabled();
        }

        super._update(from, to, value);
    }

    function enableTrading() external onlyOwner {
        if (tradingEnabled) {
            revert TradingAlreadyEnabled();
        }

        tradingEnabled = true;

        emit TradingEnabled();
    }

    function excludeFromEnable(address account, bool excluded) external onlyOwner{
        isExcludedFromEnable[account] = excluded;

        emit ExcludedFromEnable(account, excluded);
    }
}