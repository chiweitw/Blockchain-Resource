// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

contract FlashLiquidate is Test {
    // oracle
    // whitepapper
    // comptroller
    // token A: USDC
    // token B: UNI
    // users
    // flashliquidate

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

        function testFlashLiquidate() {
            
        }
    }
}