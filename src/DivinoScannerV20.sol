// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IV20 {
    function getVirtualPrice() external view returns (uint256);
    function deposit() external payable;
    function withdraw() external;
    function lpBalance(address) external view returns (uint256);
}

contract DivinoScannerV20 {
    function scanReadOnly(address target) public returns (bool isVulnerable) {
        // Deploy tester já com saldo
        V20Tester tester = new V20Tester{value: 2 ether}(target);
        try tester.test() returns (uint256 priceNormal, uint256 priceDuring) {
            // Se preço mudou durante withdraw = VULNERÁVEL
            // Se view reverteu, priceDuring = MAX = SEGURO (tem nonReentrantView)
            if (priceDuring == type(uint256).max) return false;
            return priceDuring != priceNormal;
        } catch {
            return false; // view protegida
        }
    }
}

contract V20Tester {
    address public target;
    uint256 public priceDuring;
    uint256 public priceNormal;
    bool public attacked;

    constructor(address _t) payable {
        target = _t;
    }

    function test() external returns (uint256, uint256) {
        priceNormal = IV20(target).getVirtualPrice();
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
                priceDuring = type(uint256).max;
            }
        }
    }
}
