// SPDX-License-Identifier: MIT
/*
▗▄▄▖ ▗▖    ▗▄▖ ▗▖  ▗▖ ▗▄▖ ▗▄▄▖ ▗▄▄▄▖ ▗▄▄▖ ▗▄▄▖
▐▌ ▐▌▐▌   ▐▌ ▐▌▐▛▚▖▐▌▐▌ ▐▌▐▌ ▐▌  █  ▐▌   ▐▌   
▐▛▀▘ ▐▌   ▐▛▀▜▌▐▌ ▝▜▌▐▛▀▜▌▐▛▀▚▖  █  ▐▌    ▝▀▚▖
▐▌   ▐▙▄▄▖▐▌ ▐▌▐▌  ▐▌▐▌ ▐▌▐▌ ▐▌▗▄█▄▖▝▚▄▄▖▗▄▄▞▘
                                            
                                by Jr Casas 
--------------------------------------------- 
Planarics are on-chain digital organisms,
inspired by real planarian flatworms.

They are cut, they grow, they expand.
Artwork and metadata are 100% generated on-chain.
---------------------------------------------
*/
pragma solidity ^0.8.20;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract Planarics is ERC721A, ReentrancyGuard, ERC2981, Ownable {
    uint256 public maxSupply = 360;
    uint256 public constant lineageLimit = 45; // Max Planarics per genetic lineage

    mapping(uint256 => uint256) private birthTimes;
    mapping(uint256 => uint16) private linajes; 
    mapping(uint16 => uint256) private linajeCount; 

    struct planaricObject {
        int8 tailRot;
        int8 headRot;
        uint8 faseOne;
        uint8 faseTwo;
        uint8 faseThree;
        uint16 linaje; 
        uint16 tailHue1; 
        uint16 tailHue2; 
        uint16 tailHue3; 
        uint16 headHue1; 
        uint16 headHue2; 
        bool isProtoPlanaric; 
    }

    constructor() ERC721A("Planarics", "PLAN") Ownable(msg.sender) {
        _setDefaultRoyalty(msg.sender, 500);
    }


    /// @notice Deterministically calculates a color offset based on tokenId and salt
    /// @dev Used for variation in non-lineage body parts
    function calculateHueOffset(uint256 tokenId, string memory salt) internal pure returns (int8) {
        uint256 rand = random(string(abi.encodePacked("HUE_OFFSET", salt, toString(tokenId))));
        return int8(int256(rand % 51) - 25); 
    }

    /// @notice Adjusts a base hue by an offset and ensures it stays within the 0-359 HSL range
    function calculateHue(uint16 baseHue, int8 offset, uint8 multiplier) internal pure returns (uint16) {
        int16 offsetValue = int16(offset) * int16(uint16(multiplier));
        int16 newHue = int16(baseHue) + offsetValue;
        
        
        while (newHue < 0) {
            newHue += 360;
        }
        while (newHue >= 360) {
            newHue -= 360;
        }
        
        return uint16(newHue);
    }

    /// @notice Generates the structural data for a Planaric on the fly
    /// @dev Logic ensures offspring inherit the core lineage hue but have body variations
    function randomPlanaric(uint256 tokenId) internal view returns (planaricObject memory) {
        uint256 rand = random(string(abi.encodePacked("PLAN DATA", toString(tokenId))));
        
        planaricObject memory planaric;
        planaric.tailRot = int8(int256(rand % 31) - 15);
        planaric.headRot = int8(int256((rand >> 8) % 31) - 15);
        (uint8 fase1, uint8 fase2, uint8 fase3) = growthPhases(tokenId);

        planaric.faseOne = fase1;
        planaric.faseTwo = fase2;
        planaric.faseThree = fase3;
        planaric.linaje = linajes[tokenId]; 
        
        
        planaric.isProtoPlanaric = (tokenId >= 1 && tokenId <= 8);
        
        // For the first 8 planarics, all circles have the same color as the lineage.
        if (planaric.isProtoPlanaric) {
            planaric.tailHue1 = planaric.linaje;
            planaric.tailHue2 = planaric.linaje;
            planaric.tailHue3 = planaric.linaje;
            planaric.headHue1 = planaric.linaje;
            planaric.headHue2 = planaric.linaje;
        } else {
            // Calculate offset for tail (random direction)
            int8 tailOffset = calculateHueOffset(tokenId, "TAIL");
            planaric.tailHue1 = calculateHue(planaric.linaje, tailOffset, 1);
            planaric.tailHue2 = calculateHue(planaric.linaje, tailOffset, 2);
            planaric.tailHue3 = calculateHue(planaric.linaje, tailOffset, 3);
            
            // Calculate offset for head (random direction)
            int8 headOffset = calculateHueOffset(tokenId, "HEAD");
            planaric.headHue1 = calculateHue(planaric.linaje, headOffset, 1);
            planaric.headHue2 = calculateHue(planaric.linaje, headOffset, 2);
        }

        return planaric;
    }

    /// @notice Calculates the growth progress (opacity) based on time elapsed since birth
    /// @dev Full maturity takes 6 days (2 days per phase)
    function growthPhases(uint256 tokenId) private view returns (uint8 fase1, uint8 fase2, uint8 fase3) {
        uint256 age = block.timestamp - birthTimes[tokenId];
        uint256 day = 1 days; 

        uint8 maxOpacity = 80;
        if (age < 2 * day) {
            fase1 = uint8((age * maxOpacity) / (2 * day));
        } else {
            fase1 = maxOpacity;
            if (age < 4 * day) {
                fase2 = uint8(((age - 2 * day) * maxOpacity) / (2 * day));
            } else {
                fase2 = maxOpacity;
                if (age < 6 * day) {
                    fase3 = uint8(((age - 4 * day) * maxOpacity) / (2 * day));
                } else {
                    fase3 = maxOpacity;
                }
            }
        }
    }

    /// @notice Validates if a Planaric is fully grown and can be cut without exceeding its lineage limit
    function canBeCut(uint256 tokenId) public view returns (bool, string memory) {
        
        if (tokenId == 0 || !_exists(tokenId)) {
            return (false, "Token does not exist");
        }
        
        (, , uint8 fase3) = growthPhases(tokenId);
        if (fase3 < 80) {
            return (false, "Planaric is still growing");
        }
        
        uint16 linaje = linajes[tokenId];
        if (linajeCount[linaje] + 2 > lineageLimit) {
            return (false, "Lineage limit reached");
        }
        
        return (true, "Planaric can be cut");
    }

    function getColorName(uint16 hue) private pure returns (string memory) {
        if (hue == 0) return "Ruber"; // Red
        if (hue == 30) return "Luteus"; //orange
        if (hue == 60) return "Flavus"; //Yellow
        if (hue == 120) return "Viridis"; //Green
        if (hue == 180) return "Cyaneus"; //Cyan
        if (hue == 210) return "Caeruleus";  //Blue
        if (hue == 270) return "Purpureus";  //Purple
        if (hue == 310) return "Roseus";  //Magenta
        return "Forsaken";
    }

    function twoDigitString(uint8 value) internal pure returns (string memory) {
        if (value < 10) return string(abi.encodePacked("0", toString(value)));
        return toString(value);
    }

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function getSVG(planaricObject memory planaric) internal pure returns (string memory) {
        string[4] memory parts;
        
        parts[0] = string(abi.encodePacked(
            '<svg width="1000" height="1000" viewBox="0 0 400 400" xmlns="http://www.w3.org/2000/svg">',
            '<rect width="100%" height="100%" fill="#1c1c1c"/>'
           
            
        ));

        parts[1] = string(abi.encodePacked(
            '<circle cx="200" cy="275" r="15" fill="hsl(', toString(planaric.tailHue3), ', 100%, 50%)" transform="rotate(', intToString(planaric.tailRot * 3), ' 200 200)" opacity="0.', twoDigitString(planaric.faseThree), '" />',
            '<circle cx="200" cy="255" r="20" fill="hsl(', toString(planaric.tailHue2), ', 100%, 50%)" transform="rotate(', intToString(planaric.tailRot * 2), ' 200 200)" opacity="0.', twoDigitString(planaric.faseTwo), '" />'
        ));

        parts[2] = string(abi.encodePacked(
            '<circle cx="200" cy="230" r="26" fill="hsl(', toString(planaric.tailHue1), ', 100%, 50%)" transform="rotate(', intToString(planaric.tailRot), ' 200 200)" opacity="0.', twoDigitString(planaric.faseOne), '" />',
            '<circle cx="200" cy="200" r="30" fill="hsl(', toString(planaric.linaje), ', 100%, 50%)" opacity="0.85" />'
            
        ));

        parts[3] = string(abi.encodePacked(
            '<circle cx="200" cy="170" r="26" fill="hsl(', toString(planaric.headHue1), ', 100%, 50%)" transform="rotate(', intToString(planaric.headRot), ' 200 200)" opacity="0.', twoDigitString(planaric.faseOne), '" />',
            '<circle cx="200" cy="145" r="20" fill="hsl(', toString(planaric.headHue2), ', 100%, 50%)" transform="rotate(', intToString(planaric.headRot * 2), ' 200 200)" opacity="0.', twoDigitString(planaric.faseTwo), '" />',
            '</svg>'
        ));

        return string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3]));
    }

    /// @notice Returns the base64 encoded SVG image for a given Planaric token
    /// @dev The SVG is fully generated on-chain based on the token's deterministic data
    function tokenIdToPlanaricSVG(uint256 tokenId) public view returns (string memory) {
        require(tokenId > 0 && tokenId <= totalSupply(), "Token does not exist"); 
        planaricObject memory myPlanaric = randomPlanaric(tokenId);
        string memory svg = getSVG(myPlanaric);
        string memory svgBase64 = Base64.encode(bytes(svg));
        return string(abi.encodePacked("data:image/svg+xml;base64,", svgBase64));
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        require(tokenId > 0 && tokenId <= totalSupply(), "Token does not exist");

        planaricObject memory myPlanaric = randomPlanaric(tokenId);
        string memory colorName = getColorName(myPlanaric.linaje);
        
        string memory attributes;
        if (myPlanaric.isProtoPlanaric) {
            attributes = string(abi.encodePacked(
                '{"trait_type": "Genetic Lineage", "value": "', colorName, '"},',
                '{"trait_type": "Type", "value": "ProtoPlanaric"}'
            ));
        } else {
            attributes = string(abi.encodePacked(
                '{"trait_type": "Genetic Lineage", "value": "', colorName, '"}'
            ));
        }

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Planaric #', toString(tokenId), '", ',
                        '"description": "Planarics that grow and regenerate by cutting.", ',
                        '"attributes": [', attributes, '],',
                        '"image": "data:image/svg+xml;base64,', Base64.encode(bytes(getSVG(myPlanaric))), '"',
                        '}'
                    )
                )
            )
        );

        return string(abi.encodePacked('data:application/json;base64,', json));
    }

     
    /// @notice Updates the royalty receiver and percentage.
    /// @dev feeNumerator is in basis points (e.g., 500 = 5%).
    function setRoyalties(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }


    function supportsInterface(bytes4 interfaceId) 
    public 
    view 
    override(ERC721A, ERC2981)
    returns (bool)
{
    return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
}

    function mint(address _to, uint256 amountOfTokens) private {
        require(totalSupply() < maxSupply, "All tokens have been minted");
        require(totalSupply() + amountOfTokens <= maxSupply, "Minting would exceed max supply");
        require(amountOfTokens > 0, "Must mint at least one token");

        uint256 startTokenId = _nextTokenId();
        _safeMint(_to, amountOfTokens);

        for (uint256 i = 0; i < amountOfTokens; i++) {
            birthTimes[startTokenId + i] = block.timestamp;
        }
    }
    
    
    /// @notice Fragments a Planaric into 2 new entities while the parent restarts its growth cycle.
    /// @dev Offspring inherit the same genetic lineage as the parent.
    function cutPlanaric(uint256 tokenId) public nonReentrant {
        require(ownerOf(tokenId) == msg.sender, "Not your planaric");
        require(balanceOf(msg.sender) < 8 || msg.sender == owner(), "You already own 8 planarics, Distributing is good to cut again.");

        (bool canCut, string memory reason) = canBeCut(tokenId);
        require(canCut, reason);

        uint16 linaje = linajes[tokenId];
        uint256 newStartId = _nextTokenId();
        mint(msg.sender, 2);

        // Inherit lineage and update counter
        linajes[newStartId] = linaje;
        linajes[newStartId + 1] = linaje;
        linajeCount[linaje] += 2;

        birthTimes[tokenId] = block.timestamp;
    }


    /// @notice Mints the first 8 ProtoPlanarics with the colors of each lineage
    /// @dev Can only be executed once to start the collection
    function mintTo(address _to, uint256 amountOfTokens) public onlyOwner {
        uint256 startTokenId = _nextTokenId();

        require(startTokenId == 1 && amountOfTokens == 8, "mintTo can only be used once to create the first 8 tokens");

        mint(_to, amountOfTokens);
 

        for (uint256 i = 0; i < amountOfTokens; i++) {
            uint256 tokenId = startTokenId + i;
            birthTimes[tokenId] = block.timestamp;

            // Assigning lineages to the first 8 tokens
            if (tokenId >= 1 && tokenId <= 8) {
                uint16[8] memory coloresBase = [0, 30, 60, 120, 180, 210, 270, 310];
                uint16 linaje = coloresBase[tokenId - 1];
                linajes[tokenId] = linaje;
                linajeCount[linaje]++; 
            }
        }
    }

    function withdraw() public onlyOwner {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "Withdraw failed.");
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) return "0";
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function intToString(int256 _i) internal pure returns (string memory) {
        if (_i == 0) return "0";
        bool negative = _i < 0;
        uint256 len;
        uint256 j = uint256(negative ? -_i : _i);
        uint256 temp = j;

        while (temp != 0) {
            len++;
            temp /= 10;
        }

        if (negative) len++;

        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (j != 0) {
            k--;
            bstr[k] = bytes1(uint8(48 + j % 10));
            j /= 10;
        }

        if (negative) bstr[0] = "-";

        return string(bstr);
    }

    /// @notice Returns the lineage name, the number of tokens created in that lineage,
    /// and whether the lineage limit has been reached for the given tokenId.
    /// @dev The 8 possible lineages are: 
    /// Ruber, Luteus, Flavus, Viridis, Cyaneus, Caeruleus, Purpureus and Roseus
    /// The limit for each lineage is 45 tokens.
    function getLineageCountByToken(uint256 tokenId) public view returns (string memory lineageType, uint256 created, string memory limitReached) {
        require(tokenId > 0 && tokenId <= totalSupply(), "Planaric does not exist");
        uint16 linaje = linajes[tokenId];
        lineageType = getColorName(linaje);
        created = linajeCount[linaje];

        if (linajeCount[linaje] >= lineageLimit) {
        limitReached = "Lineage limit reached";
    } else {
        limitReached = "Lineage limit not reached";
    }
        
    }

    
}
