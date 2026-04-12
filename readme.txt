Installation

Setup guide
Import folder

Click "contracts" -> Select one contract
Click "Solidity compiler" -> Select compiler above 0.8.0 -> Tick "Auto compile"
Click "Advanced Configurations" -> Make sure "LANGUAGE" = Solidity, "EVM VERSION" = london
Compile all contracts one by one
Back to "File explorer" -> Select "UserAuth.sol" under contracts
Click "Deploy & run transactions" -> Click "Deploy"
Back to "File explorer" -> Select "RewardToken.sol" under contracts
Click "Deploy & run transactions" -> Copy and Paste address of selected account into "initialOwner" -> Click "Deploy"
Back to "File explorer" -> Select "Campaign.sol" under contracts
Click "Deploy & run transactions" -> Copy and Paste address of deployed "RewardToken.sol" into "initialOwner" -> Click "Deploy"
Click deployed "RewardToken.sol" -> Click transferOwnership(address newOwner) function -> Copy and paste address of deployed "Campaign.sol" -> Click "transact"
Copy and paste all the deployed contracts ABI and address into app.js
Open terminal -> type "node server.js" -> Click "Enter"
Copy and paste the http address into a browser