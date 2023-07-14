// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script,console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";
import {DevOpsTools} from "../lib/foundry-devops/src/DevOpsTools.sol";

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
        (,, address vrfCoordinator,, uint64 subId,,address linkToken) = helperConfig.activeNetworkConfig();
        fundSubscription(vrfCoordinator, subId, linkToken);
    }

    function fundSubscription(address _vrfCoordinator, uint64 _subId, address _linkToken) public {
        console.log("Funding subscription %s on ChainId %s using %s", _subId, block.chainid, _vrfCoordinator);
        if (block.chainid == 31337) {
            // console.log("Skipping funding on local chain");
            vm.startBroadcast();
            VRFCoordinatorV2Mock(_vrfCoordinator).fundSubscription(_subId, FUND_AMOUNT);
            vm.stopBroadcast(); 
            // return;
        } else {
            vm.startBroadcast();
            LinkToken(_linkToken).transferAndCall(_vrfCoordinator, FUND_AMOUNT, abi.encode(_subId));
            vm.stopBroadcast();
        }
        console.log("Funded subscription");
    }

    function run() external {
        fundSubscriptionUsingConfig();
    }

}


contract AddConsumer is Script {

    function addConsumer(uint64 _subId, address _vrfCoordinator, address _raffle) public {
        console.log("Adding consumer to subscription %s on ChainId %s using %s", _subId, block.chainid, _vrfCoordinator);
        vm.startBroadcast();
        VRFCoordinatorV2Mock(_vrfCoordinator).addConsumer(_subId, _raffle);
        vm.stopBroadcast();
        console.log("Added consumer");
    }
    function addConsumerUsingConfig(address _raffle) public {
        HelperConfig helperConfig = new HelperConfig();
        (,, address vrfCoordinator,, uint64 subId,,) = helperConfig.activeNetworkConfig();
        addConsumer(subId, vrfCoordinator, _raffle);
    }

    function run() external {
        address raffle = DevOpsTools.get_most_recent_deployment("Raffle", block.chainid);
        addConsumerUsingConfig(raffle);
    }

}