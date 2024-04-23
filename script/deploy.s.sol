// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/mockUSDC.sol"; // Adjust import path;
import "../src/Leverage.sol"; // Adjust import path

contract DeployScript is Script {

    function run() public {
        // Start broadcasting to Anvil (local node)
        //vm.startBroadcast();
        uint256 deployerPrivateKey = vm.envUint("OWNER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy MockERC20 contract
        MockUSDC USDC = new MockUSDC();
        Leverage leverage = new Leverage(address(USDC)); // Deploy Leverage contract, passing in the MockERC20 address
        console.log("MockERC20 deployed at:", address(USDC));
        
        console.log("Leverage contract deployed at:", address(leverage));
        USDC.mint(address(leverage), 1000 * 1e18); // Mint to the MockERC20 contract

        // Stop broadcasting
        vm.stopBroadcast();
    }
}
