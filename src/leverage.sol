pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SyntheticLeverage {
    IERC20 public collateralToken; // ERC-20 token used as collateral
    address public owner;

    struct Position {
        uint256 collateral; // User's collateral
        uint256 leverage;
        bool isLong; // True for long, False for short
    }

    mapping(address => Position) public positions; // Track user positions

    constructor(address _collateralToken) {
        collateralToken = IERC20(_collateralToken);
        owner = msg.sender;
    }

    // modifier onlyOwner {
    //     require(msg.sender == owner, "Not owner");
    //     _;
    // }

    //should be onlyOwner, skipped for demonstrative purposes. 
    function getPriceChange() public pure returns(bool,uint){
        uint256 syntheticPriceChange = 15;
        bool isUpward=true;
        return (isUpward,syntheticPriceChange);
    }

    // Deposit collateral to open a leveraged position
    function depositCollateral(uint256 amount, bool isLong, uint256 leverage) public {
        require(collateralToken.balanceOf(msg.sender) >= amount, "Insufficient token balance");
        require(amount > 0, "Deposit amount must be greater than 0");
        require(positions[msg.sender].collateral == 0, "Open position already exists");

        bool success = collateralToken.transferFrom(msg.sender, address(this), amount);
        require(success, "Collateral transfer failed");

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
        (bool isUpward,uint256 syntheticPriceChange) = getPriceChange();
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

    // Transfer any remaining collateral back to the user
    if (remainingCollateral > 0) {
       collateralToken.transfer(msg.sender, remainingCollateral);
        
    }
       
    }

    // Update leverage for an open position
    function updateLeverage(uint256 newLeverage) public {
        Position storage pos = positions[msg.sender];
        require(pos.collateral > 0, "No open position");

        pos.leverage = newLeverage;
    }

    // Get user's current position details
    function getPositionDetails() public view returns (uint256 collateral, uint256 leverage, bool isLong) {
        Position storage pos = positions[msg.sender];
        require(pos.collateral > 0, "No open position");

        return (pos.collateral, pos.leverage, pos.isLong);
    }
}
