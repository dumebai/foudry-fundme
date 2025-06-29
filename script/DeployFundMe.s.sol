// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "../lib/forge-std/src/Script.sol";
import {FundMe} from "../src/FundMe.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployFundMe is Script {
    function run() external returns (FundMe) {
        // before startBroadcast so it's gonna just simulate it. not a "real" tx
        HelperConfig helperConfig = new HelperConfig();
        // (address ethUsdPriceFeed,param2,,param4,) = helperConfig.activeNetworkConfig(); if we had struct with multiple return values
        address ethUsdPriceFeed = helperConfig.activeNetworkConfig();
        vm.startBroadcast();
        // after broadcast -> real tx!
        FundMe fundMe = new FundMe(ethUsdPriceFeed);
        vm.stopBroadcast();
        return fundMe;
    }
}
