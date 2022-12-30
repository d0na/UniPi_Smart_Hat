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
        
        //Recupero l'indirizzo del contratto
        address hat_contract=intToAddress(tokenId);

        //Otteniamo lo stato degli esami dell'indirizzo chiamante
        /*
        bytes4 selector=bytes4(keccak256("get3DModel()"));
        bytes memory data= abi.encodeWithSelector(selector);
        (bool success, bytes memory result)=hat_contract.call(data);

        require(success,"Failed to obtain tokenURI from Smart_Hat contract");
        (string memory uri)=abi.decode(result,(string));
        */
        return "";
        //Da rivedere facendo in modo di restituire la URI ottenuta dal contratto
    }

    //-----Funzioni per la gestione degli indirizzi-----
    function addressToInt(address index) public pure returns(uint){
        return uint(uint160(index));
    }
    
    function intToAddress(uint index) public pure returns (address){
        return address(uint160(index));
    }
}
