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
}
