// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "hardhat/console.sol";
import "./Gestione_Esami.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Smart_Hat is Ownable{
    using Strings for string; 

    //Costanti relative agli esami supportati dal sistema degli Smart_Hat
    string constant ComputerNetworks = "274AA";
    string constant Cryptography = "245AA";
    string[] supportedExams;

    //Costanti relative all'hash ipfs delle cartelle contenenti i modelli
    string constant StandardHat = "QmfHYFuzPLNvrGJ76xUY7y1fS9Z5wqAxNCAz5J5jsA522A";
    string constant GraduatedHat = "QmV3E1VUg9tUymRuoR7Couf8VwHtrasFFwE24B2DS75T2F";

    //Riferimento al contratto utilizzato da UniPi per caricare gli esami superati e le lauree conseguite
    address public examsManager;
    address public collectionContract;

    //Stato del cappellino
    mapping(string => pinVersion) state;
    uint numberOfPins = 0;
    bool graduatedVersion = false;
    enum pinVersion{NO_PIN, SILVER_PIN, GOLDEN_PIN}

    bool public initialized=false;
    //bool unsupportedConfiguration=false; //configurazione di esami non supportata dal sistema di spille

    //-----Construttore e funzione per la gestione dell'indirizzo del contratto manager degli esami
    constructor(address manager, address collection){
        require(manager == address(manager),"Invalid exams manager contract address");
        require(collection == address(collection),"Invalid collection contract address");
        examsManager = manager;
        collectionContract = collectionContract;
        supportedExams.push(ComputerNetworks);
        supportedExams.push(Cryptography);
    }

    //-----Gestione degli stati del cappellino-----

    /***
    * @notice Crea il cappellino considerando anche dagli esami già sostenuti dall'utente.
    *   Solo il creatore del cappellino può chiamare questa funzione.
    * @return Il numero di spille applicate al cappello ed un booleano che indica se il cappello
    *   è in versione da laureato.
    ***/
    function crea_cappellino() public onlyOwner returns (uint pinsNum, bool) {
        require(!initialized, "Hat already initialized");

        //Ottengo lo stato degli esami dell'indirizzo chiamante
        Gestione_Esami ge = Gestione_Esami(examsManager);
        (Gestione_Esami.examState[] memory results, bool graduated) = ge.getSituation(msg.sender);
        string[] memory examList = ge.getExamList();

        //Controllo dei risultati finora conseguiti
        for(uint i=0; i<results.length; i++){
            //Caso di un esame superato
            if(results[i] != Gestione_Esami.examState.TO_DO){
                //Caso esame superato e con spilla disponibile
                if(isSupported(examList[i])){ 
                    numberOfPins++;
                    //Assegnazione spilla corretta
                    if(results[i] == Gestione_Esami.examState.PASSED)
                        state[examList[i]] = pinVersion.SILVER_PIN;
                    else
                        state[examList[i]] = pinVersion.GOLDEN_PIN;
                }
            }
        }
        graduatedVersion = graduated;
        initialized = true;
        return(numberOfPins,graduatedVersion);
    }

    /***
    * @notice La funzione aggiunge al cappello una spilla relativa ad un esame superato senza lode. 
    *   Solo il creatore del cappellino può chiamare questa funzione.
    * @param Una stringa che rappresenta il codice dell'esame di cui vogliamo aggiungere la spilla.
    ***/
    function aggiungi_spilla_argentata(string memory exam_code) public onlyOwner{
        //Controllo cappello inizializzato
        require(initialized, "Hat not initialized");

        //Controllo cappello laureato
        require(!graduatedVersion, "Graduated version of the hat cannot be edited");

        //Controllo spilla già inserita
        require(state[exam_code] == pinVersion.NO_PIN, "Pin already put for this exam!");

        //Otteniamo lo stato degli esami dell'indirizzo chiamante
        Gestione_Esami ge = Gestione_Esami(examsManager);
        Gestione_Esami.examState examState = ge.getExamState(msg.sender, exam_code);

        //Controllo valutazione esame
        if(examState == Gestione_Esami.examState.TO_DO)    
            revert("Exam not passed");
        if(examState == Gestione_Esami.examState.PASSED_WITH_MERIT)
            revert("Exam passed with merit");

        //Controllo disponibilità della spilla
        require(isSupported(exam_code),"Pin not available for this exam!");

        state[exam_code] = pinVersion.SILVER_PIN;
        numberOfPins++;
    }

    /***
    * @notice La funzione aggiunge al cappello una spilla relativa ad un esame superato con lode. 
    *   Solo il creatore del cappellino può chiamare questa funzione.
    * @param Una stringa che rappresenta il codice dell'esame di cui vogliamo aggiungere la spilla.
    ***/
    function aggiungi_spilla_dorata(string memory exam_code) public onlyOwner{
        //Controllo cappello inizializzato
        require(initialized, "Hat not initialized");

        //Controllo cappello laureato
        require(!graduatedVersion, "Graduated version of the hat cannot be edited");
        
        //Controllo spilla già inserita
        require(state[exam_code]==pinVersion.NO_PIN, "Pin already put for this exam!");

        //Otteniamo lo stato degli esami dell'indirizzo chiamante
        Gestione_Esami ge = Gestione_Esami(examsManager);
        Gestione_Esami.examState examState = ge.getExamState(msg.sender, exam_code);

        //Controllo valutazione esame
        if(examState == Gestione_Esami.examState.TO_DO)    
            revert("Exam not passed");
        if(examState == Gestione_Esami.examState.PASSED)
            revert("Exam passed without merit");

        //Controllo disponibilità della spilla
        require(isSupported(exam_code),"Pin not available for this exam!");

        state[exam_code] = pinVersion.GOLDEN_PIN;
        numberOfPins++;
    }

    /***
    * @notice La funzione cambia lo stato del cappello ordinario in cappello da laureato, il quale
    *   manterrà tutte le spille aggiunte in precedenza. Solo il creatore del cappellino può chiamare
    *   questa funzione.
    ***/
    function cambia_aspetto_cappello_da_laureato() public onlyOwner{
        //Controllo inizializzazione
        require(initialized, "Hat not initialized");

        //Controllo aspetto
        require(!graduatedVersion, "Graduated hat already obtained");

        //Verifico lo status di laureato dell'indirizzo chiamante
        Gestione_Esami ge = Gestione_Esami(examsManager);
        bool graduated = ge.isGraduated(msg.sender); 

        //Controllo conseguimento laurea
        require(graduated, "You are not graduated");
        graduatedVersion = true;
    }

    //-----Funzioni per ottenimento del modello 3D del cappello-----
    /***
    * @notice La funzione permette l'ottenimento dell'URL IPFS al modello tridimensionale del cappellino
    *   corrispondente allo stato corrente.
    */
    function get3DModel() public view returns(string memory){
        require(initialized, "Hat not initialized");
        
        //Determinazione del nome del file del modello tridimensionale
        string memory Filename = "";
        if(numberOfPins == 0){
            Filename = "0";
        }else{
            for(uint i=0; i<supportedExams.length; i++){
                Filename = string(abi.encodePacked(Filename,Strings.toString(uint(state[supportedExams[i]]))));
            }
        }
        Filename = string(abi.encodePacked(Filename,".glb"));
        
        //Determinazione della cartella IPFS nella quale ricercare il modello individuato
        string memory completeURL;
        if(graduatedVersion)
            completeURL = string(abi.encodePacked("ipfs.io/ifps/",GraduatedHat,"?filename=",Filename));
        else
            completeURL = string(abi.encodePacked("ipfs.io/ifps/",StandardHat,"?filename=",Filename));
        return completeURL;
    }

    //-----Funzioni getter-----
    function isGraduatedVersion() public view returns (bool){
        require(initialized, "Hat not initialized");
        return graduatedVersion;
    }

    function getNumberOfPins() public view returns (uint){
        require(initialized, "Hat not initialized");
        return numberOfPins;
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
    function isSupported(string memory to_test) internal view returns (bool){
        for(uint i=0; i<supportedExams.length; i++){
            if(equal(supportedExams[i],to_test))
                return true;
        }
        return false;
    }
}
