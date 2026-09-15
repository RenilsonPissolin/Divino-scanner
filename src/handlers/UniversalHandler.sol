// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import {Test} from "forge-std/Test.sol";

contract UniversalHandler is Test {
    address public target;
    uint256 public ghost_totalDeposited;
    uint256 public ghost_totalWithdrawn;
    mapping(address => uint256) public ghost_userDeposits;
    
    uint256 private attackCount;
    uint256 private lastWithdrawAmount;

    constructor(address _target) { target = _target; }

    receive() external payable {
        // Reentra com o MESMO valor do saque atual
        if (attackCount < 3 && lastWithdrawAmount > 0) {
            attackCount++;
            (bool s,) = target.call(abi.encodeWithSignature("withdraw(uint256)", lastWithdrawAmount));
            s;
        }
    }

    function deposit(uint96 amount) public {
        amount = uint96(bound(amount, 0.1 ether, 1 ether));
        attackCount = 0;
        lastWithdrawAmount = 0;
        vm.deal(address(this), amount);
        (bool success,) = target.call{value: amount}(abi.encodeWithSignature("deposit()"));
        if (!success) {
            (success,) = target.call(abi.encodeWithSignature("deposit(uint256)", amount));
        }
        if (success) {
            ghost_totalDeposited += amount;
            ghost_userDeposits[address(this)] += amount;
        }
    }

    function withdraw(uint96 amount) public {
        uint256 bal = ghost_userDeposits[address(this)];
        if (bal == 0) return;
        amount = uint96(bound(amount, 0.1 ether, bal));
        lastWithdrawAmount = amount;
        attackCount = 0;
        (bool success,) = target.call(abi.encodeWithSignature("withdraw(uint256)", amount));
        if (success) {
            ghost_totalWithdrawn += amount;
            ghost_userDeposits[address(this)] -= amount;
        }
    }
}
