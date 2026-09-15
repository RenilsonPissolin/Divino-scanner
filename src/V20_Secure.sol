// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract V20_Secure {
    mapping(address => uint256) public lpBalance;
    uint256 public totalLP;
    uint256 private _locked = 1;

    modifier nonReentrant() {
        require(_locked == 1, "LOCKED");
        _locked = 2;
        _;
        _locked = 1;
    }
    // FIX V20: view também checa lock
    modifier nonReentrantView() {
        require(_locked == 1, "LOCKED_VIEW");
        _;
    }

    function deposit() external payable {
        lpBalance[msg.sender] += msg.value;
        totalLP += msg.value;
    }

    function withdraw() external nonReentrant {
        uint256 amount = lpBalance[msg.sender];
        require(amount > 0);
        lpBalance[msg.sender] = 0;
        totalLP -= amount;
        (bool ok,) = msg.sender.call{value: amount}("");
        require(ok);
    }

    function getVirtualPrice() external view nonReentrantView returns (uint256) {
        if (totalLP == 0) return 1e18;
        return (address(this).balance * 1e18) / totalLP;
    }
}
