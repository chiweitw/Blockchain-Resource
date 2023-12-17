// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
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

    function setup() public {
        vm.createSelectFork(vm.envString("MAINNET_RPC_URL"), 17465000);

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
            comptroller,
            InterestRateModel(address(whitePaperInterestModel)),
            1 ether,
            USDC.name(),
            USDC.symbol(),
            18,
            payable(msg.sender),
            address(cUSDCDelegate),
            becomeImplementationData
        );
        unitrollerProxy._supportMarket(CToken(address(cUSDC)));

        // prepare token B: UNI
        cUNIDelegate = new CErc20Delegate();
        cUNI = new CErc20Delegator(
            address(UNI),
            comptroller,
            InterestRateModel(address(whitePaperInterestModel)),
            1 ether,
            UNI.name(),
            UNI.symbol(),
            18,
            payable(msg.sender),
            address(cUNIDelegate),
            becomeImplementationData
        );
        unitrollerProxy._supportMarket(CToken(address(UNI)));
        // set oracle price
        simplePriceOracle.setUnderlyingPrice(CToken(address(cUSDC)), 1 * 10 * (36 - USDC.decimals()));
        simplePriceOracle.setUnderlyingPrice(CToken(address(cUNI)), 5 * 10 * (36 - UNI.decimals()));
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

        // deal user1 1000 UNI
        deal(address(UNI), user1, 1000 * 10 ** UNI.decimals());
    }

    function testFlashLiquidate() public {}
}