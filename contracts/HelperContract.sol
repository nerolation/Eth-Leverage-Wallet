// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Interfaces.sol";

// --- HELPER CONTRACT ---
// Contract stores the state variables and very basic helper functions
//
contract HelperContract {
    address payable owner;
    address DssProxyActions = 0x82ecD135Dce65Fbc6DbdD0e4237E0AF93FFD5038;
    address CPD_MANAGER = 0x5ef30b9986345249bc32d8928B7ee64DE9435E39;
    address MCD_VAT = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;
    address MCD_JUG = 0x19c0976f590D67707E62397C87829d896Dc0f1F1;
    address ETH_JOIN = 0x2F0b23f53734252Bda2277357e97e1517d6B042A;
    address DAI_JOIN = 0x9759A6Ac90977b93B58547b4A71c78317f391A28;
    bytes32 ilk =
        0x4554482d41000000000000000000000000000000000000000000000000000000;
    address DAI_TOKEN = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address UNI_Router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address UNI_Factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address Wrapped_ETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address MCD_PROXY_REGISTRY = 0x4678f0a6958e4D2Bc4F1BAF7Bc52E8F3564f3fE4;
    address MCD_UrnHandler;
    address public proxy;
    uint256 public cdpi;
    uint8 public loopCount;
    DssCdpManagerLike dcml = DssCdpManagerLike(CPD_MANAGER);
    ProxyRegistryLike prl = ProxyRegistryLike(MCD_PROXY_REGISTRY);
    UniswapV2Router02Like url = UniswapV2Router02Like(UNI_Router);
    UniswapV2FactoryLike uv2 = UniswapV2FactoryLike(UNI_Factory);
    TokenLike dai = TokenLike(DAI_TOKEN);
    TokenLike weth = TokenLike(url.WETH());
    VatLike vat = VatLike(MCD_VAT);

    //
    // Modifiers
    //

    // Ensure only the deployer of the contract can interact with ´onlyMyself´ flagged functions
    modifier onlyMyself {
        require(tx.origin == owner, "Your not the owner");
        _;
    }

    // Ensure only the DS Proxy doesn't already have opened a Vault
    modifier NoExistingCDP {
        require(cdpi == 0, "There exists already a CDP");
        _;
    }

    // Ensure only the Contract doesn't already have a DS Proxy
    modifier NoExistingProxy {
        require(proxy == address(0), "There exists already a Proxy");
        _;
    }

    //
    // Helper Function
    //

    // Return minimum and maximum draw amount of DAI
    function getMinAndMaxDraw(uint256 input)
        public
        view
        onlyMyself
        returns (uint256[2] memory)
    {
        (, uint256 rate, uint256 spot, , uint256 dust) = vat.ilks(ilk);
        (uint256 balance, uint256 dept) = vat.urns(ilk, MCD_UrnHandler);
        uint256 ethbalance = balance + input;
        return [dust / rate, (ethbalance * spot) / rate - dept];
    }

    // get Uniswap's exchange rate of DAI/WETH
    function getExchangeRate() public view onlyMyself returns (uint256) {
        (uint256 a, uint256 b) = getTokenReserves_uni();
        return a / b;
    }

    // get token reserves from the pool to determine the current exchange rate
    function getTokenReserves_uni()
        public
        view
        onlyMyself
        returns (uint256, uint256)
    {
        address pair = uv2.getPair(DAI_TOKEN, address(weth));
        (uint256 reserved0, uint256 reserved1, ) =
            UniswapV2PairLike(pair).getReserves();
        return (reserved0, reserved1);
    }

    // This contracts ether balance
    function daiBalance() public view onlyMyself returns (uint256) {
        return dai.balanceOf(address(this));
    }

    // This contracts weth balance
    function wethBalance() public view onlyMyself returns (uint256) {
        return weth.balanceOf(address(this));
    }

    // Check if Uniswap's Router is approved to transfer Dai
    function daiAllowanceApproved() public view onlyMyself returns (uint256) {
        return dai.allowance(address(this), UNI_Router);
    }

    // This contracts' vault balance
    function vaultBalance() public view onlyMyself returns (uint256[2] memory) {
        (uint256 coll, uint256 dept) = vat.urns(ilk, MCD_UrnHandler);
        return [coll, dept];
    }

    // This contracts' vault balance incl. collaterals locked
    function vaultEndBalance() public view onlyMyself returns (uint256) {
        (uint256 coll, ) = vat.urns(ilk, MCD_UrnHandler);
        return address(this).balance + coll;
    }
}
