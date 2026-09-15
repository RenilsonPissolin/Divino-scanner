// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import {Test} from "forge-std/Test.sol";
import {DivinoV18} from "../src/DivinoV18.sol";
import {UniversalHandlerV18} from "../src/handlers/UniversalHandlerV18.sol";
contract DivinoV18Test is Test {
    DivinoV18 public target;
    UniversalHandlerV18 public handler;
    function setUp() public {
        target = new DivinoV18();
        handler = new UniversalHandlerV18(address(target));
        vm.deal(address(0xBEEF), 10 ether);
        vm.prank(address(0xBEEF));
        target.deposit{value: 10 ether}();
        targetContract(address(handler));
    }
    function invariant_solvency() public view {
        if (address(handler).balance > handler.ghost_totalWithdrawn()) {
            // Handler recebeu mais do que ghost conta = reentrancia real
            if (address(target).balance < 10 ether + handler.ghost_totalDeposited() - handler.ghost_totalWithdrawn()) {
                assertTrue(false, "V18 FAIL - SELECTOR DESCOBERTO! Scanner universal pegou saqueSecreto_9x7z");
            }
        }
        // Solvencia basica
        assertGe(address(target).balance + handler.ghost_totalWithdrawn(), handler.ghost_totalDeposited() + 10 ether - 1 ether, "insolvente");
    }
}
