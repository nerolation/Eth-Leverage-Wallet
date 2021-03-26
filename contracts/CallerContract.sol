// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./HelperContract.sol";


// --- CALLER CONTRACT ---
// Contract stores the functions that interact with the protocols of MakerDao and Uniswap
//
contract CallerContract is HelperContract{
    
     // Build DS Proxy for the CallerContract
     function buildProxy() NoExistingProxy public {
         prl.build();
         proxy = prl.proxies(address(this)); // Safe proxy address to state variable
     }

     // Open CDP, lock some Eth and draw Dai
     function openLockETHAndDraw(uint input, uint drawAmount) public payable onlyMyself NoExistingCDP {   
         bytes memory payload = abi.encodeWithSignature("openLockETHAndDraw(address,address,address,address,bytes32,uint256)", 
                                    address(dcml), 
                                    MCD_JUG, 
                                    ETH_JOIN, 
                                    DAI_JOIN, 
                                    ilk, 
                                    drawAmount
                                    );
                                    
       (bool success, ) = proxy.call{
                value:input
            }(abi.encodeWithSignature(
                "execute(address,bytes)",
                    DssProxyActions, payload)
             );
                    
        cdpi = dcml.first(proxy);
        MCD_UrnHandler = dcml.urns(cdpi);
    }
    
    // Lock some Eth and draw Dai
    function lockETHAndDraw(uint input, uint drawAmount) public payable onlyMyself {
        bytes memory payload = abi.encodeWithSignature("lockETHAndDraw(address,address,address,address,uint256,uint256)", 
                                   address(dcml), 
                                   MCD_JUG, 
                                   ETH_JOIN,
                                   DAI_JOIN, 
                                   cdpi,
                                   drawAmount
                                   );
                                   
        (bool success, ) = proxy.call{
                value:input
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
    function swapDAItoETH(uint value_in, uint value_out) 
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
    function wethToEthSwap() 
        public 
        onlyMyself {
            weth.withdraw(wethBalance());
    }
    
    // Pay back contract's ether to owner
    function payBack() 
        public 
        onlyMyself {
            owner.transfer(address(this).balance);
    }
    
    fallback() external payable{}
    receive() external payable{}
}
