// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "./Ownable.sol";
import "./Smart_Hat.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract UniPi_Hat is ERC721, Ownable {
    //Riferimento al contratto utilizzato da UniPi per caricare gli esami superati e le lauree conseguite
    address public managerContract;

    constructor(address managerAddress) ERC721("UniPi Metaverse Hat", "UNIPIMVHAT") {
        require(managerAddress == address(managerAddress),"Invalid address");
        managerContract = managerAddress;
    }

    function setExamsManager(address manager) public onlyOwner {
        require(manager == address(manager),"Invalid manager contract address");
        managerContract = manager;
    }

    /***
    * @notice Funzione per l'ottenimento della URI che contiene i metadati associati ad un token.
    * @param Il tokenId del token di cui vogliamo ottenere la URI
    */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireMinted(tokenId);
        
        //Recupero l'indirizzo del contratto
        address hat_contract = intToAddress(tokenId);

        //Otteniamo dal contratto del cappello l'URI che ne descrive lo stato corrente
        Smart_Hat hat = Smart_Hat(hat_contract);
        return hat.get3DModel();
    }

    /***
    * @notice Funzione per il minting del token e trasferimento al beneficiario.
    * @param Indirizzo del proprietario del nuovo token coniato
    */
    function mint(address to) public returns (address){
        //Creo un nuovo cappellino passando l'indirizzo di questo contratto come manager.
        console.log("Mio address %s",address(this));
        Smart_Hat new_hat = new Smart_Hat(managerContract,address(this));
        console.log("Hat address %s",address(new_hat));

        /*Il proprietario di questo contratto sarà il beneficiario il quale potrà invocare
        tutti i metodi previsti da esso*/
        new_hat.transferOwnership(to);

        uint tokenId=uint160(address(new_hat));
        console.log("Hat id %s",tokenId);
        _safeMint(to, tokenId, "");

        return address(new_hat);
    }


    //-----Funzioni per la gestione degli indirizzi-----
    function addressToInt(address index) public pure returns(uint){
        return uint(uint160(index));
    }
    
    function intToAddress(uint index) public pure returns (address){
        return address(uint160(index));
    }
}
