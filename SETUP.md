# 🚀 Modular Crowdfunding System - Setup Guide

This guide provides step-by-step instructions to deploy and run the modular crowdfunding application using **Remix IDE (Browser)** and **Ganache (Local Blockchain)**.

---

## 📋 Prerequisites

1.  **Ganache**: Download and run [Ganache](https://trufflesuite.com/ganache/). Ensure it's running on `http://127.0.0.1:7545`.
2.  **MetaMask**: Installed in your browser and connected to your local Ganache network.
3.  **Node.js**: Installed on your machine.
4.  **Remix IDE**: Access [remix.ethereum.org](https://remix.ethereum.org/).

---

## 🛠️ Phase 1: Smart Contract Deployment

Deploy the contracts in the **EXACT** order listed below to ensure dependencies are handled correctly.

### 1. Environment Setup in Remix
*   Go to **Deploy & Run Transactions** tab.
*   Set **Environment** to `Dev - Ganache Provider`.
*   Ensure the **Ganache JSON-RPC Endpoint** is `http://127.0.0.1:7545`.

### 2. Deployment Sequence

| Order | Contract | Constructor Arguments | Notes |
| :--- | :--- | :--- | :--- |
| **1** | `UserAuth.sol` | *None* | Handles user registration. |
| **2** | `RewardToken.sol` | `initialOwner` (Your account address) | ERC-20 token for rewards. |
| **3** | `Campaign.sol` | `_rewardTokenAddress` (Address of **Step 2**) | The Core Vault. |
| **4** | `Funding.sol` | `_campaignAddress` (Address of **Step 3**) | Contribution logic. |
| **5** | `AutoRefund.sol` | `_campaignAddress` (Address of **Step 3**) | Refund logic. |

---

## 🔗 Phase 2: Manual Linking (CRITICAL)

The contracts are independent; you must manually "plug" them together using these 3 transactions:

1.  **Authorize Funding Logic**:
    *   In Remix, select the deployed `Campaign` contract.
    *   Find the `authorizeModule` function.
    *   Paste the address of your deployed **`Funding`** contract.
    *   Click **transact**.
2.  **Authorize Refund Logic**:
    *   In Remix, select the deployed `Campaign` contract.
    *   Find the `authorizeModule` function.
    *   Paste the address of your deployed **`AutoRefund`** contract.
    *   Click **transact**.
3.  **Transfer Token Ownership**:
    *   In Remix, select the deployed `RewardToken` contract.
    *   Find the `transferOwnership` function.
    *   Paste the address of your deployed **`Campaign`** contract.
    *   Click **transact**. (This allows the vault to mint rewards).

---

## 💻 Phase 3: Application Configuration

### 1. Backend (`server.js`)
Open `server.js` and update the following lines with your newly deployed addresses:
```javascript
const campaignAddress = "YOUR_CAMPAIGN_ADDRESS";
const autoRefundAddress = "YOUR_AUTOREFUND_ADDRESS";
```

### 2. Frontend (`js/app.js`)
Open `js/app.js` and update all 5 addresses at the top of the file:
*   `userAuthAddress`
*   `campaignAddress`
*   `rewardTokenAddress`
*   `fundingAddress`
*   `autoRefundAddress`

---

## 🏃 Phase 4: Running the System

1.  **Install Dependencies** (First time only):
    ```powershell
    npm install
    ```
2.  **Start the Backend & Refund Bot**:
    ```powershell
    node server.js
    ```
3.  **Access the App**:
    Open your browser and navigate to `http://127.0.0.1:5000`.

---

> [!IMPORTANT]
> **Defensive Programming Note**: All contracts are hardened with `assert` and `revert` checks. If a transaction fails in Remix, check the console for specific error messages (e.g., "Funding: Campaign has ended").

> [!TIP]
> If you restart Ganache, you **must** redeploy all contracts and update all addresses in your code, as the blockchain state will be reset.
