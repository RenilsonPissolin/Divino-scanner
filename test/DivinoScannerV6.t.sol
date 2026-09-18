// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "forge-std/Test.sol";
import "../src/DivinoScannerV6.sol";

contract DivinoScannerV6Test is Test {
    DivinoScannerV6 scanner;

    function setUp() public {
        scanner = new DivinoScannerV6();
    }

    function test_ReentrancyCEI() public {
        string memory vuln = "function withdraw() public { (bool s,) = msg.sender.call{value:1}(''); balances[msg.sender] -=1; }";
        DivinoScannerV6.Vulnerability[] memory f = scanner.scanContract("Vault.sol", vuln);
        assertTrue(f.length > 0);
        assertEq(f[0].severity, "CRITICAL");
    }

    function test_MissingAccessControl_Pause() public {
        string memory vuln = "function pause() public { paused = true; }";
        DivinoScannerV6.Vulnerability[] memory f = scanner.scanContract("Pause.sol", vuln);
        assertTrue(f.length > 0);
    }

    function test_CommentFiltering() public {
        string memory safe = "//.call aqui eh comentario\n /*.call bloco */ \n function safe() public {}";
        DivinoScannerV6.Vulnerability[] memory f = scanner.scanContract("Safe.sol", safe);
        assertEq(f.length, 0);
    }

    function test_SafeContract() public {
        string memory safe = "function withdraw() public onlyOwner nonReentrant { balances[msg.sender] -=1; (bool s,) = msg.sender.call{value:1}(''); }";
        DivinoScannerV6.Vulnerability[] memory f = scanner.scanContract("Safe.sol", safe);
        // Deve ser SAFE porque tem nonReentrant e CEI correto
        assertEq(f.length, 0);
    }
}
