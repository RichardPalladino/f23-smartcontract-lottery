// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
/**
 * @title Raffle - A raffle contract
 * @notice This contract is used for provably-random raffles
 * @dev Implements Chainlink VRFv2 and uses Chainlink Auotmation
 */

contract Raffle is VRFConsumerBaseV2 {
    error Raffle__InsufficientEntranceFee();
    error Raffle__NotEnoughTimePassed();
    error Raffle__CalculatingWinner();
    error Raffle__UpkeepNotNeeded(uint256 currentBalance, uint256 numPlayers, uint256 raffleState);

    /**
     * Type Declarations
     */
    enum RaffleState {
        OPEN, // 0
        CALCULATING // 1
    }
    /**
     * State Variables
     */
    // Chainlink VRF

    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval;
    bytes32 private immutable i_gasHash;
    address private immutable i_coordinatorAddress;
    RaffleState private s_raffleState;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    uint32 private constant NUM_WORDS = 1;
    uint16 private constant REQUEST_CONFIRMATIONS = 2;

    // VRF_Coordinator private immutable i_coordinator;

    uint256 private s_lastTimestamp;
    address payable[] private s_players;

    /**
     * Events
     */
    event EnteredRaffle(address indexed player);
    event WinnerPicked(address indexed winner);

    constructor(
        uint256 _entrance_fee,
        uint256 _interval,
        address _vrfCoordinator,
        bytes32 _gasHash,
        uint64 _subscriptionId,
        uint32 _callbackGasLimit
    ) VRFConsumerBaseV2(_vrfCoordinator) {
        // @dev Minimum wei needed to enter the raffle
        i_entranceFee = _entrance_fee;
        // @dev Duration of the lottery in seconds
        i_interval = _interval;
        // @dev Chainlink VRF Coordinator
        i_coordinatorAddress = _vrfCoordinator;
        // @dev Chainlink VRF Key Hash
        i_gasHash = _gasHash;
        // @dev Chainlink VRF Subscription ID
        i_subscriptionId = _subscriptionId;
        i_callbackGasLimit = _callbackGasLimit;
        s_raffleState = RaffleState.OPEN;
    }

    function enterRaffle() external payable {
        if (msg.value < i_entranceFee) {
            revert Raffle__InsufficientEntranceFee();
        }
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__CalculatingWinner();
        }
        if (s_players.length == 0) {
            s_lastTimestamp = block.timestamp;
        }
        s_players.push(payable(msg.sender));

        emit EnteredRaffle(msg.sender);
    }

    // 1. Get random number
    // 2. Use random number to pick a player
    // 3. Automatically trigger this function

    /**
     * @dev Function the Chainlink Automation nodes call to determine if it's time to perform upkeep
     * @dev Returns true if:
     * 1. Time interval has passed between raffle runs
     * 2. Raffle is in OPEN state
     * 3. Contract has ETH
     * 4. (Implicit) Subscription is funded with LINK
     */

    function checkUpkeep(bytes memory /* ckeckData */ )
        public
        view
        returns (bool upkeepNeeded, bytes memory /* upkeepData */ )
    {
        bool timeHasPassed = (block.timestamp - s_lastTimestamp) >= i_interval;
        bool isOpen = RaffleState.OPEN == s_raffleState;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;
        upkeepNeeded = (timeHasPassed && isOpen && hasBalance && hasPlayers);
        return (upkeepNeeded, "");
    }

    /**
     * @dev Function the Chainlink Automation nodes call to perform upkeep
     * @dev Calls the checkUpkeep function to confirm it's time to perform upkeep
     */

    function performUpkeep(bytes calldata /* performData */ ) external {
        (bool upkeepNeeded,) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(address(this).balance, s_players.length, uint256(s_raffleState));
        }
        s_raffleState = RaffleState.CALCULATING;
        // uint256 requestId =
        VRFCoordinatorV2Interface(i_coordinatorAddress).requestRandomWords(
            i_gasHash, // gas lane
            i_subscriptionId, // what I used to fund the subscription
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
    }

    function pickWinner() public {
        // confirm enough time has passed by comparing current block time to initial block time + interval
        if (block.timestamp - s_lastTimestamp < i_interval) {
            revert Raffle__NotEnoughTimePassed();
        }
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__CalculatingWinner();
        }
        s_raffleState = RaffleState.CALCULATING;
        // uint256 requestId =
        VRFCoordinatorV2Interface(i_coordinatorAddress).requestRandomWords(
            i_gasHash, // gas lane
            i_subscriptionId, // what I used to fund the subscription
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
    }

    function fulfillRandomWords(uint256, /* requestId */ uint256[] memory randomWords) internal override {
        uint256 index = randomWords[0] % s_players.length;
        address payable winner = s_players[index];
        winner.transfer(address(this).balance);
        s_raffleState = RaffleState.OPEN;

        s_players = new address payable[](0);
        s_lastTimestamp = block.timestamp;

        emit WinnerPicked(winner);
    }

    // Getter functions

    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }

    function getRaffleState() external view returns (RaffleState) {
        return s_raffleState;
    }

    function getPlayers() external view returns (address payable[] memory) {
        return s_players;
    }
}
