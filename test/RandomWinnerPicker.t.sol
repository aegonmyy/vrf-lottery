// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;
import {Test, console} from "forge-std/Test.sol";
import {RandomWinnerPicker} from "../src/RandomWinnerPicker.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink-brownie-contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract testing_RandomWinnerPicker is Test {
    RandomWinnerPicker randomWinner;
    VRFCoordinatorV2_5Mock vrfMock;
    address sender1;
    address sender2;
    address sender3;
    event PlayerEntered(address indexed player, uint256 amount);
    event WinnerPicked(address indexed winner, uint256 amount);
    bytes32 keyHash =
        0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae;

    function setUp() public {
        vrfMock = new VRFCoordinatorV2_5Mock(0.25 ether, 1e9, 4e15);
        uint256 subId = vrfMock.createSubscription();
        uint256 fee = 0.01 ether;
        randomWinner = new RandomWinnerPicker(
            subId,
            fee,
            address(vrfMock),
            keyHash
        );
        vrfMock.addConsumer(subId, address(randomWinner));
        vrfMock.fundSubscription(subId, 10000 ether);
        sender1 = makeAddr("sender1");
        sender2 = makeAddr("sender2");
        sender3 = makeAddr("sender3");
        vm.deal(sender1, 100 ether);
    }

    function test_SingleDeposit() public {
        hoax(sender1);
        vm.expectEmit(true, false, false, true);
        emit PlayerEntered(sender1, 0.01 ether);
        randomWinner.enter{value: 0.01 ether}();
        assertEq(randomWinner.entrants(0), sender1);
        assertEq(randomWinner.prizePool(), 0.01 ether);
    }

    function test_MultipleUserDeposit() public {
        hoax(sender1);
        vm.expectEmit(true, false, false, true);
        emit PlayerEntered(sender1, 0.002 ether);
        randomWinner.enter{value: 0.002 ether}();
        hoax(sender2);
        vm.expectEmit(true, false, false, true);
        emit PlayerEntered(sender2, 0.003 ether);
        randomWinner.enter{value: 0.003 ether}();
        hoax(sender3);
        vm.expectEmit(true, false, false, true);
        emit PlayerEntered(sender3, 0.004 ether);
        randomWinner.enter{value: 0.004 ether}();
        assertEq(randomWinner.findLength(), 3);
        assertEq(randomWinner.entrants(0), sender1);
        assertEq(randomWinner.entrants(1), sender2);
        assertEq(randomWinner.entrants(2), sender3);
        assertEq(randomWinner.prizePool(), 0.009 ether);
    }

    function test_CompleteFLow() public {
        hoax(sender1, 5 ether);
        vm.expectEmit(true, false, false, true);
        emit PlayerEntered(sender1, 1 ether);
        randomWinner.enter{value: 1 ether}();
        hoax(sender2, 5 ether);
        vm.expectEmit(true, false, false, true);
        emit PlayerEntered(sender2, 2 ether);
        randomWinner.enter{value: 2 ether}();
        hoax(sender3, 5 ether);
        vm.expectEmit(true, false, false, true);
        emit PlayerEntered(sender3, 3 ether);
        randomWinner.enter{value: 3 ether}();
        uint256 totalPrizepooll = randomWinner.prizePool();
        uint256 requestId = randomWinner.manuallyInitiateDraw();
        vrfMock.fulfillRandomWords(requestId, address(randomWinner));
        uint256 p1 = randomWinner.PendingWithdrawals(sender1);
        uint256 p2 = randomWinner.PendingWithdrawals(sender2);
        uint256 p3 = randomWinner.PendingWithdrawals(sender3);

        assertEq(p1 + p2 + p3, totalPrizepooll);
        assertEq(randomWinner.prizePool(), 0);
        (address winnerAddr, uint256 t_Prizepool) = randomWinner.winners(0);
        console.log("the winner prize is :", t_Prizepool);
        assertTrue(
            winnerAddr == sender1 ||
                winnerAddr == sender2 ||
                winnerAddr == sender3
        );
        console.log("winner was ", winnerAddr);
    }

    function test_insufficientBalance() public {
        hoax(sender1);
        vm.expectRevert();
        randomWinner.enter{value: 0.000001 ether}();
    }

    function test_funnn() public {
        hoax(sender1, 5 ether);
        randomWinner.enter{value: 1 ether}();
        hoax(sender2, 5 ether);
        randomWinner.enter{value: 2 ether}();
        hoax(sender3, 5 ether);
        randomWinner.enter{value: 2 ether}();
    }
}
