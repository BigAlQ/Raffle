// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "lib/forge-std/src/Test.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {console} from "lib/forge-std/src/console.sol";
import {Vm} from "lib/forge-std/src/Vm.sol";
import {VRFCoordinatorV2_5Mock} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {CodeConstants} from "script/HelperConfig.s.sol";


contract RaffleTest is Test, CodeConstants {
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


    /*//////////////////////////////////////////////////////////////
                              CHECK UPKEEP
    //////////////////////////////////////////////////////////////*/

    function testCheckUpkeepReturnsFlaseIfItHasNoBalance() public {
        // arrange
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        // act 
        (bool upkeepNeeded,) = raffle.checkUpkeep("");

        // assert
        assert(!upkeepNeeded);

    }

    function testCheckUpkeepReturnsFalseIfRaffleIsntOpen() public {
        // Arrange
        vm.prank(PLAYER);  
        raffle.enterRaffle{value: entranceFee}(); 
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep(""); // <--  this is where ethe code is messing up

        // Act
        (bool upkeepNeeded,) = raffle.checkUpkeep("");

        // Assert
        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsFalseIfNotEnoughTimeHasPassed() public {
        // arrange      
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}(); 
        // act 
        (bool upkeepNeeded,) = raffle.checkUpkeep("");
        // assert
        assert(!upkeepNeeded);
    }   

    function testCheckUpKeepReturnsTrueIfAllCondittionsAreMet() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}(); 
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        // act 
        (bool upkeepNeeded,) = raffle.checkUpkeep("");
        // assert
        assert(upkeepNeeded);

    }

 /*//////////////////////////////////////////////////////////////
                             PREFORMUPKEEP
    //////////////////////////////////////////////////////////////*/

    function testPreformUpkeepCanOnlyRunIfCheckUpkeepIstrue() public {
        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}(); 
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        // Act / Assert
        raffle.performUpkeep(""); //  <--- If this function fails, the test will fail (there is a better way to do this test)
    }

    function testPreformUpkeepRevertsIfCheckUpkeepIsFalse() public {
        // Arrange 
        uint256 currentBalance = 0;  
        uint256  numPlayers = 0;
        Raffle.RaffleState rState = raffle.getRaffleState();

        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        currentBalance = currentBalance + entranceFee;
        numPlayers = 1;

        // Act/Assert
        vm.expectRevert(
            abi.encodeWithSelector(Raffle.Raffle__UpKeepNotNeeded.selector, currentBalance, numPlayers, rState)
        );
        raffle.performUpkeep(""); 

    }

    modifier raffleEntered() {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}(); 
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        _;
    }

    function testPreformUpkeepUpdatesRaffleStateAndEmitsRequestId() public raffleEntered {
        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}(); 
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        //Act
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[0];
        //Assert 
        Raffle.RaffleState raffleState = raffle.getRaffleState(); 
        assert(uint256(requestId) > 0);
        assert(uint256(raffleState) == 1);
    }

      /*//////////////////////////////////////////////////////////////
                           FULFILLRANDOMWORDS
    //////////////////////////////////////////////////////////////*/

    modifier skipFork() {
        if(block.chainid!= LOCAL_CHAIN_ID){
            return;
        }
        _;
    }

    function testFulfillrandomWordsCanOnlyBeCalledAfterPreformUpkeep(uint256 randomRequestId) public raffleEntered skipFork {
            // Arrange / Act / Assert 
            vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector); // InvalidRequest is the name of the error
            VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(randomRequestId, address(raffle));
    }

    function testFulfillRandomWordsPicksAWinnerResetsAndSendsMoney () public raffleEntered skipFork{
        // Arrange 
        uint256 additionalEntrants = 3; // 3 + 1 person = 4 people in the lottery 
        uint256 startingIndex = 1; 
        address expectedWinner = address(1);

        for(uint256 i= startingIndex; i< startingIndex + additionalEntrants; i++){
            address newPlayer = address(uint160(i));
            hoax(newPlayer, 1 ether);
            raffle.enterRaffle{value: entranceFee}();
        }
        uint256 startingTime = raffle.getLastTimeStamp();
        uint256 startingWinnerBalance  = expectedWinner.balance;

        // Act 
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(uint256(requestId), address(raffle));

        // Assert 
        address recentWinner = raffle.getRecentWinner();
        Raffle.RaffleState raffleState = raffle.getRaffleState();
        uint256 winnerBalance = recentWinner.balance;
        uint256 endingTimeStanmp = raffle.getLastTimeStamp();
        uint256 prize = entranceFee * (additionalEntrants + 1);  // 0.01 * 4 = 0.04 

        assert(prize + startingWinnerBalance == winnerBalance);
        assert(expectedWinner ==  recentWinner);
        assert(uint256(raffleState) == 0);
        assert(endingTimeStanmp > startingTime);
        }
}