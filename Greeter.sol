// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract Greeter {
    string private yourname;

    constructor()  {
        yourname = "Hello World 123";
    }

    function set (string memory name) public {
        yourname = name;
    }

    function get() public view returns (string memory) {
        return yourname;
    }
}