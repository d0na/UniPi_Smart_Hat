// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol";
import "hardhat/console.sol";
import "./Gestione_Esami";

contract Smart_Hat is Ownable{
    using Strings for string; 

    //Costanti relative agli esami supportati dal sistema degli Smart_Hat
    string ComputerNetworks = "274AA";
    string constant Cryptography = "245AA";
    string[] supportedExams;

    //Riferimento al contratto utilizzato da UniPi per caricare gli esami superati e le lauree conseguite
    address managerContract;

    //Stato del cappellino
    mapping(string => pinVersion) state;
    enum pinVersion{NO_PIN, SILVER_PIN, GOLDEN_PIN}

    bool public graduatedVersion=false;
    bool initialized=false;
    bool unsupportedConfiguration=false; //configurazione di esami non supportata dal sistema di spille

    //-----Construttore e funzione per la gestione dell'indirizzo del contratto manager degli esami
    constructor(address manager){
        require(manager == address(manager),"Invalid manager contract address");
        managerContract = manager;
        supportedExams.push(ComputerNetworks);
        supportedExams.push(Cryptography);
    }

    function setManager(address manager) public onlyOwner {
        require(manager == address(manager),"Invalid manager contract address");
        managerContract = manager;
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
        Gestione_Esami ge = Gestione_Esami(managerContract);
        (uint[] results, bool graduated) = ge.getSituation(msg.sender);
        string[] examList = ge.getExamList();

        //Ottenimento dello stato del cappellino per l'indirizzo chiamante    
        if(results.length>supportedExams.length){ 
            /*Se l'array di risultati ha una lunghezza maggiore dell'array degli esami previsti 
            sicuramente vi saranno esami non supportati*/
            unsupportedConfiguration = true;
        }else{
            //Esame dei risultati finora conseguiti
            for(uint i=0;i<results.length;i++){
                //Caso di un esame superato
                if(results[i]!=0){
                    if(isSupported(examList[i])){ //Caso esame superato e con spilla disponibile
                        //Assegnazione spilla corretta
                        if(results[i]==1)
                            state[examList[i]] = SILVER_PIN;
                        else
                            state[examList[i]] = GOLDEN_PIN;
                    }else{  //Caso esame superato ma spilla NON disponibile
                        unsupportedConfiguration=true;
                    }
                }
            }
        }
        graduatedVersion = graduated;
        initialized = true;
        return(state,graduatedVersion);
    }

    /***
    * @notice La funzione aggiunge al cappello una spilla relativa ad un esame superato senza lode. 
    *   Solo il creatore del cappellino può chiamare questa funzione.
    * @param Una stringa che rappresenta il codice dell'esame di cui vogliamo aggiungere la spilla.
    * @return Restituisce un booleano che indica se vi è un modello 3D disponibile per tale configurazione di esami.
    ***/
    function aggiungi_spilla_argentata(string memory exam_code) public onlyOwner returns (bool ModelAvailable){
        //Controllo cappello inizializzato
        require(initialized, "Hat not initialized");

        //Controllo cappello laureato
        require(!graduatedVersion, "Graduated version of the hat cannot be edited");

        //Controllo spilla già inserita
        require(state[examCode]==NO_PIN, "Pin already put for this exam!");

        //Otteniamo lo stato degli esami dell'indirizzo chiamante
        Gestione_Esami ge = Gestione_Esami(managerContract);
        uint examState = ge.getExamState(msg.sender, exam_code);

        //Controllo valutazione esame
        if(examState==0)    
            revert("Exam not passed");
        if(examState==2)
            revert("Exam passed with merit");

        //Passaggio al nuovo stato
        if(!supportedExams(exam_code))
            unsupportedConfiguration = true;
        state[exam_code] = SILVER_PIN;
    

        //Restituisce lo stato raggiunto dopo la chiamata
        return (!unsupportedConfiguration);
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
        require(state[examCode]==NO_PIN, "Pin already put for this exam!");

        //Otteniamo lo stato degli esami dell'indirizzo chiamante
        Gestione_Esami ge = Gestione_Esami(managerContract);
        uint examState = ge.getExamState(msg.sender, exam_code);

        //Controllo valutazione esame
        if(examState==0)    
            revert("Exam not passed");
        if(examState==1)
            revert("Exam passed without merit");

        //Passaggio al nuovo stato
        if(!supportedExams(exam_code))
            unsupportedConfiguration = true;
        state[exam_code] = GOLDEN_PIN;

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

        //Verifico lo status di laureato dell'indirizzo chiamante
        Gestione_Esami ge = Gestione_Esami(managerContract);
        bool graduated = ge.isGraduated(msg.sender); 

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
        //TODO: DA SISTEMARE CON IL NUOVO SISTEMA DI STATI!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        string memory uri;
        if(!graduatedVersion){
            uri=string(abi.encodePacked("https://ipfs.io/ipfs/QmRwUk7emCH91aaNd9DZR4WE1dsQsynzsyzVnYXvqC4zdU/",Strings.toString(uint(state)),".glb"));
        }else{
            //Il cappello da laureato può trovarsi in un numero minore di stati rispetto al cappellino ordinario
            require((uint(state)>=uint(exams_Situation.NETWORK_STD_CRYPTO_STD)||(uint(state)<uint(exams_Situation.OTHER_CONFIG))),"Invalid state");
            uri=string(abi.encodePacked("https://ipfs.io/ipfs/Qmdt5oYDmLuVm4WXxtVU861SGpWzfzDbnLS6D1CqAVUfVu",Strings.toString(uint(state)),".glb")); 
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

    /***
    * @notice Funzione che verifica se il codice esame verificato è uno di quelli supportati dal contratto
    */
    function isSupported(string memory to_test) internal returns (bool){
        for(uint i=0;i<supportedExams.length;i++){
            if(equal(supportedExams[i],to_test))
                return true;
        }
        return false;
    }
}
