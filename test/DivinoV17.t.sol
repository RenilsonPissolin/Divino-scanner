// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import {Test} from "forge-std/Test.sol";
import {DivinoV17} from "../src/DivinoV17.sol";
import {UniversalHandler} from "../src/handlers/UniversalHandler.sol";

contract DivinoV17Test is Test {
    DivinoV17 public target;
    UniversalHandler public handler;
    function setUp() public {
        target = new DivinoV17();
        handler = new UniversalHandler(address(target));
        vm.deal(address(0xBEEF), 10 ether);
        vm.prank(address(0xBEEF));
        target.deposit{value: 10 ether}();
        targetContract(address(handler));
    }
    function invariant_solvency() public {
        if (address(handler).balance > handler.ghost_totalWithdrawn() + 0.5 ether) {
            assertTrue(false, "V17 FAIL - GENERIC REENTRANCY! Roubou com nome diferente");
        }
        assertGe(address(target).balance, 1 ether, "Vault drenado");
    }
}
