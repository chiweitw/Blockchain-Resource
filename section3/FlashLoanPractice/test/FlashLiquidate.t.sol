// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "compound-protocol/contracts/SimplePriceOracle.sol";
import "compound-protocol/contracts/WhitePaperInterestRateModel.sol";
import "compound-protocol/contracts/Unitroller.sol";
import "compound-protocol/contracts/Comptroller.sol";
import "compound-protocol/contracts/CErc20Delegate.sol";
import "compound-protocol/contracts/CErc20Delegator.sol";
import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "../src/FlashLiquidate.sol";

contract FlashLiquidateTest is Test {
    // oracle
    SimplePriceOracle public simplePriceOracle;
    // whitepapper
    WhitePaperInterestRateModel public whitePaperInterestModel;
    // comptroller
    Unitroller public unitroller;
    Comptroller public comptroller;
    Comptroller public unitrollerProxy;
    // token A: USDC
    ERC20 public USDC = ERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    CErc20Delegate public cUSDCDelegate;
    CErc20Delegator public cUSDC;
    // token B: UNI
    ERC20 public UNI = ERC20(0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984);
    CErc20Delegate public cUNIDelegate;
    CErc20Delegator public cUNI;
    // users
    address public user1;
    address public user2;
    // flashliquidate
    FlashLiquidate public flashLiquidate;

    // common variables
    uint256 public initialUSDCAmount;
    uint256 public initialUNIAmount;
    uint256 public mintAmount;
    uint256 public borrowAmount;

    function setUp() public {
        vm.createSelectFork(vm.envString("MAINNET_RPC_URL"), 17_465_000);

        // prepare oracle
        simplePriceOracle = new SimplePriceOracle();
        // prepare whitepapper
        whitePaperInterestModel = new WhitePaperInterestRateModel(0, 0);
        // prepare comptroller
        comptroller = new Comptroller();
        unitroller = new Unitroller();
        unitrollerProxy = Comptroller(address(unitroller));
        unitroller._setPendingImplementation(address(comptroller));
        comptroller._become(unitroller);
        unitrollerProxy._setPriceOracle(simplePriceOracle);
        // becomeImplementationData
        bytes memory becomeImplementationData = new bytes(0x00);
        // prepare token A: USDC
        cUSDCDelegate = new CErc20Delegate();
        cUSDC = new CErc20Delegator(
            address(USDC),
            unitrollerProxy,
            InterestRateModel(address(whitePaperInterestModel)),
            1e6,
            USDC.name(),
            USDC.symbol(),
            18,
            payable(msg.sender),
            address(cUSDCDelegate),
            becomeImplementationData
        );
        
        // prepare token B: UNI
        cUNIDelegate = new CErc20Delegate();
        cUNI = new CErc20Delegator(
            address(UNI),
            unitrollerProxy,
            InterestRateModel(address(whitePaperInterestModel)),
            1e18,
            UNI.name(),
            UNI.symbol(),
            18,
            payable(msg.sender),
            address(cUNIDelegate),
            becomeImplementationData
        );

        // support market
        unitrollerProxy._supportMarket(CToken(address(cUSDC)));
        unitrollerProxy._supportMarket(CToken(address(cUNI)));
        // set oracle price
        simplePriceOracle.setUnderlyingPrice(CToken(address(cUSDC)), 1 * 10 ** (36 - USDC.decimals()));
        simplePriceOracle.setUnderlyingPrice(CToken(address(cUNI)), 5 * 10 ** (36 - UNI.decimals()));
        // set close factor
        unitrollerProxy._setCloseFactor(0.5 * 1e18);
        // set collateral factor
        unitrollerProxy._setCollateralFactor(CToken(address(cUNI)), 0.5 * 1e18);
        // set liquidation incentive
        unitrollerProxy._setLiquidationIncentive(1.08 * 1e18);
        // set users
        user1 = makeAddr("User1");
        user2 = makeAddr("User2");
        // deploy flashliquidate contract
        flashLiquidate = new FlashLiquidate();

        // deal user1 initial UNI
        deal(address(UNI), user1, 3000 * 10 ** UNI.decimals());

        // set initial ammount
        // initialUSDCAmount = 1000 * 10 ** USDC.decimals();
        initialUNIAmount = 1000 * 10 ** UNI.decimals();
        mintAmount = initialUNIAmount;
        borrowAmount = 2500 * 10 ** USDC.decimals();

        // deal(address(USDC), user1, initialUSDCAmount);
        deal(address(UNI), user1, initialUNIAmount);
    }

    function testFlashLiquidate() public {
        // 1. user1 use 1000 UNI to borrow 2500 USDC
        assertEq(UNI.balanceOf(user1), mintAmount); // user have enough UNI to mint

        vm.startPrank(user1);
        // 1.1 user1 approve cUNI to use UNI
        ERC20(UNI).approve(address(cUNI), mintAmount);

        assertEq(ERC20(UNI).allowance(address(user1) ,address(cUNI)), mintAmount);
        // 1.2 user1 mint 1000 cUNI
        cUNI.mint(mintAmount);

        assertEq(cUNI.balanceOf(user1), mintAmount);
        // 1.3 user1 enter markets
        address[] memory addr = new address[](1);
        addr[0] = address(cUNI);

        unitrollerProxy.enterMarkets(addr);
        // 1.4 user1 borrow USDC
        deal(address(USDC), address(cUSDC), borrowAmount);
        assertEq(USDC.balanceOf(address(cUSDC)), borrowAmount); // cUSDC pair has enough USDC to be borrowed


        cUSDC.borrow(borrowAmount);

        // assert user1 has 2500 USDC
        assertEq(ERC20(USDC).balanceOf(user1), borrowAmount);
        vm.stopPrank();

        // 2. UNI price down to 4, and induce user1 shortfall

        // 3. user2 use flashloan to liquidate user1

        // 4. check user2 earn around 63 USDC
    }
}