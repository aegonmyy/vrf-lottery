// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

import {RandomWinnerPicker} from "../src/RandomWinnerPicker.sol";
import {console} from "forge-std/console.sol";
import {Script} from "forge-std/Script.sol";

contract deploy is Script {
    uint256 subId = 90;
    address vrfCoordinator = 0x92fAf43CbBEce86ab3f887B9dFef3a8604b16c4B;

    function run() external {
        uint256 subId = vm.envUint("_subscriptionId");
        address coord = vm.envAddress("_coordinator");
        bytes32 hash = vm.envBytes32("_keyHash");
        vm.startBroadcast();
        RandomWinnerPicker picker = new RandomWinnerPicker(subId, coord, hash);
        console.log("Contract deployed at:", address(picker));
        vm.stopBroadcast();
    }
}
