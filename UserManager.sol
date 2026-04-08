// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract UserManager {

    // Struct to store user details
    struct User {
        string name;
        uint age;
        string email;
        bool isRegistered;
    }

    // Mapping: address => User
    mapping(address => User) public users;

    // Event to log registration
    event UserRegistered(address indexed userAddress, string name, uint age, string email);

    // Function to register a user
    function registerUser(string memory name, uint age, string memory email) public {

        // Prevent duplicate registration
        require(!users[msg.sender].isRegistered, "User already registered");

        // Basic validation
        require(bytes(name).length > 0, "Name cannot be empty");
        require(age > 0, "Age must be greater than 0");
        require(bytes(email).length > 0, "Email cannot be empty");

        // Store user data
        users[msg.sender] = User(name, age, email, true);

        // Emit event
        emit UserRegistered(msg.sender, name, age, email);
    }

    // Function to get user details
    function getUserDetails(address userAddr) public view returns (
        string memory name,
        uint age,
        string memory email,
        bool isRegistered
    ) {
        User memory user = users[userAddr];
        return (user.name, user.age, user.email, user.isRegistered);
    }
}