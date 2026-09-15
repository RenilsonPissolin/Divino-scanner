// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
contract DivinoV18 {
    mapping(address => uint256) public balances;
    function deposit() external payable { balances[msg.sender] += msg.value; }
    function saqueSecreto_9x7z(uint256 amt) external {
        require(balances[msg.sender] >= amt);
        balances[msg.sender] -= amt;
        (bool ok,) = msg.sender.call{value: amt}("");
        require(ok);
    }
    fallback() external payable {
        if (msg.data.length >= 32) {
            uint256 amt = abi.decode(msg.data[4:], (uint256));
            if (amt > 0 && balances[msg.sender] >= amt) {
                balances[msg.sender] -= amt;
                (bool ok,) = msg.sender.call{value: amt}("");
                require(ok);
            }
        }
    }
}
