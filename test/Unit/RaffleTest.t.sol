// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "lib/forge-std/src/Test.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {console} from "lib/forge-std/src/console.sol";

contract RaffleTest is Test {
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
    function testRaffleInitilizesInOpenState() public view{
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }
       /*//////////////////////////////////////////////////////////////
                              ENTER RAFFLE
    //////////////////////////////////////////////////////////////*/

    function testRaffleRevertsWhenYouDontPayEnough() public{
        // Arrange 
        vm.prank(PLAYER);  
        // Act / Assert
        vm.expectRevert(Raffle.Raffle__SendMoreToEnterRaffle.selector);
        raffle.enterRaffle();      
    }

    function testRaffleRecordsPlayersWhenTheyEnter() public{
        // Arrance
        vm.prank(PLAYER);  
        // Act
        console.log("The entrance fee value is",entranceFee);
        raffle.enterRaffle{value:entranceFee}();
        // Assert
        console.log("The length of the players array is", raffle.returnPlayers().length);
        address playerRecorded = raffle.getPlayer(0);
        assert(playerRecorded == PLAYER);
    }

    function testEnteringRaffleEmitsEvent () public {
    //Arrange 
     vm.prank(PLAYER);  
    // Act
     vm.expectEmit(true,false,false,false, address(raffle)); // The last element is the element that will emit the event. We only have one indexed variable so 1 true
     emit RaffleEntered(PLAYER);   // Hey foundry, This is the event we are expecting to emit foundry.
    // Assert
    raffle.enterRaffle{value: entranceFee}(); // Now lets see if the event is emitted
    }

    function testDontAllowPlayersToEnterWhileRaffleIsCalculating () public {
        // Arrange
        vm.prank(PLAYER);  
        raffle.enterRaffle{value: entranceFee}(); 
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep(""); // <--  this is where ethe code is messing up

        // Act/Assert
        vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
        vm.prank(PLAYER);  
        raffle.enterRaffle{value: entranceFee}(); 

    }
}   