// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./CallerContract.sol";

// --- ETH LEVERAGE CONTRACT ---
// Main Interface to interact with the CallerContract
//
contract EthLeverager is CallerContract {
    constructor() payable {
        owner = payable(msg.sender);
    }

    //
    // Single Round - Action function to execute the magic within one transaction
    //
    // Input: ExchangeRate DAI/ETH (1855), price tolerance in wei (1000000000)
    function action(uint256 rate, uint256 offset) public payable onlyMyself {
        // Ensure that the exchange rate didn't change dramatically
        uint256 exchangeRate = getExchangeRate();
        require(
            exchangeRate >= rate - offset && exchangeRate <= rate + offset,
            "Exchange Rate might have changed or offset too small"
        );

        uint256 input = msg.value;
        uint256 drawAmount = getMinAndMaxDraw(input)[1];
        uint256 eth_out = drawAmount / (exchangeRate + offset);
        if (proxy == address(0)) {
            buildProxy();
        }
        if (cdpi == 0) {
            openLockETHAndDraw(input, drawAmount);
        } else {
            lockETHAndDraw(input, drawAmount);
        }
        require(daiBalance() > 0, "SR - Problem with lock and draw");
        approveUNIRouter(drawAmount);
        require(daiAllowanceApproved() > 0, "SR - Problem with Approval");
        swapDAItoETH(drawAmount, eth_out);
    }

    //
    // Mulitple Rounds - Action function to execute the magic within one transaction
    //
    // Input: Leverage factor (ex. 150), exchangeRate DAI/ETH (ex. 1855), price tolerance in wei (ex. 1000000000)
    function action(
        uint256 leverage,
        uint256 rate,
        uint256 offset
    ) public payable onlyMyself {
        // Leverage factor cannot be risen above 2.7x
        require(
            leverage >= 100 && leverage < 270,
            "Leverage factor must be somewhere between 100 and 270"
        );

        // Ensure that the exchange rate didn't change dramatically
        uint256 exchangeRate = getExchangeRate();
        require(
            exchangeRate >= rate - offset && exchangeRate <= rate + offset,
            "Exchange Rate might have changed or offset too small"
        );

        // Desired ether amount at the end
        uint256 goal = (msg.value * leverage) / 100;

        if (proxy == address(0)) {
            buildProxy();
        }

        uint256 input = msg.value;
        uint256[2] memory draw = getMinAndMaxDraw(input);
        uint256 minDraw = draw[0];
        uint256 drawAmount = draw[1];
        uint256 eth_out = drawAmount / (exchangeRate + offset);
        uint256 vault = vaultBalance()[0];
        loopCount = 0;
        while ((vault < goal) && (drawAmount > minDraw)) {
            require(drawAmount > 0, "MR - Draw is zero");
            require(eth_out > 0, "MR - ETH out is zero");
            if (cdpi == 0) {
                openLockETHAndDraw(input, drawAmount);
            } else {
                lockETHAndDraw(input, drawAmount);
            }
            require(daiBalance() > 0, "MR - Problem with lock and draw");

            approveUNIRouter(drawAmount);
            require(daiAllowanceApproved() > 0, "MR - Problem with approval");

            swapDAItoETH(drawAmount, eth_out);
            require(address(this).balance > 0, "MR - Problem with the swap");

            input = address(this).balance;
            draw = getMinAndMaxDraw(input);
            minDraw = draw[0];
            drawAmount = draw[1];
            eth_out = drawAmount / (exchangeRate + offset);
            vault = vaultBalance()[0];
            require(vault > 0, "MR - Problem with the vault");
            loopCount += 1;
        }
    }
}
