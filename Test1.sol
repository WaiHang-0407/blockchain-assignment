// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract counter {
    uint public count;

    // Function to get the current count
    function get() public view returns (uint) {
        return count;
    }

    // Function to increment count by 1
    function increase() public {
        count += 1;
    }

    // Function to decrement count by 1
    function decrease() public {
        count -= 1;
    }

}