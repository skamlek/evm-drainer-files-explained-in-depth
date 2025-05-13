## Database Schemas and Logging Mechanisms in EVM Wallet Drainer Backends

This document details the typical database schemas and logging mechanisms employed by the backend infrastructure of EVM wallet drainer kits. The information is derived from security research, analysis of how such systems would logically operate to manage data, and common practices in web application development that can be repurposed for malicious activities.

Drainer backends need to store various pieces of information to track victims, manage the attack lifecycle, and collect stolen assets. The choice of database and schema depends on the sophistication of the drainer kit.

### Common Data Points Logged

Regardless of the specific database technology, drainer backends aim to log comprehensive data about each interaction and victim. Key data points include:

1.  **Victim Identification & Connection Details**:
    *   Victim's wallet address (primary key for tracking).
    *   IP address.
    *   User-Agent string (browser, OS details).
    *   Timestamp of initial connection and subsequent interactions.
    *   Chain ID the victim is connected to.
    *   Referrer URL (how they reached the phishing site).

2.  **Asset Information**:
    *   Native currency balance (ETH, BNB, etc.).
    *   List of discovered ERC20 tokens: contract address, symbol, name, balance.
    *   List of discovered NFTs (ERC721, ERC1155): contract address, name, token IDs owned by the victim.
    *   Estimated value of assets (if the backend integrates with price oracles or APIs).

3.  **Approval Events**:
    *   For ERC20 tokens: token contract address, spender address (attacker's address/contract), approved amount (often `MAX_UINT256`), timestamp of approval.
    *   For NFTs (`setApprovalForAll`): NFT contract address, operator address (attacker's address/contract), approval status (`true`), timestamp.
    *   Details of signed messages if using `permit` (EIP-2612) or Seaport (EIP-712) signatures: the signed data, signature, intended use.

4.  **Draining Status & Transactions**:
    *   Status of the draining attempt (e.g., "pending_approval", "approved", "draining_in_progress", "partially_drained", "fully_drained", "failed").
    *   Transaction hashes of successful draining operations.
    *   Amounts and types of assets successfully transferred.
    *   Attacker's receiving address used for each transaction.
    *   Timestamp of draining transactions.
    *   Error messages or reasons for failed draining attempts.

5.  **Attacker/Campaign Management (Internal)**:
    *   Campaign ID (if the drainer kit is sold as a service and used by multiple attackers).
    *   Attacker's configured receiving wallet addresses (hot/cold wallets).
    *   Configuration settings for the specific phishing instance.

### Database Technology Choices

1.  **NoSQL Databases (e.g., MongoDB)**:
    *   **Prevalence**: Highly likely for many drainer kits, especially those built with Node.js.
    *   **Advantages**: Flexible schema allows for easy storage of varied and evolving data structures (like lists of different tokens and NFTs per victim). JSON-like document storage aligns well with JavaScript objects used in Node.js.
    *   **Schema Example (Conceptual MongoDB Collection: `victims`)**:
        ```json
        {
          "_id": "0xVictimWalletAddress_ChainID", // Composite key or just wallet address if single chain focus
          "wallet_address": "0xVictimWalletAddress",
          "chain_id": 1,
          "ip_address": "123.45.67.89",
          "user_agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) ...",
          "first_seen": "2025-05-12T10:00:00Z",
          "last_active": "2025-05-12T10:30:00Z",
          "status": "approved_usdt", // e.g., connected, approved_xyz, draining, drained, failed
          "notes": "High value target, monitor closely.",
          "assets": {
            "native_balance": "2.5 ETH",
            "erc20": [
              { "contract": "0xdAC17F958D2ee523a2206206994597C13D831ec7", "symbol": "USDT", "balance": "5000.75" },
              { "contract": "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48", "symbol": "USDC", "balance": "1200.50" }
            ],
            "nfts": [
              { "contract": "0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D", "token_ids": ["1234", "5678"] }
            ]
          },
          "approvals": [
            { "token_contract": "0xdAC17F958D2ee523a2206206994597C13D831ec7", "spender": "0xAttackerSpenderAddress", "amount": "unlimited", "timestamp": "2025-05-12T10:15:00Z" }
          ],
          "drain_attempts": [
            { "tx_hash": "0xabc...def", "asset_type": "USDT", "amount": "5000.75", "receiver": "0xAttackerReceiverWallet", "status": "success", "timestamp": "2025-05-12T10:20:00Z" }
          ]
        }
        ```

2.  **SQL Databases (e.g., MySQL, PostgreSQL, SQLite)**:
    *   **Prevalence**: Possible, especially if the attackers have a background in traditional web development or if the kit is more mature and requires complex querying.
    *   **Advantages**: Strong data integrity, transactional capabilities. SQLite could be used for simpler, self-contained backends.
    *   **Schema Example (Conceptual Tables)**:
        *   `Victims` (victim_id PK, wallet_address, ip, user_agent, first_seen, last_active, status)
        *   `VictimAssets` (asset_id PK, victim_id FK, asset_type, contract_address, symbol, balance_or_token_id)
        *   `Approvals` (approval_id PK, victim_id FK, token_contract, spender, amount, timestamp)
        *   `DrainTransactions` (tx_id PK, victim_id FK, tx_hash, asset_type, amount, receiver, status, timestamp)

3.  **Flat Files (JSON, CSV, Text Logs)**:
    *   **Prevalence**: Very common for simpler or hastily developed drainer kits. PHP backends might often log to text files or append JSON objects to a `.json` file.
    *   **Advantages**: Extremely easy to implement; no database server setup required. Sufficient for basic logging.
    *   **Disadvantages**: Difficult to query, prone to corruption, not scalable, security risks if web-accessible.
    *   **Example (JSON log file, one entry per line or as a large array)**:
        ```json
        {"timestamp": "2025-05-12T10:00:00Z", "event": "connection", "wallet": "0xVictim1...", "ip": "1.2.3.4"}
        {"timestamp": "2025-05-12T10:05:00Z", "event": "assets_discovered", "wallet": "0xVictim1...", "assets": [{"token": "USDT", "balance": 100}]}
        {"timestamp": "2025-05-12T10:15:00Z", "event": "approval_granted", "wallet": "0xVictim1...", "token": "USDT", "spender": "0xAttacker..."}
        ```

### Logging Mechanisms

*   **API Endpoints**: The primary mechanism. The frontend drainer script sends HTTP POST requests with data (usually JSON payloads) to backend API endpoints (e.g., `/log`, `/event`, `/victim_data`).
*   **Server-Side Scripting**: PHP, Node.js, or Python scripts on the server receive these requests, parse the data, and then write it to the chosen database or log file.
*   **Timestamping**: All log entries are critically timestamped to reconstruct the timeline of events.
*   **Error Logging**: Backends also log their own errors or errors reported by the frontend to help attackers debug and improve their drainer kits.

### Management of Attacker Wallets

The backend plays a role in managing the attacker's receiving addresses:

*   **Configuration**: A list of attacker-controlled wallet addresses (for receiving stolen funds) is often stored in a backend configuration file or database table.
*   **Rotation**: The backend might provide a fresh or less-used address to the frontend drainer for each new victim or transaction to make tracing harder and avoid single points of failure if one address gets blacklisted or flagged.
*   **Consolidation Logic (Advanced)**: More sophisticated backends might have logic to automatically sweep funds from these initial receiving addresses to more secure, consolidated cold wallets, possibly using cron jobs or other automated scripts.

Understanding these database and logging patterns is crucial for researchers to analyze the scope of drainer operations, identify attacker infrastructure, and potentially trace stolen funds, although attackers employ various obfuscation techniques to hinder such efforts.

