/* 
TEST TYPES
    Unit Tests
    Integration Tests
    Forked  
    Staging Tests  <-- runs tests on mainnet or testnet
ADDITIONAL TESTS
    Fuzzing 
    stateful fuzz
    stateless fuzz
    formal verificiation <- Turning your code into mathematical proofs
*/



//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import  {Script} from "lib/forge-std/src/Script.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";


contract EnterRaffle is Script{
     Raffle public raffle;
    HelperConfig public helperConfig;

    uint256 entranceFee;    
    uint256 interval; 
    address vrfCoordinator; 
    bytes32 gasLane;
    uint32 callbackGasLimit;
    uint256 subscriptionID;

    address payable public PLAYER = payable(makeAddr("player")); // I added payable
    uint256 public constant STARTING_PLAYER_BALANCE = 10 ether;
    uint256 constant SEND_VALUE = 1 ether;


       /* Events */
    event RaffleEntered(address indexed player);
    event WinnerPicked( address indexed winner);
    
    function setUp() external {
        DeployRaffle deployer = new DeployRaffle(); 
        (raffle,helperConfig) = deployer.deployContract();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        entranceFee = config.entranceFee;
        interval = config.interval; 
        vrfCoordinator = config.vrfCoordinator; 
        gasLane = config.gasLane; 
        callbackGasLimit = config.callbackGasLimit; 
        subscriptionID = config.subscriptionID;

        vm.deal(PLAYER,STARTING_PLAYER_BALANCE);
    }

    function testEnterRaffle()external{
        vm.startBroadcast(); 
        raffle.enterRaffle{value: SEND_VALUE}();        
        vm.stopBroadcast();
    }
}

