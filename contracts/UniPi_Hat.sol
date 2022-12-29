// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

contract UniPi_Hat is ERC721URIStorage {
    
    constructor() ERC721("UniPi Metaverse Hat", "UNIPIMVHAT") {
    }

    function addressHash(address addr) view returns(string memory)
}
