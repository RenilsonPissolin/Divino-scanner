// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/DivinoScannerV6.sol";
contract ScanAll is Script {
    function run() external {
        DivinoScannerV6 scanner = new DivinoScannerV6();
        string[] memory files = new string[](2);
        files[0] = "src/DivinoScannerV6.sol";
        files[1] = "src/VulnerableVault.sol";
        string memory table=""; uint256 total=0; uint256 cCrit; uint256 cHigh; uint256 cMed; uint256 cSafe;
        for(uint256 i=0;i<files.length;i++){
            total++;
            try vm.readFile(files[i]) returns (string memory code) {
                DivinoScannerV6.Vulnerability[] memory f = scanner.scanContract(files[i], code);
                if(f.length==0){cSafe++; table=string.concat(table, "| ", files[i], " | SAFE | OK | - |\n");}
                else {for(uint256 j=0;j<f.length;j++){if(keccak256(bytes(f[j].severity))==keccak256(bytes("CRITICAL"))) cCrit++; if(keccak256(bytes(f[j].severity))==keccak256(bytes("HIGH"))) cHigh++; if(keccak256(bytes(f[j].severity))==keccak256(bytes("MEDIUM"))) cMed++; table=string.concat(table, "| ", f[j].file, " | **", f[j].severity, "** | ", f[j].bugType, " | ", f[j].detail, " |\n");}}
            } catch {}
        }
        string memory risk = cCrit>0?"CRITICO - ACAO IMEDIATA":cHigh>0?"ALTO - REVISAO NECESSARIA":"BAIXO - OK";
        string memory md = string.concat("# RELATORIO EXECUTIVO - DIVINO-SCANNER V6.2\n\n## Sumario Executivo\n- **Total arquivos:** ", vm.toString(total), "\n- **Risco Geral:** **", risk, "**\n- **CRITICAL:** ", vm.toString(cCrit), " | HIGH:", vm.toString(cHigh), " | MEDIUM:", vm.toString(cMed), " | SAFE:", vm.toString(cSafe), "\n\n---\n\n## Detalhamento\n| Arquivo | Sev | Bug | Detalhe |\n|---|---|---|---|\n", table);
        vm.writeFile("RELATORIO_AUDITORIA.md", md);
        console.log("RELATORIO GERADO COM 5 TOPICOS! Risco:", risk);
    }
}
