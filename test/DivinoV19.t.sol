// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import {Test} from "forge-std/Test.sol";
import {DivinoV19} from "../src/DivinoV19.sol";
import {CrossHandlerV19} from "../src/handlers/CrossHandlerV19.sol";
contract DivinoV19Test is Test {
    DivinoV19 target;
    CrossHandlerV19 handler;
    function setUp() public {
        target = new DivinoV19();
        handler = new CrossHandlerV19(address(target));
        vm.deal(address(0xBEEF), 10 ether);
        vm.prank(address(0xBEEF));
        target.deposit{value: 10 ether}();
        targetContract(address(handler));
    }
    function invariant_solvency() public view {
        if (address(handler).balance > handler.ghost_withdrawn()) {
            if (address(target).balance < 10 ether + handler.ghost_deposited() - handler.ghost_withdrawn()) {
                assertTrue(false, "V19 FAIL - CROSS-FUNCTION! deposit() resetou lock do withdraw()");
            }
        }
    }
}
