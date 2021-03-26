from web3 import Web3
import re
import os
import time
from src.Helper import Helper


class EthLeverage(Helper):
    def __init__(self):
        self.w3 = None
        self.latestBlock = None
        self.contract = None

    def init(self, infuraurl=None):
        global w3
        self.w3, self.latestBlock = super().initiate_ganache(infura_url=infuraurl)
        self.contract = super().initialize(self.w3)
        w3 = self.w3
        return self

    # Deploy contract and initiate proxy
    def buildContract(self):
        genesisHash = self.contract.constructor().transact()  # Build Contract
        receipt = self.w3.eth.waitForTransactionReceipt(genesisHash, poll_latency=1)
        self.contract.address = receipt.contractAddress
        print("Contract created      {:>44}".format("@ " + self.contract.address))
        return self

    def buildProxy(self):
        txHash = self.contract.functions.buildProxy().transact(
            {"to": self.contract.address}
        )  # Build Proxy
        self.w3.eth.waitForTransactionReceipt(txHash, poll_latency=1)
        self.contract.proxy = self.contract.functions.proxy().call(
            {"to": self.contract.address}
        )
        print("Proxy created      {:>47}".format("@ " + self.contract.proxy))
        return self

    # Open Vault, lock Eth and withdraw Dai
    def openLockETHAndDraw(self, value):  # 530,000 Gas needed
        drawAmount = super().CDPStats(value)[1]
        tx = super().buildTx(value)
        txHash = self.contract.functions.openLockETHAndDraw(drawAmount).transact(tx)
        self.w3.eth.waitForTransactionReceipt(txHash, poll_latency=1)
        self.contract.cdpi = super().CDP_ID()
        daibal = round(self.w3.fromWei(super().balanceEth(), "ether"), 5)
        ethbal = round(self.w3.fromWei(super().balanceDai(), "ether"), 5)
        print("CDP/Vault created with ID {}\n".format(self.contract.cdpi))
        print(
            "{:<13} Ether locked into Vault".format(
                round(self.w3.fromWei(value, "ether"), 5)
            )
        )
        print(
            "{:<13} Dai unlocked from Vault\n".format(
                round(self.w3.fromWei(drawAmount, "ether"), 5)
            )
        )
        print("New Balance: {:>1} ETH\n{:>17} DAI".format(daibal, ethbal))
        return txHash

    # Approve Uniswap to spend Dai
    def approveUniRouter(self, amount=0):
        if amount == 0:
            amount = super().balanceDai()
        return self.contract.functions.approveUNIRouter(amount).transact(
            {"to": self.contract.address}
        )

    # Swap Dai to Eth
    def swapDAItoETH(self):  # 530,000 Gas needed
        value_in = super().balanceDai()
        value_out = value_in / super().exchangeRate_DAI_ETH()
        tx = super().buildTx()
        txHash = self.contract.functions.swapDAItoETH(value_in, value_out).transact(tx)
        self.w3.eth.waitForTransactionReceipt(txHash, poll_latency=1)
        print("New Balance: {:>1} ETH\n{:>24} DAI".format(daibal, ethbal))
        return txHash

    # High Level Function that starts the leverage
    def action(self, value, gas=3000000, gasPrice=0, leverage_factor=230, offset=20):
        tx = super().buildTx(value, gas=gas, gasPrice=gasPrice)
        rate = self.exchangeRate_DAI_ETH()
        txhash = self.contract.functions.action(leverage_factor, rate, offset).transact(
            tx
        )
        print("Transaction published @ {}".format(txhash.hex()))
        gasAmount = self.w3.eth.waitForTransactionReceipt(
            txhash, poll_latency=1
        ).gasUsed
        loopCount = self.contract.functions.loopCount().call(
            {"to": self.contract.address}
        )
        self.printOverview(gasPrice=gasPrice, gasAmount=gasAmount)
        self.printStats(initial_deposit=value, loops=loopCount)
        return
