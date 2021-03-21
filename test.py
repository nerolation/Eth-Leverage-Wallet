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