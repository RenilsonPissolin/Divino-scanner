// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import {Test} from "forge-std/Test.sol";
import {DivinoV15} from "../src/DivinoV15.sol";
import {UniversalHandler} from "../src/handlers/UniversalHandler.sol";

contract DivinoV16 is Test {
    DivinoV15 public target;
    UniversalHandler public handler;

    function setUp() public {
        target = new DivinoV15();
        handler = new UniversalHandler(address(target));
        // Vítima deixa 10 ETH no contrato
        vm.deal(address(0xBEEF), 10 ether);
        vm.prank(address(0xBEEF));
        target.deposit{value: 10 ether}();
        targetContract(address(handler));
    }

    function invariant_solvency() public {
        // Se houver reentrancy, o handler vai ter mais ETH do que o ghost contabilizou
        // Ex: ghost_withdrawn = 1 ETH, mas handler.balance = 2 ETH (roubou 1 da vítima)
        if (address(handler).balance > handler.ghost_totalWithdrawn() + 0.5 ether) {
            // Força o fail com mensagem clara
            assertTrue(false, "V16 FAIL - REENTRANCY DETECTADA! Handler roubou da vitima");
        }
        // E o contrato vítima foi drenado
        assertGe(address(target).balance, 1 ether, "Vault drenado");
    }
}
