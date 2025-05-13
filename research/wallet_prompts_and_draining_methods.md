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
