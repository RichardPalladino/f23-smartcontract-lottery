// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
/**
 * @title Raffle - A raffle contract
 * @notice This contract is used for provably-random raffles
 * @dev Implements Chainlink VRFv2 and uses Chainlink Auotmation
 */

contract Raffle is VRFConsumerBaseV2{
    error Raffle__InsufficientEntranceFee();
    error Raffle__NotEnoughTimePassed();
    error Raffle__CalculatingWinner();

    /** Type Declarations */
    enum RaffleState {
        OPEN, // 0
        CALCULATING  // 1
    }
    /** State Variables */
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

    /** Events  */
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
    }

    // 1. Get random number
    // 2. Use random number to pick a player
    // 3. Automatically trigger this function
    function pickWinner() public {
        // confirm enough time has passed by comparing current block time to initial block time + interval
        if (block.timestamp - s_lastTimestamp < i_interval) {
            revert Raffle__NotEnoughTimePassed();
        }
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__CalculatingWinner();
        }
        s_raffleState = RaffleState.CALCULATING;
        uint256 requestId = VRFCoordinatorV2Interface(i_coordinatorAddress).requestRandomWords(
            i_gasHash, // gas lane
            i_subscriptionId, // what I used to fund the subscription
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
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
}
