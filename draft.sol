// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.0;

contract DssCdpManagerLike {
    mapping (address => uint) public first;     // Owner => First CDPId
    mapping (uint => address) public urns;      // CDPId => UrnHandler
    
}


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
interface ProxyRegistryLike {
    function proxies(address) 
        external 
        view 
        returns (address);
        
    function build() 
        external;
}


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

interface UniswapV2FactoryLike{
    function getPair(address tokenA, 
                     address tokenB
                     ) 
        external 
        view 
        returns (address pair);
}

interface UniswapV2PairLike {   
    function getReserves() 
        external 
        view 
        returns (uint112 reserve0, 
                 uint112 reserve1, 
                 uint32 blockTimestampLast
                );
}




contract HelperContract {
     address payable owner;
     address DssProxyActions = 0x82ecD135Dce65Fbc6DbdD0e4237E0AF93FFD5038;
     address CPD_MANAGER = 0x5ef30b9986345249bc32d8928B7ee64DE9435E39;
     address MCD_VAT = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;
     address MCD_JUG = 0x19c0976f590D67707E62397C87829d896Dc0f1F1;
     address ETH_JOIN = 0x2F0b23f53734252Bda2277357e97e1517d6B042A;
     address DAI_JOIN = 0x9759A6Ac90977b93B58547b4A71c78317f391A28;
     bytes32 ilk = 0x4554482d41000000000000000000000000000000000000000000000000000000;
     address DAI_TOKEN = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
     address UNI_Router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
     address UNI_Factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
     address Wrapped_ETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
     address MCD_PROXY_REGISTRY = 0x4678f0a6958e4D2Bc4F1BAF7Bc52E8F3564f3fE4;
     address MCD_UrnHandler;
     address public proxy;
     uint256 public cdpi;
     DssCdpManagerLike      dcml =  DssCdpManagerLike(CPD_MANAGER);
     ProxyRegistryLike      prl  =  ProxyRegistryLike(MCD_PROXY_REGISTRY);
     UniswapV2Router02Like  url  =  UniswapV2Router02Like(UNI_Router);
     UniswapV2FactoryLike   uv2  =  UniswapV2FactoryLike(UNI_Factory);
     TokenLike              dai  =  TokenLike(DAI_TOKEN);
     TokenLike              weth =  TokenLike(url.WETH());
     VatLike                vat  =  VatLike(MCD_VAT);
     
     
     modifier onlyMyself {
         require(tx.origin == owner, "Your not the owner");
         _;
     }
     
    // Return minimum and maximum draw amount of DAI
    function getMinAndMaxDraw(uint input) public view onlyMyself returns (uint[2] memory) {
        (,uint rate,uint spot,,uint dust) = vat.ilks(ilk);
        return [dust/rate, input*spot/rate];
    }
    
    function getExchangeRate() public view onlyMyself returns(uint) {
         (uint a, uint b) = getTokenReserves_uni() ;
         return a/b;
     }
     
     // get token reserves from the pool to determine the current exchange rate
     function getTokenReserves_uni() public view onlyMyself returns (uint, uint) {
        address pair = uv2.getPair(DAI_TOKEN,address(weth));
        (uint reserved0, uint reserved1,) = UniswapV2PairLike(pair).getReserves();
        return (reserved0, reserved1);
        
    }
        
    function daiBalance() public view onlyMyself returns (uint){
        return dai.balanceOf(address(this));
    }
     
    function wethBalance() public view onlyMyself returns (uint){
        return weth.balanceOf(address(this));
    }
    
    function daiAllowanceApproved() public view onlyMyself returns (uint) {
        return dai.allowance(address(this),UNI_Router);
    }
    
    function vaultBalance() public view onlyMyself returns (uint[2] memory){
        (uint coll, uint dept) = vat.urns(ilk, MCD_UrnHandler);
        return [coll, dept];
    }
     
     
}

contract CallerContract is HelperContract{
    
     

     // build DS Proxy for the CallerContract
     function buildProxy() public {
         prl.build();
         //Safe proxy address to state variable
         proxy = prl.proxies(address(this));
     }

     // Open CDP, lock some Eth and draw Dai
     function openLockETHAndDraw(uint drawAmount) public payable onlyMyself {   
         bytes memory payload = abi.encodeWithSignature("openLockETHAndDraw(address,address,address,address,bytes32,uint256)", 
                            address(dcml), 
                            MCD_JUG, 
                            ETH_JOIN, 
                            DAI_JOIN, 
                            ilk, 
                            drawAmount
                           );
        (bool success, ) = proxy.call{
                value:msg.value
            }(abi.encodeWithSignature(
                "execute(address,bytes)",
                    DssProxyActions, 
                    payload
                    )                          
             );
            cdpi = dcml.first(proxy);
            MCD_UrnHandler = dcml.urns(cdpi);
    }
    
    // Lock some Eth and draw Dai
    function lockETHAndDraw(uint drawAmount) public payable onlyMyself {
        bytes memory payload = abi.encodeWithSignature("lockETHAndDraw(address,address,address,address,uint256,uint256)", 
            address(dcml), 
            MCD_JUG, 
            ETH_JOIN,
            DAI_JOIN, 
            cdpi,
            drawAmount);
        (bool success, ) = proxy.call{
                value:msg.value
            }(abi.encodeWithSignature(
                "execute(address,bytes)",
                DssProxyActions, payload)
             );
    }
    
    // Approve Uniswap to take Dai tokens
    function approveUNIRouter(uint value) 
        public 
        onlyMyself {
            (bool success) = dai.approve(UNI_Router, value);
            require(success);
    }
    
    // Execute Swap from Dai to Weth on Uniswap
    function  swapDAItoWETH(uint value_in, uint value_out) 
        public 
        onlyMyself 
        returns (uint[] memory amounts) {
            address[] memory path = new address[](2);
            path[0] = address(DAI_TOKEN);
            path[1] = url.WETH();
            
            // IN and OUT amounts
            uint amount_in = value_in;
            uint amount_out = value_out;
            amounts = url.swapExactTokensForETH(amount_in,
                                                amount_out, 
                                                path, 
                                                address(this), 
                                                block.timestamp + 60
                                                );
            return amounts;  
    }
    
    // Swap WETH to ETH
    function wethToEthSwap() public onlyMyself {
        weth.withdraw(wethBalance());
    }
    
    // Pay back contract's ether to owner
    function payBack() public onlyMyself {
        owner.transfer(address(this).balance);
    }
    
    fallback() external payable{}
    receive() external payable{}
}

contract EthLeverager is CallerContract {
    
    constructor() payable {
        owner = payable(msg.sender);
    }
    
    function action(uint drawAmount, uint offset) payable onlyMyself public {
        uint exchangeRate = getExchangeRate();
        uint weth_out = (drawAmount/exchangeRate)-offset;
        buildProxy();
        openLockETHAndDraw(drawAmount);
        require(daiBalance()>0, "Problem with lock and draw");
        approveUNIRouter(drawAmount);
        require(daiAllowanceApproved() > 0, "Problem with Approval");
        swapDAItoWETH(drawAmount, weth_out);
        
        
    }
    
    function action(uint leverage, uint rate, uint offset) 
        payable 
        onlyMyself 
        public {
            uint exchangeRate = getExchangeRate();
            require(exchangeRate >= rate - offset 
                                 && 
                    exchangeRate <= rate + offset, "Exchange Rate might have changed or offset too small"
                    );
            uint goal = msg.value*leverage;
    
            
            
            if (proxy == address(0)) {
                buildProxy();
            }
            uint drawAmount = msg.value;
            while (vaultBalance()[0] < goal) {
                
                if (cdpi == 0){
                    openLockETHAndDraw(drawAmount);
                } else {
                    lockETHAndDraw(drawAmount);
                }
                require(daiBalance() > 0, "Problem with lock and draw");
                
                approveUNIRouter(drawAmount);
                require(daiAllowanceApproved() > 0, "Problem with Approval");
                
                uint weth_out = msg.value/(exchangeRate-offset);
                swapDAItoWETH(drawAmount, weth_out);
            
            }
            
        
        
    }
}
