# LeverageV2 Contract Workflow

## Contract Overview
- **Contract Name**: LeverageV2.sol
- **Test files**:
  - **Unit tests**: leverageV2.t.sol
  - **Fuzz tests**: leverageV2Fuzz.t.sol
- **Functionality**: A simple smart contract for leveraged trading of ERC-20 tokens.
- **Assumptions**: 
  - Asset price change is fixed for simplicity.
  - Users have to approve the LeverageV2 contract to spend ERC-20 tokens on their behalf for the deposit function to work.
  - Users need to use a faucet function to obtain ERC-20 tokens initially for trading.
  - The ERC-20 token contract should mint tokens to the LeverageV2 contract so that it can send funds to users when they earn profits.

## Key Functions

1. **depositCollateral**
   - **Description**: Allows users to deposit collateral.
   - **Parameters**: 
     - `amount`: Amount of collateral to deposit.
   - **Interaction**: Users need to approve the LeverageV2 contract to spend ERC-20 tokens on their behalf before calling this function.

2. **openPosition**
   - **Description**: Allows users to open a leveraged position.
   - **Parameters**: 
     - `isLong`: Boolean indicating whether the position is long (true) or short (false).
     - `leverage`: Leverage ratio for the position.
   - **Interaction**: Users must have previously deposited collateral using the `depositCollateral` function. They also need to approve the LeverageV2 contract to spend ERC-20 tokens on their behalf.

3. **closePosition**
   - **Description**: Allows users to close their open position.
   - **Interaction**: Users must have an existing open position.

4. **updateLeverage**
   - **Description**: Allows users to update the leverage ratio of their open position.
   - **Parameters**: 
     - `newLeverage`: New leverage ratio.
   - **Interaction**: Users must have an existing open position.
5. **withdrawCollateral**:
    - **Description**: Withdraws the mentioned amount from deposited collateral
    - **Parameters**: `amount` that is to be withdrawn, if not mentioned, total collateral will be withdrawn. 

6. **getPositionDetails**
   - **Description**: Returns the details of the user's current position.
   - **Returns**: 
     - `collateral`: User's collateral in the current position.
     - `leverage`: Leverage ratio of the current position.
     - `isLong`: Boolean indicating whether the position is long (true) or short (false).
    - **Reverts**: This function call reverts if there is no open position.
6. **setPriceChange**
   - **Description**: Allows the owner to change the synthetic price change and direction of change for testing/demo purposes.
   - **Parameters**: 
     - `_isUpward`: Boolean indicating the direction of price change (true for upward, false for downward).
     - `_syntheticPriceChange`: New synthetic price change value(without erc20 decimals.)
   - **Interaction**: Only callable by the contract owner.
