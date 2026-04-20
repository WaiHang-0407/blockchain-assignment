// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./RewardToken.sol";

contract Campaign {
    // --- Voting State ---
    mapping(uint => mapping(address => bool)) public hasVoted;
    mapping(uint => uint) public voteCount;
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
    mapping(uint => mapping(address => uint)) public contributions;
    mapping(uint => address[]) public campaignContributors;
    mapping(uint => mapping(address => bool)) public refunded; // To match server.js ABI check

    event CampaignCreated(uint indexed id, address indexed creator, string title, uint goal, uint deadline, uint timestamp);
    event ContributionMade(uint indexed campaignId, address indexed contributor, uint amount, uint timestamp);
    event RefundIssued(uint indexed campaignId, address indexed contributor, uint amount, uint timestamp);
    event RefundCompleted(uint indexed campaignId, uint timestamp);
    event FundsWithdrawn(uint indexed campaignId, address indexed creator, uint amount, uint timestamp);
    
    RewardToken public rewardToken;
    address public owner;
    mapping(address => bool) public authorizedModules;

    modifier onlyOwner() {
        require(msg.sender == owner, "Campaign: Only owner");
        _;
    }

    modifier onlyAuthorized() {
        require(authorizedModules[msg.sender] || msg.sender == owner, "Campaign: Not authorized");
        _;
    }

    constructor(address _rewardTokenAddress) {
        rewardToken = RewardToken(_rewardTokenAddress);
        owner = msg.sender;
    }

    function authorizeModule(address _module) public onlyOwner {
        require(_module != address(0), "Campaign: Invalid module address");
        authorizedModules[_module] = true;
    }

    function createCampaign(string memory _title, string memory _description, uint _goal, uint _deadline) public {
        require(_goal > 0, "Campaign: Goal must be > 0");
        require(_deadline > block.timestamp, "Campaign: Deadline must be in future");
        
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

        // State assertions
        assert(campaigns[campaignCount].id == campaignCount);
        assert(campaigns[campaignCount].creator == msg.sender);
        assert(campaigns[campaignCount].goal == _goal);

        emit CampaignCreated(campaignCount, msg.sender, _title, _goal, _deadline, block.timestamp);
    }

    // --- Module Interactivity Functions ---

    function addContribution(uint _id, address _contributor, uint _amount) external onlyAuthorized {
        CampaignData storage c = campaigns[_id];
        
        if (contributions[_id][_contributor] == 0) {
            campaignContributors[_id].push(_contributor);
        }

        uint prevFunds = c.fundsRaised;
        c.fundsRaised += _amount;
        contributions[_id][_contributor] += _amount;

        // Verify state change
        assert(c.fundsRaised == prevFunds + _amount);

        emit ContributionMade(_id, _contributor, _amount, block.timestamp);
    }

    function markRefunded(uint _id, address _contributor, uint _amount) external onlyAuthorized {
        campaigns[_id].isRefunded = true;
        refunded[_id][_contributor] = true;
        
        // The sender (AutoRefund module) is calling this, but we need to actually send the money
        (bool sent, ) = payable(_contributor).call{value: _amount}("");
        if (!sent) {
            revert("Campaign: Refund transfer failed");
        }

        emit RefundIssued(_id, _contributor, _amount, block.timestamp);
        
        // Final assertion
        assert(campaigns[_id].isRefunded == true);
    }

    // --- Core Functions ---

    function withdraw(uint _id) public {
        CampaignData storage c = campaigns[_id];
        require(msg.sender == c.creator, "Campaign: Only creator can withdraw");
        require(!c.isWithdrawn, "Campaign: Already withdrawn");
        require(!c.isRefunded, "Campaign: Already refunded");
        require(c.fundsRaised >= c.goal, "Campaign: Goal not met");

        c.isWithdrawn = true;
        uint256 amountToWithdraw = c.fundsRaised;
        
        (bool sent, ) = payable(c.creator).call{value: amountToWithdraw}("");
        if (!sent) {
            revert("Campaign: Withdraw failed");
        }

        emit FundsWithdrawn(_id, msg.sender, amountToWithdraw, block.timestamp);
        
        // Post-execution assertion
        assert(c.isWithdrawn == true);
        assert(address(this).balance >= 0);

        // Mint rewards
        for (uint i = 0; i < campaignContributors[_id].length; i++) {
            address contributor = campaignContributors[_id][i];
            uint amount = contributions[_id][contributor];
            if (amount > 0) {
                rewardToken.mint(contributor, amount);
            }
        }
    }

    // --- Frontend Compatibility Functions (app.js) ---

    function contribute(uint _id) public payable {
        CampaignData storage c = campaigns[_id];
        require(block.timestamp < c.deadline, "Campaign: Has ended");
        require(!c.isWithdrawn, "Campaign: Funds already withdrawn");
        require(!c.isRefunded, "Campaign: Refunded");
        require(msg.value > 0, "Campaign: Contribution must be > 0");
        require(c.fundsRaised < c.goal, "Campaign: Goal reached");
        require(msg.sender != c.creator, "Campaign: Creator cannot contribute");

        if (contributions[_id][msg.sender] == 0) {
            campaignContributors[_id].push(msg.sender);
        }

        c.fundsRaised += msg.value;
        contributions[_id][msg.sender] += msg.value;

        emit ContributionMade(_id, msg.sender, msg.value, block.timestamp);
    }

    function autoRefund(uint _id) public {
        CampaignData storage c = campaigns[_id];
        require(block.timestamp >= c.deadline, "Campaign: Still active");
        require(c.fundsRaised < c.goal, "Campaign: Goal was met");
        require(!c.isRefunded, "Campaign: Already refunded");

        c.isRefunded = true;

        for (uint i = 0; i < campaignContributors[_id].length; i++) {
            address contributor = campaignContributors[_id][i];
            uint amount = contributions[_id][contributor];

            if (amount > 0) {
                contributions[_id][contributor] = 0;
                (bool sent, ) = payable(contributor).call{value: amount}("");
                require(sent, "Campaign: Refund failed");
                emit RefundIssued(_id, contributor, amount, block.timestamp);
            }
        }
        emit RefundCompleted(_id, block.timestamp);
    }

    function deleteCampaign(uint _id) public {
        CampaignData storage c = campaigns[_id];
        require(msg.sender == c.creator, "Campaign: Only creator can delete");
        require(
            (c.isRefunded && c.fundsRaised == 0) ||
                (c.isWithdrawn) ||
                (c.fundsRaised == 0 && block.timestamp < c.deadline),
            "Campaign: Active funds remain"
        );

        delete campaigns[_id];
    }


    // --- Voting Functions ---
    function vote(uint campaignId) public {
        require(!hasVoted[campaignId][msg.sender], "Already voted");
        uint8 tier = rewardToken.getTier(msg.sender);
        require(tier >= 2, "Must be Silver or above to vote");
        hasVoted[campaignId][msg.sender] = true;
        if (tier == 3) {
            voteCount[campaignId] += 2; // Gold counts as 2 votes
        } else {
            voteCount[campaignId] += 1; // Silver counts as 1 vote
        }
    }

    function getVotes(uint campaignId) public view returns (uint) {
        return voteCount[campaignId];
    }

    // --- View Functions (preserving existing API for JS) ---

    function getActiveCampaigns() public view returns (CampaignData[] memory) {
        uint activeCount = 0;
        for (uint i = 1; i <= campaignCount; i++) {
            if (block.timestamp < campaigns[i].deadline && !campaigns[i].isWithdrawn) {
                activeCount++;
            }
        }
        CampaignData[] memory res = new CampaignData[](activeCount);
        uint index = 0;
        for (uint i = 1; i <= campaignCount; i++) {
            if (block.timestamp < campaigns[i].deadline && !campaigns[i].isWithdrawn) {
                res[index++] = campaigns[i];
            }
        }
        return res;
    }

    function getMyCampaigns(address _creator) public view returns (CampaignData[] memory) {
        uint count = 0;
        for (uint i = 1; i <= campaignCount; i++) {
            if (campaigns[i].creator == _creator) count++;
        }
        CampaignData[] memory res = new CampaignData[](count);
        uint index = 0;
        for (uint i = 1; i <= campaignCount; i++) {
            if (campaigns[i].creator == _creator) res[index++] = campaigns[i];
        }
        return res;
    }

    function getCampaign(uint _id) public view returns (CampaignData memory) {
        return campaigns[_id];
    }

    function getContributors(uint _id) public view returns (address[] memory) {
        return campaignContributors[_id];
    }

    function getContributorCount(uint _id) public view returns (uint) {
        return campaignContributors[_id].length;
    }

    function getContributor(uint _id, uint _index) public view returns (address contributor, uint amount) {
        contributor = campaignContributors[_id][_index];
        amount = contributions[_id][contributor];
    }

    // Receive function to allow Funding logic to send ETH here
    receive() external payable {}
}
