from web3 import Web3
import re
import os
import time


class Helper():
    # Start Ganache client with connection to infura
    # Create web3 instance
    # Recursive function used to first get the latest block and then  
    # ...fork the chain latest possible
    def initiate_ganache(self, latestBlock=1000000, infura_url = None, kill = False):
        if not infura_url:
            with open('infuraurl', "r") as inf:
                infuraUrl = inf.read()
        if kill:
            os.system("pkill -f 'bash -c ganache-cli'")
        command = "ganache-cli -b 10 --fork {}@{}".format(infuraUrl, latestBlock)
        os.system("gnome-terminal -e 'bash -c \"{}; bash\" '".format(command))
        while (latestBlock == 1000000):
            try:
                time.sleep(0.2)
                w3 = Web3(Web3.HTTPProvider('HTTP://127.0.0.1:8545'))
                latestBlock = w3.eth.getBlock("latest").number
                return self.initiate_ganache(latestBlock, kill=True)
            except:
                latestBlock=1000000
                
        w3 = Web3(Web3.HTTPProvider('HTTP://127.0.0.1:8545'))
        while(not w3.eth.default_account):
            time.sleep(0.2)
            try: w3.eth.default_account = w3.eth.accounts[0]
            except: w3.eth.default_account = None
        self.init_balance = w3.eth.get_balance(w3.eth.default_account)
            
        print("Initiated Ganache-Client @ Block Nr. {}\n".format(latestBlock))  
        print("Account initiated     @ {}".format(w3.eth.default_account))
        return w3, latestBlock
    
    def initialize(self, w3):
        with open("contract/abi.txt") as abiFile:
            abi = re.sub("\n|\t|\ ", "", abiFile.read())
        with open("contract/bytecode.txt") as abiFile:
            bytecode = abiFile.read().strip()
        return w3.eth.contract(bytecode = bytecode, abi=abi)
    
    #
    # Contract Calls
    #
    
    # Get balance of CDP/Vault
    def vaultBalance(self):
        collateral, dept = self.contract.functions.vaultBalance().call({"to": self.contract.address})
        return self.w3.fromWei(collateral, "ether"),self.w3.fromWei(dept, "ether")
    
    # Get balance of CDP/Vault incl. locked Ether
    def vaultEndBalance(self):
        balance = self.contract.functions.vaultEndBalance().call({"to": self.contract.address})
        return balance
    
    # Get CDP stats
    def CDPStats(self, base="wei", value=0):
        minDraw, maxDraw = self.contract.functions.getMinAndMaxDraw(value).call({"to": self.contract.address})
        if base == "ether":
            return round(self.w3.fromWei(minDraw, "ether"),2),round(self.w3.fromWei(maxDraw, "ether"),2)
        return minDraw, maxDraw
    
    # Get CDP ID of Contracts Vault
    def CDP_ID(self):
        return self.contract.functions.cdpi().call({"to": self.contract.address})
    
    # Get DS Proxy of Contract
    def proxy(self):
        return self.contract.functions.proxy().call({"to": self.contract.address})
    
    # Get Contracts Ether balance
    def balanceEth(self):
        return self.w3.eth.getBalance(self.contract.address)
    
    # Get Contracts Dai Balance
    def balanceDai(self):
        return self.contract.functions.daiBalance().call({"to": self.contract.address})
    
    # Get Contracts WETH balance
    def balanceWeth(self):
        return self.contract.functions.wethBalance().call({"to": self.contract.address})
    
    # Get exchange rate of DAI/ETH from Uniswap
    def exchangeRate_DAI_ETH(self):
        return self.contract.functions.getExchangeRate().call({"to": self.contract.address})
    
    # Get allowance of Uniswap's Router to spend DAI
    def uniRouterIsAllowed(self):
        return self.contract.functions.daiAllowanceApproved().call({"to": self.contract.address})
    
    def buildTx(self, value = 0, gas = 1000000, gasPrice = 0):
        if gasPrice == 0:
            gasPrice = self.w3.eth.gas_price
        return dict(to = self.contract.address,
                    value = value,
                    gas = gas,
                    gasPrice = gasPrice
                    #nounce 
                    )
    
    def printStats(self, initial_deposit = None, loops = None):
        print("\n\033[4mContract Stats:\033[0m")
        print("Balances:     {:>15} ETH".format(round(self.w3.fromWei(self.balanceEth(), "ether"),5)))
        print("              {:>15} DAI".format(round(self.balanceDai(), 5)))
        print("Dai Approval: {:>15} DAI approved to Uniswap\n\n".format(round(self.uniRouterIsAllowed(), 5)))
        print("\033[4mVault Stats:\033[0m")
        print("Balances:     {:>15} ETH locked".format(round(self.vaultBalance()[0], 5)))
        print("              {:>15} DAI dept".format(round(self.vaultBalance()[1], 5)))
        print("Min Draw:     {:>15} DAI (set by MakerDao)".format(self.CDPStats("ether")[0]))
        print("Possible Draw:{:>15} DAI (...based on locked collaterals)".format(self.CDPStats("ether")[1]))
        print("CDP ID:       {:>15}\n\n".format(self.CDP_ID()))
        if initial_deposit:
            print("Leverage factor: {:>12} %".format(round(self.vaultEndBalance()/initial_deposit*100, 5)))
        if loops:
            print("Total iterations:  {:>10}\n\n".format(loops))
    
    def printOverview(self, gasPrice, gasAmount):
        balance_t0 = self.w3.fromWei(self.init_balance, "ether")
        balance_t1 = self.w3.fromWei(w3.eth.get_balance(self.w3.eth.default_account), "ether")
        gasCosts = self.w3.fromWei(gasAmount * gasPrice, "ether")
        print("Proxy created   {:>50}\n".format("@ "+self.proxy()))
        print("Acc balance_t0: {:>13} ETH".format(balance_t0))
        print("Acc balance_t1: {:>13} ETH\n".format(balance_t1))
        print("\033[4mTransaction Info:\033[0m")
        print("Gas costs (in eth): {:>9} ETH".format(gasCosts))
        print("Gas costs (in USD): {:>9} USD\n".format(round(gasCosts*self.exchangeRate_DAI_ETH(),2)))
        print("Gas price (in gwei): {:>8} GWEI".format(self.w3.fromWei(gasPrice, "gwei")))
        print("Gas amount:         {:>9} GAS".format(gasAmount))

    
class MyContract(Helper):
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
        genesisHash = self.contract.constructor().transact() # Build Contract
        receipt = self.w3.eth.waitForTransactionReceipt(genesisHash, poll_latency=1)
        self.contract.address = receipt.contractAddress
        print("Contract created      {:>44}".format("@ "+ self.contract.address))
        return self
    
    def buildProxy(self):
        txHash = self.contract.functions.buildProxy().transact({"to": self.contract.address}) # Build Proxy
        self.w3.eth.waitForTransactionReceipt(txHash, poll_latency=1)
        self.contract.proxy = self.contract.functions.proxy().call({"to": self.contract.address})
        print("Proxy created      {:>47}".format("@ "+ self.contract.proxy))
        return self
    
    # Open Vault, lock Eth and withdraw Dai
    def openLockETHAndDraw(self, value): # 530,000 Gas needed
        drawAmount = super().CDPStats(value)[1]
        tx = super().buildTx(value)
        txHash = self.contract.functions.openLockETHAndDraw(drawAmount).transact(tx)
        self.w3.eth.waitForTransactionReceipt(txHash, poll_latency=1)
        self.contract.cdpi = super().CDP_ID()
        daibal = round(self.w3.fromWei(super().balanceEth(), "ether"), 5)
        ethbal = round(self.w3.fromWei(super().balanceDai(), "ether"), 5)
        print("CDP/Vault created with ID {}\n".format(self.contract.cdpi))
        print("{:<13} Ether locked into Vault".format(round(self.w3.fromWei(value, "ether"),5)))
        print("{:<13} Dai unlocked from Vault\n".format(round(self.w3.fromWei(drawAmount, "ether"),5)))
        print("New Balance: {:>1} ETH\n{:>17} DAI".format(daibal, ethbal))
        return txHash
    
    # Approve Uniswap to spend Dai
    def approveUniRouter(self, amount = 0):
        if amount == 0:
            amount = super().balanceDai()
        return self.contract.functions.approveUNIRouter(amount).transact({'to':self.contract.address})
    
    # Swap Dai to Eth
    def swapDAItoETH(self): # 530,000 Gas needed
        value_in = super().balanceDai()
        value_out = value_in/super().exchangeRate_DAI_ETH()
        tx = super().buildTx()
        txHash = self.contract.functions.swapDAItoETH(value_in, value_out).transact(tx)
        self.w3.eth.waitForTransactionReceipt(txHash, poll_latency=1)
        print("New Balance: {:>1} ETH\n{:>24} DAI".format(daibal, ethbal))
        return txHash
    
    # High Level Function that starts the leverage
    def action(self, value, gas=3000000, gasPrice=0, leverage_factor=230, offset=20):
        tx = super().buildTx(value, gas=gas, gasPrice=gasPrice)
        rate = self.exchangeRate_DAI_ETH()
        txhash = self.contract.functions.action(leverage_factor, rate, offset).transact(tx)
        print("Transaction published @ {}".format(txhash.hex()))
        gasAmount = self.w3.eth.waitForTransactionReceipt(txhash, poll_latency=1).gasUsed
        loopCount = self.contract.functions.loopCount().call({"to": self.contract.address})
        self.printOverview(gasPrice=gasPrice, gasAmount=gasAmount)
        self.printStats(initial_deposit=value, loops=loopCount) 
        return