// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import OpenZeppelin ERC20 implementation
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RewardToken is ERC20, Ownable {
    constructor(address initialOwner) ERC20("CampaignRewardToken", "CRT") Ownable(initialOwner) {}

    function mint(address to, uint amount) external onlyOwner {
        _mint(to, amount);
    }
}