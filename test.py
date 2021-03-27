from src.EthLeverageWallet import EthLeverage
from web3 import Web3

http_rpc = None  # https://mainnet.infura.io/v3/...

# Automatically takes `w3.eth.accounts[0]` as the main account
i_EthLW = EthLeverage().init(http_rpc)
i_EthLW.buildContract()

value = 50  # 50  Ether
gasPrice = 100  # 100 Gwei
maxGas = 3000000  # 3   Mio.

transaction_value = i_EthLW.w3.toWei(value, "ether")
transaction_gaspr = i_EthLW.w3.toWei(gasPrice, "gwei")


i_EthLW.action(transaction_value, gasPrice=transaction_gaspr)
