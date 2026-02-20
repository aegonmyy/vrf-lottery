// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

import {RandomWinnerPicker} from "../src/RandomWinnerPicker.sol";
import {console} from "forge-std/console.sol";
import {Script} from "forge-std/Script.sol";

contract deploy is Script {
    function run() external {
        uint256 subId = vm.envUint("_subscriptionId");
        uint256 interval = 30 minutes;
        address coord = vm.envAddress("_coordinator");
        bytes32 hash = vm.envBytes32("_keyHash");
        uint256 fee = 0.01 ether;
        vm.startBroadcast();
        RandomWinnerPicker picker = new RandomWinnerPicker(
            subId,
            fee,
            interval,
            coord,
            hash
        );
        console.log("Contract deployed at:", address(picker));
        vm.stopBroadcast();
    }
}
