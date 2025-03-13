// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {MyToken} from "../src/StableCoin.sol";

contract Deployer is Script {
    function run() external returns (MyToken) {
        // Define constructor parameters
        string memory name = "Indian Rupee Token";
        string memory symbol = "INRT";
        uint8 decimals = 6; // Using 6 decimals like USDT
        uint256 initialSupply = 1_000_000_000000; // 1 million tokens with 6 decimals

        vm.startBroadcast();
        MyToken myToken = new MyToken(
            name, 
            symbol, 
            decimals,
            initialSupply
        );
        vm.stopBroadcast();
        
        return myToken;
    }
}