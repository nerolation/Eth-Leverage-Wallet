# Ethereum wallet with MakerDao and Uniswap integration
Using MakerDao and Uniswap to leverage ether balances by a factor of up to 2.7 within a single transaction

## Usage
#### Prerequisites: 
* Ganache-Cli is globally executable with the command `ganache-cli`
* RPC HTTP Host (ex. [infura.io](infura.io))

#### Run:
###### Make sure to add your RPC HTTP endpoint or (optional) create a text file called `infuraurl` in the project's directory that holds the url for your RPC connection

```python
from src.EthLeverageWallet import EthLeverage
from web3 import Web3

http_rpc = None  # https://mainnet.infura.io/v3/...

# Automatically takes `w3.eth.accounts[0]` as the main account
i_EthLW = EthLeverage().init(http_rpc)
i_EthLW.buildContract()

value = 50        # 50  Ether
gasPrice = 100    # 100 Gwei
maxGas = 3000000  # 3 Mio.

transaction_value = i_EthLW.w3.toWei(value, "ether")
transaction_gaspr = i_EthLW.w3.toWei(gasPrice, "gwei")


i_EthLW.action(transaction_value, gasPrice=transaction_gaspr)
```
## Mainnet-fork test results:

![image](static/test.png)

In the above test case, 50 ETH were sent in to the LeverageWallet.
After a single transaction the accounts ETH balance grew to 128 ETH (118 + 10) with an outstanding DAI debt of 141,160 DAI.
50 ETH were leveraged to 128, which results in a leverage-factor of about 2.57x.

The fact that under-collateralized vaults are in risk of liquidations was completely ignored.
This should definatelly not be used in production environments!

Visit [toniwahrstaetter.com](https://toniwahrstaetter.com/) for further details!
<br/><br/><br/>

Anton Wahrstätter, 21.03.2021 
