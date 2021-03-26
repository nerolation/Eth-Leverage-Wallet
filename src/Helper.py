from web3 import Web3
import re
import os
import time


class Helper:
    # Start Ganache client with connection to infura
    # Create web3 instance
    # Recursive function used to first get the latest block and then
    # ...fork the chain latest possible
    def initiate_ganache(self, latestBlock=1000000, infura_url=None):
        if not infura_url:
            with open("infuraurl", "r") as inf:
                infura_url = inf.read().strip()
        command = "ganache-cli -b 10 --fork {}".format(infura_url)
        os.system("gnome-terminal -e 'bash -c \"{}; bash\" '".format(command))
        while latestBlock == 1000000:
            try:
                time.sleep(0.2)
                w3 = Web3(Web3.HTTPProvider("HTTP://127.0.0.1:8545"))
                latestBlock = w3.eth.getBlock("latest").number
            except:
                latestBlock = 1000000

        while not w3.eth.default_account:
            time.sleep(0.2)
            try:
                w3.eth.default_account = w3.eth.accounts[0]
            except:
                w3.eth.default_account = None
        self.init_balance = w3.eth.get_balance(w3.eth.default_account)

        print("Initiated Ganache-Client @ Block Nr. {}\n".format(latestBlock))
        print("Account initiated     @ {}".format(w3.eth.default_account))
        return w3, latestBlock

    def initialize(self, w3):
        with open("build/abi.txt") as abiFile:
            abi = re.sub("\n|\t|\ ", "", abiFile.read())
        with open("build/bytecode.txt") as abiFile:
            bytecode = abiFile.read().strip()
        return w3.eth.contract(bytecode=bytecode, abi=abi)

    #
    # Contract Calls
    #

    # Get balance of CDP/Vault
    def vaultBalance(self):
        collateral, dept = self.contract.functions.vaultBalance().call(
            {"to": self.contract.address}
        )
        return self.w3.fromWei(collateral, "ether"), self.w3.fromWei(dept, "ether")

    # Get balance of CDP/Vault incl. locked Ether
    def vaultEndBalance(self):
        balance = self.contract.functions.vaultEndBalance().call(
            {"to": self.contract.address}
        )
        return balance

    # Get CDP stats
    def CDPStats(self, base="wei", value=0):
        minDraw, maxDraw = self.contract.functions.getMinAndMaxDraw(value).call(
            {"to": self.contract.address}
        )
        if base == "ether":
            return round(self.w3.fromWei(minDraw, "ether"), 2), round(
                self.w3.fromWei(maxDraw, "ether"), 2
            )
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
        return self.contract.functions.getExchangeRate().call(
            {"to": self.contract.address}
        )

    # Get allowance of Uniswap's Router to spend DAI
    def uniRouterIsAllowed(self):
        return self.contract.functions.daiAllowanceApproved().call(
            {"to": self.contract.address}
        )

    def buildTx(self, value=0, gas=1000000, gasPrice=0):
        if gasPrice == 0:
            gasPrice = self.w3.eth.gas_price
        return dict(
            to=self.contract.address,
            value=value,
            gas=gas,
            gasPrice=gasPrice
            # nounce
        )

    def printStats(self, initial_deposit=None, loops=None):
        print("\n\033[4mContract Stats:\033[0m")
        print(
            "Balances:     {:>15} ETH".format(
                round(self.w3.fromWei(self.balanceEth(), "ether"), 5)
            )
        )
        print("              {:>15} DAI".format(round(self.balanceDai(), 5)))
        print(
            "Dai Approval: {:>15} DAI approved to Uniswap\n\n".format(
                round(self.uniRouterIsAllowed(), 5)
            )
        )
        print("\033[4mVault Stats:\033[0m")
        print(
            "Balances:     {:>15} ETH locked".format(round(self.vaultBalance()[0], 5))
        )
        print("              {:>15} DAI dept".format(round(self.vaultBalance()[1], 5)))
        print(
            "Min Draw:     {:>15} DAI (set by MakerDao)".format(
                self.CDPStats("ether")[0]
            )
        )
        print(
            "Possible Draw:{:>15} DAI (...based on locked collaterals)".format(
                self.CDPStats("ether")[1]
            )
        )
        print("CDP ID:       {:>15}\n\n".format(self.CDP_ID()))
        if initial_deposit:
            print(
                "Leverage factor: {:>12} %".format(
                    round(self.vaultEndBalance() / initial_deposit * 100, 5)
                )
            )
        if loops:
            print("Total iterations:  {:>10}\n\n".format(loops))

    def printOverview(self, gasPrice, gasAmount):
        balance_t0 = self.w3.fromWei(self.init_balance, "ether")
        balance_t1 = self.w3.fromWei(
            self.w3.eth.get_balance(self.w3.eth.default_account), "ether"
        )
        gasCosts = self.w3.fromWei(gasAmount * gasPrice, "ether")
        print("Proxy created   {:>50}\n".format("@ " + self.proxy()))
        print("Acc balance_t0: {:>13} ETH".format(balance_t0))
        print("Acc balance_t1: {:>13} ETH\n".format(balance_t1))
        print("\033[4mTransaction Info:\033[0m")
        print("Gas costs (in eth): {:>9} ETH".format(gasCosts))
        print(
            "Gas costs (in USD): {:>9} USD\n".format(
                round(gasCosts * self.exchangeRate_DAI_ETH(), 2)
            )
        )
        print(
            "Gas price (in gwei): {:>8} GWEI".format(self.w3.fromWei(gasPrice, "gwei"))
        )
        print("Gas amount:         {:>9} GAS".format(gasAmount))
