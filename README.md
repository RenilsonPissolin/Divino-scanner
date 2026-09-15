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
