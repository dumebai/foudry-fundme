// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {PriceConverter} from "./PriceConverter.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

error FundMe__NotOwner(); // naming convention: <ContractName>__<ErrorName> with two underscores

contract FundMe {
    using PriceConverter for uint256;

    uint256 private s_myValue = 1;

    // gas efficient
    uint256 public constant MINIMUM_USD = 5e18; //5 * (10 ** 18);

    address[] private s_funders; // storage variables
    mapping(address funder => uint256 amountFunded)
        private s_addressToAmountFunded;

    // gas efficient
    address private immutable i_owner;

    AggregatorV3Interface private s_priceFeed;

    constructor(address priceFeed) {
        i_owner = msg.sender; // msg.sender exists only inside a function / constructor
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    function fund() public payable {
        // Allow users to send $
        // Have a minimum $ sent

        s_myValue += 2; // Executes, but gets reverted if require doesn't go through
        // If getConversionRate would have had two params, starting with the second, we pass in the brackets
        // example: msg.value.getConversionRate(88);
        require(
            msg.value.getConversionRate(s_priceFeed) > MINIMUM_USD,
            "didn't send enough ETH"
        ); //1e18 = 1 ETH = 1 * 10 ** 18 wei
        // What is a revert?
        // Undo any actions that have been done, and send the remaining gas back

        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] += msg.value;
    }

    function cheaperWithdraw() public onlyOwner {
        uint256 fundersLength = s_funders.length; // not reading from storage on every iteration, like a loser
        for (
            uint256 funderIndex = 0;
            funderIndex < fundersLength;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        (bool callSuccess /*bytes memory dataReturned*/, ) = payable(msg.sender)
            .call{value: address(this).balance}("");
        require(callSuccess, "call failed");
    }

    function withdraw() public onlyOwner {
        // require(msg.sender == owner, "must be owner");
        for (
            /* starting index, ending index, step amount*/ uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        // reset the funders array
        s_funders = new address[](0);
        // withdraw the funds

        // msg.sender = address
        // payable(msg.sender) = payable address
        // transfer - capped at 2300 gas, throws error
        // payable(msg.sender).transfer(address(this).balance);

        // send - also capped at 2300 gas, returns bool
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "send failed");

        //call
        (bool callSuccess /*bytes memory dataReturned*/, ) = payable(msg.sender)
            .call{value: address(this).balance}("");
        require(callSuccess, "call failed");
    }

    // Modifiers - functions that can only be called by the contract
    // modifier = a keyword to run some code at runtime when a function is called
    modifier onlyOwner() {
        // _; - order matters
        // require(msg.sender == i_owner, "only the owner can call this function.");
        if (msg.sender != i_owner) {
            // revert => send the gas back to the user
            revert FundMe__NotOwner();
        }
        _; // do whatever's next in the function
    }

    function getVersion() public view returns (uint256) {
        return s_priceFeed.version();
    }

    // What happens if someone sends this contract ETH without calling the fund function?

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    // fallback()

    /**
     * View / Pure functions (Getters)
     */

    function getAddressToAmountFunded(
        address fundingAddress
    ) external view returns (uint256) {
        return s_addressToAmountFunded[fundingAddress];
    }

    function getFunder(uint256 index) external view returns (address) {
        return s_funders[index];
    }

    function getOwner() external view returns (address) {
        return i_owner;
    }
}
