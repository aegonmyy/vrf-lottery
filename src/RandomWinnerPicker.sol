// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {VRFConsumerBaseV2Plus} from "@chainlink-brownie-contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink-brownie-contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {AutomationCompatibleInterface} from "@chainlink-brownie-contracts/src/v0.8/automation/interfaces/AutomationCompatibleInterface.sol";

contract RandomWinnerPicker is
    VRFConsumerBaseV2Plus,
    AutomationCompatibleInterface
{
    error RandomWinnerPicker__nothingToWithdraw();
    error RandomWinnerPicker__claimingFailed();
    error RandomWinnerPicker__sendMoreToEnter();
    error RandomWinnerPicker__raffleNotOpen();
    error RandomWinnerPicker__NotEnoughParticipants();
    error RandomWinnerPicker__OnlyOwner();

    uint256 public subscriptionId;
    uint256 public randomResult;
    bytes32 public keyHash;
    address public the_owner;
    uint256 public i_entranceFee;
    uint256 public interval;
    uint256 public lastTimestamp;
    address[] public entrants;
    uint256 public prizePool;
    mapping(address => uint256) public PendingWithdrawals;
    enum LotteryState {
        OPEN,
        CALCULATING,
        CLOSED
    }
    LotteryState public lotteryState;

    struct Winner {
        address winnerOfTheRound;
        uint256 amountWon;
    }
    Winner[] public winners;
    event PlayerEntered(address indexed player, uint256 amount);
    event WinnerPicked(address indexed winner, uint256 amount);
    modifier only_the_owner() {
        if (msg.sender != the_owner) revert RandomWinnerPicker__OnlyOwner();
        _;
    }

    constructor(
        uint256 _subscriptionId,
        uint256 _fee,
        address _coordinatorAddress,
        bytes32 _keyHash
    ) VRFConsumerBaseV2Plus(_coordinatorAddress) {
        keyHash = _keyHash;
        i_entranceFee = _fee;
        subscriptionId = _subscriptionId;
        lotteryState = LotteryState.OPEN;
        the_owner = msg.sender;
    }

    function changeLotteryState(LotteryState _state) external only_the_owner {
        lotteryState = _state;
    }

    function setLotteryMinEntry(uint256 fee) external only_the_owner {
        i_entranceFee = fee;
    }

    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        bool isOpen = LotteryState.OPEN == lotteryState;
        bool timePassed = ((block.timestamp - lastTimestamp) > interval);
        bool hasEnoughPlayers = entrants.length > 2;
        bool upkeepNeeded = (isOpen && timePassed && hasEnoughPlayers);
        return (upkeepNeeded, "");
    }

    function performUpkeep(bytes calldata performData) external override {
        requestRandomWords();
    }

    function withdrawPrize() external {
        uint256 amount = PendingWithdrawals[msg.sender];
        if (PendingWithdrawals[msg.sender] == 0)
            revert RandomWinnerPicker__nothingToWithdraw();
        PendingWithdrawals[msg.sender] = 0;
        (bool success, ) = msg.sender.call{value: amount}("");
        revert RandomWinnerPicker__claimingFailed();
    }

    function enter() external payable {
        if (msg.value < i_entranceFee)
            revert RandomWinnerPicker__sendMoreToEnter();
        if (lotteryState != LotteryState.OPEN)
            revert RandomWinnerPicker__raffleNotOpen();
        entrants.push(msg.sender);
        prizePool += msg.value;
        emit PlayerEntered(msg.sender, msg.value);
    }

    function manuallyInitiateDraw() external only_the_owner returns (uint256) {
        return requestRandomWords();
    }

    function requestRandomWords() internal returns (uint256) {
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
        lastTimestamp = block.timestamp;
    }

    function findLength() external view returns (uint256) {
        return entrants.length;
    }
}
