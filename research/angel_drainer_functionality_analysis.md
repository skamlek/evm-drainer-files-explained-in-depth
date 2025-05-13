## Analysis of Angel Drainer Core Functionalities (Based on Available Technical Details)

This document outlines the core functionalities of Web3 wallet drainers like Angel Drainer, based on the technical analysis by Bernhard Mueller (Medium) and other publicly available information. Since full source code was not retrieved, this analysis relies on descriptions of behavior, configuration details, and partial code snippets.

### 1. Wallet Connection (`connectWallet()` - Conceptual)

Drainer kits need to interact with the victim's browser-based Web3 wallet (e.g., MetaMask, Trust Wallet via WalletConnect, Coinbase Wallet). The connection process is typically initiated when the victim lands on a phishing page designed to mimic a legitimate DApp, NFT mint, airdrop claim, or other Web3 service.

*   **Mechanism**: The phishing page's JavaScript code will trigger a connection request to the wallet extension or mobile wallet.
    *   For browser extensions like MetaMask, this usually involves checking for the presence of `window.ethereum` (or `window.web3`) provider injected by the wallet.
    *   It then calls methods like `eth_requestAccounts` or the older `enable()` to prompt the user to connect their wallet to the site.
    *   For WalletConnect, the drainer would integrate the WalletConnect SDK, display a QR code or deep link, and wait for the user to approve the connection from their mobile wallet.
*   **User Prompt**: The user sees a standard wallet prompt asking for permission to connect the site to their wallet, allowing the site to view their address and suggest transactions.
*   **Information Gained**: Once connected, the drainer script gains access to the user's public wallet address and the current network (e.g., Ethereum Mainnet, Binance Smart Chain).

### 2. Asset Scanning (`scanAssets()` - Conceptual)

After a successful wallet connection, the drainer needs to identify valuable assets held by the victim. This is a crucial step to maximize the theft.

*   **Multi-Chain Capability**: Sophisticated drainers like Angel are often multi-chain. The decrypted configuration for Angel Drainer (as shown in the Medium article) includes parameters for different chains and assets.
*   **Process**:
    1.  **Native Currency Balance**: The drainer will query the balance of the native currency (e.g., ETH, BNB, MATIC) on the connected chain(s) using standard RPC calls like `eth_getBalance`.
    2.  **ERC20 Token Balances**: It will iterate through a predefined list of valuable ERC20 token contract addresses or use a more dynamic approach to discover tokens held by the user. For each potential token, it calls the `balanceOf` function of the token contract with the victim's address.
    3.  **NFT Holdings (ERC721, ERC1155)**: The drainer will query known valuable NFT contract addresses or use services/APIs that list NFTs owned by an address. It would check for ownership using functions like `ownerOf` (ERC721) or `balanceOf` (ERC1155).
    4.  **Prioritization**: The Angel Drainer configuration includes details like an "exhaustive list of the user’s assets, including tokens and NFTs across various blockchains, as well as the estimated value of each asset. This helps the drainer prioritize the most valuable assets." This implies communication with a backend that provides asset valuation or the drainer itself has some valuation logic.
*   **Backend Communication**: The client-side drainer script likely sends the victim's address to its backend API (e.g., `https://api.ipjsonapi.com` mentioned for Angel Drainer). The backend might perform the heavy lifting of asset discovery and valuation across multiple chains and return a prioritized list of assets to target.

### 3. Approval Mechanisms and Triggering Wallet Prompts (`approveMax()`, `setApprovalForAll()` - Conceptual)

To steal ERC20 tokens and NFTs, the drainer needs the victim to approve the drainer's contract (or an address controlled by the attacker) to spend those assets on their behalf.

*   **ERC20 Tokens - `approve()` / `permit()`**:
    *   The most common method is to trick the user into signing an `approve()` transaction. The drainer will craft a transaction that calls the `approve()` function on the target ERC20 token contract. The `spender` argument will be an attacker-controlled address or a malicious contract, and the `amount` will typically be the maximum possible value (uint256_max) to allow draining all tokens of that type, now and in the future. This is often referred to as `approveMax()`.
    *   The user sees a wallet prompt asking them to approve token spending. The phishing site will use social engineering to make this seem like a necessary step (e.g., 

        "Verify your assets to receive airdrop", "Enable trading for a new token").
    *   Some drainers might also exploit `permit()` (EIP-2612) for certain ERC20 tokens. This allows approvals via an off-chain signature, which can be less alarming to users as it doesn't immediately show up as an on-chain transaction requiring gas. The drainer tricks the user into signing a `permit` message, then the attacker submits this signature along with a `transferFrom` call in a single transaction.
*   **NFTs (ERC721, ERC1155) - `setApprovalForAll()`**:
    *   For NFTs, the drainer will typically request the user to approve an operator for all their NFTs of a specific collection (or even all collections if the phishing site is generic enough, though less common for specific NFT projects).
    *   This is done by calling the `setApprovalForAll(operator, approved)` function on the NFT contract. The `operator` is an attacker-controlled address, and `approved` is set to `true`.
    *   The user sees a wallet prompt asking to "Set approval for all" or similar, which grants the attacker broad permissions over their NFTs from that contract.
*   **Seaport (for OpenSea etc.) - `approve()` on conduit controller**:
    *   Modern NFT marketplaces like OpenSea use protocols like Seaport. Draining assets listed or traded here involves interacting with Seaport's contracts. This often means tricking users into signing approvals that grant a malicious contract (or the attacker's Seaport conduit) permissions to execute orders on their behalf. The Angel Drainer config specifically mentions a `seaport_receiver` and uses Seaport-related functions.
    *   The user might be presented with a prompt that looks like they are listing an item, accepting an offer, or signing a new marketplace terms of service, but it's actually an approval for the drainer's malicious Seaport interactions.

### 4. Draining Assets (`drain()` - Conceptual)

Once the necessary approvals are in place, the drainer can proceed to transfer the assets out of the victim's wallet.

*   **ERC20 Tokens**: The attacker (or their malicious contract, now approved as a spender) calls the `transferFrom(from, to, amount)` function on the ERC20 token contract. `from` is the victim's address, `to` is an attacker-controlled address (e.g., the `receiver` address from the Angel Drainer config), and `amount` is the victim's entire balance of that token (or as much as was approved).
*   **NFTs (ERC721, ERC1155)**: The attacker (now an approved operator) calls `safeTransferFrom(from, to, tokenId)` (ERC721) or `safeTransferFrom(from, to, id, amount, data)` (ERC1155) on the NFT contract to transfer NFTs to their wallet.
*   **Native Currency (ETH, BNB, etc.)**: This is usually stolen by tricking the user into signing a standard `sendTransaction` call. The phishing site will present a fake reason for the transaction (e.g., "gas fee for airdrop claim", "mint fee", "contract interaction fee"). The transaction will simply send the native currency to an attacker's address.
*   **Multicall Contracts**: Drainers often use multicall contracts (the Angel Drainer config has a `multicall` address) to batch multiple draining operations (e.g., multiple `transferFrom` calls for different tokens, NFT transfers) into a single transaction. This can be more efficient and potentially less suspicious to some on-chain monitoring if not carefully analyzed.
*   **Backend Coordination**: The drainer script communicates with its backend throughout this process. The backend might provide the sequence of transactions to execute, the specific receiver addresses (which can be rotated or dynamically generated for high-value targets to evade blacklists, as noted in the Angel Drainer analysis regarding "unmarked" contract addresses for BlockAid evasion), and confirm successful exfiltration of assets.
*   **Value Prioritization**: As mentioned, drainers prioritize high-value assets. The configuration and backend logic will guide which assets to target first and which draining methods to employ (e.g., using dynamically generated unmarked contracts for high-value assets to bypass tools like BlockAid).

### 5. Triggering Wallet Prompts (MetaMask / WalletConnect)

All interactions that modify the blockchain state or grant permissions require the user's explicit approval via their wallet.

*   **Connection**: `eth_requestAccounts` (or similar) triggers a prompt to connect.
*   **Approvals**: `approve` (ERC20), `setApprovalForAll` (NFTs), or Seaport-related approval calls trigger transaction signing prompts. The prompt will show the contract being interacted with, the function being called, and the parameters (e.g., spender address, approval status).
*   **Transfers**: `sendTransaction` (for native currency) or any function call that results in a state change (like `transferFrom` if the drainer itself is a contract executing these) will trigger a transaction signing prompt. The prompt will detail the recipient, amount (for native currency), gas fees, and data payload.
*   **Message Signing**: `signTypedData_v4` (for EIP-712 permits, Seaport orders) or `personal_sign` (less common for direct draining but used in other scams) will trigger a signature request prompt. This prompt is often less alarming to users as it might not explicitly state "transaction" or show gas fees, but the signed message can authorize significant actions.

**Social Engineering is Key**: The phishing website's design and messaging are critical for convincing the user that these prompts are legitimate and expected actions within the context of the fake service they believe they are using.

### 6. Anti-Detection and Evasion Techniques

Drainers employ various methods to avoid detection by users, wallets, and security tools.

*   **Obfuscation**: As detailed in `angel_drainer_deobfuscation_analysis.md`, heavy JavaScript obfuscation (Base64, XZ compression, obfuscator.io) is standard.
*   **Dynamic Code Loading**: Fetching parts of the malicious script dynamically from C2 servers.
*   **Encrypted Communication**: Angel Drainer encrypts communication with its backend API using AES, with hardcoded keys.
*   **Anti-Phishing Extension Bypass**: The Angel Drainer analysis highlights a specific technique to bypass extensions like WalletGuard and Pocket Universe by overriding the `request` method of the Ethereum provider and forwarding calls directly to MetaMask via `window.postMessage`. This hides the interaction from extensions that proxy the provider's `request` method.
*   **Rotating Domains and Infrastructure**: Phishing sites and C2 server domains are frequently changed.
*   **Blacklist Evasion (Researcher Addresses)**: The Angel Drainer config includes a list of `researchers_latest` addresses that are exempt from draining, likely to avoid detection by known security researchers or high-profile wallets.
*   **BlockAid Evasion (Unmarked Contracts)**: For high-value assets, Angel Drainer uses dynamically generated, previously unused ("unmarked") smart contract addresses for withdrawals. The drainer client notifies the backend, and a contract is counterfactually created at that address. This aims to bypass security tools like BlockAid that flag transactions involving known malicious addresses. However, the article notes this isn't always fully successful as BlockAid might still flag the transaction due to interaction with an untrusted EOA (Externally Owned Account).
*   **Single-Use Smart Contracts**: Some drainers deploy smart contracts for a single victim or a small number of victims and then abandon them.

This analysis, while based on partial information, provides a strong conceptual understanding of how drainer kits like Angel Drainer operate at a functional level.
