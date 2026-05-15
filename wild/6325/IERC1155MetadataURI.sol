// SPDX-License-Identifier: MIT

/***************************************************************************
          ___        __         _     __           __   __ ___
        / __ \      / /_  _____(_)___/ /____       \ \ / /  _ \
       / / / /_  __/ __/ / ___/ / __  / __  )       \ / /| |
      / /_/ / /_/ / /_  (__  ) / /_/ / ____/         | | | |_
      \____/\____/\__/ /____/_/\__,_/\____/          |_|  \___/
                                       
****************************************************************************/

pragma solidity ^0.8.0;

import "./IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}
