## Obfuscation and Evasion Patterns in Web3 Drainer Kits

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
