const express = require("express");
const path = require("path");
const { ethers } = require("ethers");

const app = express();

app.use(express.json());

// Serve everything in project folder
app.use(express.static(path.join(__dirname)));

app.get("/", (req, res) => {
  res.sendFile(path.join(__dirname, "index.html"));
});

// Ganache setup
const provider = new ethers.JsonRpcProvider("http://127.0.0.1:7545");
const privateKey = "0x1a648402d35e802742343ff55372bfb7204f308835edb5cba74bb432e7126d7a";
const signer = new ethers.Wallet(privateKey, provider);

// Wrap async logic in a function
async function startAutoRefund() {
  setInterval(async () => {
    console.log("Checking campaigns at", new Date().toLocaleTimeString());

    try {
      // Force a block mine to advance blockchain time (required for Ganache/local testing)
      await provider.send("evm_mine", []);

      const campaignContract = new ethers.Contract(campaignAddress, campaignABI, signer);
      const autoRefundContract = new ethers.Contract(autoRefundAddress, autoRefundABI, signer);
      
      const count = await campaignContract.campaignCount();

      const block = await provider.getBlock("latest");
      const now = BigInt(block.timestamp);

      for (let i = 1; i <= count; i++) {
        const campaign = await campaignContract.campaigns(i);

        const deadline = BigInt(campaign.deadline);
        const fundsRaised = BigInt(campaign.fundsRaised);
        const goal = BigInt(campaign.goal);

        console.log(`Campaign ${i}: deadline=${deadline}, now=${now}`);

        // Logic check: if deadline passed AND goal not met AND not already refunded
        if (now >= deadline && fundsRaised < goal && !campaign.isRefunded) {
          console.log("   ⚡ Triggering aggregate refund for Campaign:", i);
          const tx = await autoRefundContract.issueRefundToAll(i);
          await tx.wait();
          console.log("   ✅ Refund transaction confirmed for campaign:", i);
        } else {
          let reason = "";
          if (now < deadline) reason = "Still active";
          else if (fundsRaised >= goal) reason = "Goal met";
          else if (campaign.isRefunded) reason = "Already refunded";
          else if (campaign.isWithdrawn) reason = "Already withdrawn";
          
          console.log(`Campaign ${i} skipped: ${reason}`);
        }
      }
    } catch (err) {
      console.error("Auto refund loop error:", err);
    }
  }, 10000); // Check every 10 seconds
}

// Start the server and auto refund loop
const port = 5000;
app.listen(port, () => {
  console.log(`Server running on http://127.0.0.1:${port}`);
  startAutoRefund().catch(console.error);
});

// Contract Configuration
const campaignAddress = "0xEEB21bca629fe172a879460a8994E7f4C5A2FBa2";
const autoRefundAddress = "0xa5AB5339a985FF3De1fB60CE01e22973916b6bDE";
const rewardTokenAddress = "0xdAFe7327FeC0c5a4057A9DAbe8e5CeBfbd184BbC";

// Minimal ABIs needed for server operation
const campaignABI = [
  {
    "inputs": [],
    "name": "campaignCount",
    "outputs": [{"internalType": "uint256","name": "","type": "uint256"}],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [{"internalType": "uint256","name": "","type": "uint256"}],
    "name": "campaigns",
    "outputs": [
      {"internalType": "uint256","name": "id","type": "uint256"},
      {"internalType": "address","name": "creator","type": "address"},
      {"internalType": "string","name": "title","type": "string"},
      {"internalType": "string","name": "description","type": "string"},
      {"internalType": "uint256","name": "goal","type": "uint256"},
      {"internalType": "uint256","name": "deadline","type": "uint256"},
      {"internalType": "uint256","name": "fundsRaised","type": "uint256"},
      {"internalType": "bool","name": "isWithdrawn","type": "bool"},
      {"internalType": "bool","name": "isRefunded","type": "bool"},
      {"internalType": "uint256","name": "createdAt","type": "uint256"}
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [{"internalType": "uint256","name": "campaignId","type": "uint256"}],
    "name": "getVotes",
    "outputs": [{"internalType": "uint256","name": "","type": "uint256"}],
    "stateMutability": "view",
    "type": "function"
  }
];

const rewardTokenABI = [
  {
    "inputs": [{"internalType": "address","name": "user","type": "address"}],
    "name": "getTier",
    "outputs": [{"internalType": "uint8","name": "","type": "uint8"}],
    "stateMutability": "view",
    "type": "function"
  }
];

const autoRefundABI = [
  {
    "inputs": [{"internalType": "uint256","name": "_id","type": "uint256"}],
    "name": "issueRefundToAll",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  }
];

app.get("/api/votes/:campaignId", async (req, res) => {
  try {
    const campaignContract = new ethers.Contract(campaignAddress, campaignABI, provider);
    const votes = await campaignContract.getVotes(req.params.campaignId);
    res.json({ campaignId: String(req.params.campaignId), votes: votes.toString() });
  } catch (err) {
    res.status(400).json({ error: err?.message ?? String(err) });
  }
});

app.get("/api/tier/:address", async (req, res) => {
  try {
    const reward = new ethers.Contract(rewardTokenAddress, rewardTokenABI, provider);
    const tier = await reward.getTier(req.params.address);
    res.json({ address: String(req.params.address), tier: Number(tier) });
  } catch (err) {
    res.status(400).json({ error: err?.message ?? String(err) });
  }
});