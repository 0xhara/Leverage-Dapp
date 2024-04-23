// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LeverageV2 {
    event CollateralDeposited(address indexed user, uint256 amount);
    event PositionOpened(address indexed user, uint256 collateral, bool isLong, uint256 leverage);
    event PositionClosed(address indexed user, uint256 profitLoss, uint256 remainingCollateral);
    event LeverageUpdated(address indexed user, uint256 newLeverage);
    event CollateralWithdrawn(address indexed user, uint256 amount);

    IERC20 public collateralToken; // ERC-20 token used as collateral
    address public owner;

    struct Position {
        uint256 collateral; // User's collateral
        uint256 leverage;
        bool isLong; // True for long, False for short
    }

    uint256 syntheticPriceChange = 15 * 1e18;
    bool isUpward = true; // indicates direction of price change
    uint256 public minLeverage = 1; // Minimum leverage, typically at least 1
    uint256 public maxLeverage = 10; // Maximum leverage, can be set to an acceptable upper limit

    mapping(address => Position) public positions; // Track user positions
    mapping(address => uint256) public collateralDeposits; // Track collateral deposits

    constructor(address _collateralToken) {
        collateralToken = IERC20(_collateralToken);
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function setPriceChange(bool _isUpward, uint256 _syntheticPriceChange) public  onlyOwner returns(bool,uint){
        syntheticPriceChange = _syntheticPriceChange * 1e18;
        isUpward = _isUpward;
        return (isUpward,syntheticPriceChange);
    }

    // Deposit collateral without opening a position
    function depositCollateral(uint256 amount) public {
        require(collateralToken.balanceOf(msg.sender) >= amount, "Insufficient token balance");
        require(amount > 0, "Deposit amount must be greater than 0");

        bool success = collateralToken.transferFrom(msg.sender, address(this), amount);
        require(success, "Collateral transfer failed");

        collateralDeposits[msg.sender] += amount;

        emit CollateralDeposited(msg.sender, amount);
    }

    // Open a position using all available collateral
    function openPosition(bool isLong, uint256 leverage) public {
        require(collateralDeposits[msg.sender] > 0, "No collateral deposited");
        require(leverage >= minLeverage && leverage <= maxLeverage, "Leverage out of bounds");
        require(positions[msg.sender].collateral == 0, "Position already exists");

        uint256 collateral = collateralDeposits[msg.sender];

        positions[msg.sender] = Position({
            collateral: collateral,
            leverage: leverage,
            isLong: isLong
        });

        collateralDeposits[msg.sender] = 0; // Reset collateral deposits

        emit PositionOpened(msg.sender, collateral, isLong, leverage);
    }

    // Withdraw collateral, ensuring no open position
    function withdrawCollateral(uint256 amount) public {
        require(positions[msg.sender].collateral == 0, "Cannot withdraw while position is open");
        require(collateralDeposits[msg.sender] >= amount, "amount cannot be greater than deposited collateral");

        collateralDeposits[msg.sender] -= amount;

        bool success = collateralToken.transfer(msg.sender, amount);
        require(success, "Collateral transfer failed");
        emit CollateralWithdrawn(msg.sender,amount);
    }
    //function to withdraw complete collateral
    function withdrawCollateral() public {
        require(positions[msg.sender].collateral == 0, "Cannot withdraw while position is open");
        

        uint256 amount=collateralDeposits[msg.sender];
        collateralDeposits[msg.sender]=0;
        bool success = collateralToken.transfer(msg.sender, amount);
        require(success, "Collateral transfer failed");
        emit CollateralWithdrawn(msg.sender,amount);
    }


    // Close a position and return remaining collateral
    function closePosition() public {
        Position storage pos = positions[msg.sender];
        require(pos.collateral > 0, "No open position");

        uint256 profitLoss = pos.leverage * syntheticPriceChange;

        if ((pos.isLong && !isUpward) || (!pos.isLong && isUpward)) {
            if (pos.collateral < profitLoss) {
                pos.collateral = 0;
            } else {
                pos.collateral -= profitLoss;
            }
        } else {
            pos.collateral += profitLoss;
        }

        uint256 remainingCollateral = pos.collateral;

        delete positions[msg.sender];
        emit PositionClosed(msg.sender, profitLoss, remainingCollateral);

        if (remainingCollateral > 0) {
             collateralDeposits[msg.sender] += remainingCollateral;
            // collateralToken.transfer(msg.sender, remainingCollateral); // Return remaining collateral
        }
    }

    function updateLeverage(uint256 newLeverage) public {
        require(newLeverage >= minLeverage && newLeverage <= maxLeverage, "Leverage out of bounds");
        Position storage pos = positions[msg.sender];
        require(pos.collateral > 0, "No open position");

        pos.leverage = newLeverage;

        emit LeverageUpdated(msg.sender, newLeverage);
    }

    function getPositionDetails() public view returns (uint256 collateral, uint256 leverage, bool isLong){
        Position storage pos = positions[msg.sender];
        require(pos.collateral > 0, "No open position");

        return (pos.collateral, pos.leverage, pos.isLong);
    }
}
