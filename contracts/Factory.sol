// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {Token} from "./Token.sol";

// Factory Contract is going to create new smart contracts on blockchain for each of the coins (tokens)

contract Factory {
    uint256 public constant TARGET = 3 ether;
    uint256 public constant TOKEN_LIMIT = 500_000 ether;

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
    event Buy(address indexed token, uint256 amount);

    // the developer who created the contract is going to get a fee, so we can call this the owner
    // the owner is the one who will be going to get paid and is the one who is going to be able to deploy new tokens

    // Function -> Developer who deployed the contract is going to get paid anytime sombody lists a token
    constructor(uint256 _fee) {
        fee = _fee;
        owner = msg.sender; // msg.sender is the address of account that directly calls the function
    }

    function create(
        string memory _name,
        string memory _symbol
    ) external payable {
        require(msg.value >= fee, "Fee not paid");

        Token token = new Token(msg.sender, _name, _symbol, 1_000_000 ether); // msg.sender is the creator of the token
        tokens.push(address(token));

        totalTokens++;

        TokenSale memory sale = TokenSale(
            address(token),
            _name,
            msg.sender,
            0,
            0,
            true
        ); // true means that the token is open for sale, 0 means that no tokens have been sold, 0 means that no money has been raised
        tokenToSale[address(token)] = sale;

        emit Created(address(token));
    }

    function getTokenSale(
        uint256 _index
    ) public view returns (TokenSale memory) {
        return tokenToSale[tokens[_index]];
    }

    function getCost(uint256 _sold) public pure returns (uint256) {
        uint256 floor = 0.0001 ether;
        uint256 step = 0.0001 ether;
        uint256 increment = 10000 ether;

        uint256 cost = (step * (_sold / increment)) + floor;
        return cost;
    }

    function buy(address _token, uint256 _amount) external payable {
        TokenSale storage sale = tokenToSale[_token];

        require(sale.isOpen, "Sale is not open");
        require(_amount >= 1 ether, "Amount must be greater than 0");
        require(_amount <= 10000 ether, "Amount must be less than 10000 ether");

        uint256 cost = getCost(sale.sold);
        uint256 price = cost * (_amount / 10 ** 18);

        require(msg.value >= price, "Not enough ether sent");

        sale.sold += _amount;
        sale.raised += price;

        if (sale.sold >= TOKEN_LIMIT || sale.raised >= TARGET) {
            sale.isOpen = false;
        }

        Token(_token).transfer(msg.sender, _amount);

        emit Buy(_token, _amount);
    }
}
