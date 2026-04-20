const fs = require('fs')
const path = require('path')
const { ethers } = require('ethers')

async function main() {
  const provider = new ethers.providers.JsonRpcProvider('http://127.0.0.1:7545')
  const accounts = await provider.listAccounts()
  if (accounts.length < 3) {
    console.error('Need at least 3 accounts from the provider (Ganache)')
    process.exit(1)
  }

  const deployer = provider.getSigner(accounts[0])
  const alice = provider.getSigner(accounts[1])
  const bob = provider.getSigner(accounts[2])

  const artifactsDir = path.join(__dirname, '..', 'artifacts')
  const rewardArtifact = JSON.parse(fs.readFileSync(path.join(artifactsDir, 'RewardToken.json'), 'utf8'))
  const campaignArtifact = JSON.parse(fs.readFileSync(path.join(artifactsDir, 'Campaign.json'), 'utf8'))

  const rewardAbi = rewardArtifact.abi
  const rewardBytecode = rewardArtifact.data.bytecode.object
  const campaignAbi = campaignArtifact.abi
  const campaignBytecode = campaignArtifact.data.bytecode.object

  console.log('Deploying RewardToken...')
  const RewardFactory = new ethers.ContractFactory(rewardAbi, '0x' + rewardBytecode, deployer)
  const reward = await RewardFactory.deploy(accounts[0])
  await reward.deployed()
  console.log('RewardToken deployed at', reward.address)

  console.log('Deploying Campaign...')
  const CampaignFactory = new ethers.ContractFactory(campaignAbi, '0x' + campaignBytecode, deployer)
  const campaign = await CampaignFactory.deploy(reward.address)
  await campaign.deployed()
  console.log('Campaign deployed at', campaign.address)

  // Mint sample balances (deployer is owner)
  console.log('Minting tokens: alice=1, bob=500')
  let tx = await reward.mint(accounts[1], 1)
  await tx.wait()
  tx = await reward.mint(accounts[2], 500)
  await tx.wait()

  const aBal = await reward.balanceOf(accounts[1])
  const bBal = await reward.balanceOf(accounts[2])
  console.log('Balances:', accounts[1], aBal.toString(), accounts[2], bBal.toString())

  const aTier = await reward.getTier(accounts[1])
  const bTier = await reward.getTier(accounts[2])
  console.log('Tiers:', accounts[1], aTier.toString(), accounts[2], bTier.toString())

  // Create a campaign (id == 1)
  const now = Math.floor(Date.now() / 1000)
  tx = await campaign.createCampaign('Test1', 'desc', 1, now + 3600)
  await tx.wait()
  console.log('Campaign 1 created')

  // Alice (bronze) tries to vote -> expect revert
  try {
    console.log('Alice (bronze) attempting to vote (should revert)')
    const t = await campaign.connect(alice).vote(1)
    await t.wait()
    console.error('ERROR: Alice vote unexpectedly succeeded')
  } catch (err) {
    console.log('Alice vote reverted as expected')
  }

  // Bob (gold) votes
  console.log('Bob (gold) voting on campaign 1')
  tx = await campaign.connect(bob).vote(1)
  await tx.wait()
  const votes1 = await campaign.getVotes(1)
  console.log('Campaign 1 votes:', votes1.toString(), '(expected 2)')

  // Make Alice silver by minting 100 more
  console.log('Upgrading Alice to Silver by minting 100 tokens')
  tx = await reward.mint(accounts[1], 100)
  await tx.wait()
  const aBal2 = await reward.balanceOf(accounts[1])
  const aTier2 = await reward.getTier(accounts[1])
  console.log('Alice balance:', aBal2.toString(), 'tier:', aTier2.toString())

  // Create campaign 2 and have Alice vote
  tx = await campaign.createCampaign('Test2', 'desc', 1, now + 3600)
  await tx.wait()
  console.log('Campaign 2 created')
  tx = await campaign.connect(alice).vote(2)
  await tx.wait()
  const votes2 = await campaign.getVotes(2)
  console.log('Campaign 2 votes:', votes2.toString(), '(expected 1)')

  console.log('All tests complete')
}

main().catch(err => {
  console.error('Test script failed:', err)
  process.exit(1)
})
