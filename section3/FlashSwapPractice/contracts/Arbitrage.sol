// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IUniswapV2Pair } from "v2-core/interfaces/IUniswapV2Pair.sol";
import { IUniswapV2Callee } from "v2-core/interfaces/IUniswapV2Callee.sol";

// This is a practice contract for flash swap arbitrage
contract Arbitrage is IUniswapV2Callee, Ownable {
    struct CallbackData {
        address priceLowerPool;
        address priceHigherPool;
        address priceLowerPoolTokenOut;
        address priceLowerPoolTokenIn;
        uint256 priceLowerPoolAmountOut;
        uint256 priceHigherPoolAmountOut;
        uint256 priceLowerPoolAmountIn;
    }

    //
    // EXTERNAL NON-VIEW ONLY OWNER
    //

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{ value: address(this).balance }("");
        require(success, "Withdraw failed");
    }

    function withdrawTokens(address token, uint256 amount) external onlyOwner {
        require(IERC20(token).transfer(msg.sender, amount), "Withdraw failed");
    }

    //
    // EXTERNAL NON-VIEW
    //

    function uniswapV2Call(address sender, uint256 amount0, uint256 amount1, bytes calldata data) external override {
        require(sender == address(this), "Sender must be this contract");
        require(amount0 > 0 || amount1 > 0, "Amount must be greater than 0");
        
        // decode callbackData
        CallbackData memory callbackData = abi.decode(data, (CallbackData));

        // Transfer borrow token (ETH) to priceHigherPool
        IERC20(callbackData.priceLowerPoolTokenOut).transfer(callbackData.priceHigherPool, callbackData.priceLowerPoolAmountOut);

        // Swap WETH for USDC in higher price pool at priceHigherPool
        IUniswapV2Pair(callbackData.priceHigherPool).swap(0, callbackData.priceHigherPoolAmountOut, address(this), "");

        // Repay USDC to lower pool
        IERC20(callbackData.priceLowerPoolTokenIn).transfer(callbackData.priceLowerPool, callbackData.priceLowerPoolAmountIn);
    }

    // Method 1 is
    //  - borrow WETH from lower price pool
    //  - swap WETH for USDC in higher price pool
    //  - repay USDC to lower pool
    // Method 2 is
    //  - borrow USDC from higher price pool
    //  - swap USDC for WETH in lower pool
    //  - repay WETH to higher pool
    // for testing convenient, we implement the method 1 here
    function arbitrage(address priceLowerPool, address priceHigherPool, uint256 borrowETH) external {
        // Get the reserves of priceHigherPool
        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(priceHigherPool).getReserves();

        // Calculate the amount of USDC after swap in priceHigherPool
        uint256 priceHigherPoolAmountOut = _getAmountOut(borrowETH, reserve0, reserve1); 

        // Get the reserves of priceLowerPool
        (reserve0, reserve1, ) = IUniswapV2Pair(priceLowerPool).getReserves();

        // Calculate the amount of USDC to repay to priceLowerPool
        uint256 priceLowerPoolAmountIn = _getAmountIn(borrowETH, reserve1, reserve0);

        // Organize the callback data
        CallbackData memory callbackData = CallbackData(
            priceLowerPool,
            priceHigherPool,
            IUniswapV2Pair(priceLowerPool).token0(), // WETH
            IUniswapV2Pair(priceHigherPool).token1(), // USDC
            borrowETH, // WETH borrow amount
            priceHigherPoolAmountOut, // USDC swap amount
            priceLowerPoolAmountIn // USDC repay amount
        );

        // borrow WETH from lower price pool
        IUniswapV2Pair(priceLowerPool).swap(borrowETH, 0, address(this), abi.encode(callbackData));
    }

    //
    // INTERNAL PURE
    //

    // copy from UniswapV2Library
    function _getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, "UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        uint256 numerator = reserveIn * amountOut * 1000;
        uint256 denominator = (reserveOut - amountOut) * 997;
        amountIn = numerator / denominator + 1;
    }

    // copy from UniswapV2Library
    function _getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }
}
