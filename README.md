# Ethereum wallet with MakerDao and Uniswap integration
Using MakerDao and Uniswap to leverage ether balances with up to a factor of 2.7 within one transaction

## Usage
#### Prerequisites: 
* Ganache-Cli is globally executable with the command `ganache-cli`
* RPC HTTP Host (ex. [infura.io](infura.io))

#### Run:
###### Make sure to add your RPC HTTP endpoint or (optional) create a text file called `infuraurl` in the project's directory that holds the url for your RPC connection

```python
from DefiLeverageWallet import MyContract
from web3 import Web3

http_rpc = None # https://mainnet.infura.io/v3/...

# Automatically takes `w3.eth.accounts[0]` as the main account
myContract = MyContract().init(http_rpc)
myContract.buildContract()

value = 50       # 50  Ether
gasPrice = 100   # 100 Gwei
maxGas = 3000000 # 3   Mio.

transaction_value = myContract.w3.toWei(value, "ether")
transaction_gaspr = myContract.w3.toWei(gasPrice, "gwei")


myContract.action(transaction_value, gasPrice = transaction_gaspr)
```
## Mainnet-fork test results:

![image](https://user-images.githubusercontent.com/51536394/111901806-6a3c3900-8a3a-11eb-94eb-2e5af6330be1.png)

In the above test case, 50 ETH were sent in to the LeverageWallet
After a single transaction the accounts ETH balance grew to 128 ETH (118 + 110) with an outstanding DAI dept of 141,160 DAI.
50 ETH were leveraged to 128, which results in a laverage-factor of about 2.57x.

The fact that under-collateralized vaults are in risk of liquidations was completely ignored.
This should definatelly not be used in production environments!

Visit [toniwahrstaetter.com](https://toniwahrstaetter.com/) for further details!
<br/><br/><br/>

Anton Wahrstätter, 21.03.2021 
