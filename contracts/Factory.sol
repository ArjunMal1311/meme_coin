// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {Token} from "./Token.sol";

// Factory Contract is going to create new smart contracts on blockchain for each of the coins (tokens)

contract Factory {
    struct TokenSale {
        address token;
        string name;
        address creator;
        uint256 sold;
        uint256 raised;
        bool isOpen; 
    }


    uint256 public immutable fee;
    address public owner;

    address[] public tokens;
    uint256 public totalTokens;

    mapping(address => TokenSale) public tokenToSale;

    event Created(address indexed token);


    // the developer who created the contract is going to get a fee, so we can call this the owner
    // the owner is the one who will be going to get paid and is the one who is going to be able to deploy new tokens
    
    // Function -> Developer who deployed the contract is going to get paid anytime sombody lists a token
    constructor (uint256 _fee) {
        fee = _fee;
        owner = msg.sender; // msg.sender is the address of account that directly calls the function
    }

    function create(string memory _name, string memory _symbol) external payable {
        require(msg.value >= fee, "Fee not paid");

        Token token = new Token(msg.sender, _name, _symbol, 1_000_000 ether); // msg.sender is the creator of the token
        tokens.push(address(token));

        totalTokens ++;


        TokenSale memory sale = TokenSale(address(token), _name, msg.sender, 0, 0, true); // true means that the token is open for sale, 0 means that no tokens have been sold, 0 means that no money has been raised
        tokenToSale[address(token)] = sale;

        emit Created(address(token));
    }

    function getTokenSale(uint256 _index) public view returns (TokenSale memory) {
        return tokenToSale[tokens[_index]];
    }


    
}
