// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script,console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

contract CreateSubscription is Script {
    function createSubscriptionUsingConfig() public returns (uint64) {
        HelperConfig helperConfig = new HelperConfig();
        (,, address vrfCoordinator,,,,) = helperConfig.activeNetworkConfig();
        return createSubscription(vrfCoordinator);
    }

    function createSubscription(address _vrfCoordinator) public returns (uint64) {
        console.log("Creating subscription on ChainId: %s", block.chainid);
        vm.startBroadcast();
        uint64 subscriptionId = VRFCoordinatorV2Mock(_vrfCoordinator).createSubscription();
        vm.stopBroadcast();
        console.log("Created subscriptionId: %s", subscriptionId);
        console.log("Please update subscriptionId in HelperConfig.s.sol");
        return subscriptionId;
    }

    // function run() external returns (uint64) {
    //     vm.startBroadcast();

    //     vm.stopBroadcast();
    // }
}

contract FundSubscription is Script {
    uint96 public constant FUND_AMOUNT = 3 ether;

    function fundSubscriptionUsingConfig() public payable {
        HelperConfig helperConfig = new HelperConfig();
        (,, address vrfCoordinator,, uint64 subId,,) = helperConfig.activeNetworkConfig();
        fundSubscription(vrfCoordinator);
    }

    function fundSubscription(address _vrfCoordinator) public payable {
        console.log("Funding subscription on ChainId: %s", block.chainid);
        vm.startBroadcast();
        VRFCoordinatorV2Mock(_vrfCoordinator).fundSubscription{value: msg.value}();
        vm.stopBroadcast();
        console.log("Funded subscription");
    }

    function run() external {
        fundSubscriptionUsingConfig();
    }

}
