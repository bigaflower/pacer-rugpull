// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/******************************************************************************\
* Author: Nick Mudge <nick@perfectabstractions.com> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import {IDiamond} from "../interfaces/IDiamond.sol";
import {IDiamondCut} from "../interfaces/IDiamondCut.sol";

// Remember to add the loupe functions from DiamondLoupeFacet to the diamond.
// The loupe functions are required by the EIP2535 Diamonds standard

library LibDiamond {
  bytes32 private constant DIAMOND_STORAGE_POSITION = keccak256("fact.diamond.storage");

  struct FacetAddressAndSelectorPosition {
    address facetAddress;
    uint16 selectorPosition;
  }

  struct DiamondStorage {
    // function selector => facet address and selector position in selectors array
    mapping(bytes4 => FacetAddressAndSelectorPosition) facetAddressAndSelectorPosition;
    bytes4[] selectors;
    mapping(bytes4 => bool) supportedInterfaces;
    // owner of the contract
    address contractOwner;
    // pending owner of the contract
    address pendingContractOwner;
  }

  function diamondStorage() internal pure returns (DiamondStorage storage ds) {
    bytes32 position = DIAMOND_STORAGE_POSITION;
    assembly {
      ds.slot := position
    }
  }

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

  function transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0), "DMND0016");
    enforceIsContractOwner();
    setPendingContractOwner(_newOwner);
  }

  function acceptOwnership() internal {
    enforceIsPendingContractOwner();
    setContractOwner(pendingContractOwner());
  }

  function renounceOwnership() internal {
    enforceIsContractOwner();
    setContractOwner(address(0));
  }

  function setPendingContractOwner(address _newOwner) internal {
    DiamondStorage storage ds = diamondStorage();
    ds.pendingContractOwner = _newOwner;
    emit OwnershipTransferStarted(contractOwner(), _newOwner);
  }

  function setContractOwner(address _newOwner) internal {
    DiamondStorage storage ds = diamondStorage();
    address previousOwner = ds.contractOwner;
    ds.contractOwner = _newOwner;
    ds.pendingContractOwner = address(0);
    emit OwnershipTransferred(previousOwner, _newOwner);
  }

  function contractOwner() internal view returns (address contractOwner_) {
    contractOwner_ = diamondStorage().contractOwner;
  }

  function pendingContractOwner() internal view returns (address pendingContractOwner_) {
    pendingContractOwner_ = diamondStorage().pendingContractOwner;
  }

  function enforceIsContractOwner() internal view {
    require(msg.sender == contractOwner(), "DMND0001");
  }

  function enforceIsPendingContractOwner() internal view {
    require(msg.sender == pendingContractOwner(), "DMND0018");
  }

  event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

  // Internal function version of diamondCut
  function diamondCut(IDiamondCut.FacetCut[] memory _diamondCut, address _init, bytes memory _calldata) internal {
    for (uint256 facetIndex = 0; facetIndex < _diamondCut.length; facetIndex++) {
      bytes4[] memory functionSelectors = _diamondCut[facetIndex].functionSelectors;
      address facetAddress = _diamondCut[facetIndex].facetAddress;
      require(functionSelectors.length != 0, "DMND0002");

      IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
      if (action == IDiamond.FacetCutAction.Add) {
        addFunctions(facetAddress, functionSelectors);
      } else if (action == IDiamond.FacetCutAction.Replace) {
        replaceFunctions(facetAddress, functionSelectors);
      } else if (action == IDiamond.FacetCutAction.Remove) {
        removeFunctions(facetAddress, functionSelectors);
      } else {
        revert("DMND0005");
      }
    }
    emit DiamondCut(_diamondCut, _init, _calldata);
    initializeDiamondCut(_init, _calldata);
  }

  function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
    require(_facetAddress != address(0), "DMND0003");

    DiamondStorage storage ds = diamondStorage();
    uint16 selectorCount = uint16(ds.selectors.length);
    enforceHasContractCode(_facetAddress);
    for (uint256 selectorIndex = 0; selectorIndex < _functionSelectors.length; selectorIndex++) {
      bytes4 selector = _functionSelectors[selectorIndex];
      address oldFacetAddress = ds.facetAddressAndSelectorPosition[selector].facetAddress;
      require(oldFacetAddress == address(0), "DMND0006");

      ds.facetAddressAndSelectorPosition[selector] = FacetAddressAndSelectorPosition(_facetAddress, selectorCount);
      ds.selectors.push(selector);
      selectorCount++;
    }
  }

  function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
    DiamondStorage storage ds = diamondStorage();
    require(_facetAddress != address(0), "DMND0007");

    enforceHasContractCode(_facetAddress);
    for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
      bytes4 selector = _functionSelectors[selectorIndex];
      address oldFacetAddress = ds.facetAddressAndSelectorPosition[selector].facetAddress;
      
      // can't replace immutable functions -- functions defined directly in the diamond in this case
      require(oldFacetAddress != address(this), "DMND0008");
      require(oldFacetAddress != _facetAddress, "DMND0009");
      require(oldFacetAddress != address(0), "DMND0010");
      // replace old facet address
      ds.facetAddressAndSelectorPosition[selector].facetAddress = _facetAddress;
    }
  }

  function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
    DiamondStorage storage ds = diamondStorage();
    uint256 selectorCount = ds.selectors.length;
    require(_facetAddress == address(0), "DMND0011");

    for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
      bytes4 selector = _functionSelectors[selectorIndex];
      FacetAddressAndSelectorPosition memory oldFacetAddressAndSelectorPosition = ds.facetAddressAndSelectorPosition[
        selector
      ];
      require(oldFacetAddressAndSelectorPosition.facetAddress != address(0), "DMND0012");

      // can't remove immutable functions -- functions defined directly in the diamond
      require(oldFacetAddressAndSelectorPosition.facetAddress != address(this), "DMND0013");

      // replace selector with last selector
      selectorCount--;
      if (oldFacetAddressAndSelectorPosition.selectorPosition != selectorCount) {
        bytes4 lastSelector = ds.selectors[selectorCount];
        ds.selectors[oldFacetAddressAndSelectorPosition.selectorPosition] = lastSelector;
        ds.facetAddressAndSelectorPosition[lastSelector].selectorPosition = oldFacetAddressAndSelectorPosition
          .selectorPosition;
      }
      // delete last selector
      ds.selectors.pop();
      delete ds.facetAddressAndSelectorPosition[selector];
    }
  }

  function initializeDiamondCut(address _init, bytes memory _calldata) internal {
    if (_init == address(0)) {
      return;
    }
    enforceHasContractCode(_init);
    (bool success, bytes memory error) = _init.delegatecall(_calldata);
    if (!success) {
      if (error.length > 0) {
        // bubble up error
        /// @solidity memory-safe-assembly
        assembly {
          let returndata_size := mload(error)
          revert(add(32, error), returndata_size)
        }
      } else {
        revert("DMND0014");
      }
    }
  }

  function enforceHasContractCode(address _contract) internal view {
    uint256 contractSize;
    assembly {
      contractSize := extcodesize(_contract)
    }
    require(contractSize != 0, "DMND0004");
  }

  function setInititalContractOwner(address _newOwner) internal {
    DiamondStorage storage ds = diamondStorage();
    ds.contractOwner = _newOwner;
  }
}
