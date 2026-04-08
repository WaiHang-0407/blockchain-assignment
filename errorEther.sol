//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract sendEther{

function send(address payable toReceiver) public payable{

//call function returns a boolean value indicating success or falure.

//This is the current recommended method to use

(bool sent, ) = toReceiver.call{value:msg.value} (" ");

require(sent, " Failed to send Ether");

}

}