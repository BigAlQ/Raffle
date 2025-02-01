// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import  {Script} from "lib/forge-std/src/Script.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {CreateSubscription} from "script/Intereactions.s.sol";

contract DeployRaffle is Script{
    function run() public {}

    function deployContract() public returns(Raffle,HelperConfig){

        HelperConfig helperConfig =  new HelperConfig();
        // local -> deploy mocks, get local config 
        // speolia -> get Sepolia Config
        HelperConfig.NetworkConfig memory config  = helperConfig.getConfig();

        if(config.subscriptionID == 0){
            CreateSubscription createSubscription = new CreateSubscription();
            (config.subscriptionID,config.vrfCoordinator) = createSubscription.createSubscription(config.vrfCoordinator);// creates a Subscription
            // Now we have to fund the subscription with LINK
        }

        vm.startBroadcast();
        Raffle raffle = new Raffle(
            config.entranceFee,
            config.interval,
            config.vrfCoordinator,
            config.gasLane,
            config.subscriptionID,
            config.callbackGasLimit
        );
        vm.stopBroadcast();

        return (raffle,helperConfig );
    }
}

