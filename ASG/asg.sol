// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Crowdfunding {

    // ==============================
    // Module 1: User Registration
    // ==============================

    struct User {
        string name;
        string email;
        bool isRegistered;
    }

    mapping(address => User) public users;

    modifier onlyRegistered() {
        require(users[msg.sender].isRegistered, "User not registered");
        _;
    }

    function registerUser(string memory _name, string memory _email) public {
        require(!users[msg.sender].isRegistered, "Already registered");

        users[msg.sender] = User({
            name: _name,
            email: _email,
            isRegistered: true
        });
    }

    function getUser(address _addr) public view returns (
        string memory, 
        string memory, 
        bool
    ) {
        User memory u = users[_addr];
        return (u.name, u.email, u.isRegistered);
    }

    // ==============================
    // Campaign Structure
    // ==============================

    struct Campaign {
        address payable creator;
        string title;
        uint goal;
        uint deadline;
        uint amountRaised;
        bool completed;
    }

    uint public campaignCount;
    mapping(uint => Campaign) public campaigns;

    mapping(uint => mapping(address => uint)) public contributions;

    // ==============================
    // Module 2: Create Campaign
    // ==============================
    function createCampaign(
        string memory _title, 
        uint _goal, 
        uint _duration
    ) public onlyRegistered {

        campaignCount++;

        campaigns[campaignCount] = Campaign(
            payable(msg.sender),
            _title,
            _goal,
            block.timestamp + _duration,
            0,
            false
        );
    }

    // ==============================
    // Module 3: Fund Campaign
    // ==============================
    function fundCampaign(uint _id) public payable onlyRegistered {
        Campaign storage c = campaigns[_id];

        require(block.timestamp < c.deadline, "Campaign ended");
        require(msg.value > 0, "Must send ETH");

        c.amountRaised += msg.value;
        contributions[_id][msg.sender] += msg.value;
    }

    // ==============================
    // Release Funds (Success)
    // ==============================
    function releaseFunds(uint _id) public {
        Campaign storage c = campaigns[_id];

        require(block.timestamp >= c.deadline, "Not ended yet");
        require(c.amountRaised >= c.goal, "Goal not reached");
        require(!c.completed, "Already completed");

        // EFFECT
        c.completed = true;

        // INTERACTION (safe call)
        (bool success, ) = c.creator.call{value: c.amountRaised}("");
        require(success, "Transfer failed");
    }

    // ==============================
    // Module 4: Refund
    // ==============================
    function refund(uint _id) public onlyRegistered {
        Campaign storage c = campaigns[_id];

        require(block.timestamp >= c.deadline, "Not ended yet");
        require(c.amountRaised < c.goal, "Goal reached");

        uint amount = contributions[_id][msg.sender];
        require(amount > 0, "No contribution");

        // EFFECT
        contributions[_id][msg.sender] = 0;

        // INTERACTION (safe call)
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Refund failed");
    }

    // ==============================
    // View Campaign
    // ==============================
    function getCampaign(uint _id) public view returns (
        address,
        string memory,
        uint,
        uint,
        uint,
        bool
    ) {
        Campaign memory c = campaigns[_id];
        return (
            c.creator,
            c.title,
            c.goal,
            c.deadline,
            c.amountRaised,
            c.completed
        );
    }

    // ==============================
    // Extra: Check Contribution
    // ==============================
    function getContribution(uint _id, address _user) public view returns (uint) {
        return contributions[_id][_user];
    }
}