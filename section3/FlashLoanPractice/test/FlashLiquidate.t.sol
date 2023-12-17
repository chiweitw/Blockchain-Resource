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
        // prepare whitepapper
        // prepare comptroller
        // prepare token A: USDC
        // prepare token B: UNI
        // set oracle price
        // set close factor
        // set collateral factor
        // set liquidation incentive
        // set users
        // deploy flashliquidate contract
    }

    function testFlashLiquidate() public {}
}