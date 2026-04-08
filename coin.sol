// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Coin {

address public minter;

mapping(address => uint) public balances;

event Sent(address indexed from, address indexed to, uint
amount);

constructor() {

minter = msg.sender;

}

function mint(address receiver, uint amount) public {  //Create coint

require(msg.sender == minter, "Only the minter can mintcoins");

require(receiver != address(0), "Invalid receiveraddress");

require(amount > 0, "Amount must be greater thanzero");

balances[receiver] += amount;

}
function send(address receiver, uint amount) public {

require(receiver != address(0), "Invalid receiveraddress");  //0x0000000000000000000000000000000000000000

require(amount > 0, "Amount must be greater thanzero");

require(balances[msg.sender] >= amount,"Insufficient balance");

balances[msg.sender] -= amount;

balances[receiver] += amount;

emit Sent(msg.sender, receiver, amount);

}

}