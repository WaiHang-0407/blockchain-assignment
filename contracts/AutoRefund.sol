// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Campaign.sol";

contract AutoRefund {
    Campaign public campaignContract;

    event RefundIssuedToAll(uint indexed campaignId, uint count, uint totalAmount);

    constructor(address payable _campaignAddress) {
        require(_campaignAddress != address(0), "AutoRefund: Invalid campaign address");
        campaignContract = Campaign(_campaignAddress);
    }

    function issueRefundToAll(uint _id) public {
        Campaign.CampaignData memory c = campaignContract.getCampaign(_id);

        require(block.timestamp >= c.deadline, "AutoRefund: Campaign still active");
        require(c.fundsRaised < c.goal, "AutoRefund: Goal was met");
        require(!c.isRefunded, "AutoRefund: Already refunded");

        if (_id == 0) {
            revert("AutoRefund: Invalid campaign ID");
        }

        uint contributorCount = campaignContract.getContributorCount(_id);
        if (contributorCount == 0) {
            revert("AutoRefund: No contributors to refund");
        }

        uint totalRefunded = 0;

        for (uint i = 0; i < contributorCount; i++) {
            (address contributor, uint amount) = campaignContract.getContributor(_id, i);

            if (amount > 0) {
                // Trigger the refund emission in the Core Vault
                campaignContract.markRefunded(_id, contributor, amount);

                
                // For simplicity and matching the original logic:
                // We'll update Campaign.sol to have a `processExternalRefund` function.
                totalRefunded += amount;
            }
        }

        emit RefundIssuedToAll(_id, contributorCount, totalRefunded);
        
        // Final sanity check: Verify core vault reflects refund status
        Campaign.CampaignData memory finalState = campaignContract.getCampaign(_id);
        assert(finalState.isRefunded == true);
    }
}
