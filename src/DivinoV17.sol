// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
contract DivinoV17 {
    mapping(address => uint256) public balances;
    function deposit() external payable { balances[msg.sender] += msg.value; }
    function resgatar(uint256 amt) external {
        require(balances[msg.sender] >= amt);
        balances[msg.sender] -= amt;
        (bool ok,) = msg.sender.call{value: amt}("");
        require(ok);
    }
}
