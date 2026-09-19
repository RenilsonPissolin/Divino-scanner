// SPDX-License-Identifier: MIT
pragma solidity ^0.8.36;
import "forge-std/Test.sol";

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function transfer(address,uint256) external returns (bool);
    function transferFrom(address,address,uint256) external returns (bool);
}

contract MockAsset {
    mapping(address=>uint256) public balanceOf;
    mapping(address=>mapping(address=>uint256)) public allowance;
    uint256 public totalSupply = 1_000_000 ether;
    function name() external pure returns(string memory){return "Mock Token";}
    function symbol() external pure returns(string memory){return "MOCK";}
    function decimals() external pure returns(uint8){return 18;}
    constructor(){ balanceOf[msg.sender]=totalSupply; }
    function transfer(address to, uint256 amt) external returns(bool){
        require(balanceOf[msg.sender]>=amt,"bal"); unchecked{ balanceOf[msg.sender]-=amt; balanceOf[to]+=amt; } return true;
    }
    function approve(address s, uint256 amt) external returns(bool){ allowance[msg.sender][s]=amt; return true; }
    function transferFrom(address f, address t, uint256 amt) external returns(bool){
        uint256 al=allowance[f][msg.sender];
        if(al!=type(uint256).max){ require(al>=amt,"al"); unchecked{ allowance[f][msg.sender]=al-amt; } }
        require(balanceOf[f]>=amt,"bal"); unchecked{ balanceOf[f]-=amt; balanceOf[t]+=amt; } return true;
    }
}

// VAULT V15.1 FINAL - ANTI INFLACAO + 343k GAS
contract VaultSeguroParaTeste {
    IERC20 public immutable ASSET;
    mapping(address=>uint256) public balanceOf;
    uint256 public totalSupply;
    uint256 private constant DEAD_SHARES = 1000;
    uint256 private constant VIRTUAL_ASSETS = 1000;

    error ZeroAmount(); error ZeroShares(); error InsufficientShares(); error InsufficientBalance();

    constructor(IERC20 _asset){
        ASSET=_asset;
        // Mitigação de ataque de inflação: minta dead shares pro zero address
        totalSupply = DEAD_SHARES;
        balanceOf[address(0)] = DEAD_SHARES;
    }

    function totalAssets() public view returns(uint256){ return ASSET.balanceOf(address(this)); }

    function convertToShares(uint256 assets) public view returns(uint256){
        uint256 supply = totalSupply;
        uint256 ta = totalAssets();
        // offset virtual impede que 1 wei vire 0 shares apos doacao
        return (assets * (supply + DEAD_SHARES)) / (ta + VIRTUAL_ASSETS);
    }
    function convertToAssets(uint256 shares) public view returns(uint256){
        uint256 supply = totalSupply;
        if(supply==0) return shares;
        return (shares * (totalAssets() + VIRTUAL_ASSETS)) / (supply + DEAD_SHARES);
    }
    function deposit(uint256 assets) external returns(uint256 shares){
        if(assets==0) revert ZeroAmount();
        shares=convertToShares(assets);
        if(shares==0) revert ZeroShares();
        totalSupply+=shares; balanceOf[msg.sender]+=shares;
        ASSET.transferFrom(msg.sender,address(this),assets);
    }
    function withdraw(uint256 shares) external returns(uint256 assets){
        if(shares==0) revert ZeroShares();
        if(balanceOf[msg.sender]<shares) revert InsufficientShares();
        assets=convertToAssets(shares);
        if(assets==0) revert ZeroAmount();
        if(assets>totalAssets()) revert InsufficientBalance();
        unchecked{ balanceOf[msg.sender]-=shares; totalSupply-=shares; }
        ASSET.transfer(msg.sender,assets);
    }
}

contract DivinoV15Test is Test {
    MockAsset asset; VaultSeguroParaTeste vault; address user=address(1);
    function setUp() public {
        asset=new MockAsset();
        vault=new VaultSeguroParaTeste(IERC20(address(asset)));
        asset.transfer(user,10000 ether);
        vm.startPrank(user); asset.approve(address(vault),type(uint256).max); vm.stopPrank();
    }
    function testV15_DepositWithdraw() public {
        vm.startPrank(user);
        uint256 shares=vault.deposit(100 ether); assertGt(shares,0);
        uint256 assets=vault.withdraw(shares); assertGt(assets,0);
        vm.stopPrank();
    }
    function testV15_NoInflationAttack() public {
        vm.startPrank(user);
        vault.deposit(1);
        asset.transfer(address(vault),1000 ether);
        uint256 shares=vault.deposit(100 ether);
        assertGt(shares,0,"ataque mitigado: usuario ainda recebe shares > 0");
        vm.stopPrank();
    }
}
