// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RewardToken is ERC20, Ownable {
    constructor(address initialOwner) ERC20("CampaignRewardToken", "CRT") Ownable(initialOwner) {
        assert(owner() == initialOwner);
    }

    function mint(address to, uint amount) external onlyOwner {
        require(to != address(0), "Token: Cannot mint to zero address");
        uint256 beforeBalance = balanceOf(to);
        _mint(to, amount);
        assert(balanceOf(to) == beforeBalance + amount);
    }

    // Returns 0 = None, 1 = Bronze, 2 = Silver, 3 = Gold
    // Demo-friendly thresholds: raw token units (no 1e18 multiplier)
    function getTier(address user) public view returns (uint8) {
        uint256 bal = balanceOf(user);
        if (bal >= 500) {
            return 3;
        } else if (bal >= 100) {
            return 2;
        } else if (bal >= 1) {
            return 1;
        } else {
            return 0;
        }
    }
}