// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Campaign.sol";

contract Funding {
    Campaign public campaignContract;

    event ContributionReceived(uint indexed campaignId, address indexed contributor, uint amount);

    constructor(address payable _campaignAddress) {
        require(_campaignAddress != address(0), "Funding: Invalid campaign address");
        campaignContract = Campaign(_campaignAddress);
    }

    function contribute(uint _id) public payable {
        require(msg.value > 0, "Funding: Contribution must be > 0");
        
        // Safety checks (using require for user input validation)
        Campaign.CampaignData memory c = campaignContract.getCampaign(_id);
        require(block.timestamp < c.deadline, "Funding: Campaign has ended");
        require(!c.isWithdrawn, "Funding: Funds already withdrawn");
        require(!c.isRefunded, "Funding: Campaign refunded");
        require(c.fundsRaised < c.goal, "Funding: Goal already reached");
        require(msg.sender != c.creator, "Funding: Creator cannot contribute");

        // Forward ETH to the Campaign Core Vault
        (bool sent, ) = address(campaignContract).call{value: msg.value}("");
        if (!sent) {
            revert("Funding: Failed to forward ETH to Vault");
        }

        // Update state in the Core Vault
        campaignContract.addContribution(_id, msg.sender, msg.value);

        emit ContributionReceived(_id, msg.sender, msg.value);
        
        // Final invariant check: logic module should never hold ETH
        assert(address(this).balance == 0);
    }
    
    // Fallback to prevent accidental ETH locking
    receive() external payable {
        revert("Funding: Use contribute() function");
    }
}
