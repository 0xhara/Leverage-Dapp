// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console2} from "forge-std/Test.sol";
import "../src/MockUSDC.sol"; 
import "../src/Leverage.sol"; 

contract LeverageTest is Test {
    MockUSDC public token; // ERC-20 token
    Leverage public leverage; // Leverage contract
    address public user; // Test user

    function setUp() public {
        // Deploy the MockUSDC contract
        token = new MockUSDC();
        
        // Mint some tokens to the user
        user = address(0x123); // Test user address
        token.mint(user, 100 * 10**18); // Mint 100 tokens to the user
        
        // Deploy the Leverage contract with MockUSDC as collateral token
        leverage = new Leverage(address(token));
        token.mint(address(leverage),1000 * 10**18);

        // Approve the Leverage contract to spend tokens on behalf of the user
        vm.prank(user); // Use the `prank` function to simulate transactions from the user
        token.approve(address(leverage), 100 * 10**18); // Approve 100 tokens
    }

    // Test that a user can deposit collateral
    function testDepositCollateral() public {
        vm.startPrank(user); 
    
        leverage.depositCollateral(50 * 10**18, true, 3); // Deposit 50 tokens

        // Assert that the position was created
        (uint256 collateral, uint256 leverageValue, bool isLong) = leverage.getPositionDetails();
        assertEq(collateral, 50 * 10**18); // Collateral should be 50 tokens
        assertTrue(isLong); // Position should be long
        assertEq(leverageValue, 3); // Leverage should be 3
        
        vm.stopPrank();
        
    }

    // Test closing a position
    function testClosePosition() public {
        // Deposit collateral
         vm.startPrank(user);
        leverage.depositCollateral(50 * 10**18, true, 3); // Deposit 50 tokens
        
        // Close the position
        leverage.closePosition();

        // Check the token balance of the user
        uint256 userBalance = token.balanceOf(user);
        assertTrue(userBalance > 0); // User should have received remaining collateral
        vm.stopPrank();

    }

    // Test updating leverage
    function testUpdateLeverage() public {
        vm.startPrank(user);
        leverage.depositCollateral(50 * 10**18, true, 3); // Deposit 50 tokens

        leverage.updateLeverage(5); // Update leverage to 5

        // Verify leverage value has been updated
        (, uint256 leverageValue, ) = leverage.getPositionDetails();
        assertEq(leverageValue, 5); // Leverage should be 5 after update
        vm.stopPrank();

    }
}
