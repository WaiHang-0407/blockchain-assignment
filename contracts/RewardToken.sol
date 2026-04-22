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


}