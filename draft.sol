pragma solidity 0.8.0;

contract DssCdpManagerLike {
    mapping (address => uint) public first;     // Owner => First CDPId
}

interface ProxyRegistryLike {
    function proxies(address) external view returns (address);
}

contract myCallerContract {
     address DssProxyActions = 0xd1D24637b9109B7f61459176EdcfF9Be56283a7B;
     address CPD_MANAGER = 0x1476483dD8C35F25e568113C5f70249D3976ba21;
     address MCD_JUG = 0xcbB7718c9F39d05aEEDE1c472ca8Bf804b2f1EaD;
     address ETH_JOIN = 0x775787933e92b709f2a3C70aa87999696e74A9F8;
     address DAI_JOIN = 0x5AA71a3ae1C0bd6ac27A1f28e1415fFFB6F15B8c;
     bytes32 ilk = 0x4554482d41000000000000000000000000000000000000000000000000000000;
     address DAI_TOKEN = 0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa;
     address UNI_Router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
     address Wrapped_ETH = 0xd0A1E359811322d97991E03f863a0C30C2cF029C;
     
     DssCdpManagerLike dcml = DssCdpManagerLike(0x1476483dD8C35F25e568113C5f70249D3976ba21);
     address ProxyRegistry = 0x64A436ae831C1672AE81F674CAb8B6775df3475C;
     ProxyRegistryLike prl = ProxyRegistryLike(0x64A436ae831C1672AE81F674CAb8B6775df3475C);
     address public proxy;
     uint256 public cdpi;
     
     
     function buildProxy() public {
         (bool success, ) = ProxyRegistry.call(abi.encodeWithSignature("build()"));
         proxy = prl.proxies(address(this));
     }
     
     function openLockETHAndDraw() public payable {
         (bool success, ) = proxy.call{
                value:msg.value
             }(abi.encodeWithSignature(
                 "execute(address,bytes)",
                 DssProxyActions, 
                 abi.encodeWithSignature("openLockETHAndDraw(address,address,address,address,bytes32,uint256)", CPD_MANAGER, MCD_JUG, ETH_JOIN, DAI_JOIN, ilk, 100000000000000000000)));
             cdpi = dcml.first(proxy);
    }
    
    function approveUNIRouter(uint value) public  {
        (bool success, ) = DAI_TOKEN.call(abi.encodeWithSignature("approve(address,uint256)", UNI_Router, 100000000000000000000));
    }
    
    function  swapThatShit() public  {
        (bool success, ) = UNI_Router.call(abi.encodeWithSignature("swapTokensForExactETH(uint256,uint256,address[],address,uint256)", 10, 100, 
        [DAI_TOKEN,Wrapped_ETH], address(this), block.timestamp + 20000));
    }
    
     function LockETHAndDraw() public payable {
         (bool success, ) = proxy.call{
             value:msg.value
         }(abi.encodeWithSignature("execute(address,bytes)", DssProxyActions, abi.encodeWithSignature("lockETHAndDraw(address,address,address,address,uint256,uint256)", CPD_MANAGER, 
                                                                                                                                                             MCD_JUG, 
                                                                                                                                                             ETH_JOIN, 
                                                                                                                                                            DAI_JOIN, 
                                                                                                                                                             cdpi, 
                                                                                                                                                             100000000000000000000)));
    }
    
    receive() external payable{}
   
    
    
    
    
}
