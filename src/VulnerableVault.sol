// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// CONTRATO PROPOSITALMENTE VULNERAVEL PARA TESTAR O SCANNER V6.2
contract VulnerableVault {
    mapping(address => uint256) public balances;
    address public owner;
    bool public paused;

    constructor() { owner = msg.sender; }

    // VULNERABILIDADE 1: Reentrancy + VIOLACAO CEI
    // Muda o estado DEPOIS do.call - classico DAO hack
    function withdraw() public {
        uint256 amount = balances[msg.sender];
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success);
        balances[msg.sender] -= amount; // <- CEI VIOLATION: depois do call!
    }

    // VULNERABILIDADE 2: Missing Access Control - funcao critica sem protecao
    function pause() public {
        paused = true;
    }

    // VULNERABILIDADE 3: mint sem onlyOwner
    function mint(address to, uint256 amount) public {
        balances[to] += amount;
    }

    // VULNERABILIDADE 4: setFee sem protecao + unchecked
    function setFee(uint256 newFee) public {
        unchecked {
            uint256 x = newFee + 1;
        }
    }

    // COMENTARIO QUE NAO DEVE SER DETECTADO: //.call aqui é só comentario
    /*
       Isso é um bloco de documentação mencionando.call
       mas não é vulnerabilidade real
    */

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }
}
