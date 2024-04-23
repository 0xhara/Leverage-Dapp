// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/MockUSDC.sol";
import "../src/LeverageV2.sol";

contract LeverageV2FuzzTest is Test {
    MockUSDC public token;
    LeverageV2 public leverage;
    address public user;

    function setUp() public {
        token = new MockUSDC();
        leverage = new LeverageV2(address(token));
        
        user = address(0x123);
        token.mint(user, 1000 * 10**18); // Mint 1000 tokens
        
        leverage = new LeverageV2(address(token));
        token.mint(address(leverage),10000 * 10**18);
        vm.prank(user);
        token.approve(address(leverage), 1000 * 10**18); // Approve 1000 tokens
    }

    // Fuzz test for depositCollateral
    function testfuzz_DepositCollateral(uint256 depositAmount) public {
        vm.startPrank(user);
        uint256 normalizedAmount = bound(depositAmount,1,1000 * 10**18); // Normalize to a sensible range
        // if (normalizedAmount == 0) normalizedAmount = 1; // Avoid zero values

        leverage.depositCollateral(normalizedAmount);
        
        uint256 collateral = leverage.collateralDeposits(user);
        assert(collateral >= normalizedAmount); // Validate the deposit
        vm.stopPrank();
    }

    // Fuzz test for openPosition
    function testfuzz_OpenPosition(uint256 leverageValue, bool isLong) public {
        vm.startPrank(user);
        leverage.depositCollateral(50 * 10**18); // Ensure some collateral is deposited
        
        uint256 normalizedLeverage = bound(leverageValue,1,10); // Leverage between 1 and 10
        leverage.openPosition(isLong, normalizedLeverage);
        
        (, uint256 leverageStored, bool positionIsLong) = leverage.getPositionDetails();
        assertEq(leverageStored, normalizedLeverage); // Validate leverage
        assertEq(positionIsLong, isLong); // Validate position type
        vm.stopPrank();
    }

    // Fuzz test for withdrawCollateral
    function testfuzz_WithdrawCollateral(uint256 withdrawAmount) public {
        vm.startPrank(user);
        leverage.depositCollateral(100 * 10**18); // Ensure sufficient collateral

       if (withdrawAmount > 100 * 10**18) {
        // If the withdrawal amount exceeds deposited collateral, expect a revert
        vm.expectRevert("amount cannot be greater than deposited collateral");
        leverage.withdrawCollateral(withdrawAmount); // This should revert
    } else {
        leverage.withdrawCollateral(withdrawAmount); // Withdraw
        uint256 collateral = leverage.collateralDeposits(user);
        assert(collateral >= 0 && collateral <= 100 * 10**18); // Validate remaining collateral
    }
        
    vm.stopPrank();
}
}