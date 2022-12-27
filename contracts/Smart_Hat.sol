// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "hardhat/console.sol";

contract Smart_Hat is Ownable{
    //Riferimento al contratto utilizzato da UniPi per caricare gli esami superati e le lauree conseguite
    address managerContract;

    //Stato del cappellino
    enum hat_State{NO_EXAMS, NETWORK_MERIT_CRYPTO_MERIT, NETWORK_MERIT_CRYPTO_STD,NETWORK_STD_CRYPTO_MERIT,NETWORK_STD_CRYPTO_STD,OTHER_CONFIG}
    hat_State state;

    constructor() {
    }

    function setManager(address manager) public onlyOwner {
        require(manager == address(manager),"Invalid manager contract address");
        managerContract=manager;
    }

    function crea_cappellino() public onlyOwner returns (uint[] memory, bool) {
        //Otteniamo lo stato degli esami dell'indirizzo chiamante
        bytes4 selector=bytes4(keccak256("getSituation(address)"));
        bytes memory data= abi.encodeWithSelector(selector,msg.sender);
        (bool success, bytes memory result)=managerContract.call(data);
        
        //Controllo esito chiamata
        require(success,"Call to exam manager contract failed!");
        (uint[] memory results, bool graduated)=abi.decode(result,(uint[],bool));

        //Ottenimento dello stato del cappellino per l'indirizzo chiamante
        //TODO
        return(results,graduated);
    }
}
