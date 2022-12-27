// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "hardhat/console.sol";

contract Gestione_Esami is Ownable {

    enum examState{TO_DO, PASSED, PASSED_WITH_MERIT}
   
    /*  (Codice esame => (indirizzo studente => stato esame))
        Per ogni esame la mappa contiene il relativo stato per ogni studente*/
    mapping(string => mapping(address => examState)) exams;
    mapping(address => bool) graduated;
    string[] planned_exams;
    constructor() {
        planned_exams.push("274AA");
        planned_exams.push("245AA");
    }

    //-----Funzioni per la gestione ed il controllo del superamento degli esami-----
    function getExamState(address who,string memory examCode) public view returns (examState) {
        //Controllo codice esame
        require(checkExamCode(examCode),"Unknown exam code");

        return exams[examCode][who];
    }

    function addExamResult(address who, string memory examCode, examState assestment) public onlyOwner {
        //Controllo valutazioni
        require(uint(assestment)!=uint(examState.TO_DO),"Not allowed to delete an evaluation");
        require(uint(assestment)<=2,"Unknown assestment");
        //Controllo codice esame
        require(checkExamCode(examCode),"Unknown exam code");
        //Controllo se lo studente ha già passato l'esame (no modifiche di voto)
        require(exams[examCode][who]==examState.TO_DO,"The student has already passed this exam");

        exams[examCode][who]=assestment;
    }

    function getMyExamState(string memory examCode) public view returns (examState){
        return getExamState(msg.sender, examCode);
    }
    
    function getMySituation() public view returns (examState[] memory, bool){
        return getSituation(msg.sender);
    }

    function getSituation(address who) public view onlyOwner returns (examState[] memory, bool){
        examState[] memory results = new examState[](planned_exams.length);
        for(uint i=0;i<planned_exams.length;i++){
            results[i]=exams[planned_exams[i]][who];
        }
        bool _graduated=isGraduated(who);
        return (results,_graduated);
    }
    
    //-----Funzioni per la gestione ed il controllo delle lauree-----
    function publishGraduation(address who) public onlyOwner {
        require(!graduated[who],"The student is already graduated");
        for(uint i=0;i<planned_exams.length;i++){
            if(exams[planned_exams[i]][who]==examState.TO_DO)
                revert("The student has not passed all the exams required for the degree");
        }
        graduated[who]=true;
    }

    function isGraduated(address who) public view returns (bool){
        return graduated[who];
    }

    //-----Gestione degli esami previsti per la laurea-----
    function getExamList() public view returns (string[] memory){
        return planned_exams;
    }

    function addExam(string memory examCode) public onlyOwner{
        require(!checkExamCode(examCode),"Exam already added");
        planned_exams.push(examCode);
    }

    function checkExamCode(string memory examCode) internal view returns (bool){
        for(uint i=0;i<planned_exams.length;i++){
            if(keccak256(abi.encodePacked(planned_exams[i])) == keccak256(abi.encodePacked(examCode))){
                return true;
            } 
        }
        return false;
    }
}
