pragma solidity ^0.8.0;

contract DynamicArrayExample {

uint256[] public dynamicArray;

// Function to push an element to the dynamic array

function pushElement(uint256 _element) public {

dynamicArray.push(_element);

}

// Function to get the length of the dynamic array

function getArrayLength() public view returns (uint256) {

return dynamicArray.length;

}

function getAllElements() public view returns (uint256[] memory) {

return dynamicArray;

}

function popElement() public {

require(dynamicArray.length > 0, "Array is empty");

dynamicArray.pop();

}

}