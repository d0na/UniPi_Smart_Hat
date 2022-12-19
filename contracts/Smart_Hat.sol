// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./Gestione_Esami.sol";

contract Smart_Hat {
    Gestione_Esami private manager;
    enum examState{TO_DO, PASSED, PASSED_WITH_MERIT} 

    constructor() {
        manager = new Gestione_Esami();
    }

    function crea_cappellino() public {
        (examState _e1,examState _e2)=manager.getExamsState(msg.sender);
    }

    function aggiungi_spilla() public {
    }
}
