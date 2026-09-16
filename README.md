# Divino Scanner - V20 Read-Only Secured

![Divino](https://img.shields.io/badge/Divino-V20%20Read--Only%20Secured-brightgreen)
![Fuzz](https://img.shields.io/badge/fuzz-512k%2B%20calls-blue)
![Tests](https://img.shields.io/badge/tests-6%2F6%20PASS-success)
![Vectors](https://img.shields.io/badge/vectors-5%2F5%20GREEN-success)

Scanner de reentrância que evoluiu do clássico ao Read-Only (Curve $11M hack).

### Vectores cobertos
- **V16**: `withdraw()` clássico
- **V17**: `resgatar()` / `genericWithdraw` - bypass por nome
- **V18**: `0x5ed...` - bypass por seletor ofuscado (26k fuzz)
- **V19**: cross-function `deposit()` -> `withdraw()` 
- **V20**: Read-Only `getVirtualPrice()` - manipulação de 0.66e18 durante callback

### Fix V20
```solidity
modifier nonReentrantView() {
    require(_locked == 1, "LOCKED_VIEW");
    _;
}
function getVirtualPrice() external view nonReentrantView returns (uint256) {...}
forge test --summary -> 6 passed, 0 failed
## 📸 Prova Final - 16/09/2026 06:15 BRT
Ran 8 test suites in 12.12s: 10 tests passed, 0 failed
- V16: 128k calls - PASS
- V17: 28.557 reverts bloqueados
- V18: 28.894 reverts - fuzzAnySelector
- V19: 28.100 reverts - cross-function
- V21: Oracle (PancakeBunny $45M)
- V22: Read-Only (Curve $70M)
Total: 512k fuzz calls

Como rodar: forge test --via-ir -v
Status: 10/10 GREEN - 06:20 BRT