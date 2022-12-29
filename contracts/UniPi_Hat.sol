// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

contract UniPi_Hat is ERC721URIStorage {
    
    constructor() ERC721("UniPi Metaverse Hat", "UNIPIMVHAT") {
    }

    /***
    * @notice Funzione per l'ottenimento della URI che contiene i metadati associati ad un token
    * @param Il tokenId del token di cui vogliamo ottenere la URI
    */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireMinted(tokenId);
        /*
        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);*/
        //Da rivedere facendo in modo di restituire la URI ottenuta dal contratto
    }

    //-----Funzioni per la gestione degli indirizzi-----
    function addressHash(address addr) public pure returns(bytes32,uint){
        bytes32 res=keccak256(abi.encodePacked(addr));
        return(res,uint(res));
    }

    function addressToInt(address index) public pure returns(uint){
        return uint(uint160(index));
    }
    
    function IntToAddress(uint index) public pure returns (address){
        return address(uint160(index));
    }
}
