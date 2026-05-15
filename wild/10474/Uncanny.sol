// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/*
!!!!!!!!!!!!!!!!~!!!!!!!!!!!!!!!!!!!!~!!!!!!!!!!!!!7!!!!!!!!!!!!!!!!!!!!~~!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!!!!!!!!!!!!!~!!!!~~!!!!!!!!!!!!!!!!!!!~G?~!!!!!!~!!!!!!!!!~~?7~!!!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!~?J~~!!!!!!!!!~~!!!!!~!BY~!!!!!~!!!!!!!!!~!5G!~!!!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!~7GG7~~!!!!!!~JJ~!!!!~!#G~!!!!~7B7~!!!!!~7GB!~!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!~!5#Y!~!!!!!~?&J~!!!~!G5~!!!!~YP!~!!!!~?BB!~!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!~~J#B?~!!!!!~YY~~~~~~~~~~~~~~!!~~~~!~?#B7~!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!!!!!!!!!!!!!!~~!!!!~~7GB7~!!!~~~~!777??????777!!!777!!~?Y!~!!!~~~!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!!!!!!!!!!!!!~77!~~!!!~~!!!~~!7?JJ?77!~~~~~~~!77?J?!7?J?!~~!!!~!YJ~!!!!!!!!~~~!!!!!!!!!!!
!!!!!!!!!!!!!!!~~~!!!!!!~75PY!~!!~~~~!7JJ7~:................::::~^~J7~!!!~55!~!!!!!~~~7J5J!!!!!!!!!!
!!!!!!!!!!!!!~!J?7!~~~~!!~~7Y?~!!!~~7J7^........................7^^?J!~~!!!~~!!!~~~7JPPY7~!!!!!!!!!!
!!!!!!!!~~!!!!!7J5P5Y?!~~~~~~~~~~~~J?:..........................~^..~??!~!!!!!~~!JPB5?!~~!!!!!!!!!!!
!!!!!!~!!!!!!!!~~~!?5GBGY?????????JJ:...........................~^....~J?~~!!~?PBGJ!~~!!!!!!!!!~!!!!
!!!!!!!!!!!!!!!!~!7?JJJJ?777!!!!777!!!!!!~~^^:..................~:.....:?J~!!~Y57~~~!!!!!!!!!!!!!!!!
!!!!!!!!!!!!!!!~7Y7~^:...............:::^^~!!!!!~^::...........:~........?J~!!~~~~~~~~!!!!!!!!!!!!!!
!!!!!!!!!!!!~!!!Y:............................:^~!!!!~^:.......~..........J7~!!~~!7?Y?!!!!!!!!!!!!!!
!!!!!!!!!!!!!!!!J.................^~7?JYYYYJJ?7!^^^^~~!!~^:...^:..........^Y~!~7PGPY?!!!!!!!!!!!!!!!
!!!!!!!!!!!!!!!~7?:............:?PB#&&&&&&&&&&&##BG5Y?7!~~~~^:.............J7~~!?7~~~!!!!!!!!!!!!!!!
!!!!!!!!!!!!!!!!~7?!:.........^B&&###############&&&&&#BPY?!~~:............77~!~~~!!!!!!!!!!!!!!!!!!
~!!!!!!!!!!!!!!!!~~7?7~:......?&#######################&&&##P?7~...........77~!!!!!!!!!!!!!!!!!!!!!!
~!!!!!!!!!!!!!!!!!!~~!7?7!^:. J&############################&&#GY^.........?!~!!!~!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!!!~!!!!!!~~~!77?7!5&###############################&&BY^......:J~!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!!!!!!!!!!!!!~~~~!!P&#################################&&#GG5?^.?7~!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!~~G&####################################&&&&BY?~!!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!~!B&########################################&#7~!!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!~7##########################################&B!~!!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!~?########################################&&G7~!!!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!!!!!!!!!~!!!!!!!~?###################################&&&##GJ!~!!!!!!!!!!!!!!!!!!~!!!!!!!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!~7###&#############################&#5??7!~~~!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!~Y&###&&&&&&&&&&#################&B?~~~~~!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!!!!!~!!!!!!!!!!!!~~Y#&############################B7~~~!!!!!!!!!!!!!!!!!!!!!!~!!!!!!!!!!
!!!!!!!!!!!!!!!!!!!!!!~~~~~~!!~~75B&&&#######################&?~!77!~!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!!!!!!!!!!~!7JJ7!~!!!~~!JPB#&&&&&&&#############&&#^..:~?!~!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!!~~~~~~!~?G#&&#B?~!!!!~~~!7?Y5GGPPB########&&&#B5?:....~J!~!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!~!?YJ?!~7#&####&B!~~~~~~~!!7?!^. ~B&###&&&#GY7~:.......~???~~!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!!~~~?B&&&#BYJ&#####&BJJ7!77??JJ~:..^!GBB#&&BY7^...........~?7!?J!~~~!!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!~~!77G&####&&###B###G55PPJY5Y??:...~J?777JB7:............^7?777!?J7!!~~~!!!!!!!!!!!!!!!!!!!!!
!!!!!!~!5B#####&&#BPY7^:^^!PGB###&&#B?...:?7?7!7!?~..........:~7?7!7777!Y?????!!~!~!!!!!!!!!!!~!!!!!
!!!!!!~P&#####BP?~:.... .^?#&#######&B:..^?!J?77!J!.......^!7??777777!!?Y7!777?J7~~!!!!!!!!!!!!!~!!!
!!!!!!~P&#####BGP?....^7P#&######&&#G5!...77YY!77!.....^!??777!!!!777?JJ777777!7?J!~!!!!!!!!!!!!!!!!
!!!!!!~!YB####B55#J:75#&&######&#PY?77!~~~?7777~~:...^7?7777777????J??7!77777777!?J~!!!!!!!!!!!!!!!!
!!!!!!!~~5&#######BB&&#########57!!!77...!?77!?~.~^^7?7!77777!YY7777!777777777777!J7~!!!!!!!!~!!!!!!
!!!!!!!!~5&########&#########&G!!77777..!?!?7777..!J7!7777777!?J!7777777777777777!J?~!!~!!!!!!!!!!!!
!!!!!!!!~Y&##################&P77777?!.7?!?7777J.!?!77777777!7JJ!77777777777777777J?~!!!!!!!!!!!!!!!
!!!!!!!!~!B&################&BYJ!7777???!7?777!JJ?!7777777!7JJ?!77777777777777777!J7~!!!!!!!!!!!!!!!
!!!!!!!!!~7G&###############BJJY?!77757!77?7777J?!77777!77JJ7!7J7777777777777777777J~!!!!!!!!!!!!!!!
!!!!!!!!!!~!Y##############B7?J7Y?!7!J?!777777??!7777!7?J?7!77!JJ!7777777777777777!Y7~!!!!!!!!!!!!!!
!!!!!!!!!!!~~P&###########&P!J?!7Y?77?Y!777777?!77777JJ?7!7777!?Y!7777777777777777!J?~!!!!!!!!!!!!!!

Contract by @backseats_eth
*/

import "@limitbreak/creator-token-contracts/contracts/examples/erc721c/ERC721CWithBasicRoyalties.sol";
import { console2 } from "forge-std/Test.sol"; // DEPLOY

interface IUncanny {
    function mint(address _to) external;
    function paidMint(address _to, uint _amount) external;
}

// ERC721CWithBasicRoyalties contains OwnableBasic
contract UncannyV2 is IUncanny, ERC721CWithBasicRoyalties {

    // The address of the minting contract
    address public uncannyMinter;

    address public teamWallet = 0x7AA0F5c54c1c52745E1ddc34DB82ee7FA816B6C3;

    // The base URI for the token
    string public baseTokenURI;

    // The total supply of the collection
    uint public totalSupply;

    // The next token id to mint
    uint public nextTokenId;

    // The max supply of the collection
    uint public constant MAX_SUPPLY = 2_462;

    /// Errors

    error ArrayEmpty();
    error CantMintThatMany();
    error LengthsDontMatch();
    error OnlyMinter();

    /// Modifier

    // Only the minter contract can mint
    modifier onlyMinter() {
        if (msg.sender != uncannyMinter) revert OnlyMinter();
        _;
    }

    /// Constructor

    constructor(address _royaltyReceiver, uint96 _royaltyFeeNumerator)
    ERC721CWithBasicRoyalties(_royaltyReceiver, _royaltyFeeNumerator, "Uncanny", "UCC") {
        // V1 had a bug with the counter, 616 have been minted to date. First one minted here will be 617.
        // https://www.contractreader.io/contract/mainnet/0x3eab42f5bf2f775e00b535ceab6555eb8a20a837

        // Mint missing commons between 1 and 616
        _mint(teamWallet, 1);
        _mint(teamWallet, 43);
        _mint(teamWallet, 150);
        _mint(teamWallet, 262);
        _mint(teamWallet, 513);
        _mint(teamWallet, 606);
        _mint(teamWallet, 609);

        // Mint all the 1/1s to the team wallet
        for(uint i = 2383; i <= 2462;) {
            _mint(teamWallet, i);
            unchecked { ++i; }
        }

        totalSupply = 87;
        nextTokenId = 618;
    }

    /// Minting

    function mint(address _to) public onlyMinter() {
        if (totalSupply + 1 > MAX_SUPPLY) revert CantMintThatMany();

        _regularMint(_to);
    }

    function paidMint(address _to, uint _amount) public onlyMinter() {
        if (totalSupply + _amount > MAX_SUPPLY) revert CantMintThatMany();

        for (uint i; i < _amount;) {
            _regularMint(_to);
            unchecked { ++i; }
        }
    }

    function _regularMint(address _to) internal {
        uint nextIndex = nextTokenId;

        _mint(_to, nextIndex);

        unchecked {
            ++totalSupply;
            nextTokenId = nextIndex + 1;
        }
    }

    // Airdrop

    /// @dev Example input data: [0xabc123, 0xdef456, 0xghi789], [[1,2,3], [4,5], [9]]
    function airdrop(address[] calldata _addresses, uint[][] calldata _tokenIds) external onlyOwner {
        if (_addresses.length != _tokenIds.length) revert LengthsDontMatch();
        uint length = _addresses.length;

        for (uint i; i < length;) {
            for (uint n; n < _tokenIds[i].length;) {
                _mint(_addresses[i], _tokenIds[i][n]);
                unchecked { ++n; }
            }

            unchecked {
                totalSupply += _tokenIds[i].length;
                ++i;
            }
        }
    }

    /// Virtual

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /// Setters

    function setMinterAddress(address _newMinter) external onlyOwner {
        uncannyMinter = _newMinter;
    }

    // Sets the location of the metadata
    function setBaseURI(string calldata _uri) external onlyOwner {
        baseTokenURI = _uri;
    }

    // Changes the mint address that can call this contract
    function changeMinterAddress(address _newMinter) external onlyOwner {
        uncannyMinter = _newMinter;
    }

}
