// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

interface IExchangeWallet {
        
    function isAllowedAddress(address addr) external view returns (bool);

    
}
