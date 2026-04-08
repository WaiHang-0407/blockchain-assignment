//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract MyContractModifier1{

    uint256 public peopleCount = 0;

    mapping(uint => Person) public people;

        struct Person{

        uint _id;

        string _firstName;

        string _lastName;

    }

    function addPerson(string memory _fName, string memory _lName) public {

        people[peopleCount] = Person(peopleCount, _fName, _lName);

        increamentCount();

    }

    //internal function

    function increamentCount() internal{

        peopleCount+=1;

    }

}