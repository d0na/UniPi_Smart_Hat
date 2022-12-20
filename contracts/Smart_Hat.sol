// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./Gestione_Esami.sol";

contract Smart_Hat {
    Gestione_Esami private manager;

    constructor() {
        manager = new Gestione_Esami();
    }

    function crea_cappellino() public view returns(Gestione_Esami.examState _e1, Gestione_Esami.examState _e2) {
        (_e1, _e2)=manager.getExamsState(msg.sender);
    }

    function aggiungi_spilla() public {
    }
}
