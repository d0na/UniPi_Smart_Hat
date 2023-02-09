// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "hardhat/console.sol";
import "./Smart_Hat.sol";

contract Conference_Hall_Door {
    /***
    * @notice Controllo delle condizioni di accesso alla sala seminari.
    * @param L'indirizzo del cappello che l'utente indossa all'ingresso della sala.
    * @return Restituisce true se lo studente ha accesso al seminario, ovvero se
    * il cappello è di sua proprietà ed è in versione da laureato.
    ***/
    function checkAccess(address hatAddress) public view returns (bool){
        Smart_Hat hat = Smart_Hat(hatAddress);
        
        if((hat.currentOwner()==msg.sender) && (hat.isGraduatedVersion())){
            return true;
        }else{
            return false;
        }
    }
}
