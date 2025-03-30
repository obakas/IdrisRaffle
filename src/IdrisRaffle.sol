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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;



import {VRFConsumerBaseV2Plus} from
    "../lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from
    "../lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
/**
 * @title IdrisRaffle
 * @author Idris Obaka George
 * @dev IdrisRaffle is a contract for managing a raffle.
 */

contract IdrisRaffle is VRFConsumerBaseV2Plus {
    /* errors */
    /// @dev Thrown when the entrance fee provided is incorrect.
    error raffle__SendMoreToEnterRaffle();
    error raffle__TransferFailed();
    error raffle__RaffleNotOpen();
    error raffle__UpKeepNotNeeded(uint256 balance, uint256 participants, uint256 raffleState);

    /* Type declarations */
    enum RaffleState {
        OPEN,
        CALCULATING
    }

    /* State variables */
    uint256 private immutable i_entranceFee;
    address payable[] private s_participants;
    uint256 private immutable i_interval;
    uint256 private s_lastTimeStamp;
    bytes32 private immutable i_keyHash;
    uint256 private immutable i_subscriptionId;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private immutable i_callbackGasLimit;
    uint32 private constant NUM_WORDS = 1;
    address private s_winner;
    RaffleState private s_raffleState;

    /* Events */
    event raffleEntered(address indexed participant);
    event WinnerPicked(address indexed winner);
    event RequstedRaffleWinner(uint256 indexed requsetId);

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint256 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
        i_keyHash = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_raffleState = RaffleState.OPEN;
    }

    function enterRaffle() external payable {
        if (msg.value < i_entranceFee) {
            revert raffle__SendMoreToEnterRaffle();
        }
        if (s_raffleState == RaffleState.CALCULATING) {
            revert raffle__RaffleNotOpen();
        }
        s_participants.push(payable(msg.sender));
        emit raffleEntered(msg.sender);
    }

    function checkUpkeep(bytes memory) public view returns (bool upkeepNeeded, bytes memory /* performData */ ) {
        bool timeHasPassed = (block.timestamp - s_lastTimeStamp) >= i_interval;
        bool isOpen = s_raffleState == RaffleState.OPEN;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_participants.length > 0;
        upkeepNeeded = timeHasPassed && isOpen && hasBalance && hasPlayers;
        return (upkeepNeeded, "");
    }

    function performUpkeep(bytes calldata /* performData */ ) external {
        (bool upKeepNeeded,) = checkUpkeep("");
        if (!upKeepNeeded) {
            revert raffle__UpKeepNotNeeded(address(this).balance, s_participants.length, uint256(s_raffleState));
        }
        s_raffleState = RaffleState.CALCULATING;
        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient.RandomWordsRequest({
            keyHash: i_keyHash,
            subId: i_subscriptionId,
            requestConfirmations: REQUEST_CONFIRMATIONS,
            callbackGasLimit: i_callbackGasLimit,
            numWords: NUM_WORDS,
            extraArgs: VRFV2PlusClient._argsToBytes(
                // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
            )
        });
        uint256 requsetId = s_vrfCoordinator.requestRandomWords(request);
        emit RequstedRaffleWinner(requsetId);
    }

    //CEI: checks, effects, interactions pattern
    function fulfillRandomWords(uint256, /* requestId */ uint256[] calldata randomWords) internal override {
        //checks
        //effects (internal contract state)
        uint256 winnerIndex = randomWords[0] % s_participants.length;
        address payable recentWinner = s_participants[winnerIndex];
        s_winner = recentWinner;
        s_raffleState = RaffleState.OPEN;
        s_participants = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        (bool success,) = recentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert raffle__TransferFailed();
        }
        emit WinnerPicked(s_winner);
    }

    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }

    function getRaffleState() external view returns (RaffleState) {
        return s_raffleState;
    }

    function getPlayer(uint256 indexOfPlayer) external view returns (address) {
        return s_participants[indexOfPlayer];
    }

    function getLastTimeStamp() external view returns (uint256){
        return s_lastTimeStamp;
    }

    function getRecentWinner() external view returns (address){
        return s_winner;
    }
}
