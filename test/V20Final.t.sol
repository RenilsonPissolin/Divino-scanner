// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "forge-std/Test.sol";
import "../src/V20_ReadOnlyReentrancy.sol";
import "../src/V20_Secure.sol";
import "../src/DivinoScannerV20.sol";

contract V20Final is Test {
    function testScannerDetects() public {
        V20_ReadOnlyReentrancy vuln = new V20_ReadOnlyReentrancy();
        V20_Secure safe = new V20_Secure();
        DivinoScannerV20 scanner = new DivinoScannerV20();
        
        vm.deal(address(vuln), 20 ether);
        vm.deal(address(safe), 20 ether);
        // Simula LP
        vm.deal(address(this), 10 ether);
        
        bool isVulnVulnerable = scanner.scanReadOnly(address(vuln));
        bool isSafeVulnerable = scanner.scanReadOnly(address(safe));
        
        console.log("Vulneravel detectado como vulneravel?", isVulnVulnerable);
        console.log("Seguro detectado como vulneravel?", isSafeVulnerable);
        
        assertTrue(isVulnVulnerable, "Scanner deveria detectar V20");
        assertFalse(isSafeVulnerable, "Scanner nao deveria acusar seguro");
    }
}
