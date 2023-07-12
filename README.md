# Proveably Random Raffle / Lottery

## Description

Implementation of a proveably random smart contract lottery.

## How it works

1. User enter by paying (a minimum) for a ticket
    * The ticket fees are going to the winner after drawn.
2. After X period of time, the lottery will automatically draw a winner.
    * This will be done programatically.
3. Uses Chainlink VRM and Chainlink Automation -- 
    * Chainlink VRF for randomness
    * Chainlink Automation for time-based trigger to draw winner

## Tests!

1. Write some deploy scripts
2. Write our tests
    * work on a local chain
    * work on a forked testnet
    * work on a forked mainnet

## Solidity code layout

```
// Layout of Contract:
// license identifier
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
// internal & private view & pure functions
// external & public view & pure functions
```