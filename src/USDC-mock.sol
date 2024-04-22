pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract USDC is ERC20 {
    address public owner;

    constructor() ERC20("USDCmock", "USDC") {
        owner = msg.sender;
    }

}
