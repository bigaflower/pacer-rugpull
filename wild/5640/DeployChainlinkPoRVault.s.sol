// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {CassaITUT} from "../src/CassaITUT.sol";
import {ChainlinkPoRPolicy} from "../src/policies/examples/ChainlinkPoRPolicy.sol";

address constant ADMIN = 0xB0e34f640Be7f3156EFABdd3a66eF9eA3d4a5B50;

uint256 constant EFFECTIVE_DATE_IN = 0;
uint256 constant EXPIRATION_DATE_IN = 30 days;
uint256 constant MAX_UPDATE_GAP = 25 hours;

// EETH
address constant POR_FEED = 0xC8cd82067eA907EA4af81b625d2bB653E21b5156;
address constant TOKEN = 0x35fA164735182de50811E8e2E824cFb9B6118ac2;

contract CassaITUT_EOAAdmin is CassaITUT {
    address private immutable _admin;

    constructor(string memory __name, address __asset, address __policy, address __admin)
        CassaITUT(__name, __asset, __policy)
    {
        _admin = __admin;
    }

    function admin() public view virtual override returns (address __admin) {
        return _admin;
    }
}

contract MockERC20 is ERC20 {
    constructor() ERC20("Mock Token", "MOCK") {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract DeployChainlinkPoRVault is Script {
    function run() external {
        vm.startBroadcast();

        uint256 effectiveDate = block.timestamp + EFFECTIVE_DATE_IN;
        uint256 expirationDate = block.timestamp + EXPIRATION_DATE_IN;

        console.log("Deploying policy");
        ChainlinkPoRPolicy policy =
            new ChainlinkPoRPolicy(effectiveDate, expirationDate, MAX_UPDATE_GAP, POR_FEED, TOKEN);

        console.log("Deploying mock asset");
        MockERC20 asset = new MockERC20();

        console.log("Deploying vault");
        CassaITUT itut = new CassaITUT_EOAAdmin("Test", address(asset), address(policy), ADMIN);

        console.log("Minting asset to admin");
        asset.mint(ADMIN, 1_000e18);

        console.log("");
        console.log("DONE.");
        console.log("");

        console.log("effective date:", effectiveDate);
        console.log("expiration date:", expirationDate);
        
        console.log("policy:", address(policy));
        console.log("asset:", address(asset));
        console.log("vault:", address(itut));
        console.log("it:", address(itut.IT()));
        console.log("ut:", address(itut.UT()));

        vm.stopBroadcast();
    }
}
