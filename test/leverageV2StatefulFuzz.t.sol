// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/LeverageV2.sol";
import "../src/MockUSDC.sol";

contract LeverageV2StatefulFuzzTest is Test {
    MockUSDC public token; // Mock ERC-20 contract
    LeverageV2 public leverage; // Leverage contract
    address public user; // Test user

    function setUp() public {
        token = new MockUSDC(); // Deploy MockUSDC
        leverage = new LeverageV2(address(token)); // Deploy LeverageV2
        token.mint(address(leverage),10000 * 10**18);
       
        user = address(0x123); // Test user
        token.mint(user, 1000 * 10**18); // Mint 1000 tokens
        
        vm.startPrank(user); // Start pranking as the user
        token.approve(address(leverage), 1000 * 10**18); // Approve 1000 tokens for spending
        vm.stopPrank(); // Stop pranking
    }

    // Fuzz test for multiple deposit and open position actions
    function testfuzz_StatefulDepositAndOpen(uint256 depositAmount, bool isLong, uint256 leverageValue) public {
        vm.startPrank(user); // Simulate the user transaction
        depositAmount=bound(depositAmount,1,1000); // Avoid zero values
        leverage.depositCollateral(depositAmount); // Deposit collateral

        leverageValue=bound(leverageValue,1,10);// Normalize leverage to a valid range
        leverage.openPosition(isLong, leverageValue); // Open a position

        (uint256 collateral, uint256 leverageValue2, bool positionIsLong) = leverage.getPositionDetails();

        assert(collateral > 0); // Ensure there is collateral after opening a position
        assertEq(leverageValue, leverageValue2); // Validate the leverage value
        assertEq(positionIsLong, isLong); // Validate the position type
        vm.stopPrank(); // Stop pranking
    }

    // Fuzz test for closing a position after deposits and positions
    function testfuzz_StatefulClosePosition() public {
        vm.startPrank(user); // Simulate the user
        leverage.depositCollateral(100 * 10**18); // Deposit collateral
        leverage.openPosition(true, 3); // Open a position with leverage 3
        leverage.closePosition(); // Close the position
        vm.stopPrank(); // Stop pranking

        // Expect the position details to revert, indicating no open position
        vm.expectRevert("No open position");
        leverage.getPositionDetails(); // Should revert because the position is closed
    }
}
