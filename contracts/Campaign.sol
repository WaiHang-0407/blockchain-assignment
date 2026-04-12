// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./UserAuth.sol";
import "./RewardToken.sol";

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
        bool isRefunded;
        uint createdAt;
    }

    uint public campaignCount;
    mapping(uint => CampaignData) public campaigns;

    event CampaignCreated(
        uint indexed id,
        address indexed creator,
        string title,
        uint goal,
        uint deadline,
        uint timestamp
    );

    event ContributionMade(
        uint indexed campaignId,
        address indexed contributor,
        uint amount,
        uint timestamp
    );

    event RefundIssued(
        uint indexed campaignId,
        address indexed contributor,
        uint amount,
        uint timestamp
    );

    event RefundCompleted(uint indexed campaignId, uint timestamp);

    event FundsWithdrawn(
        uint indexed campaignId,
        address indexed creator,
        uint amount,
        uint timestamp
    );

    RewardToken public rewardToken;

    constructor(address _rewardTokenAddress) {
        rewardToken = RewardToken(_rewardTokenAddress);
    }

    mapping(uint => mapping(address => uint)) public contributions;
    mapping(uint => address[]) public campaignContributors;

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
            isWithdrawn: false,
            isRefunded: false,
            createdAt: block.timestamp
        });
        emit CampaignCreated(
            campaignCount,
            msg.sender,
            _title,
            _goal,
            _deadline,
            block.timestamp
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

    function contribute(uint _id) public payable {
        CampaignData storage c = campaigns[_id];
        require(block.timestamp < c.deadline, "Campaign has ended");
        require(!c.isWithdrawn, "Funds already withdrawn");
        require(!c.isRefunded, "Campaign refunded");
        require(msg.value > 0, "Contribution must be greater than 0");
        require(c.fundsRaised < c.goal, "Goal already reached");
        require(msg.sender != c.creator, "Creator cannot contribute");

        if (contributions[_id][msg.sender] == 0) {
            campaignContributors[_id].push(msg.sender);
        }

        c.fundsRaised += msg.value;
        contributions[_id][msg.sender] += msg.value;

        emit ContributionMade(_id, msg.sender, msg.value, block.timestamp);
    }

    function finalizeCampaign(uint _id) public {
        CampaignData storage c = campaigns[_id];
        require(block.timestamp >= c.deadline, "Campaign still active");
        require(!c.isWithdrawn, "Already withdrawn");
        require(!c.isRefunded, "Already refunded");

        if (c.fundsRaised >= c.goal) {
            // Success: do nothing here, creator must call withdraw()
            revert("Goal met: creator must withdraw funds");
        } else {
            // Failure → refund contributors automatically
            for (uint i = 0; i < campaignContributors[_id].length; i++) {
                address contributor = campaignContributors[_id][i];
                uint amount = contributions[_id][contributor];
                if (amount > 0) {
                    contributions[_id][contributor] = 0;
                    (bool sent, ) = payable(contributor).call{value: amount}(
                        ""
                    );
                    require(sent, "Refund failed");
                    emit RefundIssued(
                        _id,
                        contributor,
                        amount,
                        block.timestamp
                    );
                }
            }
            c.isRefunded = true;
            emit RefundCompleted(_id, block.timestamp);
        }
    }

    function withdraw(uint _id) public {
        CampaignData storage c = campaigns[_id];
        require(msg.sender == c.creator, "Only creator can withdraw");
        require(!c.isWithdrawn, "Already withdrawn");
        require(!c.isRefunded, "Campaign refunded");
        require(c.fundsRaised >= c.goal, "Goal not met");

        c.isWithdrawn = true;
        (bool sent, ) = payable(c.creator).call{value: c.fundsRaised}("");
        require(sent, "Withdraw failed");
        emit FundsWithdrawn(_id, msg.sender, c.fundsRaised, block.timestamp);

        // Mint reward tokens to contributors
        for (uint i = 0; i < campaignContributors[_id].length; i++) {
            address contributor = campaignContributors[_id][i];
            uint amount = contributions[_id][contributor];
            if (amount > 0) {
                // Example: 1 token per 1 wei contributed
                rewardToken.mint(contributor, amount);
            }
        }
    }

    function getContributors(uint _id) public view returns (address[] memory) {
        return campaignContributors[_id];
    }
}
