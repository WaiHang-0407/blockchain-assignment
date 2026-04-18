// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract UserAuth {
    struct User {
        string username;
        address userAddress;
        bool isRegistered;
    }

    mapping(address => User) private users;
    mapping(string => address) private usernameToAddress;

    event UserRegistered(address indexed userAddress, string username);

    function register(string memory _username) public {
        require(!users[msg.sender].isRegistered, "User: Already registered");
        require(bytes(_username).length > 0, "User: Username cannot be empty");
        
        if (usernameToAddress[_username] != address(0)) {
            revert("User: Username already taken");
        }

        users[msg.sender] = User({
            username: _username,
            userAddress: msg.sender,
            isRegistered: true
        });

        usernameToAddress[_username] = msg.sender;

        emit UserRegistered(msg.sender, _username);
        
        // Final sanity checks
        assert(users[msg.sender].isRegistered == true);
        assert(usernameToAddress[_username] == msg.sender);
    }

    function isUserRegistered(address _user) public view returns (bool) {
        return users[_user].isRegistered;
    }

    function isUsernameRegistered(string memory _username) public view returns (bool) {
        return usernameToAddress[_username] != address(0);
    }

    function getUser(address _user) public view returns (string memory, address, bool) {
        User memory u = users[_user];
        return (u.username, u.userAddress, u.isRegistered);
    }

    function deleteAccount() public {
        if (!users[msg.sender].isRegistered) {
            revert("User: Not registered");
        }

        string memory username = users[msg.sender].username;

        delete usernameToAddress[username];
        delete users[msg.sender];
        
        // Final sanity checks
        assert(users[msg.sender].isRegistered == false);
        assert(usernameToAddress[username] == address(0));
    }
}