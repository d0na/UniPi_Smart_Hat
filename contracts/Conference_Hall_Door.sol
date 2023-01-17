// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "hardhat/console.sol";
import "./Smart_Hat.sol";

contract Conference_Hall_Door {

    /***
    * @notice The function checks the access conditions of the caller user.
    * @return Returns true if the callers has the access to the seminar reserved
    *    for graduated students.
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
