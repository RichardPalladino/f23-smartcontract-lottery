// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;


import {Script,console} from "forge-std/Script.sol";
import {SolveChallenge} from "../src/SolveChallenge.sol";

interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface Challenge {
    function solveChallenge(uint256 randomGuess, string memory yourTwitterHandle) external;
}

contract SolveChallengeScript is Script {
    address private userAddress;
    address private challengeAddress;
    uint256 private tokenId;
    address private NFTAddress;

    function run() external {
        solveChallenge();
    }
    function solveChallenge() public {
        console.log("Attempting to solve challenge on blockchain # %s", block.chainid);
        vm.startBroadcast();

        SolveChallenge challengeSolver = new SolveChallenge();
        console.log("SolveChallenge address: %s",address(challengeSolver) );
        console.log("Operator: %s", challengeSolver.nftOperator());
        console.log("From: %s", challengeSolver.nftFrom());
        console.log("TokenId: %s", challengeSolver.nftTokenId());
        console.log("NFT Contract: %s", challengeSolver.nftContract());
        vm.stopBroadcast();

    }

}