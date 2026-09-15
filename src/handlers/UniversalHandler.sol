// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import {Test} from "forge-std/Test.sol";

contract UniversalHandler is Test {
    address public target;
    uint256 public ghost_totalDeposited;
    uint256 public ghost_totalWithdrawn;
    mapping(address => uint256) public ghost_userDeposits;
    bytes public lastCallData;
    uint256 public attackCount;

    constructor(address _target) { target = _target; }

    function deposit(uint96 amount) public {
        amount = uint96(bound(amount, 0.1 ether, 1 ether));
        attackCount = 0;
        vm.deal(address(this), address(this).balance + amount);
        (bool success,) = target.call{value: amount}(abi.encodeWithSignature("deposit()"));
        if (success) {
            ghost_totalDeposited += amount;
            ghost_userDeposits[address(this)] += amount;
        }
    }

    function genericWithdraw(uint96 amount) public {
        uint256 bal = ghost_userDeposits[address(this)];
        if (bal == 0) return;
        amount = uint96(bound(amount, 0.1 ether, bal));
        bytes memory data = abi.encodeWithSignature("resgatar(uint256)", amount);
        uint256 before = address(this).balance;
        lastCallData = data;
        attackCount = 0;
        (bool success,) = target.call(data);
        if (success && address(this).balance > before) {
            uint256 gained = address(this).balance - before;
            ghost_totalWithdrawn += gained;
            ghost_userDeposits[address(this)] -= gained;
        }
    }

    receive() external payable {
        if (attackCount < 2 && lastCallData.length > 0) {
            attackCount++;
            target.call(lastCallData);
        }
    }
}
