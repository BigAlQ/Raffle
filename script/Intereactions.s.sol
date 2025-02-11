// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import  {Script, console} from "lib/forge-std/src/Script.sol";
import {CodeConstants} from "script/HelperConfig.s.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "test/Mock/LinkToken.t.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";



contract CreateSubscription is CodeConstants, Script {
    function createSubscriptionUsingConfig() public returns(uint256, address){
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        address account = helperConfig.getConfig().account;
        (uint256 subId,) = createSubscription(vrfCoordinator,account);
        return  (subId,vrfCoordinator);    
    }   

    function createSubscription(address VRFCoordinator, address account) public returns(uint256, address) {
        console.log("Creating subscription on chain Id ", block.chainid);
        vm.startBroadcast(account);
        uint256 subID = VRFCoordinatorV2_5Mock(VRFCoordinator).createSubscription();  // This code is equivelant to going to chainlink and requesting a subscription ID 
        vm.stopBroadcast();
        console.log("Your subscription Id is: ", subID);
        console.log("Please update the subscription Id in your HelperConfig.s.sol");
        return  (subID,VRFCoordinator );    

    }


    function run() public {
        createSubscriptionUsingConfig();
    }
}

    contract FundSubscription is Script, CodeConstants{
        uint256 public constant FUND_AMOUNT = 3 ether; // Link

        function run() public {
            fundSubscriptionUsingConfig();
        }
        function fundSubscriptionUsingConfig() public {
            HelperConfig helperConfig = new HelperConfig();
            address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
            uint256 subscriptionId = helperConfig.getConfig().subscriptionID;
            address linkToken = helperConfig.getConfig().link;
            address account = helperConfig.getConfig().account;
            fundSubscription(vrfCoordinator,subscriptionId,linkToken,account);
        }

        function fundSubscription (
        address vrfCoordinator,
         uint256 subscriptionId,
          address linkToken,
          address account
          ) public {
            console.log("Funding Subscription ", subscriptionId);
            console.log("Using vrfCoordinator",vrfCoordinator);
            console.log("Using link token address",linkToken);

            if (block.chainid == LOCAL_CHAIN_ID){
                vm.startBroadcast(account);
                VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(subscriptionId, FUND_AMOUNT * 100);

                vm.stopBroadcast();
            }
            else{
                vm.startBroadcast(account);
                LinkToken(linkToken).transferAndCall(vrfCoordinator, FUND_AMOUNT, abi.encode(subscriptionId));
                vm.stopBroadcast();
            }



        }

    }   

    contract AddConsumer is Script {
        function addConsumerUsingConfig(address mostRecentlyDeployed) public{
            HelperConfig helperConfig = new HelperConfig();
            uint256 subId = helperConfig.getConfig().subscriptionID;
            address vrfCoordinator =  helperConfig.getConfig().vrfCoordinator;
            address account = helperConfig.getConfig().account; 
            addConsumer(mostRecentlyDeployed,vrfCoordinator,subId, account);
        }
 
        function addConsumer (address contractToAddToVRF, address vrfCoordinator , uint256 subId , address account) public {
            console.log("Adding consumer contract ,", contractToAddToVRF);
            console.log("To vrf coordinator ,", vrfCoordinator);
            console.log("On chain ID , ", block.chainid);
            console.log("Your address is", msg.sender);
            vm.startBroadcast(account);
            VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer(subId, contractToAddToVRF);
            vm.stopBroadcast();
        }

        function run() external {
            address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("Raffle", block.chainid);
            addConsumerUsingConfig(mostRecentlyDeployed);
        }
    }

