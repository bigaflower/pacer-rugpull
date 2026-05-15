// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ERC721SeaDropPausable} from "./extensions/ERC721SeaDropPausable.sol";

contract GKoiBattlecards is ERC721SeaDropPausable {
    constructor(string memory name_, string memory symbol_, address[] memory allowedSeaDrop_)
        ERC721SeaDropPausable(name_, symbol_, allowedSeaDrop_)
    {}

    function mint(address to, uint256 quantity) external onlyOwner nonReentrant {
        if (transfersPaused) {
            revert TransfersPaused();
        }

        if (_totalMinted() + quantity > maxSupply()) {
            revert MintQuantityExceedsMaxSupply(_totalMinted() + quantity, maxSupply());
        }

        _safeMint(to, quantity);
    }
}
