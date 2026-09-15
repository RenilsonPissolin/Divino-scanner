// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "forge-std/Test.sol";
import "../src/V20_ReadOnlyReentrancy.sol";
import "../src/V20_Secure.sol";
import "../src/DivinoScannerV20.sol";

contract V20Final is Test {
    V20_ReadOnlyReentrancy vuln;
    V20_Secure safe;

    function setUp() public {
        vuln = new V20_ReadOnlyReentrancy();
        safe = new V20_Secure();

        // Liquidez inicial real via deposit
        vm.deal(address(0x1), 20 ether);
        vm.prank(address(0x1));
        vuln.deposit{value: 20 ether}();

        vm.deal(address(0x1), 20 ether);
        vm.prank(address(0x1));
        safe.deposit{value: 20 ether}();
    }

    function testScannerDetects() public {
        DivinoScannerV20 scanner = new DivinoScannerV20();
        vm.deal(address(scanner), 10 ether);

        bool isVulnVulnerable = scanner.scanReadOnly(address(vuln));
        bool isSafeVulnerable = scanner.scanReadOnly(address(safe));

        console.log("Vulneravel detectado como vulneravel?", isVulnVulnerable);
        console.log("Seguro detectado como vulneravel?", isSafeVulnerable);

        assertTrue(isVulnVulnerable, "Scanner deveria detectar V20");
        assertFalse(isSafeVulnerable, "Scanner nao deveria acusar seguro");
    }
}
