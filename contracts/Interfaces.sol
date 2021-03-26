// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// --- INTERFACES ---
// Interfaces for Uniswap and MakerDao
//

// CDP Interface
contract DssCdpManagerLike {
    mapping (address => uint) public first;     // Owner => First CDPId
    mapping (uint => address) public urns;      // CDPId => UrnHandler
}

// Vat Interface
contract VatLike {
    struct Ilk {
            uint256 Art;   // Total Normalised Debt     [wad]
            uint256 rate;  // Accumulated Rates         [ray]
            uint256 spot;  // Price with Safety Margin  [ray]
            uint256 line;  // Debt Ceiling              [rad]
            uint256 dust;  // Urn Debt Floor            [rad]
    }
    struct Urn {
        uint256 ink;   // Locked Collateral  [wad]
        uint256 art;   // Normalised Debt    [wad]
    }
    mapping (bytes32 => Ilk) public ilks;
    mapping (bytes32 => mapping (address => Urn)) public urns;
}

// Proxy Registry Interface
interface ProxyRegistryLike {
    function proxies(address) 
        external 
        view 
        returns (address);
    
    // build proxy contract
    function build() 
        external;
}

// Very basic Erc-20 like token interface
interface TokenLike {
    function approve(address usr, uint wad) 
        external 
        returns (bool);
    function balanceOf(address account) 
        external 
        view 
        returns (uint256);
    function withdraw(uint wad) external;
    function allowance(address owner,address spender)
        external 
        view 
        returns (uint256);
}

// Uniswap Router Interface
interface UniswapV2Router02Like {
    function WETH() external returns (address);
    function swapExactTokensForETH(uint amountIn, 
                                   uint amountOutMin, 
                                   address[] calldata path, 
                                   address to, 
                                   uint deadline
                                   ) 
        external 
        returns (uint[] memory amounts);
}

// Uniswap Factory Interface
interface UniswapV2FactoryLike{
    function getPair(address tokenA, 
                     address tokenB
                     ) 
        external 
        view 
        returns (address pair);
}

// Uniswap Pair Interface
interface UniswapV2PairLike {   
    function getReserves() 
        external 
        view 
        returns (uint112 reserve0, 
                 uint112 reserve1, 
                 uint32 blockTimestampLast
                );
}