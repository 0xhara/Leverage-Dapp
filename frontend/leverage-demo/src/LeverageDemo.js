import React, { useState, useEffect } from 'react';
import { ethers } from 'ethers';
import leverageABI from './abi/Leverage.json';
import erc20ABI from './abi/erc20.json';

// This is linked to leverage V1 contract, deployed locally using anvil. 

// Hardcoded values for simplicity
const PRIVATE_KEY='0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d'; // Be cautious with private keys
// const ALCHEMY_URL = 'https://polygon-mumbai.g.alchemy.com/v2/N_-JU1B2XbGAPiCpCE0CSv7Y9P5CFP-D';
const LOCAL_NODE_URL = 'http://127.0.0.1:8545';
const LEVERAGE_CONTRACT_ADDRESS = '0xe7f1725e7734ce288f8367e1bb143e90bb3f0512'; 
const ERC20_CONTRACT_ADDRESS = '0x5fbdb2315678afecb367f032d93f642f64180aa3'; 

const LeverageDemo = () => {
  const [collateral, setCollateral] = useState('');
  const [leverage, setLeverage] = useState('');
  const [isLong, setIsLong] = useState(true);
  const [positionDetails, setPositionDetails] = useState({});
  const [userBalance, setUserBalance] = useState('');
  const [events, setEvents] = useState([]);
 console.log("user private key ",PRIVATE_KEY);
  // Connect to Mumbai
  const provider = new ethers.JsonRpcProvider(LOCAL_NODE_URL);
  const wallet = new ethers.Wallet(PRIVATE_KEY, provider);
  console.log("leverage abi ",leverageABI[0])
  
  // Create contract instances
  const leverageContract = new ethers.Contract(
    LEVERAGE_CONTRACT_ADDRESS,
    leverageABI,
    wallet
  );

  const erc20Contract = new ethers.Contract(
    ERC20_CONTRACT_ADDRESS,
    erc20ABI,
    wallet
  );

  // Event listener for emitted events
  useEffect(() => {
    const onCollateralDeposited = (user, amount, isLong, leverage) => {
      setEvents((events) => [...events, `Collateral deposited by ${user}: ${amount} Position: (isLong: ${isLong}, leverage: ${leverage})`]);
    };

    const onPositionClosed = (user, profitLoss, remainingCollateral) => {
      setEvents((events) => [...events, `Position closed by ${user}: profit/loss ${profitLoss}, Transfer amount ${remainingCollateral}`]);
    };

    leverageContract.on('CollateralDeposited', onCollateralDeposited);
    leverageContract.on('PositionClosed', onPositionClosed);

    return () => {
      leverageContract.removeAllListeners(); // Clean up listeners
    };
  }, []);

  // Function to approve ERC-20 token for collateral
  const approveCollateral = async (amount) => {
    const txn = await erc20Contract.approve(LEVERAGE_CONTRACT_ADDRESS, amount);
    await txn.wait();
  };

  // Function to deposit collateral
  const depositCollateral = async () => {
    
    const amountInWei = ethers.parseUnits(collateral, 18);
    await approveCollateral(amountInWei); // Ensure approval before depositing
    const txn = await leverageContract.depositCollateral(amountInWei, isLong, leverage);
    await txn.wait();
  };

  // Function to update leverage
  const updateLeverage = async (newLeverage) => {
    const txn = await leverageContract.updateLeverage(newLeverage);
    await txn.wait();
  };

  // Function to get position details
  const getPositionDetails = async () => {
    const details = await leverageContract.getPositionDetails();
    console.log("details of position ", details[1].toString());
    setPositionDetails({
      collateral: ethers.formatUnits(details[0], 18),
      leverage: details[1].toString(),
      isLong: details[2],
    });
  };

  // Function to close position
  const closePosition = async () => {
    const txn = await leverageContract.closePosition();
    await txn.wait();
  };

  // Function to get user balance from ERC-20 contract
  const getUserBalance = async () => {
    const balance = await erc20Contract.balanceOf(wallet.address);
    setUserBalance(ethers.formatUnits(balance, 18));
  };
  const requestFaucet = async()=>{
    const txn = await erc20Contract.faucet(); // Call the faucet function
    await txn.wait(); // Wait for the transaction to be mined
    console.log("Faucet tokens received");
  }

  return (
    <div>
      <h1>Leverage Contract Demo</h1>
      <div>
        <label>Collateral:</label>
        <input
          type="text"
          value={collateral}
          onChange={(e) => setCollateral(e.target.value)}
        />
      </div>
      <div>
        <label>Leverage:</label>
        <input
          type="text"
          value={leverage}
          onChange={(e) => setLeverage(e.target.value)}
        />
      </div>
      <div>
        <label>Position:</label>
        <select
          value={isLong}
          onChange={(e) => setIsLong(e.target.value === 'true')}
        >
          <option value="true">Long</option>
          <option value="false">Short</option>
        </select>
      </div>
      <div>
        <button onClick={depositCollateral}>Deposit Collateral</button>
        <button onClick={() => updateLeverage(leverage)}>Update Leverage</button>
        <button onClick={getPositionDetails}>Get Position Details</button>
        <button onClick={closePosition}>Close Position</button>
        <button onClick={getUserBalance}>Get User Balance</button>
        <button onClick={requestFaucet}>USDC Faucet</button>
      </div>
      <div>
        <h2>Position Details</h2>
        <p>Collateral: {positionDetails.collateral}</p>
        <p>Leverage: {positionDetails.leverage}</p>
        <p>Is Long: {positionDetails.isLong ? 'Yes' : 'No'}</p>
      </div>
      <div>
        <h2>User Balance</h2>
        <p>{userBalance}</p>
      </div>
      <div>
        <h2>Events</h2>
        {events.map((event, index) => (
          <p key={index}>{event}</p>
        ))}
      </div>
    </div>
  );
};

export default LeverageDemo;
