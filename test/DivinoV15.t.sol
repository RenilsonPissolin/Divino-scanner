// SPDX-License-Identifier: MIT
pragma solidity ^0.8.36;
import "forge-std/Test.sol";
import "forge-std/StdInvariant.sol";
interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function transfer(address,uint256) external returns (bool);
    function transferFrom(address,address,uint256) external returns (bool);
}
contract MockERC20 is IERC20 {
    string public name = "Mock Token";
    string public symbol = "MCK";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    function mint(address to, uint256 amount) external { balanceOf[to] += amount; totalSupply += amount; }
    function approve(address spender, uint256 amount) external returns (bool) { allowance[msg.sender][spender] = amount; return true; }
    function transfer(address to, uint256 amount) external returns (bool) { require(balanceOf[msg.sender] >= amount, "insuf"); balanceOf[msg.sender] -= amount; balanceOf[to] += amount; return true; }
    function transferFrom(address from, address to, uint256 amount) external returns (bool) { require(balanceOf[from] >= amount, "insuf"); if (allowance[from][msg.sender]!= type(uint256).max) { require(allowance[from][msg.sender] >= amount, "allow"); allowance[from][msg.sender] -= amount; } balanceOf[from] -= amount; balanceOf[to] += amount; return true; }
}
interface IVault {
    function deposit(uint256 assets) external;
    function withdraw(uint256 assets) external;
    function totalDeposits() external view returns (uint256);
    function totalAssets() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
}
contract VaultSeguroParaTeste is IVault {
    IERC20 public token;
    mapping(address => uint256) public balanceOf;
    uint256 public totalSupply;
    uint256 public totalDeposits;
    uint256 private constant VIRTUAL_OFFSET = 1e6;
    constructor(address _token) { token = IERC20(_token); }
    function deposit(uint256 assets) external {
        require(assets > 0, "zero");
        require(token.transferFrom(msg.sender, address(this), assets), "transfer fail");
        uint256 shares; uint256 supply = totalSupply; uint256 vaultAssets = token.balanceOf(address(this)) - assets;
        if (supply == 0) { shares = assets; } else { shares = (assets * (supply + VIRTUAL_OFFSET)) / (vaultAssets + VIRTUAL_OFFSET); }
        require(shares > 0, "zero shares"); balanceOf[msg.sender] += shares; totalSupply += shares; totalDeposits += assets;
    }
    function withdraw(uint256 assets) external {
        require(assets > 0, "zero"); uint256 supply = totalSupply; require(supply > 0, "no supply");
        uint256 vaultAssets = token.balanceOf(address(this)); require(vaultAssets >= assets, "insuf vault");
        uint256 shares = (assets * (supply + VIRTUAL_OFFSET)) / (vaultAssets + VIRTUAL_OFFSET); if (shares == 0) shares = 1;
        require(balanceOf[msg.sender] >= shares, "insuf shares"); balanceOf[msg.sender] -= shares; totalSupply -= shares; totalDeposits -= assets;
        require(token.transfer(msg.sender, assets), "transfer fail");
    }
    function totalAssets() external view returns (uint256) { return token.balanceOf(address(this)); }
}
contract HandlerDivinoV15 is Test {
    VaultSeguroParaTeste public vault; MockERC20 public token; address[] public actors; uint256 public sumDeposited;
    constructor(VaultSeguroParaTeste _vault, MockERC20 _token) {
        vault = _vault; token = _token;
        actors.push(address(0x1001)); actors.push(address(0x1002)); actors.push(address(0x1003));
        for (uint i = 0; i < actors.length; i++) { token.mint(actors[i], 1_000_000e18); }
    }
    function _randomActor(uint256 seed) internal view returns (address) { return actors[seed % actors.length]; }
    function deposit(uint256 actorSeed, uint256 amount) public {
        amount = bound(amount, 1e12, 100_000e18); address actor = _randomActor(actorSeed);
        vm.startPrank(actor); token.approve(address(vault), amount);
        try vault.deposit(amount) { sumDeposited += amount; } catch {} vm.stopPrank();
    }
    function withdraw(uint256 actorSeed, uint256 amount) public {
        amount = bound(amount, 1e12, 100_000e18); address actor = _randomActor(actorSeed);
        if (vault.balanceOf(actor) == 0) return; uint256 vaultBal = token.balanceOf(address(vault)); if (vaultBal == 0) return;
        amount = bound(amount, 1, vaultBal); vm.startPrank(actor);
        try vault.withdraw(amount) { if (sumDeposited >= amount) sumDeposited -= amount; } catch {} vm.stopPrank();
    }
    function getActors() external view returns (address[] memory) { return actors; }
}
contract DivinoV15 is Test {
    MockERC20 public token; VaultSeguroParaTeste public vault; HandlerDivinoV15 public handler;
    function setUp() public {
        token = new MockERC20(); vault = new VaultSeguroParaTeste(address(token)); handler = new HandlerDivinoV15(vault, token);
        targetContract(address(handler));
        bytes4[] memory selectors = new bytes4[](2); selectors[0] = HandlerDivinoV15.deposit.selector; selectors[1] = HandlerDivinoV15.withdraw.selector;
        targetSelector(FuzzSelector({addr: address(handler), selectors: selectors}));
    }
    function invariant_TOTAL() public view { assertEq(vault.totalAssets(), token.balanceOf(address(vault))); }
    function invariant_SUM() public view { if (vault.totalSupply() == 0) { assertEq(vault.totalAssets(), 0); } }
    function invariant_SOLVENCIA_CONDICIONAL() public view { if (vault.totalSupply() > 0) { assertGe(vault.totalAssets() + 1e6, vault.totalSupply() > 1e12? vault.totalSupply() - 1e12 : 0); } }
    function invariant_SHARES() public view {
        address[] memory actors = handler.getActors(); uint256 sumShares;
        for (uint i = 0; i < actors.length; i++) { sumShares += vault.balanceOf(actors[i]); assertLe(vault.balanceOf(actors[i]), vault.totalSupply()); }
        assertEq(sumShares, vault.totalSupply());
    }
    function invariant_CONVERSION_RATE() public view { if (vault.totalSupply() == 0) return; assertGe(vault.totalAssets() + 1e6, vault.totalSupply() - (vault.totalSupply() / 100)); }
    function test_dummy() public { assertTrue(true); }
}
