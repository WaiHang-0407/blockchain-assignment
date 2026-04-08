// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract myContractStruct {
    
    struct Person {
        string _firstName;
        string _lastName;
    }

    Person[] public people;
    uint256 public peopleCount;

    function addPerson (string memory _firstName, string memory _lastName) public {
        people.push (Person(_firstName, _lastName));
        peopleCount++;
    }

}