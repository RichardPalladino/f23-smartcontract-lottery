// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;


import {Script,console} from "forge-std/Script.sol";

interface Challenge {
    function solveChallenge(uint256 randomGuess, string memory yourTwitterHandle) external;
}

contract SolveChallenge is Script {
    address private userAddress;
    address private challengeAddress;

    function run() external {
        if (block.chainid == 11155111) {
            challengeAddress = 0x33e1fD270599188BB1489a169dF1f0be08b83509;
        } else {
            challengeAddress = 0xdF7cdFF0c5e85c974D6377244D9A0CEffA2b7A86;
        }        
        solveChallenge(challengeAddress);
    }
    function solveChallenge(address _challengeAddress) public {
        uint256 privateKey = vm.envUint("SEPOLIA_PRIVATE_KEY");
        userAddress = vm.addr(privateKey);
        console.log("Attempting to solve challenge on blockchain # %s", block.chainid);
        vm.startBroadcast();
            // address msgSender = msg.sender;
            console.log("Current address: %s", userAddress);
            console.log("Challenge address: %s", _challengeAddress);
            console.log("This address: %s", address(this));
            uint256 guess = uint256(keccak256(abi.encodePacked(userAddress, block.prevrandao, block.timestamp))) % 100000;
            console.log("Guess: %s", guess);
            Challenge challenge = Challenge(_challengeAddress);
            vm.prank(userAddress);
            challenge.solveChallenge(guess, "0xPallad1n0");
        vm.stopBroadcast();
    }
}