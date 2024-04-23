// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console2} from "forge-std/Test.sol";
import "../src/MockUSDC.sol"; 
import "../src/LeverageV2.sol"; 

contract LeverageV2Test is Test {
    MockUSDC public token; // ERC-20 token
    // Leverage contract
    LeverageV2 public leverage;
    address public user; // Test user

    function setUp() public {
        // Deploy the MockUSDC contract
        token = new MockUSDC();
        
        // Mint some tokens to the user
        user = address(0x123); // Test user address
        token.mint(user, 100 * 10**18); // Mint 100 tokens to the user
        
        // Deploy the Leverage contract with MockUSDC as collateral token
        leverage = new LeverageV2(address(token));
        token.mint(address(leverage),1000 * 10**18);

        // Approve the Leverage contract to spend tokens on behalf of the user
        vm.prank(user); // Use the `prank` function to simulate transactions from the user
        token.approve(address(leverage), 100 * 10**18); // Approve 100 tokens
    }

    // Test that a user can deposit collateral
     // Test collateral deposit
    function testDepositCollateral() public {
        vm.startPrank(user); // Simulate the user transaction
        leverage.depositCollateral(50 * 10**18); // Deposit 50 tokens
        vm.stopPrank(); // Stop pranking

        assertEq(leverage.collateralDeposits(user), 50 * 10**18); // Validate the collateral deposit
    }
// Test opening a position
    function testOpenPosition() public {
        vm.startPrank(user); // Simulate the user
        leverage.depositCollateral(50 * 10**18); // Deposit collateral
        leverage.openPosition(true, 3); // Open a long position with leverage 3

        (uint256 collateral, uint256 leverageValue, bool isLong) = leverage.getPositionDetails();

        assertEq(collateral, 50 * 10**18); // Validate collateral amount
        assertEq(leverageValue, 3); // Validate leverage
        assertTrue(isLong); // Validate position type (long)
    }
     // Test closing a position
    function testClosePosition() public {
        vm.startPrank(user); // Simulate the user
        leverage.depositCollateral(50 * 10**18); // Deposit collateral
        leverage.openPosition(true, 3); // Open a position
        leverage.closePosition(); // Close the position
        vm.stopPrank(); // Stop pranking

        // uint256 collateral = leverage.collateralDeposits(user);
        // assert(collateral > 0); // Ensure there is some collateral returned after closing
    vm.expectRevert("No open position");
    leverage.getPositionDetails(); // This should revert because the position is closed
    }

    // Test leverage update
    function testUpdateLeverage() public {
        vm.startPrank(user); // Simulate the user
        leverage.depositCollateral(50 * 10**18); // Deposit collateral
        leverage.openPosition(true, 3); // Open a position
        leverage.updateLeverage(5); // Update leverage to 5

        (, uint256 leverageValue,) = leverage.getPositionDetails();
        assertEq(leverageValue, 5); // Validate that the leverage has been updated to 5
        vm.stopPrank(); // Stop pranking
    }
    // Test collateral withdrawal
    function testWithdrawCollateral() public {
        vm.startPrank(user); // Simulate the user
        leverage.depositCollateral(50 * 10**18); // Deposit collateral
        vm.stopPrank(); // Stop pranking

        vm.startPrank(user); // Simulate the user again
        leverage.withdrawCollateral(20 * 10**18); // Withdraw 20 tokens
        vm.stopPrank(); // Stop pranking

        uint256 collateral = leverage.collateralDeposits(user);
        assertEq(collateral, 30 * 10**18); // Validate remaining collateral
    }
    function testWithdrawCollateral_withOpenPosition() public {
         vm.startPrank(user); 
        leverage.depositCollateral(50 * 10**18); 
        leverage.openPosition(true, 3);
        vm.expectRevert("Cannot withdraw while position is open");
        leverage.withdrawCollateral(20 * 10**18);
        vm.stopPrank();
    }
}
