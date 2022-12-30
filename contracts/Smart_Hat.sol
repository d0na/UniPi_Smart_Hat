// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol";
import "hardhat/console.sol";

contract Smart_Hat is Ownable{
    using Strings for string; 

    //Costanti relative agli esami supportati dal sistema degli Smart_Hat
    string ComputerNetworks = "274AA";
    string constant Cryptography = "245AA";

    //Riferimento al contratto utilizzato da UniPi per caricare gli esami superati e le lauree conseguite
    address managerContract;

    //Stato del cappellino
    enum exams_Situation{NO_EXAMS, NETWORK_STD, NETWORK_MERIT, CRYPTO_STD, CRYPTO_MERIT, NETWORK_STD_CRYPTO_STD, NETWORK_STD_CRYPTO_MERIT, NETWORK_MERIT_CRYPTO_STD, NETWORK_MERIT_CRYPTO_MERIT, OTHER_CONFIG}
    bool public graduatedVersion=false;
    bool initialized=false;
    exams_Situation public state=exams_Situation.NO_EXAMS;

    //-----Construttore e funzione per la gestione dell'indirizzo del contratto manager degli esami
    constructor(address manager){
        require(manager == address(manager),"Invalid manager contract address");
        managerContract=manager;
    }

    function setManager(address manager) public onlyOwner {
        require(manager == address(manager),"Invalid manager contract address");
        managerContract=manager;
    }

    //-----Gestione degli stati del cappellino-----

    /***
    * @notice Crea il cappellino considerando anche dagli esami già sostenuti dall'utente.
    *   Solo il creatore del cappellino può chiamare questa funzione.
    * @return La situazione degli esami finora sostenuti ed un booleano che indica se 
    *   lo studente è laureato.
    ***/
    function crea_cappellino() public onlyOwner returns (exams_Situation, bool) {
        require(!initialized,"Hat already initialized");
        //Ottengo lo stato degli esami dell'indirizzo chiamante
        bytes4 selector=bytes4(keccak256("getSituation(address)"));
        bytes memory data= abi.encodeWithSelector(selector,msg.sender);
        (bool success, bytes memory result)=managerContract.call(data);

        //Controllo esito chiamata
        require(success,"Call to exam manager contract failed!");
        (uint[] memory results, bool graduated)=abi.decode(result,(uint[],bool));

        //Ottenimento dello stato del cappellino per l'indirizzo chiamante
        if(results.length!=2){
            state=exams_Situation.OTHER_CONFIG;
        }else{
            if(results[0]==0){
                if(results[1]==1){
                    state=exams_Situation.CRYPTO_STD;
                }else{
                    if(results[1]==2){
                        state=exams_Situation.CRYPTO_MERIT;
                    }else{
                        state=exams_Situation.NO_EXAMS;
                    }
                }
            }
            if(results[0]==1){
                if(results[1]==0){
                    state=exams_Situation.NETWORK_STD;
                }else{
                    if(results[1]==1){
                        state=exams_Situation.NETWORK_STD_CRYPTO_STD;
                    }else{
                        state=exams_Situation.NETWORK_STD_CRYPTO_MERIT;
                    }
                }
            }
            if(results[0]==2){
                if(results[1]==0){
                    state=exams_Situation.NETWORK_MERIT;
                }else{
                    if(results[1]==1){
                        state=exams_Situation.NETWORK_MERIT_CRYPTO_STD;
                    }else{
                        state=exams_Situation.NETWORK_MERIT_CRYPTO_MERIT;
                    }
                }
            }
        }
        graduatedVersion=graduated;
        initialized=true;
        return(state,graduatedVersion);
    }

    /***
    * @notice La funzione aggiunge al cappello una spilla relativa ad un esame superato senza lode. 
    *   Solo il creatore del cappellino può chiamare questa funzione.
    * @param Una stringa che rappresenta il codice dell'esame di cui vogliamo aggiungere la spilla.
    * @return Restituisce il nuovo stato raggiunto dal cappellino
    ***/
    function aggiungi_spilla_argentata(string memory exam_code) public onlyOwner returns(exams_Situation){
        //Controllo cappello inizializzato
        require(initialized,"Hat not initialized");

        //Controllo cappello laureato
        require(!graduatedVersion,"Graduated version of the hat cannot be edited");

        //Controllo spilla già inserita
        if(equal(exam_code, ComputerNetworks)){
            bool already_put=(uint(state)==uint(exams_Situation.CRYPTO_MERIT)) || (uint(state)==uint(exams_Situation.CRYPTO_STD)) || (uint(state)==uint(exams_Situation.NO_EXAMS)) || (uint(state)==uint(exams_Situation.OTHER_CONFIG));
            require(already_put,"Pin already put for this exam!");
        }
        if(equal(exam_code, Cryptography)){
            bool already_put=(uint(state)==uint(exams_Situation.NETWORK_MERIT)) || (uint(state)==uint(exams_Situation.NETWORK_STD)) || (uint(state)==uint(exams_Situation.NO_EXAMS)) || (uint(state)==uint(exams_Situation.OTHER_CONFIG));
            require(already_put,"Pin already put for this exam!");
        }

        //Otteniamo lo stato degli esami dell'indirizzo chiamante
        bytes4 selector=bytes4(keccak256("getExamState(address,string)"));
        bytes memory data= abi.encodeWithSelector(selector, msg.sender, exam_code);
        (bool success, bytes memory result)=managerContract.call(data);

        //Controllo esito chiamata
         require(success,"Call to exam manager contract failed!");
        (uint examState)=abi.decode(result,(uint));

        //Controllo valutazione esame
        if(examState==0)    
            revert("Exam not passed");
        if(examState==2)
            revert("Exam passed with merit");

        //Passaggio al nuovo stato
        if(equal(exam_code, ComputerNetworks)){
            if(state==exams_Situation.CRYPTO_MERIT){
                state=exams_Situation.NETWORK_STD_CRYPTO_MERIT;
            }else{
                if(state==exams_Situation.CRYPTO_STD){
                    state=exams_Situation.NETWORK_STD_CRYPTO_STD;
                }else{
                    if(state==exams_Situation.NO_EXAMS){
                        state=exams_Situation.NETWORK_STD;
                    }
                    //Se il cappello presenta una configurazione di esami diversa dallo standard non far niente
                }
            }   
        }

        if(equal(exam_code, Cryptography)){
            if(state==exams_Situation.NETWORK_MERIT){
                state=exams_Situation.NETWORK_MERIT_CRYPTO_STD;
            }else{
                if(state==exams_Situation.NETWORK_STD){
                    state=exams_Situation.NETWORK_STD_CRYPTO_STD;
                }else{
                    if(state==exams_Situation.NO_EXAMS){
                        state=exams_Situation.CRYPTO_STD;
                    }
                    //Se il cappello presenta una configurazione di esami diversa dallo standard non far niente
                }
            }   
        }

        //Restituisce lo stato raggiunto dopo la chiamata
        return (state);
    }

    /***
    * @notice La funzione aggiunge al cappello una spilla relativa ad un esame superato con lode. 
    *   Solo il creatore del cappellino può chiamare questa funzione.
    * @param Una stringa che rappresenta il codice dell'esame di cui vogliamo aggiungere la spilla.
    * @return Restituisce il nuovo stato raggiunto dal cappellino
    ***/
    function aggiungi_spilla_dorata(string memory exam_code) public onlyOwner returns(exams_Situation){
        //Controllo cappello inizializzato
        require(initialized,"Hat not initialized");

        //Controllo cappello laureato
        require(!graduatedVersion,"Graduated version of the hat cannot be edited");
        
        //Controllo spilla già inserita
        if(equal(exam_code,ComputerNetworks)){
            bool already_put=(uint(state)==uint(exams_Situation.CRYPTO_MERIT)) || (uint(state)==uint(exams_Situation.CRYPTO_STD)) || (uint(state)==uint(exams_Situation.NO_EXAMS)) || (uint(state)==uint(exams_Situation.OTHER_CONFIG));
            require(already_put,"Pin already put for this exam!");
        }
        if(equal(exam_code,Cryptography)){
            bool already_put=(uint(state)==uint(exams_Situation.NETWORK_MERIT)) || (uint(state)==uint(exams_Situation.NETWORK_STD)) || (uint(state)==uint(exams_Situation.NO_EXAMS)) || (uint(state)==uint(exams_Situation.OTHER_CONFIG));
            require(already_put,"Pin already put for this exam!");
        }

        //Otteniamo lo stato degli esami dell'indirizzo chiamante
        bytes4 selector=bytes4(keccak256("getExamState(address,string)"));
        bytes memory data= abi.encodeWithSelector(selector, msg.sender, exam_code);
        (bool success, bytes memory result)=managerContract.call(data);

        //Controllo esito chiamata
         require(success,"Call to exam manager contract failed!");
        (uint examState)=abi.decode(result,(uint));

        //Controllo valutazione esame
        if(examState==0)    
            revert("Exam not passed");
        if(examState==1)
            revert("Exam passed without merit");

        //Passaggio al nuovo stato
        if(equal(exam_code,ComputerNetworks)){
            if(state==exams_Situation.CRYPTO_MERIT){
                state=exams_Situation.NETWORK_MERIT_CRYPTO_MERIT;
            }else{
                if(state==exams_Situation.CRYPTO_STD){
                    state=exams_Situation.NETWORK_MERIT_CRYPTO_STD;
                }else{
                    if(state==exams_Situation.NO_EXAMS){
                        state=exams_Situation.NETWORK_MERIT;
                    }
                    //Se il cappello presenta una configurazione di esami diversa dallo standard non far niente
                }
            }   
        }

        if(equal(exam_code, Cryptography)){
            if(state==exams_Situation.NETWORK_MERIT){
                state=exams_Situation.NETWORK_MERIT_CRYPTO_MERIT;
            }else{
                if(state==exams_Situation.NETWORK_STD){
                    state=exams_Situation.NETWORK_STD_CRYPTO_MERIT;
                }else{
                    if(state==exams_Situation.NO_EXAMS){
                        state=exams_Situation.CRYPTO_MERIT;
                    }
                    //Se il cappello presenta una configurazione di esami diversa dallo standard non far niente
                }
            }   
        }

        //Restituisce lo stato raggiunto dopo la chiamata
        return (state);
    }

    /***
    * @notice La funzione cambia lo stato del cappello ordinario in cappello da laureato, il quale
    *   manterrà tutte le spille aggiunte in precedenza. Solo il creatore del cappellino può chiamare
    *   questa funzione.
    ***/
    function cambia_aspetto_cappello_da_laureato() public onlyOwner{
        //Controllo inizializzazione
        require(initialized,"Hat not initialized");

        //Controllo aspetto
        require(!graduatedVersion,"Graduated hat already obtained");

        //Otteniamo lo stato degli esami dell'indirizzo chiamante
        bytes4 selector=bytes4(keccak256("isGraduated(address)"));
        bytes memory data= abi.encodeWithSelector(selector,msg.sender);
        (bool success, bytes memory result)=managerContract.call(data);

        //Controllo esito chiamata
         require(success,"Call to exam manager contract failed!");
        (bool graduated)=abi.decode(result,(bool));

        //Controllo conseguimento laurea
        require(graduated,"You are not graduated");
        graduatedVersion=true;
    }

    //-----Funzioni per ottenimento del modello 3D del cappello-----
    /***
    * @notice La funzione permette l'ottenimento dell'URL IPFS al modello tridimensionale del cappellino
    *   corrispondente allo stato corrente.
    */
    function get3DModel() public view returns(string memory){
        string memory uri;
        if(!graduatedVersion){
            uri=string(abi.encodePacked("https://ipfs.io/ipfs/QmRwUk7emCH91aaNd9DZR4WE1dsQsynzsyzVnYXvqC4zdU/",Strings.toString(uint(state)),".glb"));
        }else{
            //Il cappello da laureato può trovarsi in un numero minore di stati rispetto al cappellino ordinario
            require((uint(state)>=uint(exams_Situation.NETWORK_STD_CRYPTO_STD)||(uint(state)<uint(exams_Situation.OTHER_CONFIG))),"Invalid state");
            uri=string(abi.encodePacked("https://ipfs.io/ipfs/QmYbV9sAiTmg7i9bjYzUMUvN2zoWTVS2LG4HLDcUn51XAy",Strings.toString(uint(state)),".glb")); 
        }
        return uri;
    }

    //-----Funzioni di utilità-----
    /***
     * @dev Funzione che verifica se due stringhe sono uguali
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}
