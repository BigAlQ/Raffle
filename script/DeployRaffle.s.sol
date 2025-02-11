// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import  {Script} from "lib/forge-std/src/Script.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "script/Intereactions.s.sol";

contract DeployRaffle is Script{
    function run() public {
        deployContract();
    }

    function deployContract() public returns(Raffle,HelperConfig){
        

        HelperConfig helperConfig =  new HelperConfig();
        // local -> deploy mocks, get local config 
        // speolia -> get Sepolia Config
        HelperConfig.NetworkConfig memory config  = helperConfig.getConfig();

        if(config.subscriptionID == 0){
            CreateSubscription createSubscription = new CreateSubscription();
            (config.subscriptionID,config.vrfCoordinator) = createSubscription.createSubscription(config.vrfCoordinator,config.account);// creates a Subscription
            // Now we have to fund the subscription with LINK

            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(config.vrfCoordinator,config.subscriptionID,config.link, config.account);

        }

        vm.startBroadcast(config.account);
        Raffle raffle = new Raffle(
            config.entranceFee,
            config.interval,
            config.vrfCoordinator,
            config.gasLane,
            config.subscriptionID,
            config.callbackGasLimit
        );
        vm.stopBroadcast();

        AddConsumer addConsumer = new AddConsumer();
        // We dont need a broadcast or a prank because add consumer already has it
        addConsumer.addConsumer(address(raffle),config.vrfCoordinator, config.subscriptionID, config.account);

        return (raffle,helperConfig );
    }
}   

