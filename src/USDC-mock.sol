pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockUSDC is ERC20 {
    address public owner;

    constructor() ERC20("USDCmock", "USDC") {
        owner = msg.sender;

    }
    modifier onlyOwner {
        require(msg.sender==owner,"Only owner can mint");
        _;
    }
    // Mint function to create tokens, accessible only by the owner
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount); // Internal mint function provided by ERC20
    }
 // Faucet function to request a small amount of tokens for testing
 //send only 100 at a time.
    function faucet() public {
        uint256 amount = 100 * 10 ** decimals(); // Example amount
        _mint(msg.sender, amount);
    }
}
