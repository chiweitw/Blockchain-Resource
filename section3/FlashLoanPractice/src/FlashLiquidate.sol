// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {IFlashLoanSimpleReceiver, IPoolAddressesProvider, IPool} from "aave-v3-core/contracts/flashloan/interfaces/IFlashLoanSimpleReceiver.sol";

contract FlashLiquidate is IFlashLoanSimpleReceiver {
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant POOL_ADDRESSES_PROVIDER = 0x2f39d218133AFaB8F2B819B1066c7E434Ad94E9e;
    address constant SWAP_Router = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    struct FlashLoanParams {
        address borrower;
        address borrowCToken;
        address collateralCtoken;
        address collateralToken;
    }

    function execute(
        address asset,
        uint amount,
        bytes calldata params
    ) external {
        IPool(ADDRESSES_PROVIDER().getPool()).flashLoanSimple(
            address(this),
            asset,
            amount,
            params,
            0 // referral code, not used.
        );
    }

    function executeOperation(
        address asset, // flashloan target
        uint256 amount, // borrow amount
        uint256 premium, // fee
        address initiator, // address(this)
        bytes calldata params
    ) external returns (bool) {
        require(initiator == address(this), "not initialte by this contract");

        ({
            address borrower;
            address borrowCToken;
            address collateralCtoken;
            address collateralToken;
        }) = abi.decode(params, FlashLoanParams);

        // approve cUSDC to use USDC
        IERC20(USDC).approve(address(borrowCToken), amount);

        // liquidate borrower and get cUNI as rewards

        // redeem cUNI to get UNI

        // swap UNI to USDC

        // repay to flashloan
    }

    function ADDRESSES_PROVIDER() public view returns (IPoolAddressesProvider) {
        return IPoolAddressesProvider(POOL_ADDRESSES_PROVIDER);
    }
}