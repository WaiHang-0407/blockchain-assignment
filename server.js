const express = require("express");
const path = require("path");
const { ethers } = require("ethers");

const app = express();

// Serve everything in project folder
app.use(express.static(path.join(__dirname)));

app.get("/", (req, res) => {
  res.sendFile(path.join(__dirname, "index.html"));
});

// Ganache setup
const provider = new ethers.JsonRpcProvider("http://127.0.0.1:7545");
const privateKey = "0x054cbfcee1f7d63bb9e33952f6e3cf025eda577a1211ac9426b3a8ba236d63ae";
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
const campaignAddress = "0x451D9D3dF42dB6B2a003e71f372982e261A709De";
const autoRefundAddress = "0xf29B32e462053108577A8e7d544EDb299d96cF89";

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