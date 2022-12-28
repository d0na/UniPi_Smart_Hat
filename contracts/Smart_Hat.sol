// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "hardhat/console.sol";

contract Smart_Hat is Ownable{
    //Riferimento al contratto utilizzato da UniPi per caricare gli esami superati e le lauree conseguite
    address managerContract;

    //Stato del cappellino
    enum exams_Situation{NO_EXAMS, NETWORK_STD, NETWORK_MERIT, CRYPTO_STD, CRYPTO_MERIT, NETWORK_STD_CRYPTO_STD, NETWORK_STD_CRYPTO_MERIT, NETWORK_MERIT_CRYPTO_STD, NETWORK_MERIT_CRYPTO_MERIT, OTHER_CONFIG}
    bool graduatedVersion=false;
    exams_Situation state=exams_Situation.NO_EXAMS;

    constructor() {
    }

    function setManager(address manager) public onlyOwner {
        require(manager == address(manager),"Invalid manager contract address");
        managerContract=manager;
    }

    function crea_cappellino() public onlyOwner returns (exams_Situation, bool) {
        //Otteniamo lo stato degli esami dell'indirizzo chiamante
        bytes4 selector=bytes4(keccak256("getSituation(address)"));
        console.log("Sono prima della encode");
        bytes memory data= abi.encodeWithSelector(selector,msg.sender);
        console.log("Sono dopo la encode");
        (bool success, bytes memory result)=managerContract.call(data);
        console.log("Dopo la chiamata");

        //Controllo esito chiamata
        require(success,"Call to exam manager contract failed!");
        console.log("Prima la decode");
        (uint[] memory results, bool graduated)=abi.decode(result,(uint[],bool));
        console.log("Dopo la decode");

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
        return(state,graduatedVersion);
    }
}
