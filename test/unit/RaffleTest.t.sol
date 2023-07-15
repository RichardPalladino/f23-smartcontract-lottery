// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {Test} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";

contract RaffleTest is DeployRaffle, Test {
    /* events */
    event EnteredRaffle(address indexed player);

    uint256 public constant STARTING_USER_BALANCE = 10 ether;

    Raffle raffle;
    HelperConfig helperConfig;

    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasHash;
    uint64 subscriptionId;
    uint32 callbackGasLimit;
    address linkToken;
    uint256 deployerKey;

    address public PLAYER = makeAddr("player");

    modifier enterRaffle() {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        _;
    }

    modifier passTime() {
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        _;
    }

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.run();
        (entranceFee, interval, vrfCoordinator, gasHash, subscriptionId, callbackGasLimit, linkToken, deployerKey) =
            helperConfig.activeNetworkConfig();
        vm.deal(PLAYER, STARTING_USER_BALANCE);
    }

    // test above setup

    function testRaffleInitializesInOpenState() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    //////////////
    // test enter raffle
    function testRaffleRevertsWhenPaidLessThanFee() public {
        // Arrange
        vm.prank(PLAYER);
        // Act / Assert
        vm.expectRevert(Raffle.Raffle__InsufficientEntranceFee.selector);
        raffle.enterRaffle();
    }

    //////////////
    // test user entry

    // test user is added after entry
    function testUserIsAddedAfterEntry() public enterRaffle {
        // Arrange / Act
        // ....... raffle already entered

        // Assert
        assert(raffle.getPlayers().length == 1);
        assert(raffle.getPlayers()[0] == PLAYER);
    }

    // test entry eventing
    function testEmitsEventOnEntrance() public {
        // Arrange
        vm.prank(PLAYER);
        // Assert/Act
        vm.expectEmit(true, false, false, false, address(raffle));
        emit EnteredRaffle(PLAYER);

        raffle.enterRaffle{value: entranceFee}();
    }

    // test revert if entry after raffle entry closed
    function testRevertWhenEntryClosed() public enterRaffle passTime {
        // Arrange
        // ....... raffle already entered, time passed


        raffle.performUpkeep("");
        // Assert
        vm.expectRevert(Raffle.Raffle__CalculatingWinner.selector);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }

    ///////////////////
    // test checkUpkeep()

    // test checkupkeep() fails if no balance
    function testCheckUpkeepReturnsFalseIfNoBalance() public passTime{
        // Arrange
        // time already passed

        // Act
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        // Assert
        assert(!upkeepNeeded);

    }

    // test checkupkeep() fails if not enough time passed
    function testCheckUpkeepReturnsFalseIfInsfTimePassed() public {
        // Arrange
        vm.warp(block.timestamp + interval - 10);
        // Act
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        // Assert
        assert(!upkeepNeeded);
    }

    // test checkupkeep() fails if raffle not open
    function testCheckUpkeepReturnsFalseIfRaffleNotOpen() public enterRaffle passTime {
        // Arrange
        // ....... raffle already entered, time passed

        raffle.performUpkeep("");

        // Act
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        // Assert
        assert(!upkeepNeeded);
    }

    // test checkupkeep() succeeds when all conditions met
    function testCheckUpkeepReturnsTrue() public enterRaffle passTime{
        // Arrange
        // ....... raffle already entered, time passed

        // Act
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        // Assert
        assert(upkeepNeeded);
    }

    //////////////
    // test performUpkeep()
    //////////////

    function testPerformUpkeepCanOnlyrunIfCheckUpkeepIsTrue() public enterRaffle passTime {
        // Arrange
        // ....... raffle already entered, time passed
        
        // Act / Assert
        raffle.performUpkeep("");
    }

    function testPerformUpkeepFailsIfCheckUpkeepIsFalse() public enterRaffle {
        // Arrange
        // ... raffle already entered
        vm.warp(block.timestamp + interval - 10);
        vm.roll(block.number + 1);

        // Act / Assert
        vm.expectRevert(abi.encodeWithSelector(Raffle.Raffle__UpkeepNotNeeded.selector, 10000000000000000, 1, 0 ));
        raffle.performUpkeep("");
    }

    // test output of events
    function testPerformUpkeepUpdatesAndEmitsRequestId() public enterRaffle passTime {
        // Arrange
        // ....... raffle already entered, time passed
        // Act
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];
        Raffle.RaffleState curState = raffle.getRaffleState();

        // Assert
        assert(requestId != bytes32(0));
        assert(curState != Raffle.RaffleState.OPEN);
    }

    ///////////
    // fulfillRandomWords tests
    ///////////

    // test fulfillRandomWords() can only be called after performUpkeep()
    function testFulfillRandomWordsCanOnlyBeCalledAfterPerformUpkeep(uint256 _randomRequestId) public enterRaffle passTime {
        // Arrange
        // already entered raffle and passed time
        vm.expectRevert("nonexistent request");
        VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(_randomRequestId, address(raffle));
    }

    // test whole shebang success
    function testFulfillRandomWordsPicksWinnerResetsAndSendsFunds() public enterRaffle passTime {
        // Arrange
        // already entered raffle and passed time
        uint256 additionalEntrants = 5;
        uint256 startingIndex = 1;

        for(uint256 i = 1; i < startingIndex + additionalEntrants; i++) {
            address tmp_player = address(uint160(i));
            hoax(tmp_player, entranceFee);
            raffle.enterRaffle{value: entranceFee}();
        }

        uint256 previousTimestamp = raffle.getLastTimestamp();

        // Assert 1
        assert(raffle.getPlayers().length == startingIndex + additionalEntrants);
        assert(address(raffle).balance == (startingIndex + additionalEntrants) * entranceFee);
        // Act         
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(uint256(requestId), address(raffle));
        Raffle.RaffleState curState = raffle.getRaffleState();
 

        // Assert 2
        assert(curState == Raffle.RaffleState.OPEN);
        assert(raffle.getPlayers().length == 0);
        assert(raffle.getRecentWinner() != address(0));
        assert(address(raffle).balance == 0);
        assert(raffle.getLastTimestamp() > previousTimestamp);
        assert(raffle.getRecentWinner().balance == (startingIndex + additionalEntrants) * entranceFee);

    }

}
