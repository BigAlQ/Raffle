// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {VRFConsumerBaseV2Plus} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {console} from "lib/forge-std/src/console.sol";


/**
 * @title A sample Raffle contract
 * @author Alqasem Hasan
 * @notice  This contract is for creating a sample raffle
 * @dev Implements Chainlink VRFv2.5
 */
contract Raffle is VRFConsumerBaseV2Plus {
    /* Errors */
    error Raffle__SendMoreToEnterRaffle();
    error Raffle__TransferFailed();
    error Raffle__RaffleNotOpen();
    error Raffle__UpKeepNotNeeded(uint256 balance, uint256 playersLength, uint256 raffleState);

    /* Type Declarations */
    enum RaffleState {
        OPEN,
        CALCULATING
    }

    /* State Variables */
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval;
    bytes32 private immutable i_keyHash;
    uint256 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit = 10000;
    address payable[] private s_players;
    uint256 private s_lastTimeStamp;
    address private s_recentWinenr;
    RaffleState private s_raffleState;

    /* Events */
    event RaffleEntered(address indexed player);
    event WinnerPicked( address indexed winner);
    event RequestedRaffleWinner (uint256 indexed requestId);

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfcoordinator,
        bytes32 gasLane,
        uint256 subscriptionID,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(vrfcoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        i_keyHash = gasLane;
        i_subscriptionId = subscriptionID;
        i_callbackGasLimit = callbackGasLimit;

        s_lastTimeStamp = block.timestamp;
        s_raffleState = RaffleState.OPEN;
    }

    function enterRaffle() external payable {
        console.log("TEST");
        // require(msg.value >= i_entranceFee,SendMoreToEnterRaffle());
        // require(msg.value >= i_entranceFee, "Not enough ETH sent!" );
        if (msg.value < i_entranceFee) {
            console.log("Revert1");
            revert Raffle__SendMoreToEnterRaffle();
        }
        if(s_raffleState != RaffleState.OPEN){
            console.log("Revert2");
            revert Raffle__RaffleNotOpen(); 
        }
        s_players.push(payable(msg.sender));
        emit RaffleEntered(msg.sender);
        console.log("Player added:", msg.sender);

    }
    /**
     *@dev This is the function that the chainlink nodes will call to see if the lottery is ready to 
     * have a winner picked.
     * The following should be true in order for upkeepNeeded to be true:
     * 1. The time interval has passed between raffle runs
     * 2. The lottery is open
     * 3. The contract has ETH
     * 4. Implicitly, your subscription has Link
     *@param - ignored
     *@return upkeepNeeded - true if it's time to restart the lottery 
     *@return -ignored  
     */
    function checkUpkeep(bytes memory /* checkData */) 
    public 
    view 
    returns (bool upkeepNeeded, bytes memory /* preformData*/ )
    { 
        bool timeHasPassed = ((block.timestamp - s_lastTimeStamp) >= i_interval); 
        bool isOpen = s_raffleState == RaffleState.OPEN;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;
        upkeepNeeded = timeHasPassed && isOpen && hasBalance && hasPlayers;
        return (upkeepNeeded,"");
        }

    

    function performUpkeep(bytes calldata /* preformData*/) external {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if(!upkeepNeeded){
            revert Raffle__UpKeepNotNeeded(address(this).balance, s_players.length, uint256(s_raffleState));
        }

        s_raffleState = RaffleState.CALCULATING; 

        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient.RandomWordsRequest({
            keyHash: i_keyHash,
            subId: i_subscriptionId,
            requestConfirmations: REQUEST_CONFIRMATIONS,
            callbackGasLimit: i_callbackGasLimit,
            numWords: NUM_WORDS,
            extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: false}))
        });

        uint256 requestId = s_vrfCoordinator.requestRandomWords(request);
        emit RequestedRaffleWinner(requestId);  /* the VRF coordinator is already emmitting an event so this is redundant */
    }

    function fulfillRandomWords(uint256, /*requestId,*/ uint256[] calldata   randomWords) internal override {
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinenr = recentWinner;
        s_raffleState = RaffleState.OPEN;

        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;

        // What if someone joins the raffle in between the time it takes to run the past line of code and the next one

        (bool success,) = recentWinner.call{value: address(this).balance}("");
        if(!success) {
            revert Raffle__TransferFailed();
        }
        emit WinnerPicked(s_recentWinenr);


    }

    /**
     * Getter Functions
     */
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }

    function getRaffleState() external view returns 
    (RaffleState) {
        return s_raffleState;
    }

    function getPlayer(uint256 indexOfPlayer) external view returns
     (address) {
        return s_players[indexOfPlayer];
    }

    function getLastTimeStamp() external view returns 
    (uint256) {
        return s_lastTimeStamp;
    }

    function getRecentWinner() external view returns 
    (address) {
        return s_recentWinenr;
    }

    function returnPlayers() external view returns (address[] memory) {
    address[] memory players = new address[](s_players.length);
    for (uint256 i = 0; i < s_players.length; i++) {
        players[i] = s_players[i]; // Explicitly copy from storage to memory
    }
    return players;
}
}
