pragma solidity ^0.4.24;

import "./MintableToken.sol";
import "./CappedToken.sol";

contract CMX is CappedToken {

    string public name = "Coins Maker Coin";
    string public symbol = "CMX";
    uint8 public decimals = 8;

    constructor(
        uint256 _cap
        )
        public
        CappedToken( _cap ) {
    }
}




