// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "forge-std/Test.sol";
import "../src/V20_ReadOnlyReentrancy.sol";

contract V20_Test is Test {
    V20_ReadOnlyReentrancy pool;
    V20_Attacker attacker;
    function setUp() public {
        pool = new V20_ReadOnlyReentrancy();
        vm.deal(address(0x1), 10 ether);
        vm.prank(address(0x1));
        pool.deposit{value: 10 ether}();
        vm.deal(address(0x2), 10 ether);
        vm.prank(address(0x2));
        pool.deposit{value: 10 ether}();
        attacker = new V20_Attacker(address(pool));
        vm.deal(address(attacker), 10 ether);
    }
    function testV20_ReadOnly() public {
        uint256 priceBefore = pool.getVirtualPrice();
        console.log("Preco normal ANTES:", priceBefore);

        attacker.attack{value: 10 ether}();

        uint256 priceDuring = attacker.priceSeenDuringReentrancy();
        uint256 priceNormalAtAttack = attacker.priceNormal();
        
        console.log("Preco normal no ataque:", priceNormalAtAttack);
        console.log("Preco DURANTE reentrancia:", priceDuring);
        
        // Durante o ataque: balance = 20, totalLP = 30 (ainda nao atualizou)
        // preco = 20*1e18/30 = 0.66e18 -> MANIPULADO
        assertTrue(priceDuring != priceNormalAtAttack, "READ-ONLY VULNERAVEL");
        console.log("VULNERABILIDADE CONFIRMADA - preco mudou durante withdraw!");
    }
}
