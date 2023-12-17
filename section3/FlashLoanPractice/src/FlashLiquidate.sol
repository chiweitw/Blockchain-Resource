// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/console.sol";

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {IFlashLoanSimpleReceiver, IPoolAddressesProvider, IPool} from "aave-v3-core/contracts/flashloan/interfaces/IFlashLoanSimpleReceiver.sol";
import "compound-protocol/contracts/CErc20.sol";

// uniswap-v3
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';

contract FlashLiquidate is IFlashLoanSimpleReceiver {
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant POOL_ADDRESSES_PROVIDER = 0x2f39d218133AFaB8F2B819B1066c7E434Ad94E9e;
    address constant SWAP_Router = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    struct FlashLoanParams {
        address borrower;
        address borrowCToken;
        address rewardCToken;
        address rewardToken;
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

        FlashLoanParams memory params = abi.decode(params, (FlashLoanParams));

        // approve cUSDC to use USDC
        IERC20(USDC).approve(address(params.borrowCToken), amount);

        // liquidate borrower and get cUNI as rewards
        uint256 err = CErc20(params.borrowCToken).liquidateBorrow(
            params.borrower,
            amount,
            CErc20(params.rewardCToken)
        );

        require(err == 0, "liquidate failed");

        // redeem cUNI to get UNI
        CErc20(params.rewardCToken).redeem(CErc20(params.rewardCToken).balanceOf(initiator));

        // swap UNI to USDC
        IERC20(params.rewardToken).approve(SWAP_Router, IERC20(params.rewardToken).balanceOf(initiator));

        ISwapRouter.ExactInputSingleParams memory swapParams = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: params.rewardToken,
                tokenOut: asset,
                fee: 3000, // 0.3%
                recipient: initiator,
                deadline: block.timestamp,
                amountIn: IERC20(params.rewardToken).balanceOf(initiator),
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        uint256 amountOut = ISwapRouter(SWAP_Router).exactInputSingle(swapParams);
        console.log(amountOut);

        // repay to flashloan
        IERC20(asset).approve(msg.sender, amount + premium);
        return true;
    }

    function ADDRESSES_PROVIDER() public view returns (IPoolAddressesProvider) {
        return IPoolAddressesProvider(POOL_ADDRESSES_PROVIDER);
    }

    function POOL() public view returns (IPool) {
        return IPool(ADDRESSES_PROVIDER().getPool());
    }
}