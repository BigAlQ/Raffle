// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import  {Script, console} from "lib/forge-std/src/Script.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";



contract CreateSubscription is Script{
    function createSubscriptionUsingConfig() public returns(uint256, address){
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        (uint256 subId,) = createSubscription(vrfCoordinator);
        return  (subId,vrfCoordinator );    

    }   

    function createSubscription(address VRFCoordinator) public returns(uint256, address) {
        console.log("Creating subscription on chain Id ", block.chainid);
        vm.startBroadcast();
        uint256 subID = VRFCoordinatorV2_5Mock(VRFCoordinator).createSubscription();  // This code is equivelant to going to chainlink and requesting a subscription ID 
        vm.startBroadcast();
        console.log("Your subscription Id is: ", subID);
        console.log("Please update the subscription Id in your HelperConfig.s.sol");
        return  (subID,VRFCoordinator );    

    }


    function run() public {
        createSubscriptionUsingConfig();
    }
}

    contract FundSubscription is Script{
        uint256 public constant FUND_AMOUNT = 3 ether; // Link

        function run() public {}
        function fundSubscriptionUsingConfig() {
            HelperConfig helperConfig = new HelperConfig();
            address vrfCoordinator = helperCOnfig.getConfig().vrfCoordinator;
            uint256 subscriptionId = helperCOnfig.getConfig().subscriptionID;


        }

    }

