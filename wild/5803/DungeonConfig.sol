// SPDX-License-Identifier: MIT
//
// DungeonConfig by DungeonMaster/@DungeonSpawner

pragma solidity ^0.8.0;

import "./Ownable.sol";

interface IDungeon {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

interface IDungeonRewards {
    function getStakedTokens(
        address owner
    )
        external
        view
        returns (uint256[] memory dungeons, uint256[] memory avatars);
}

contract DungeonConfig is Ownable {
    /*///////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event AssignPerms(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    event AssignGlobalPerms(address indexed from, address indexed to);
    event RevokeGlobalPerms(address indexed from, address indexed to);

    /*///////////////////////////////////////////////////////////////
                          METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/
    address public dungeonAddress;
    address public dungeonRewardsAddress;

    struct Permission {
        address grantedBy; // The address that granted the permission
        address grantedTo; // The address that received the permission
    }
    struct GlobalPermission {
        address grantedTo;
        address grantedBy;
    }

    struct FloorData {
        string txId; // transaction ID for the floor data
        uint256 version; // current version of the floor data (every resetAllFloors increments the version #, outdating previous entries)
    }

    struct DungeonData {
        bool locked;
        uint256 trialTimeout;
        bool randomizeLayout; // randomize layout indicates each floor after floor 1 has a random layout/environment
        string passwordHash; // DungeonMaster notes: not really secure, of course, since it's publically available, but the best we have
        string ownersMessage;
        string gameMode; // space theme, 3d, leaderboard, etc... and if starts with https:, NFT will redirect to url after loading up (use for streaming via rumble, etc)
        string tilesetOverride; // override tileset with this txid/url allowing owners further customization
    }

    // Mapping that tells us which version of the dungeon data we're dealing with 
    // (reseting all floors increments the version # -- saves us gas from having to clear all the existing dungeon floor data)
    mapping(uint256 => uint256) private tokenVersions;

    mapping(uint256 => DungeonData) public dungeons;
    // Mapping from tokenId to a mapping of floorNumber to FloorData
    mapping(uint256 => mapping(uint256 => FloorData)) public dungeonFloors;

    mapping(uint256 => Permission) public tokenPermissions;
    // Mapping to store global permissions
    mapping(address => GlobalPermission) public globalPermissions;

    string public BASE_CODE_TXID = ""; // base code txid

    constructor(address _dungeonAddress, address _dungeonRewardsAddress) {
        dungeonAddress = _dungeonAddress;
        dungeonRewardsAddress = _dungeonRewardsAddress;
    }

    modifier onlyOwnerOrStaker(uint256 tokenId) {
        IDungeon dungeon = IDungeon(dungeonAddress);
        address owner = dungeon.ownerOf(tokenId);
        bool isStaker = owner == dungeonRewardsAddress &&
            isTokenStakedByAddress(tokenId, msg.sender);

        require(
            owner == msg.sender || isStaker,
            "Caller is not owner or staker"
        );
        _;
    }

    function isTokenStakedByAddress(
        uint256 tokenId,
        address addressToCheck
    ) private view returns (bool) {
        IDungeonRewards rewards = IDungeonRewards(dungeonRewardsAddress);
        (uint256[] memory stakedDungeons, ) = rewards.getStakedTokens(
            addressToCheck
        );
        for (uint i = 0; i < stakedDungeons.length; i++) {
            if (stakedDungeons[i] == tokenId) {
                return true;
            }
        }
        return false;
    }

    modifier isPermitted(uint256 tokenId) {
        IDungeon dungeon = IDungeon(dungeonAddress);
        address owner = dungeon.ownerOf(tokenId);

        // First, check if msg.sender is the owner. If true, no further checks needed.
        if (
            owner == msg.sender ||
            (owner == dungeonRewardsAddress &&
                isTokenStakedByAddress(tokenId, msg.sender))
        ) {
            _;
            return;
        }

        // Global Permissions Check
        GlobalPermission memory globalPerm = globalPermissions[msg.sender];
        if (globalPerm.grantedTo == msg.sender) {
            bool isGlobalGrantorOwnerOrStaker = globalPerm.grantedBy == owner ||
                (owner == dungeonRewardsAddress &&
                    isTokenStakedByAddress(tokenId, globalPerm.grantedBy));

            if (isGlobalGrantorOwnerOrStaker) {
                _;
                return;
            }
        }

        // Only proceed to check permissions if the sender is not the owner or a staker.
        Permission memory permission = tokenPermissions[tokenId];
        bool hasValidPermission = permission.grantedTo == msg.sender &&
            (permission.grantedBy == owner ||
                (owner == dungeonRewardsAddress &&
                    isTokenStakedByAddress(tokenId, permission.grantedBy)));

        require(hasValidPermission, "Not authorized");

        _;
    }

    function writeDungeonConfig(
        uint256 tokenId,
        DungeonData memory configData
    ) public isPermitted(tokenId) {
        DungeonData storage dungeon = dungeons[tokenId];
        dungeon.locked = configData.locked;
        dungeon.trialTimeout = configData.trialTimeout;
        dungeon.randomizeLayout = configData.randomizeLayout;
        dungeon.passwordHash = configData.passwordHash;
        dungeon.ownersMessage = configData.ownersMessage;
        dungeon.gameMode = configData.gameMode;
        dungeon.tilesetOverride = configData.tilesetOverride;
    }

    // same as above, but without tilesetOverride - costs about half the gas
    function writeDungeonConfig(
        uint256 tokenId,
        bool locked,
        uint256 trialTimeout,
        bool randomizeLayout,
        string memory passwordHash,
        string memory ownersMessage,
        string memory gameMode
    ) public isPermitted(tokenId) {
        DungeonData storage dungeon = dungeons[tokenId];
        dungeon.locked = locked;
        dungeon.trialTimeout = trialTimeout;
        dungeon.randomizeLayout = randomizeLayout;
        dungeon.passwordHash = passwordHash;
        dungeon.ownersMessage = ownersMessage;
        dungeon.gameMode = gameMode;
    }

    function readDungeonConfig(
        uint256 tokenId
    )
        public
        view
        returns (
            bool locked,
            uint256 trialTimeout,
            bool randomizeLayout,
            string memory passwordHash,
            string memory ownersMessage,
            string memory gameMode,
            string memory tilesetOverride,
            string memory codeTxId
        )
    {
        DungeonData memory dungeon = dungeons[tokenId];

        // could directly assing the fields from the dungeon struct to construct the return values as per the
        // 2nd version of this function, but it's just as gas efficient to wrap it in a return like this
        return (
            dungeon.locked,
            dungeon.trialTimeout,
            dungeon.randomizeLayout,
            dungeon.passwordHash,
            dungeon.ownersMessage,
            dungeon.gameMode,
            dungeon.tilesetOverride,
            BASE_CODE_TXID
        );
    }

    // read Dungeon Config with custom floors
    function readDungeonConfig(
        uint256 tokenId, uint256 maxFloorNumber
    )
        public
        view
        returns (
            bool locked,
            uint256 trialTimeout,
            bool randomizeLayout,
            string memory passwordHash,
            string memory ownersMessage,
            string memory gameMode,
            string memory tilesetOverride,
            string memory codeTxId,
            uint256[] memory customFloors
        )
    {
        DungeonData memory dungeon = dungeons[tokenId];
        uint256 currentVersion = tokenVersions[tokenId];

        // Directly use the fields from the dungeon struct to construct the return values
        locked = dungeon.locked;
        trialTimeout = dungeon.trialTimeout;
        randomizeLayout = dungeon.randomizeLayout;
        passwordHash = dungeon.passwordHash;
        ownersMessage = dungeon.ownersMessage;
        gameMode = dungeon.gameMode;
        tilesetOverride = dungeon.tilesetOverride;
        codeTxId = BASE_CODE_TXID;

        // Use the helper function to get customFloors - do it this way to avoid CompilerError: Stack too deep
        customFloors = getCustomFloors(tokenId, maxFloorNumber, currentVersion);
    }

    // collect customFloors data
    function getCustomFloors(uint256 tokenId, uint256 maxFloorNumber, uint256 currentVersion)
        internal
        view
        returns (uint256[] memory customFloors)
    {
        uint256[] memory tempFloors = new uint256[](maxFloorNumber);
        uint256 count = 0;

        for (uint256 floor = 0; floor <= maxFloorNumber; floor++) {
            if (dungeonFloors[tokenId][floor].version == currentVersion &&
                bytes(dungeonFloors[tokenId][floor].txId).length > 0) {
                tempFloors[count] = floor;
                count++;
            }
        }

        customFloors = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            customFloors[i] = tempFloors[i];
        }
    }

    function writeFloorData(
        uint256 tokenId,
        uint256 floorNumber,
        string memory txId
    ) public isPermitted(tokenId) {
        // Store the transaction ID for the specific floor
        dungeonFloors[tokenId][floorNumber] = FloorData(txId, tokenVersions[tokenId]);
    }

    function readFloorData(
        uint256 tokenId,
        uint256 floorNumber
    ) public view returns (string memory) {
         FloorData memory floorData = dungeonFloors[tokenId][floorNumber];
        // Return the transaction ID for the specific floor
        if(floorData.version == tokenVersions[tokenId]) {
            return floorData.txId;
        } else {
            return ""; // Indicates no data for the current version
        }        
    }

    function resetAllFloors(uint256 tokenId) public isPermitted(tokenId) { 
        tokenVersions[tokenId] += 1; // Increment the version to "reset" the data
    }

    function assignPermission(
        uint256 tokenId,
        address to
    ) public onlyOwnerOrStaker(tokenId) {
        tokenPermissions[tokenId] = Permission(msg.sender, to);

        emit AssignPerms(msg.sender, to, tokenId);
    }

    // Assign global permission
    function assignGlobalPermission(address to) public {
        globalPermissions[to] = GlobalPermission({
            grantedTo: to,
            grantedBy: msg.sender
        });

        emit AssignGlobalPerms(msg.sender, to);
    }

    // Optional: Function to revoke global permission
    function revokeGlobalPermission(address to) public {
        require(
            globalPermissions[to].grantedBy == msg.sender,
            "Not authorized to revoke"
        );
        delete globalPermissions[to];
        emit RevokeGlobalPerms(msg.sender, to);
    }

    // set the ethscription txid of the base codebase
    function setBaseCodeTxid(string memory baseCodeTxid) public onlyOwner {
        BASE_CODE_TXID = baseCodeTxid;
    }

    // read the ethscription txid of the base codebase
    function getBaseCodeTxid() public view returns (string memory) {
        return BASE_CODE_TXID;
    }

}
