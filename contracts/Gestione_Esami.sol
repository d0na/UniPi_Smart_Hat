// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Gestione_Esami {

    enum examState{TO_DO, PASSED, PASSED_WITH_MERIT}

    //Exams state
    examState RetiDiCalcolatori=examState.PASSED;
    examState Crittografia=examState.TO_DO;
    bool public graduated=false;

    constructor() {
    }

    function getExamsState(address who) public view returns (examState _exam1,examState _exam2) {
        if(who == address(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4)){
            _exam1=examState.PASSED;
            _exam2=examState.TO_DO;
        }else{
           _exam1=RetiDiCalcolatori;
            _exam2=Crittografia; 
        }
        
    }
}
