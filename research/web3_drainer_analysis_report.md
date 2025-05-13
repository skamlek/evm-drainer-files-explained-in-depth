# Comprehensive Analysis of Web3 Wallet Drainer Kits

**Date:** May 12, 2025

**Prepared by:** Manus AI

## Introduction

This report provides a detailed analysis of the operational mechanics, obfuscation techniques, and evasion strategies employed by real-world JavaScript-based Web3 wallet drainer kits, such as Inferno Drainer, Angel Drainer, and Monkey Drainer. The goal was to retrieve, deobfuscate, and fully explain how these active EVM wallet drainer kits operate at the code level.

Due to the illicit nature of these tools and active takedowns, obtaining full, operational, and unobfuscated source code for these drainer kits from public repositories or leaked sources proved challenging. Most available information comes from security researchers' analyses, technical blog posts, and partial code snippets. This report synthesizes these findings to provide a comprehensive understanding based on the available data, with a primary focus on Angel Drainer due to the more detailed public analysis available for it.

This report covers:

1.  The typical deobfuscation process for drainer scripts and an analysis of a sample configuration decryption script.
2.  An analysis of core drainer functionalities, including wallet connection, asset scanning, approval mechanisms, and the draining process itself.
3.  A detailed explanation of how drainers trigger wallet prompts and the methods used to force approvals or transfer tokens.
4.  An overview of common obfuscation and evasion patterns employed by these kits.

We will examine the Web3 libraries conceptually involved, patterns used to avoid detection, and how tokens are scanned and drained.




## 1. Deobfuscation Process and Configuration Analysis (Focus on Angel Drainer)





## 2. Core Drainer Functionalities (Based on Angel Drainer Analysis)



## Deobfuscation and Code Cleaning Process (Based on Angel Drainer Analysis)

While a full, operational drainer script (`wallet-drainer.js` or `index.js`) was not successfully retrieved from public sources during the initial search phase, the technical analysis of Angel Drainer by Bernhard Mueller on Medium provides significant insight into its obfuscation and structure. This section outlines the typical deobfuscation process for such a script, as described in the analysis, and then examines the provided configuration decryption script.

### Typical Deobfuscation Steps for Angel Drainer JavaScript:

The Angel Drainer's client-side JavaScript code is usually found heavily obfuscated to hinder analysis. The process to deobfuscate it, based on the Medium article, involves several layers:

1.  **Base64 Decoding**: The core drainer script is often embedded within a legitimate-looking JavaScript file as a very long Base64 encoded string.
    *   The first step is to extract this Base64 string.
    *   Then, decode it using a standard Base64 decoder (e.g., `base64 -d` command-line utility).

2.  **XZ Decompression**: The output of the Base64 decoding is not plain JavaScript but is typically compressed using the XZ compression algorithm.
    *   This compressed data needs to be decompressed using an XZ decompressor (e.g., `xz -d` command-line utility).
    *   The Angel Drainer reportedly uses a WebAssembly (WASM) based XZ decompressor to perform this unpacking dynamically at runtime in the victim's browser.

3.  **JavaScript Deobfuscation (obfuscator.io)**: After decompression, the result is JavaScript code, but it's usually heavily obfuscated using tools like `obfuscator.io`. This involves techniques such as:
    *   String array encoding (moving strings into an array and referencing them by index).
    *   Variable renaming to meaningless short names.
    *   Control flow flattening (making the code execution path harder to follow).
    *   Dead code injection.
    *   Constant and literal obfuscation.
    *   The Medium article mentions a specific deobfuscation tool `obfuscator-io-deobfuscator` (available on GitHub, e.g., by ben-sb) that can be used to reverse many of these transformations and produce more readable code. This tool typically applies multiple passes to simplify the code (e.g., `UnusedVariableRemover`, `ConstantPropagator`, `ReassignmentRemover`).

### Analysis of the Angel Drainer Configuration Decryption Script (`angel_drainer_decrypt_config.js`):

The provided `angel_drainer_decrypt_config.js` script is a Node.js utility designed to decrypt the configuration data used by the Angel Drainer. This configuration is likely fetched from a Command and Control (C2) server or embedded within the main drainer script in an encrypted form.

**Code Breakdown:**

```javascript
function base64ToByteString(base64) {
    return Buffer.from(base64, 'base64').toString('binary');
}

const CryptoJS = require('crypto-js'); // External library for cryptographic functions

function decryptBody(base64EncryptedString) {
    // Decode from Base64 to a raw byte string (though CryptoJS.AES.decrypt can often handle base64 directly)
    // const encryptedByteString = base64ToByteString(base64EncryptedString); // This line is commented out in the original snippet, likely not strictly needed if CryptoJS handles it.

    // Hardcoded AES decryption key. The article notes this key appears consistent across releases.
    const key = "y$B&E)H@McQfTjWmZq4t7w!z%C\\*F-JaNdRgUkXp2r5u8x/A?D(G+KbPeShVmYq3t6v9y$B&E)H@McQfTjWnZr4u7x!z%C\\*F-JaNdRgUkXp2s5v8y/B?D(G+KbPeShVmY";

    // AES decryption using CryptoJS
    // CryptoJS.AES.decrypt expects the ciphertext and the key.
    // It automatically handles aspects like IV if they are part of the standard OpenSSL-compatible format that CryptoJS uses by default.
    const decrypted = CryptoJS.AES.decrypt(base64EncryptedString, key);

    // Convert the decrypted data (which is a WordArray object in CryptoJS) to a UTF-8 string.
    const decryptedText = decrypted.toString(CryptoJS.enc.Utf8);

    return decryptedText;
}

// Command-line argument handling to pass the encrypted string
if (process.argv.length !== 3) {
    console.log("Usage: node decrypt.js <base64_encoded_encrypted_string>");
    process.exit(1);
}

const base64EncryptedString = process.argv[2]; // Get the encrypted string from command line
const decryptedString = decryptBody(base64EncryptedString);
console.log("Decrypted String:", decryptedString);
```

**Functionality:**

1.  **Dependencies**: It requires the `crypto-js` library, a popular JavaScript library for various cryptographic operations.
2.  **Key**: A hardcoded AES key is used for decryption. The article notes that this key (`y$B&E)H@McQfTjWmZq4t7w!z%C\*F-JaNdRgUkXp2r5u8x/A?D(G+KbPeShVmYq3t6v9y$B&E)H@McQfTjWnZr4u7x!z%C\*F-JaNdRgUkXp2s5v8y/B?D(G+KbPeShVmY`) seems to be static across different Angel Drainer versions, which is a significant finding for defenders.
3.  **Decryption Process**:
    *   It takes a Base64 encoded encrypted string as input (presumably the encrypted configuration data).
    *   It uses `CryptoJS.AES.decrypt` to perform AES decryption.
    *   The decrypted output is then converted to a UTF-8 string, which would be the JSON configuration object.
4.  **Usage**: The script is intended to be run from the command line, passing the Base64 encoded encrypted configuration string as an argument.

**Cleaned Code and Purpose:**

The script itself is already quite clean and serves a specific purpose: to allow an analyst (or the malware operator) to decrypt and view the drainer's operational configuration. This configuration, as shown in the Medium article, contains vital information such as:

*   `receiver`: The primary address where stolen assets are sent.
*   `seaport_receiver`: Specific receiver for assets from Seaport (an NFT marketplace protocol).
*   `ethContractAddress`: Address of a helper smart contract used by the drainer.
*   `researchers_latest`: A blacklist of addresses (e.g., known security researchers, Vitalik Buterin) to avoid draining, likely to reduce visibility and detection.
*   `multicall`: Address for a multicall contract (used to batch transactions).
*   `percentage`: The cut taken by the drainer service operator (e.g., 85% to the user of the drainer kit, meaning 15% to the drainer provider, though the article states 30% for Inferno, this might vary).
*   Details about specific token contracts, NFT collections, and various flags controlling the drainer's behavior.

This decryption script is a valuable tool for understanding the specific targets and operational parameters of a given Angel Drainer instance, assuming one can obtain the encrypted configuration string.


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




## 3. Wallet Prompt Triggers and Token Draining Methods in Web3 Drainers



## Wallet Prompt Triggers and Token Draining Methods in Web3 Drainers

This document details how Web3 wallet drainers, such as Angel Drainer, trigger wallet prompts (e.g., from MetaMask or via WalletConnect) and the subsequent methods used to force approvals or directly transfer tokens and NFTs from a victim's wallet. The analysis is based on publicly available technical breakdowns, particularly the insights into Angel Drainer.

### How Drainers Trigger Wallet Prompts

Wallet prompts are the primary interface through which users authorize blockchain interactions. Drainers are expertly designed to manipulate users into approving malicious requests presented through these standard wallet interfaces. The phishing website's deceptive design and messaging are crucial for success.

1.  **Initial Connection Prompt**:
    *   **Trigger**: When a victim lands on the phishing page, a script typically calls `eth_requestAccounts` (or similar methods like the older `enable()`) on the `window.ethereum` provider (for browser extensions) or initiates a WalletConnect session.
    *   **Wallet Prompt**: The user sees a prompt from their wallet (e.g., MetaMask) asking, "Allow [phishing_site_domain] to connect to your wallet?" or "Connect to this site?". The prompt usually states that the site will be able to see their address, account balance, and activity, and request transaction approvals.
    *   **User Deception**: The phishing site (e.g., fake NFT mint, airdrop, DEX) makes this appear as the first legitimate step to use the service.

2.  **Token Approval Prompts (ERC20 Tokens)**:
    *   **Trigger**: To steal ERC20 tokens, the drainer needs the victim to approve an attacker-controlled address (or a malicious contract) as a spender. The drainer script crafts a call to the `approve(spender, amount)` function of the target ERC20 token contract.
        *   `spender`: Attacker's address/contract.
        *   `amount`: Usually the maximum possible uint256 value (`2^256 - 1`), effectively granting unlimited approval. This is the `approveMax()` tactic.
    *   **Wallet Prompt**: MetaMask (and other wallets) will display a prompt like: "Allow [phishing_site_domain] to spend your [Token_Symbol]?" It will specify the token, the amount (often shown as "Unlimited"), and the spender address. Gas fees for this approval transaction are also shown.
    *   **User Deception**: The site will claim this approval is necessary for interacting with a smart contract, staking tokens, enabling trading, or participating in the fake service. For example, "Approve your USDT to participate in the presale."

3.  **NFT Approval Prompts (ERC721 & ERC1155)**:
    *   **Trigger**: For NFTs, drainers typically aim for broader permissions by calling the `setApprovalForAll(operator, approved)` function on the NFT contract.
        *   `operator`: Attacker's address/contract.
        *   `approved`: `true`.
    *   **Wallet Prompt**: The wallet will show a prompt like: "Allow [phishing_site_domain] to access all your [NFT_Collection_Name]?" or "Set approval for all [NFT_Symbol]?" This grants the operator permission to transfer *any* NFT from that collection owned by the victim.
    *   **User Deception**: Phishing sites might frame this as verifying NFT ownership for a game, enabling marketplace features, or staking NFTs.

4.  **Transaction Signing Prompts (Native Currency & Direct Contract Calls)**:
    *   **Trigger**: To steal native currency (ETH, BNB, etc.), the drainer crafts a standard transaction using `eth_sendTransaction` where the `to` address is attacker-controlled, and `value` is the amount to steal (often the victim's entire balance, or a significant portion).
    *   **Wallet Prompt**: The wallet displays a transaction confirmation prompt showing the recipient address, the amount of native currency being sent, and the estimated gas fees.
    *   **User Deception**: This is often disguised as a "mint fee," "gas fee for airdrop," "service activation fee," or a payment for a fake item/service.

5.  **Message Signing Prompts (Permits, Off-chain Orders - EIP-712, `personal_sign`)**:
    *   **Trigger**: Some drainers use off-chain signature schemes to gain approvals or authorize actions. This involves methods like `eth_signTypedData_v4` (for EIP-712, used in `permit` for ERC20s, Seaport orders) or `personal_sign`.
    *   **Wallet Prompt**: The wallet shows a "Signature Request" prompt. It displays the data to be signed, which can be structured (EIP-712) or a simple message (`personal_sign`). Importantly, these prompts often *do not* explicitly state that a transaction is occurring or that gas fees are involved (because the signature itself is off-chain).
    *   **User Deception**: Users might be told they are "verifying wallet ownership," "logging in securely," or "agreeing to terms." The signed message, however, can be used by the attacker to execute on-chain actions like token transfers (via `permit` + `transferFrom`) or fulfilling malicious Seaport orders.
    *   **Seaport Interaction**: Drainers targeting NFT marketplaces like OpenSea (which uses Seaport) heavily rely on tricking users into signing EIP-712 messages. These signatures can authorize listing items at zero price, accepting bogus offers, or granting private sale permissions to the attacker. The Angel Drainer analysis mentions specific handling for Seaport, indicating its importance.

### How Drainers Force Approvals or Transfer Tokens

"Forcing" is achieved through social engineering and exploiting the user's trust or misunderstanding of the prompts. The drainer doesn't technically *force* the wallet, but rather manipulates the user into authorizing malicious actions.

1.  **Exploiting Approvals**:
    *   **ERC20 Tokens**: Once `approve(attacker_address, unlimited_amount)` is signed by the victim, the attacker (or their contract) can call `transferFrom(victim_address, attacker_receiver_address, victim_balance)` on the token contract at any time to steal all approved tokens. This can be done immediately or later.
    *   **NFTs**: After `setApprovalForAll(attacker_address, true)` is signed, the attacker can call `safeTransferFrom(victim_address, attacker_receiver_address, token_id)` for any NFT in that collection owned by the victim.

2.  **Direct Transfers**:
    *   **Native Currency**: If the victim signs a transaction sending ETH/BNB directly to the attacker's address, the funds are transferred immediately upon transaction confirmation.

3.  **Signed Message Exploitation**:
    *   **Permit (EIP-2612)**: If a victim signs a `permit` message, the attacker can take that signature and call the token contract's `permit` function followed by `transferFrom` in a single transaction (often paid for by the attacker) to steal the tokens.
    *   **Seaport Orders**: A signed Seaport order (EIP-712 message) can be submitted by the attacker to the Seaport marketplace contract to execute a trade that benefits the attacker (e.g., buying the victim's valuable NFT for a negligible amount, or selling a worthless NFT to the victim for a high price if they also tricked them into approving WETH spending).

4.  **Multicall Contracts**: Drainers often use multicall contracts. This allows them to batch multiple malicious operations (e.g., several `transferFrom` calls for different tokens, multiple NFT transfers) into a single transaction that the victim is tricked into signing. This can be more efficient for the attacker and sometimes harder to scrutinize quickly in a wallet prompt if it just shows an interaction with the multicall contract itself without clearly itemizing all sub-transactions.

5.  **Backend Coordination and Dynamic Receiver Addresses**:
    *   The client-side drainer script communicates with a backend. This backend can provide fresh, non-blacklisted receiver addresses for stolen funds.
    *   The Angel Drainer analysis noted the use of "unmarked" contract addresses for high-value asset withdrawal to evade tools like BlockAid. The drainer client would notify the backend, and a new contract would be counterfactually deployed for the withdrawal. This dynamic nature makes blocking difficult.

**In summary, drainers operate by:**

*   **Deception**: Creating convincing phishing sites.
*   **Exploiting Standard Wallet Functions**: Using legitimate wallet API calls (`eth_requestAccounts`, `approve`, `setApprovalForAll`, `eth_sendTransaction`, `eth_signTypedData_v4`) for malicious ends.
*   **Social Engineering**: Crafting narratives that make the malicious wallet prompts seem like normal and necessary steps.
*   **Technical Evasion**: Obfuscating code, using dynamic infrastructure, and employing techniques to bypass security tools and blacklists.




## 4. Obfuscation and Evasion Patterns in Web3 Drainer Kits





## 4. Obfuscation and Evasion Patterns in Web3 Drainer Kits

Web3 wallet drainer kits employ a variety of sophisticated obfuscation and evasion techniques to hide their malicious nature, prolong their operational lifespan, and bypass security measures. This document outlines common patterns observed, drawing heavily from the analysis of kits like Angel Drainer and Inferno Drainer.

### I. JavaScript Code Obfuscation

The primary goal of code obfuscation is to make the drainer script unreadable and difficult to analyze for security researchers and automated tools.

1.  **Multi-Layer Obfuscation**: Drainer scripts are rarely protected by a single obfuscation method. They typically use several layers, requiring a step-by-step deobfuscation process.

2.  **Initial Encoding/Compression**:
    *   **Base64 Encoding**: The core malicious JavaScript payload is often found as a very long Base64 encoded string embedded within a seemingly innocuous loader script on the phishing page.
    *   **Compression (e.g., XZ, Gzip)**: After Base64 decoding, the resulting data is frequently found to be compressed (e.g., Angel Drainer uses XZ compression). This further reduces the size and hides the plaintext JavaScript.
    *   **Runtime Decompression**: Some drainers, like Angel, reportedly use WebAssembly (WASM) based decompressors to unpack the script dynamically in the victim's browser at runtime. This makes static analysis harder as the final payload isn't immediately visible.

3.  **Advanced JavaScript Obfuscators (e.g., obfuscator.io)**:
    Once decompressed, the JavaScript code itself is heavily mangled using tools like `obfuscator.io` or custom obfuscators. Common techniques include:
    *   **String Array Encoding**: All literal strings are moved into a separate, often shuffled and encoded, array. References in the code are then made to this array via index, sometimes with an additional decoding function call for each string access.
    *   **Variable and Function Renaming**: Meaningful names are replaced with short, cryptic, or hexadecimal-like names (e.g., `_0xabc123`).
    *   **Control Flow Flattening**: The logical flow of the code is deliberately convoluted using techniques like `switch` statements within `while` loops, making it extremely difficult to follow the execution path manually.
    *   **Dead Code Injection**: Useless or irrelevant code blocks are inserted to confuse analysts and increase the overall code size.
    *   **Literal Obfuscation**: Numbers and simple literals might be represented as complex expressions.
    *   **Proxy Functions**: Simple operations are wrapped in multiple layers of function calls.
    *   **Self-Defending Code**: Some obfuscators include anti-debugging and anti-tampering checks, though this is more common in traditional malware than web scripts.

### II. Communication Obfuscation

Drainers need to communicate with a Command and Control (C2) server to fetch configurations, report stolen assets, and receive instructions. This communication is often obfuscated.

1.  **Encrypted C2 Communication**: As seen with Angel Drainer, communication between the client-side drainer script and its backend API (e.g., `https://api.ipjsonapi.com`) is encrypted. Angel Drainer uses AES with hardcoded keys for this purpose. This prevents trivial interception and analysis of C2 traffic.
2.  **On-Chain Encrypted Configurations**: The Check Point research on Inferno Drainer mentioned that command server addresses were encrypted and stored on the blockchain, adding another layer of difficulty in identifying the C2 infrastructure.

### III. Anti-Detection and Evasion Techniques

These techniques are designed to avoid detection by users, wallet software, security extensions, and threat intelligence platforms.

1.  **Bypassing Wallet Security Extensions**:
    *   Drainers actively try to circumvent browser extensions designed to detect phishing and malicious transactions (e.g., WalletGuard, Pocket Universe, BlockAid).
    *   The Angel Drainer analysis highlighted a specific method: overriding the `request` method of the `window.ethereum` provider and forwarding RPC calls directly to the wallet (e.g., MetaMask) via `window.postMessage`. This can hide the malicious interactions from extensions that primarily monitor the standard provider's methods.

2.  **Dynamic Code and Configuration Loading**:
    *   Instead of embedding the entire malicious logic statically, parts of the drainer script or its configuration can be fetched dynamically from the C2 server after the initial compromise. This allows attackers to update tactics without redeploying the entire phishing site.

3.  **Rapid Infrastructure Rotation**:
    *   **Domains**: Phishing websites are hosted on domains that are frequently changed to evade blacklists. Attackers use newly registered domains, compromised legitimate websites, or typosquatted domains.
    *   **IP Addresses**: C2 servers and hosting infrastructure IPs are also rotated regularly.
    *   **Wallet Addresses**: Receiver wallet addresses for stolen funds are often changed, or intermediate wallets are used to quickly move funds through mixers or to exchanges.

4.  **Blacklist Evasion Tactics**:
    *   **Exempting Known Researchers/VIPs**: The Angel Drainer configuration included a blacklist of addresses (`researchers_latest`), such as those belonging to known security researchers or prominent figures (e.g., Vitalik Buterin). Draining these wallets would attract unwanted attention, so they are often deliberately skipped.
    *   **Dynamically Generated/Unmarked Contracts**: For high-value targets, Angel Drainer was observed using dynamically generated, previously unused ("unmarked") smart contract addresses for withdrawals. This is a direct attempt to bypass security tools like BlockAid, which rely on blacklists of known malicious contract addresses. The drainer client would coordinate with the backend to counterfactually create these contracts as needed.

5.  **Use of Single-Use or Short-Lived Smart Contracts**:
    *   Attackers may deploy malicious smart contracts (e.g., for approvals or specific draining functions) that are used for only one or a few victims before being abandoned. This limits the window for detection and blacklisting of these contract addresses.

6.  **Proxy-Based Communication Architectures**:
    *   More advanced drainer services (like later versions of Inferno Drainer) offload communication with the core C2 infrastructure to proxy servers. These proxies might be set up by the "customers" of the drainer-as-a-service, making it significantly harder to trace back to the actual drainer developers and their central servers.

7.  **Conditional Redirection and Cloaking**:
    *   Phishing sites may employ cloaking techniques, where different content is served to suspected security researchers or bots (based on IP address, user agent, etc.) than to genuine victims. Intermediate servers might perform conditional redirection, only forwarding users who meet certain criteria to the actual malicious page.

8.  **Sophisticated Social Engineering**:
    *   While not a code-level technique, the effectiveness of drainers heavily relies on convincing social engineering. Phishing sites are meticulously crafted to impersonate legitimate DApps, NFT projects, airdrop campaigns, or Web3 services. The language, branding, and user experience are designed to lull victims into a false sense of security, making them more likely to approve malicious wallet prompts.

These combined obfuscation and evasion strategies make Web3 drainers a persistent and challenging threat in the cryptocurrency ecosystem.


## V. Web3 Libraries and General Patterns

While specific `wallet-drainer.js` or `index.js` files were not directly retrieved and deobfuscated in their entirety, the analysis of drainer behavior and partial code indicates the conceptual use of common Web3 libraries and patterns:

*   **Web3 Libraries (Conceptual Usage)**:
    *   **ethers.js or web3.js**: Drainer scripts inherently need to interact with the Ethereum Virtual Machine (EVM) and user wallets. Functionalities like connecting to wallets (`eth_requestAccounts`), querying balances (`getBalance`), interacting with smart contracts (calling `approve`, `transferFrom`, `setApprovalForAll`, `balanceOf`, `ownerOf`), signing messages (`signTypedData_v4`, `personal_sign`), and sending transactions (`sendTransaction`) are all standard operations facilitated by libraries like ethers.js or web3.js. The drainer scripts would bundle or dynamically load such a library or implement the necessary RPC calls directly.
    *   **WalletConnect SDK**: To target mobile wallet users, drainers integrate the WalletConnect SDK to establish a connection via QR codes or deep links.

*   **Patterns for Avoiding Detection (Recap)**:
    *   Heavy obfuscation of client-side JavaScript (multi-layer, Base64, compression, obfuscator.io).
    *   Encrypted C2 communication.
    *   Dynamic loading of malicious payloads/configurations.
    *   Rapid rotation of domains, IPs, and receiver wallet addresses.
    *   Blacklisting of researcher/VIP addresses.
    *   Use of unmarked/dynamically generated contracts for withdrawals (BlockAid evasion).
    *   Bypassing security extensions by directly interacting with wallet provider's low-level messaging.
    *   Sophisticated social engineering on phishing sites.

*   **How Tokens are Scanned and Drained (Recap)**:
    1.  **Connection**: Establish connection to the victim's wallet (MetaMask, WalletConnect).
    2.  **Asset Scanning**: Query native token balance. Iterate through lists of known valuable ERC20/NFT contracts or use backend APIs to discover assets across multiple chains. Call `balanceOf` (ERC20, ERC1155) and `ownerOf` (ERC721) to confirm holdings. Prioritize based on value (often with backend assistance).
    3.  **Approval Solicitation**: Trick user into signing `approve` (for ERC20s, often for `MAX_UINT256`), `setApprovalForAll` (for NFTs), or Seaport-related approval messages. Disguise these as necessary steps for the fake service.
    4.  **Draining**: Once approvals are granted, use `transferFrom` (ERC20s, NFTs) or execute malicious Seaport orders to transfer assets to attacker-controlled wallets. Use `sendTransaction` for native currency. Multicall contracts are often used to batch operations.

## VI. Conclusion

Web3 wallet drainer kits are sophisticated pieces of malware that combine advanced JavaScript obfuscation, encrypted communications, and clever social engineering to defraud users. While obtaining complete, unobfuscated kits is difficult due to their illicit nature and active takedowns, analysis of their behavior, configurations (like those from Angel Drainer), and the techniques reported by security researchers provides a clear picture of their modus operandi.

Key characteristics include:

*   **Multi-layered obfuscation** to hinder analysis.
*   **Reliance on standard wallet interactions** (connection requests, approvals, transaction signing), which are then subverted through deceptive user interfaces and messaging.
*   **Targeting of a wide range of assets**, including native currencies, ERC20 tokens, and NFTs, often across multiple chains.
*   **Use of backend infrastructure** for configuration, asset valuation, and sometimes dynamic code loading or receiver address management.
*   **Continuous evolution of evasion techniques** to bypass security tools and blacklists.

The primary defense against these drainers remains user vigilance, the use of reputable security tools (though not foolproof), and careful scrutiny of all wallet prompts, especially those requesting broad approvals or involving high-value transactions. Understanding the technical mechanisms, as outlined in this report, is crucial for developers, security professionals, and users in mitigating the risks posed by these threats.

## VII. References

*   Mueller, B. (2023). *A brief analysis of Angel Drainer*. Medium. (Specific URL was browsed: https://muellerberndt.medium.com/a-brief-analysis-of-angel-drainer-1660d15c9248)
*   Group-IB. (2023). *Inferno Drainer: Unmasking the $87M crypto fraud operation*. Group-IB Blog. (Specific URL was browsed: https://www.group-ib.com/blog/inferno-drainer/)
*   Checkpoint Research. (2025). *Inferno Drainer Reloaded: Deep Dive into the Return of the Most Sophisticated Crypto Drainer*. Checkpoint Blog. (Specific URL was browsed: https://research.checkpoint.com/2025/inferno-drainer-reloaded-deep-dive-into-the-return-of-the-most-sophisticated-crypto-drainer/)
*   GitHub repositories related to `obfuscator-io-deobfuscator` (conceptual, e.g., by ben-sb).
*   General knowledge of ethers.js, web3.js, WalletConnect SDK, and EVM interactions.

**Disclaimer:** *This report is for informational and educational purposes only. Interacting with or attempting to replicate malware is dangerous and should only be done in secure, isolated environments by qualified professionals.*
