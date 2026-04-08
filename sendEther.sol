// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract AccountsDemo {

address public whoDeposited;

uint public depositAmt;

uint public accountBalance;

function deposit() public payable{

whoDeposited = msg.sender;

depositAmt = msg.value;

accountBalance = address(this).balance;

}

}