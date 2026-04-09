// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./UserAuth.sol";

contract Campaign {
    struct CampaignData {
        uint id;
        address creator;
        string title;
        string description;
        uint goal;
        uint deadline;
        uint fundsRaised;
        bool isWithdrawn;
    }

    uint public campaignCount;
    mapping(uint => CampaignData) public campaigns;
    event CampaignCreated(
        uint indexed id,
        address indexed creator,
        string title,
        uint goal,
        uint deadline
    );

    function createCampaign(
        string memory _title,
        string memory _description,
        uint _goal,
        uint _deadline
    ) public {
        require(_goal > 0, "Goal must be greater than 0");
        require(_deadline > block.timestamp, "Deadline must be in the future");
        campaignCount++;
        campaigns[campaignCount] = CampaignData({
            id: campaignCount,
            creator: msg.sender,
            title: _title,
            description: _description,
            goal: _goal,
            deadline: _deadline,
            fundsRaised: 0,
            isWithdrawn: false
        });
        emit CampaignCreated(
            campaignCount,
            msg.sender,
            _title,
            _goal,
            _deadline
        );
    }

    function getActiveCampaigns() public view returns (CampaignData[] memory) {
        uint activeCount = 0;
        for (uint i = 1; i <= campaignCount; i++) {
            if (
                block.timestamp < campaigns[i].deadline &&
                !campaigns[i].isWithdrawn
            ) {
                activeCount++;
            }
        }
        CampaignData[] memory activeCampaigns = new CampaignData[](activeCount);
        uint index = 0;
        for (uint i = 1; i <= campaignCount; i++) {
            if (
                block.timestamp < campaigns[i].deadline &&
                !campaigns[i].isWithdrawn
            ) {
                activeCampaigns[index] = campaigns[i];
                index++;
            }
        }
        return activeCampaigns;
    }

    function getMyCampaigns(
        address _creator
    ) public view returns (CampaignData[] memory) {
        uint count = 0;
        for (uint i = 1; i <= campaignCount; i++) {
            if (campaigns[i].creator == _creator) {
                count++;
            }
        }
        CampaignData[] memory myCampaigns = new CampaignData[](count);
        uint index = 0;
        for (uint i = 1; i <= campaignCount; i++) {
            if (campaigns[i].creator == _creator) {
                myCampaigns[index] = campaigns[i];
                index++;
            }
        }
        return myCampaigns;
    }

    event ContributionMade(
        uint indexed campaignId,
        address indexed contributor,
        uint amount
    );

    mapping(uint => mapping(address => uint)) public contributions;

    function contribute(uint _id) public payable {
        CampaignData storage c = campaigns[_id];
        require(block.timestamp < c.deadline, "Campaign has ended");
        require(!c.isWithdrawn, "Funds already withdrawn");
        require(msg.value > 0, "Contribution must be greater than 0");
        require(c.fundsRaised < c.goal, "Goal already reached"); // strict version

        c.fundsRaised += msg.value;
        contributions[_id][msg.sender] += msg.value;

        emit ContributionMade(_id, msg.sender, msg.value);
    }

    event RefundIssued(
        uint indexed campaignId,
        address indexed contributor,
        uint amount
    );

    function refund(uint _id) public {
        CampaignData storage c = campaigns[_id];
        require(block.timestamp >= c.deadline, "Campaign still active");
        require(c.fundsRaised < c.goal, "Campaign reached its goal");

        uint contributed = contributions[_id][msg.sender];
        require(contributed > 0, "No contributions to refund");

        contributions[_id][msg.sender] = 0; // reset before transfer
        (bool sent, ) = payable(msg.sender).call{value: contributed}("");
        require(sent, "Refund failed");

        emit RefundIssued(_id, msg.sender, contributed);
    }

    event FundsWithdrawn(
        uint indexed campaignId,
        address indexed creator,
        uint amount
    );

    function withdraw(uint _id) public {
        CampaignData storage c = campaigns[_id];
        require(msg.sender == c.creator, "Only creator can withdraw");
        require(block.timestamp >= c.deadline, "Campaign not ended yet");
        require(c.fundsRaised >= c.goal, "Goal not reached");
        require(!c.isWithdrawn, "Already withdrawn");

        c.isWithdrawn = true;
        (bool sent, ) = payable(c.creator).call{value: c.fundsRaised}("");
        require(sent, "Withdraw failed");

        emit FundsWithdrawn(_id, msg.sender, c.fundsRaised);
    }
}
