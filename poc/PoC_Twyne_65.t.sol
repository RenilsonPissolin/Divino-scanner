// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/AaveV3CollateralVault.sol";

contract PoC_Twyne_65 is Test {
    AaveV3CollateralVault vault;
    address attacker = address(0x1337);

    function setUp() public {
        vault = new AaveV3CollateralVault();
        vm.deal(attacker, 10 ether);
    }

    // Teste do bug que o Divino Scanner achou na linha 65
    function test_VariableShadowing_Twyne65() public {
        console.log("=== Poc da Twyne #93420 - Shadowing targetAsset ===");
        
        // 1. Estado inicial
        address initialAsset = vault.targetAsset();
        console.log("targetAsset inicial:", initialAsset);

        // 2. Chama funcao com bug
        vm.prank(attacker);
        vault.initVault();

        // 3. Verifica se a variavel de estado NAO foi alterada (bug!)
        address afterAsset = vault.targetAsset();
        console.log("targetAsset depois do initVault:", afterAsset);

        // Se continuar 0x0, o bug de shadowing aconteceu
        assertEq(afterAsset, address(0), "BUG CONFIRMADO: Shadowing - state nao foi atualizado!");
        console.log(">>> VULNERABILIDADE CONFIRMADA <<<");
    }

    function test_OracleManipulation() public {
        console.log("Testando Oracle Manipulation - getReserves()");
        // Aqui entraria flashloan + manipulacao
    }
}
