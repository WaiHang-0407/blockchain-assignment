// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Register {
    struct User {
        string username;
        address userAddress;
        bool isRegistered;
    }

    mapping(address => User) private users;
    mapping(string => address) private usernameToAddress; // NEW mapping

    event UserRegistered(address indexed userAddress, string username);

    function register(string memory _username) public {
        users[msg.sender] = User({
            username: _username,
            userAddress: msg.sender,
            isRegistered: true
        });

        usernameToAddress[_username] = msg.sender; // store username → wallet

        emit UserRegistered(msg.sender, _username);
    }

    function isUserRegistered(address _user) public view returns (bool) {
        return users[_user].isRegistered;
    }

    function getUser(address _user) public view returns (string memory, address, bool) {
        User memory u = users[_user];
        return (u.username, u.userAddress, u.isRegistered);
    }

    function login() public view returns (string memory) {
        require(users[msg.sender].isRegistered, "Not registered");
        return string.concat("Welcome back, ", users[msg.sender].username);
    }
}