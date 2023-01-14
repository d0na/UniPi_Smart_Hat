// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./Smart_Hat.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract UniPi_Hat_NFTs is ERC721, Ownable {
    //Riferimento al contratto utilizzato da UniPi per caricare gli esami superati e le lauree conseguite
    address public managerContract;

    constructor(address managerAddress) ERC721("UniPi Metaverse Hat", "UNIPIMVHAT") {
        require(managerAddress == address(managerAddress),"Invalid address");
        managerContract = managerAddress;
    }

    /***
    * @notice Funzione per l'ottenimento della URI che contiene i metadati associati ad un token.
    * @param Il tokenId del token di cui vogliamo ottenere la URI
    * @returns La stringa contenente la URI richiesta
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
    * @returns L'indirizzo del contratto Smart_Hat che rappresenta il nuovo cappellino creato.
    * @returns L'id del token creato
    */
    function mint(address to) public onlyOwner returns (address,uint){
        require(to == address(to), "Invalid address");
        
        //Creo un nuovo cappellino passando l'indirizzo di questo contratto come manager.
        Smart_Hat new_hat = new Smart_Hat(managerContract,address(this),to);

        /*Il proprietario di questo contratto sarà il beneficiario il quale potrà invocare
        tutti i metodi previsti da esso*/
        new_hat.transferOwnership(to);

        //Determinazione del tokenID e chiamata alla funzione di minting del contratto ERC721
        uint tokenId = uint160(address(new_hat));
        _safeMint(to, tokenId, "");

        return (address(new_hat), tokenId);
    }

    /***
    * @notice Funzione per il trasferimento vincolato di un cappellino dall'indirizzo 'from' all'indirizzo 'to'.
    *   Il trasferimento viene approvato solamente se 'to' ha superato tutti gli esami che sono presenti sul cappello
    *   con una spilla. La versione sicura del trasferimento effettua i controlli necessari per evitare il blocco 
    *   permanente di un token inviato ad un indirizzo di un contratto non abilitato alla ricezione di nft.
    * @param Indirizzo 'from' dell'attuale proprietario del cappellino
    * @param Indirizzo 'to' del potenziale acquirente del cappellino
    * @param Id del cappellino oggetto del trasferimento
    * @param Spazio per dati aggiuntivi
    */
    function safeTransferToStudent(address from, address to, uint256 tokenId, bytes memory data) internal {
        Gestione_Esami ge = Gestione_Esami(managerContract);

        //Recupera la situazione del potenziale acquirente
        string[] memory examList=ge.getExamList();

        //Recupera il contratto del cappello
        Smart_Hat hat = Smart_Hat(intToAddress(tokenId));

        //Verifica della conformità di versione del cappello (da laureato o standard)
        require(ge.isGraduated(to) == hat.isGraduatedVersion(), "Hat not compatible with the exams situation of the buyer!");

        //Verifica del superamento da parte di 'to' per gli esami che hanno spille apposte sul cappello
        for(uint i = 0; i<examList.length; i++){
            /*Se il cappello presenta una spilla di un esame non superato dal potenziale
                acquirente l'operazione viene annullata*/
            if( (hat.hasPin(examList[i]) != Smart_Hat.pinVersion.NO_PIN) && 
                (uint(ge.getExamState(to,examList[i])) == uint(Gestione_Esami.examState.TO_DO))
                )
                revert("Hat not compatible with the exams situation of the buyer!");
        }

        hat.transferOwnership(to);
        //Chiamata a safeTransferFrom del contratto ERC721
        ERC721.safeTransferFrom(from,to,tokenId,data);
    }

    /***
    * @notice Funzione per il trasferimento vincolato di un cappellino dall'indirizzo 'from' all'indirizzo 'to'.
    *   Il trasferimento viene approvato solamente se 'to' ha superato tutti gli esami che sono presenti sul cappello
    *   con una spilla.
    * @param Indirizzo 'from' dell'attuale proprietario del cappellino
    * @param Indirizzo 'to' del potenziale acquirente del cappellino
    * @param Id del cappellino oggetto del trasferimento
    * @param Spazio per dati aggiuntivi
    */
    function transferToStudent(address from, address to, uint256 tokenId) internal {
        Gestione_Esami ge = Gestione_Esami(managerContract);

        //Recupera la situazione del potenziale acquirente
        string[] memory examList=ge.getExamList();

        //Recupera il contratto del cappello
        Smart_Hat hat = Smart_Hat(intToAddress(tokenId));

        //Verifica della conformità di versione del cappello (da laureato o standard)
        require(ge.isGraduated(to) == hat.isGraduatedVersion(), "Hat not compatible with the exams situation of the buyer!");

        //Verifica del superamento da parte di 'to' per gli esami che hanno spille apposte sul cappello
        for(uint i = 0; i<examList.length; i++){
            /*Se il cappello presenta una spilla di un esame non superato dal potenziale
                acquirente l'operazione viene annullata*/
            if( (hat.hasPin(examList[i]) != Smart_Hat.pinVersion.NO_PIN) && 
                (uint(ge.getExamState(to,examList[i])) == uint(Gestione_Esami.examState.TO_DO))
                )
                revert("Hat not compatible with the exams situation of the buyer!");
        }

        hat.transferOwnership(to);
        //Chiamata a safeTransferFrom del contratto ERC721
        ERC721.transferFrom(from,to,tokenId);
    }

    //-----Override delle funzioni previste dallo standard per il trasferimento dei token-----
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferToStudent(from,to,tokenId,"");
    }

     function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override {
        safeTransferToStudent(from,to,tokenId,data);
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        transferToStudent(from,to,tokenId);
    }

    //-----Funzioni per la gestione degli indirizzi-----
    function addressToInt(address index) internal pure returns(uint){
        return uint(uint160(index));
    }
    
    function intToAddress(uint index) internal pure returns (address){
        return address(uint160(index));
    }
}
