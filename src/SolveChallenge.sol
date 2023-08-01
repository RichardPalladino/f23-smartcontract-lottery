
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;


import {Script,console} from "forge-std/Script.sol";

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

interface IERC721 {
    function transferFrom(address from, address to, uint256 tokenId) external;
}

interface Challenge {
    function solveChallenge(uint256 randomGuess, string memory yourTwitterHandle) external;
}


contract SolveChallenge {
    address challengeAddress;
    address public userAddress = 0xE46Ba3A5fD86ED9776F7c55497efBcCF1e58F3B2;

    address public nftOperator;
    address public nftFrom;
    uint256 public nftTokenId;
    address public nftContract;
    
    constructor() {
        if (block.chainid == 11155111) {
            challengeAddress = 0x33e1fD270599188BB1489a169dF1f0be08b83509;
        } else {
            challengeAddress = 0xdF7cdFF0c5e85c974D6377244D9A0CEffA2b7A86;
        }        
        solveChallenge(challengeAddress);
        // userAddress = msg.sender;
    }

    function solveChallenge(address _challengeAddress) public {
        Challenge ChallengeContract = Challenge(_challengeAddress);
        uint256 guess = uint256(keccak256(abi.encodePacked(address(this), block.prevrandao, block.timestamp))) % 100000;
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata // data
    ) external returns (bytes4){
        nftOperator = operator;
        nftFrom = from;
        nftTokenId = tokenId;
        nftContract = msg.sender;
        IERC721(msg.sender).transferFrom(address(this), userAddress, nftTokenId);
        return this.onERC721Received.selector;
    }

}