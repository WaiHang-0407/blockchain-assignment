// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract AddressExample {

    address public regularAddress;

    address payable public payableAddress;

    constructor(address _regularAddress, address payable _payableAddress) {

    regularAddress = _regularAddress;

    payableAddress = _payableAddress;

    }

    function sendEtherToPayableAddress() public payable {

        payableAddress.transfer(msg.value);

    }

}