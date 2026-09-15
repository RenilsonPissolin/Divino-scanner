// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// V19 SECURE - Cross-Function fix - sem reset de lock + CEI
contract DivinoV19 {
    mapping(address => uint256) public balances;
    bool private _entered;

    modifier nonReentrant() {
        require(!_entered, "locked");
        _entered = true;
        _;
        _entered = false;
    }

    function deposit() external payable {
        balances[msg.sender] += msg.value;
        // NUNCA reseta _entered aqui!
    }

    function withdraw(uint256 amt) external nonReentrant {
        require(balances[msg.sender] >= amt, "bal");
        balances[msg.sender] -= amt; // CEI antes do call
        (bool ok,) = msg.sender.call{value: amt}("");
        require(ok);
    }
}
