// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {VRFConsumerBaseV2Plus} from "@chainlink-brownie-contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink-brownie-contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

contract RandomWinnerPicker is VRFConsumerBaseV2Plus {
    uint256 public subscriptionId;
    uint256 public randomResult;
    bytes32 public keyHash;
    address the_owner;
    address[] public entrants;
    uint256 public prizePool;
    mapping(address => uint256) public PendingWithdrawals;
    enum LotteryState {
        OPEN,
        CALCULATING,
        CLOSED
    }
    modifier only_the_owner() {
        require(msg.sender == the_owner);
        _;
    }
    LotteryState public lotteryState;

    struct Winner {
        address winnerOfTheRound;
        uint256 amountWon;
    }
    Winner[] public winners;
    event PlayerEntered(address indexed player, uint256 amount);
    event WinnerPicked(address indexed winner, uint256 amount);

    constructor(
        uint256 _subscriptionId,
        address _coordinatorAddress,
        bytes32 _keyHash
    ) VRFConsumerBaseV2Plus(_coordinatorAddress) {
        keyHash = _keyHash;
        subscriptionId = _subscriptionId;
        lotteryState = LotteryState.OPEN;
        the_owner = msg.sender;
    }

    function changeLotteryState(LotteryState _state) public only_the_owner {
        lotteryState = _state;
    }

    function requestRandomWords() internal returns (uint256) {
        require(entrants.length > 2, "Not enough participants");
        require(lotteryState == LotteryState.OPEN);
        lotteryState = LotteryState.CALCULATING;
        VRFV2PlusClient.RandomWordsRequest memory data = VRFV2PlusClient
            .RandomWordsRequest({
                keyHash: keyHash,
                subId: subscriptionId,
                requestConfirmations: 3,
                callbackGasLimit: 300000,
                numWords: 1,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            });
        return s_vrfCoordinator.requestRandomWords(data);
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] calldata randomWords
    ) internal override {
        randomResult = randomWords[0];
        uint256 winnerIndex = randomWords[0] % entrants.length;
        address winner = entrants[winnerIndex];
        uint256 _prizePool = prizePool;
        emit WinnerPicked(winner, _prizePool);
        prizePool = 0;
        PendingWithdrawals[winner] += _prizePool;
        entrants = new address[](0);
        winners.push(Winner({winnerOfTheRound: winner, amountWon: _prizePool}));
        lotteryState = LotteryState.OPEN;
    }

    function withdrawPrize() external {
        uint256 amount = PendingWithdrawals[msg.sender];
        require(amount > 0, "nothing to withdraw");
        PendingWithdrawals[msg.sender] = 0;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Claiming Failed");
    }

    function enter() external payable {
        require(msg.value > 0.0001 ether, "Send 0.0001 ether");
        require(lotteryState == LotteryState.OPEN);
        entrants.push(msg.sender);
        prizePool += msg.value;
        emit PlayerEntered(msg.sender, msg.value);
    }

    function initiateDraw() public only_the_owner returns (uint256) {
        return requestRandomWords();
    }

    function findLength() external view returns (uint256) {
        return entrants.length;
    }
}
