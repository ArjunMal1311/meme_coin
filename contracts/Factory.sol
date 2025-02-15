// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

contract Factory {
    uint256 public immutable fee;
    address public owner;


    // Function -> Developer who deployed the contract is going to get paid anytime sombody lists a token
    constructor (uint256 _fee) {
        fee = _fee;
        owner = msg.sender; // msg.sender is the address of account that directly calls the function
    }
    
}
