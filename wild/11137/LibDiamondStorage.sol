// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import { EnumerableSet } from "../../utils/EnumerableSet.sol";

struct FacetAddressAndPosition {
	address facetAddress;
	uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
}

struct FacetFunctionSelectors {
	bytes4[] functionSelectors;
	uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
}

struct DiamondStorage {
	address diamondAddress;
	// maps function selector to the facet address and
	// the position of the selector in the facetFunctionSelectors.selectors array
	mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
	// maps facet addresses to function selectors
	mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
	// facet addresses
	address[] facetAddresses;
	// Used to query if a contract implements an interface.
	// Used to implement ERC-165.
	mapping(bytes4 => bool) supportedInterfaces;
	//the whole diamond is paused or not
	bool paused;
}

library LibDiamondStorage {
	bytes32 internal constant STORAGE_SLOT = keccak256("usmart.contracts.diamond.storage.v1");

	function layout() internal pure returns (DiamondStorage storage layout_) {
		bytes32 position = STORAGE_SLOT;
		assembly {
			layout_.slot := position
		}
	}
}
