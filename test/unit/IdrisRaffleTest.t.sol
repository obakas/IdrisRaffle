// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {DeployIdrisRaffle} from "script/DeployIdrisRaffle.s.sol";
import {IdrisRaffle} from "src/IdrisRaffle.sol";
import {HelperConfig, CodeConstants} from "script/HelperConfig.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2_5Mock} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract IdrisRaffleTest is Test, CodeConstants {
    IdrisRaffle public raffle;
    HelperConfig public helperConfig;

    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_PLAYER_BALANCE = 10 ether;

    /* Events */
    event raffleEntered(address indexed participant);
    event WinnerPicked(address indexed winner);

    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLane;
    uint256 subscriptionId;
    uint32 callbackGasLimit;

    modifier playerEnteredRaffle() {
    vm.prank(PLAYER);
    raffle.enterRaffle{value: entranceFee}();
    vm.warp(block.timestamp + interval + 1);
    vm.roll(block.number + 1);
    _;
}

    modifier skipFork () {
        if (block.chainid != LOCAL_CHAIN_ID){
            return;
        }
        _;
    }

    function setUp() external {
        DeployIdrisRaffle deployer = new DeployIdrisRaffle();
        (raffle, helperConfig) = deployer.deployContract();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        entranceFee = config.entranceFee;
        interval = config.interval;
        vrfCoordinator = config.vrfCoordinatorV2_5;
        gasLane = config.gasLane;
        subscriptionId = config.subscriptionId;
        callbackGasLimit = config.callbackGasLimit;
        vm.deal(PLAYER, STARTING_PLAYER_BALANCE);
    }

    function testRaffleInitialisesInOpenState() public view {
        assert(raffle.getRaffleState() == IdrisRaffle.RaffleState.OPEN);
    }

    function testRaffleRevertsWhenYouDontPayEnough() public {
        vm.prank(PLAYER);

        vm.expectRevert(IdrisRaffle.raffle__SendMoreToEnterRaffle.selector);
        raffle.enterRaffle();
    }

    function testRaffleRecordsPlayersWhenTheyEnter() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        address playerRecorded = raffle.getPlayer(0);
        assert(playerRecorded == PLAYER);
    }

    function testEnteringRaffleEmitsEvent() public {
        vm.prank(PLAYER);
        vm.expectEmit(true, false, false, false, address(raffle));
        emit raffleEntered(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }

    function testDontAllowPlayerToEnterWhileRaffleIsCalculating() public playerEnteredRaffle {
        // arrange
        raffle.performUpkeep("");
        vm.expectRevert(IdrisRaffle.raffle__RaffleNotOpen.selector);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }

    function testCheckUpkeepReturnsFalseIfItHAsNoBalance() public {
        //arrange
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        //act
        (bool upkeepNeeded,) = raffle.checkUpkeep("");
        //assert
        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsFalseIfRaffleIsntOpen () public playerEnteredRaffle{
        //arrange
   
        raffle.performUpkeep("");
        //Act
        (bool upkeepNeeded,) = raffle.checkUpkeep("");
        //assert
        assert(!upkeepNeeded);
    }

    function testPerformUpkeepCanOnlyRunIfCheckUpkeepIsTrue () public playerEnteredRaffle{
        //arrange
  
        //act/assert
        raffle.performUpkeep("");
    }

    function testPerformUpkeepRevertsIfCheckUpkeepIsFalse () public {
        //arrange
        uint256 currentBalance = 0;
        uint256 numPlayers = 0;
        IdrisRaffle.RaffleState rState = raffle.getRaffleState();

        
        //act/assert
        vm.expectRevert(abi.encodeWithSelector(IdrisRaffle.raffle__UpKeepNotNeeded.selector, currentBalance, numPlayers, rState));
        raffle.performUpkeep("");
    }


    //what if we need to get data from emitted events in our tests
    function testPerformUpkeepUpdatesRaffleStateAndEmitsRequestId() public playerEnteredRaffle{
        //arrange
        
        //Account
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];
        //assert
        IdrisRaffle.RaffleState raffleState = raffle.getRaffleState();
        assert (uint256(requestId) > 0);
        assert (uint256(raffleState) == 1);
    }

    function testFufilRandomWordsCanOnlyBeCalledAfterPerformUpkeep (uint256 randomRequestId) public playerEnteredRaffle skipFork{
        //arrange/act/assert
        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(randomRequestId, address(raffle));
    }

    // function testFufilRandomWordsPickAWinnerResetsAndSendMoney () public playerEnteredRaffle {
    //     //arrange
    //     uint256 additionalEntrants = 3;
    //     uint256 startingIndex = 1;
    //     address expectedWinner = address(1);

    //     for(uint256 i = startingIndex; i < startingIndex + additionalEntrants; i++) {
    //         address newPlayer = address(uint160(i));
    //         hoax(newPlayer, 1 ether);
    //         raffle.enterRaffle{value: entranceFee}();
    //     }
    //     uint256 startingTimeStamp = raffle.getLastTimeStamp();
    //     uint256 winnerStartingBalance = expectedWinner.balance;

    //     //Act
    //     vm.recordLogs();
    //     raffle.performUpkeep("");
    //     Vm.Log[] memory entries = vm.getRecordedLogs();
    //     bytes32 requestId = entries[1].topics[1];
    //     VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(uint256(requestId), address(raffle));

    //     //assert
    //     address recentWinner = raffle.getRecentWinner();
    //     IdrisRaffle.RaffleState raffleState = raffle.getRaffleState();
    //     uint256 winnerBalance = recentWinner.balance;
    //     uint256 endingTimeStamp = raffle.getLastTimeStamp();
    //     uint256 prize = entranceFee * (additionalEntrants + 1); 

    //     assert(recentWinner == expectedWinner);
    //     assert(uint256(raffleState) == 0);
    //     assert(winnerBalance == winnerStartingBalance + prize);
    //     assert(endingTimeStamp > startingTimeStamp);
    // }

}
