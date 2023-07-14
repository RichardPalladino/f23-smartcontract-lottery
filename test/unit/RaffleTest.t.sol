// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {Test, console} from "forge-std/Test.sol";

contract RaffleTest is DeployRaffle {
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
        (entranceFee, interval, vrfCoordinator, gasHash, subscriptionId, callbackGasLimit, linkToken) =
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
        // // Arrange
        // vm.prank(PLAYER);
        // // Act
        // raffle.enterRaffle{value: entranceFee}();
        // Assert
        assert(raffle.getPlayers().length == 1);
        assert(raffle.getPlayers()[0] == PLAYER);
    }

    // test entry eventing
    function testEmitsEventOnEntrance() public {
        vm.prank(PLAYER);
        vm.expectEmit(true, false, false, false, address(raffle));
        emit EnteredRaffle(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }

    // test revert if entry after raffle entry closed
    function testRevertWhenEntryClosed() public enterRaffle passTime {
        // // Arrange
        // vm.prank(PLAYER);
        // // Act
        // raffle.enterRaffle{value: entranceFee}();
        // vm.warp(block.timestamp + interval + 1);
        // vm.roll(block.timestamp + 1);
        raffle.performUpkeep("");
        // Assert
        vm.expectRevert(Raffle.Raffle__CalculatingWinner.selector);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }

    ///////////////////
    // test checkUpkeep()

    // test checkupkeep() fails if no balance
    function testCheckUpkeepReturnsFalseIfNoBalance() public {
        // Arrange
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
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
    function testCheckUpkeepReturnsFalseIfRaffleNotOpen() public enterRaffle {
        // // Arrange
        // vm.prank(PLAYER);
        // raffle.enterRaffle{value: entranceFee}();
        
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");
        // Act
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        // Assert
        assert(!upkeepNeeded);
    }

    // test checkupkeep() succeeds when all conditions met
    function testCheckUpkeepReturnsTrue() public enterRaffle{
        // // Arrange
        // vm.prank(PLAYER);
        // raffle.enterRaffle{value: entranceFee}();

        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        // Act
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        // Assert
        assert(upkeepNeeded);
    }

    //////////////
    // test performUpkeep()
    //////////////

    function testPerformUpkeepCanOnlyrunIfCheckUpkeepIsTrue() public enterRaffle {
        // // Arrange
        // vm.prank(PLAYER);
        // raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        // Act / Assert
        raffle.performUpkeep("");
    }

    function testPerformUpkeepFailsIfCheckUpkeepIsFalse() public enterRaffle {
        // // Arrange
        // vm.prank(PLAYER);
        // raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval - 10);
        vm.roll(block.number + 1);

        // Act / Assert
        vm.expectRevert(abi.encodeWithSelector(Raffle.Raffle__UpkeepNotNeeded.selector, 10000000000000000, 1, 0 ));
        raffle.performUpkeep("");
    }

    // test output of events
    function testPerformUpkeepUpdatesAndEmitsRequestId() public enterRaffle {
        // Arrange
        // ....... raffle already entered
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

    }

}
