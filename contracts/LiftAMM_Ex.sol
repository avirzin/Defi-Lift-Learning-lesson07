// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "hardhat/console.sol";

// Transforming contract into an ERC20
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Contract now extens ERC20
contract LiftAMMX is ERC20 { 
    uint256 private _totalSupply;
    mapping(address => uint256) public balance; 

    address public tokenA;
    address public tokenB;
    uint256 public amountFeeTokenA;
    uint256 public amountFeeTokenB;
    uint256 public LiquiditProviderFee = 3; // 3% fee for liquidity provider
    uint256 public balanceTokenB;
    uint256 public balanceTokenA;
    uint256 public priceSwap;

    // ERC20 added to constructor
    constructor(address _tokenA, address _tokenB) ERC20("LiftAMMX", "AMMX") {  
        tokenA = _tokenA;
        tokenB = _tokenB;   
    }

    // Time lock added
    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'UniswapV2Router: EXPIRED'); 
        _;
    }

    // Raiz quadrada: https://github.com/Uniswap/v2-core/blob/master/contracts/libraries/Math.sol
    function squareRoot(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }    

    function addLiquidity(uint256 amountA, uint256 amountB) external returns (uint256 liquidity) {       
        IERC20(tokenA).transferFrom(msg.sender, address(this), amountA);
        IERC20(tokenB).transferFrom(msg.sender, address(this), amountB);

        uint256 balanceA = IERC20(tokenA).balanceOf(address(this));
        uint256 balanceB = IERC20(tokenB).balanceOf(address(this));

        // Changed totalSupply to private
        require(_totalSupply * amountA / balanceA == _totalSupply * amountB / balanceB, "Wrong proportion between asset A and B");

        liquidity = squareRoot(amountA * amountB);
        _totalSupply += liquidity;
        balance[msg.sender] += liquidity;

        //Associating to mint function
        balanceTokenA += balanceA;
        balanceTokenB += balanceB;
        priceSwap = balanceA * balanceB;
        _mint(msg.sender, liquidity);
    }

    function removeLiquidity(uint256 liquidity) external returns (uint256 amountA, uint256 amountB) {   
        require(balance[msg.sender] >= liquidity, "Not enough liquidity for this, amount too big"); 
        uint256 balanceA = IERC20(tokenA).balanceOf(address(this));
        uint256 balanceB = IERC20(tokenB).balanceOf(address(this));         

        uint divisor = _totalSupply / liquidity;
        amountA = balanceA / divisor;
        amountB = balanceB / divisor;

        _totalSupply -= liquidity;
        balance[msg.sender] -= liquidity;  

        IERC20(tokenA).transfer(msg.sender, amountA);
        IERC20(tokenB).transfer(msg.sender, amountB);

        //Associating to burn function
        balanceTokenA -= balanceA;
        balanceTokenB -= balanceB;
        priceSwap = balanceA * balanceB;
        _burn(_msgSender(), liquidity);
    }

    // Added deadline and minAmountOut
    function swap(address tokenIn, uint256 amountIn,uint256 minAmountOut, uint deadline) external ensure(deadline) returns (uint256 amountOut) {
        uint256 newBalance;
        uint256 amountInWithFee;
        uint256 feeAmount;

        require(tokenIn == tokenA || tokenIn == tokenB, "TokenIn not in pool");        

        uint256 balanceA = IERC20(tokenA).balanceOf(address(this)); // X
        uint256 balanceB = IERC20(tokenB).balanceOf(address(this)); // Y

        uint256 k = balanceA * balanceB; // K = X * Y   

        if (tokenIn == tokenA) {
            // Adding fee
            feeAmount = (amountIn * LiquiditProviderFee / 1000);
            amountInWithFee = amountIn + feeAmount;
            
            IERC20(tokenA).transferFrom(msg.sender, address(this), amountIn);
            newBalance = k / (balanceA + amountIn);
            amountOut = balanceB - newBalance;
            // Slippage protection added
            require(amountOut >= minAmountOut, "Minimum quantity exceeded");          
            IERC20(tokenB).transfer(msg.sender, amountOut);
            amountFeeTokenA += feeAmount - amountIn;   

        }
        else {
            // Adding fee
            feeAmount = (amountIn * LiquiditProviderFee / 1000);
            amountInWithFee = amountIn + feeAmount;

            IERC20(tokenB).transferFrom(msg.sender, address(this), amountIn);
            newBalance = k / (balanceB + amountIn);
            amountOut = balanceA - newBalance;
            IERC20(tokenA).transfer(msg.sender, amountOut);
            amountFeeTokenB += feeAmount - amountIn;   
        }      
    }
}