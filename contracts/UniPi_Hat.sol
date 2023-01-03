// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

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
        Smart_Hat new_hat = new Smart_Hat(managerContract,address(this));

        /*Il proprietario di questo contratto sarà il beneficiario il quale potrà invocare
        tutti i metodi previsti da esso*/
        new_hat.transferOwnership(to);

        uint tokenId=uint160(address(new_hat));
        
        _safeMint(to, tokenId, "");

        return address(new_hat);
    }

    function safeTransferToStudent(address from, address to, uint256 tokenId) public{
        Gestione_Esami ge = Gestione_Esami(managerContract);

        //Recupero la situazione del potenziale acquirente
        string[] memory examList=ge.getExamList();

        //Recupero la situazione del cappello
        Smart_Hat hat = Smart_Hat(address(uint160(tokenId)));

        //Verifico la presenza delle spille per gli esami passati
        require(ge.isGraduated(to) == hat.isGraduatedVersion(), "Hat not compatible with the exams situation of the buyer!");

        for(uint i = 0; i<examList.length; i++){
            if( (hat.hasPin(examList[i]) != Smart_Hat.pinVersion.NO_PIN) && 
                (uint(ge.getMyExamState(examList[i])) == uint(Gestione_Esami.examState.TO_DO))
                )
                revert("Hat not compatible with the exams situation of the buyer!");
        }

        safeTransferFrom(from,to,tokenId,"");
    }

    //-----Funzioni per la gestione degli indirizzi-----
    function addressToInt(address index) internal pure returns(uint){
        return uint(uint160(index));
    }
    
    function intToAddress(uint index) internal pure returns (address){
        return address(uint160(index));
    }
}
