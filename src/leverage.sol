// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Leverage {

    event CollateralDeposited(address indexed user, uint256 amount, bool isLong, uint256 leverage);
    event PositionClosed(address indexed user, uint256 profitLoss, uint256 remainingCollateral);
    event LeverageUpdated(address indexed user, uint256 newLeverage);


    IERC20 public collateralToken; // ERC-20 token used as collateral
    address public owner;

    struct Position {
        uint256 collateral; // User's collateral
        uint256 leverage;
        bool isLong; // True for long, False for short
    }
    uint256 syntheticPriceChange= 15 * 1e18;
    bool isUpward=true; // indicates direction of price change
    uint256 public minLeverage = 1; // Minimum leverage, typically at least 1
    uint256 public maxLeverage = 10; // Maximum leverage, can be set to an acceptable upper limit
    
    //one user can have only one position
    mapping(address => Position) public positions; // Track user positions

    constructor(address _collateralToken) {
        collateralToken = IERC20(_collateralToken);
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Not owner");
        _;
    }

   
    function setPriceChange(bool _isUpward,uint _syntheticPriceChange) public  onlyOwner returns(bool,uint){
         syntheticPriceChange = _syntheticPriceChange * 1e18;
         isUpward=_isUpward;
        return (isUpward,syntheticPriceChange);
    }

    // Deposit collateral to open a leveraged position
    function depositCollateral(uint256 amount, bool isLong, uint256 leverage) public {
        require(collateralToken.balanceOf(msg.sender) >= amount, "Insufficient token balance");
        require(amount > 0, "Deposit amount must be greater than 0");
        require(leverage >= minLeverage && leverage <= maxLeverage, "Leverage out of bounds");

        require(positions[msg.sender].collateral == 0, "Open position already exists");

        bool success = collateralToken.transferFrom(msg.sender, address(this), amount);
        require(success, "Collateral transfer failed");
        emit CollateralDeposited(msg.sender, amount, isLong, leverage);
        positions[msg.sender] = Position({
            collateral: amount,
            leverage: leverage,
            isLong: isLong
        });
    }

    // Close the position and calculate profit/loss (simplified)
    function closePosition() public {
        Position storage pos = positions[msg.sender];
        require(pos.collateral > 0, "No open position");
        uint256 profitLoss = pos.leverage * syntheticPriceChange; // Simplified profit/loss calculation
        if((pos.isLong && !isUpward)|| (!pos.isLong && isUpward)){
            if (pos.collateral < profitLoss){
                pos.collateral=0;
            }
            else{
                pos.collateral-=profitLoss;
            }
        }
        else{
            pos.collateral+=profitLoss;
        }

    // Capture the remaining collateral
    uint256 remainingCollateral = pos.collateral;

    // Clear the position
    delete positions[msg.sender];
    emit PositionClosed(msg.sender, profitLoss, remainingCollateral);
    // Transfer any remaining collateral back to the user
    if (remainingCollateral > 0) {
       collateralToken.transfer(msg.sender, remainingCollateral);
        
    }
       
    }

    // Update leverage for an open position
    function updateLeverage(uint256 newLeverage) public {
        require(newLeverage >= minLeverage && newLeverage <= maxLeverage, "Leverage out of bounds");
        Position storage pos = positions[msg.sender];
        require(pos.collateral > 0, "No open position");

        pos.leverage = newLeverage;

        emit LeverageUpdated(msg.sender, newLeverage);

    }

    // Get user's current position details
    function getPositionDetails() public view returns (uint256 collateral, uint256 leverage, bool isLong) {
        Position storage pos = positions[msg.sender];
        require(pos.collateral > 0, "No open position");

        return (pos.collateral, pos.leverage, pos.isLong);
    }
}
