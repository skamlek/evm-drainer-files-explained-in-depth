## Backend Tech Stack and Integration Patterns in EVM Wallet Drainer Kits

This document outlines the typical backend technologies and integration methods employed by EVM wallet drainer kits. The analysis is based on information from security research reports, observed malware behavior, and common web development practices adapted for malicious purposes.

### Typical Backend Tech Stacks

Wallet drainer backends are essentially web servers designed to manage the phishing operation, log victim data, and sometimes interact with the blockchain to facilitate the theft of assets. Common choices for the tech stack include:

1.  **PHP**: PHP is a widely used server-side scripting language, particularly for web development. Its ease of deployment and large number of available hosting providers make it a common choice for attackers.
    *   **Evidence**: The Check Point Research article on a mobile WalletConnect drainer explicitly mentions a redirect to `https://connectprotocol[.]app/gate/index.php`. The `.php` extension strongly indicates a PHP backend script responsible for initial filtering (cloaking) and serving the malicious payload.
    *   **Frameworks**: Attackers might use lightweight frameworks or no framework at all, relying on basic PHP scripts to handle POST requests from the frontend drainer, log data to files or a database, and manage configurations.

2.  **Node.js with Express.js**: Node.js is a popular JavaScript runtime that allows developers to build scalable server-side applications. Express.js is a minimal and flexible Node.js web application framework.
    *   **Rationale**: JavaScript developers creating the frontend drainer scripts might find it convenient to use Node.js for the backend, allowing them to use the same language across the stack. Libraries like `Web3.js` or `ethers.js` can be easily integrated for on-chain interactions if the backend needs to trigger transactions.
    *   **Usage**: The backend would expose API endpoints (e.g., `/log_connection`, `/report_approval`, `/get_config`) that the frontend drainer script communicates with.

3.  **Python with Flask/Django**: Python is another versatile language popular for web development, with frameworks like Flask (micro-framework) and Django (full-featured framework).
    *   **Rationale**: Python's simplicity and powerful libraries, including `Web3.py` for blockchain interactions, make it a viable option for drainer backends.
    *   **Usage**: Similar to Node.js, a Python backend would provide API endpoints for the frontend to send data and receive instructions.

4.  **Other Server-Side Languages**: While less commonly detailed in public reports for drainers, other server-side languages like Ruby, Go, or Java could theoretically be used, though PHP, Node.js, and Python appear more prevalent due to ease of use and deployment for such illicit activities.

### Frontend-Backend Integration Patterns

The frontend drainer script (running in the victim's browser on the phishing site) and the backend server communicate to coordinate the attack. Key integration patterns include:

1.  **Initial Payload Delivery & Cloaking**: 
    *   The first point of contact is often a "gate" script on the backend (e.g., the `index.php` mentioned by Check Point).
    *   This gate script typically performs filtering based on the visitor's IP address, User-Agent string, and possibly other headers or referrer information.
    *   **Purpose**: To serve benign content (e.g., a fake calculator, a seemingly legitimate but non-functional site) to automated scanners, security researchers, or geolocations unlikely to be victims. Real victims are redirected to or served the actual malicious phishing page with the drainer script.
    *   The malicious drainer script itself might be heavily obfuscated and loaded dynamically, sometimes in stages, with parts fetched from the backend.

2.  **API Endpoints for Data Exchange**: The frontend drainer communicates with the backend via HTTP requests (usually POST) to specific API endpoints. Common data exchanges include:
    *   **Logging Connection**: When a victim connects their wallet, the frontend sends the wallet address, chain ID, IP address, User-Agent, and potentially a list of discovered valuable assets to a backend logging endpoint (e.g., `/api/log_victim`).
    *   **Reporting Approvals/Signatures**: When a victim approves a malicious transaction (e.g., `approve`, `setApprovalForAll`, `signTypedData_v4` for permits or Seaport orders), the frontend notifies the backend, sending details of the approval (token contract, spender, signature if applicable).
    *   **Fetching Configuration**: The frontend might fetch configuration data from the backend, such as:
        *   A list of target ERC20 token addresses and NFT contract addresses to scan for.
        *   The attacker's current receiving wallet address (which can be rotated by the backend to avoid blacklisting).
        *   Specific parameters for malicious transactions (e.g., gas settings, specific function calls).
    *   **Error Reporting**: The frontend might send error information back to the backend for the attacker to monitor issues with the drainer script.

3.  **Data Format**: Communication typically uses JSON as the data format for requests and responses between the frontend and backend.

4.  **Security (from Attacker's Perspective)**:
    *   Backend endpoints might be obfuscated or not publicly discoverable.
    *   Communication might involve some form of simple encryption or encoding if the attackers are more sophisticated, though often it's plain HTTP/HTTPS with JSON.
    *   The backend server itself will be chosen for anonymity and resilience against takedowns (e.g., bulletproof hosting).

### Example Workflow (Conceptual)

1.  Victim visits phishing URL.
2.  Backend gate (`index.php`) checks IP/User-Agent. If deemed a real target, serves the malicious HTML/JS.
3.  Frontend drainer script runs in the victim's browser.
4.  Victim connects wallet.
5.  Frontend POSTs `{'wallet_address': '0x...', 'ip': '...'}` to backend endpoint `/api/connect`.
6.  Backend logs this information.
7.  Frontend scans for assets, potentially guided by a config fetched from `/api/config`.
8.  Victim is tricked into signing an `approve` transaction.
9.  Frontend POSTs `{'wallet_address': '0x...', 'token_approved': '0xUSDT...', 'spender': '0xAttacker...'}` to `/api/approval`.
10. Backend logs the approval. Now the attacker (or an automated backend process) knows they can call `transferFrom` on the USDT contract for this victim.

This integration allows the attackers to centrally manage their operations, collect data on victims, and adapt their tactics by modifying backend configurations without needing to update the frontend script on every compromised site directly (though frontend updates are also common).

