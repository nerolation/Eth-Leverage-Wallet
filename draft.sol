pragma solidity 0.8.0;

contract DssCdpManagerLike {
    mapping (address => uint) public first;     // Owner => First CDPId
}


contract VatLike {
     struct Ilk {
            uint256 Art;   // Total Normalised Debt     [wad]
            uint256 rate;  // Accumulated Rates         [ray]
            uint256 spot;  // Price with Safety Margin  [ray]
            uint256 line;  // Debt Ceiling              [rad]
            uint256 dust;  // Urn Debt Floor            [rad]
        }
    mapping (bytes32 => Ilk) public ilks;
}
interface ProxyRegistryLike {
    function proxies(address) external view returns (address);
    function build() external;
}


interface TokenLike {
    function approve(address usr, uint wad) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}



interface UniswapV2Router02Like {
    function WETH() external returns (address);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) 
    external 
    returns (uint[] memory amounts);
}

interface UniswapV2Factory{
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface UniswapV2Pair {   
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}




contract HelperContract {
     address DssProxyActions = 0xf2A4966bE1e633Fd3A4b7011Ab543b0AA5050047;
     address MCD_JUG = 0x4bc636a867E8B9275aB022C1Ef44d6B24bc65b8d;
     address ETH_JOIN = 0xa885b27E8754f8238DBedaBd2eae180490C341d7;
     address DAI_JOIN = 0xA0b569e9E0816A20Ab548D692340cC28aC7Be986;
     bytes32 ilk = 0x4554482d41000000000000000000000000000000000000000000000000000000;
     address DAI_TOKEN = 0x31F42841c2db5173425b5223809CF3A38FEde360;
     address UNI_Router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
     address private UNI_Factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
     
     DssCdpManagerLike dcml = DssCdpManagerLike(0x033b7629CeC52a41712C362868f6cd70aEFc0545);
     ProxyRegistryLike prl = ProxyRegistryLike(0x1b8357eB14Dd29e4D29AC163342Ee838DeEBCC7f);
     UniswapV2Factory uv2 = UniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
     UniswapV2Router02Like url = UniswapV2Router02Like(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
     TokenLike dai = TokenLike(DAI_TOKEN);
     TokenLike weth = TokenLike(url.WETH());
     
     address public proxy;
     uint256 public cdpi;
     
     function aa() public view returns (uint) {
         return weth.balanceOf(address(this));
     }
     
    // Return minimum draw amount of DAI
    function getMinDraw() public view returns (uint) {
        VatLike vat = VatLike(0xFfCFcAA53b61cF5F332b4FBe14033c1Ff5A391eb);
        (uint Art, uint rate, uint spot , uint line, uint dust) = vat.ilks(ilk);
        
        return dust/rate;
    }
    
    function getExchangeRate() public view returns(uint) {
         (uint a, uint b) = getTokenReserves_uni() ;
         return a/b;
         
     }
     
     // get token reserves from the pool to determine the current exchange rate
     function getTokenReserves_uni() public view returns (uint, uint) {
        
        address pair = uv2.getPair(DAI_TOKEN,address(weth));
        (uint reserved0, uint reserved1,) = UniswapV2Pair(pair).getReserves();
        
        return (reserved0, reserved1);
        
    }
    
        
     function myContractsDaiBalance() public view returns (uint){
         return dai.balanceOf(address(this));
     }
     
     function myContractsWETHBalance() public view returns (uint){
         return weth.balanceOf(address(this));
     }
}

contract myCallerContract is HelperContract{

     // build DS Proxy for the CallerContract
     function buildProxy() public {
         prl.build();
         
         //Safe proxy address to state variable
         proxy = prl.proxies(address(this));
     }

     
     function openLockETHAndDraw(uint value) public payable {         
         // uint drawAmount = (msg.value / 10**18 ) * getExchangeRate() /2;
         (bool success, ) = proxy.call{
                value:msg.value
             }(abi.encodeWithSignature(
                 "execute(address,bytes)",
                 DssProxyActions, 
                 abi.encodeWithSignature("openLockETHAndDraw(address,address,address,address,bytes32,uint256)", address(dcml), MCD_JUG, ETH_JOIN, DAI_JOIN, ilk, value)));
             cdpi = dcml.first(proxy);
    }
    
    function approveUNIRouter(uint value) public  {
        (bool success, ) = DAI_TOKEN.call(abi.encodeWithSignature("approve(address,uint256)", UNI_Router, value));
    }
    
    function  swapThatShit(uint value, uint exchangeRate) public returns (uint[] memory amounts) {
        address[] memory path = new address[](2);
        path[0] = address(DAI_TOKEN);
        path[1] = url.WETH();
        uint amount_in = value;
        uint amount_out = value/exchangeRate;
        uint[] memory amounts = url.swapExactTokensForETH(amount_in, amount_out, path, address(this), block.timestamp + 60);
        return amounts;
    }
    
     function LockETHAndDraw() public payable {
         (bool success, ) = proxy.call{
             value:msg.value
         }(abi.encodeWithSignature("execute(address,bytes)", DssProxyActions, abi.encodeWithSignature("lockETHAndDraw(address,address,address,address,uint256,uint256)", address(dcml), 
                                                                                                                                                             MCD_JUG, 
                                                                                                                                                             ETH_JOIN, 
                                                                                                                                                            DAI_JOIN, 
                                                                                                                                                             cdpi, 
                                                                                                                                                             10000000000000000000)));
    }
    
    function payBack(address payable addr) public {
        addr.transfer(address(this).balance);
        
    }
    
    receive() external payable{}
   
    
    
    
    
}
