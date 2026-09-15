// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IV20 {
    function getVirtualPrice() external view returns (uint256);
    function deposit() external payable;
    function withdraw() external;
}

contract DivinoScannerV20 {
    function scanReadOnly(address target) public returns (bool isVulnerable) {
        // Se getVirtualPrice reverter durante locked = protegido
        // Se retornar valor manipulado = vulnerável
        V20Tester tester = new V20Tester(target);
        try tester.test() returns (uint256 priceNormal, uint256 priceDuring) {
            if (priceDuring != priceNormal) {
                return true; // VULNERAVEL
            }
            return false; // seguro
        } catch {
            return false; // view protegida com nonReentrantView = seguro
        }
    }
}

contract V20Tester {
    address target;
    constructor(address _t) { target = _t; }
    uint256 public priceDuring;
    bool attacked;
    
    function test() external returns (uint256, uint256) {
        uint256 priceNormal = IV20(target).getVirtualPrice();
        IV20(target).deposit{value: 1 ether}();
        IV20(target).withdraw();
        return (priceNormal, priceDuring);
    }
    receive() external payable {
        if (!attacked) {
            attacked = true;
            try IV20(target).getVirtualPrice() returns (uint256 p) {
                priceDuring = p;
            } catch {
                priceDuring = type(uint256).max; // view protegida, reverteu = SEGURO
            }
        }
    }
}
