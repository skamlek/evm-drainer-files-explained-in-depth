# Wallet Scam: A Case Study in Crypto Drainer Tactics - Check Point Research

September 26, 2024

## Key takeaways

*   Check Point Research (CPR) uncovered a malicious app on Google Play designed to steal cryptocurrency marking the first time a drainer has targeted mobile device users exclusively. The app used a set of evasion techniques to avoid detection and remained available for nearly five months before being removed.
*   To pose as a legitimate tool for Web3 apps, the attackers exploited the trusted name of the WalletConnect protocol, which connects crypto wallets to decentralized apps. Fake reviews and consistent branding helped the app achieve over 10,000 downloads by ranking high in search results.
*   Advanced social engineering and the use of the most modern crypto drainer toolkit allowed the hackers to steal approximately $70,000 in cryptocurrency from victims.

## Introduction

Crypto drainers are malicious tools that steal digital assets like NFTs, and tokens from cryptocurrency wallets. They often use phishing techniques and leverage smart contracts to enhance their impact. Typically, users are tricked into visiting phishing websites that mimic legitimate cryptocurrency platforms. Drainers then initiate fraudulent transactions and deceive users into signing them, allowing the drainer to siphon off funds to the attacker.

As crypto wallets become more secure and Web3 users grow more aware of malicious techniques, it becomes increasingly challenging for attackers to trick a victim into authorizing a malicious drainer transaction. Now, cybercriminals are developing more sophisticated methods to deceive users.

Recently, attackers shifted their focus to mobile devices, marking the first time drainers exclusively targeted mobile users. Check Point Research (CPR) uncovered a malicious crypto drainer app on Google Play that exploited the name of the well-known Web3 protocol, WalletConnect, creating the illusion of legitimacy. Using advanced evasion techniques, first published on March 21, 2024, the app remained undetected for over five months and was downloaded over 10,000 times.

**Figure 1** – Malicious WalletConnect application in Google Play.

The fake WalletConnect application has already been removed from Google Play. However, it managed to victimize over 150 users, resulting in losses exceeding $70,000. Not all of the users who downloaded the drainer were affected. Some didn’t complete the wallet connection, others recognized suspicious activity and secured their assets, and some may not have met the malware’s specific targeting criteria.

## Exploiting WalletConnect Users With Social Engineering

WalletConnect is an open-source protocol that acts as a bridge between decentralized applications (dApps) and cryptocurrency wallets using either a QR code or deep linking, which are URLs that navigate directly to a particular part of an application. It allows users to interact with dApps directly from their mobile wallets without the need to expose private keys, making it a crucial tool for enhancing security and user experience in the decentralized finance (DeFi) ecosystem.

WalletConnect stablishes communication between dApps and mobile wallets. It was created to solve the problem of seamlessly connecting dApps with various wallets, ensuring a smooth and secure user experience.

**Figure 2** – WalletConnect workflow for connecting to a Web3 application.

However, users may experience issues with WalletConnect when connecting to Web3 applications. Some wallets don’t support WalletConnect. For example, one of the most popular wallets for EVM networks like Ethereum, MetaMask, did not support WalletConnect v2 until last year, causing difficulties for many users ([https://github.com/WalletConnect/walletconnect-monorepo/issues/2622]()). Additionally, even if a wallet implements WalletConnect support, some users may lack automatic app updates and still use outdated versions. In such situations, when opening a Web3 application in a mobile browser and attempting to connect the wallet via WalletConnect, the wallet app typically opens, but the connection does not occur.

If the wallet connection to a Web3 application fails, the wallet connection window can give the impression that WalletConnect is just another wallet like MetaMask. For example, this is how the connection window looks on the popular platform OpenSea:

**Figure 3** – Connecting a wallet to a Web3 application.

Given all the complications with WalletConnect, an inexperienced user might conclude that it is a separate wallet application that needs to be downloaded and installed. Attackers hijack the confusion, hoping that users will search for a WalletConnect app in the application store.

However, when searching WalletConnect in Google Play, users find the malicious app “WalletConnect – Crypto Wallet” at the top of the list:

**Figure 4** – Malicious WalletConnect app appearing at the top of Google Play search results.

Despite the app’s high rating and numerous positive reviews, a deeper, more thorough analysis is needed to uncover the following discrepancy:

**Figure 5** – Fake review and high rating of the malicious WalletConnect app.

Application reviews are evidently fake, as they are unrelated to the app’s actual content. After analyzing review pages, we found prevalent fake reviews in English, French, and Spanish.

## The Deceptive WalletConnect App

The malicious WalletConnect app we found has the package name – “`co.median.android.rxqnqb`” and was created using the service [median.co](). This service allows users to convert a website into an app for Android or iOS. The app essentially functions as a web browser that opens a specified site. [Median.co]() enables the configuration of the app icon, status bar, behavior when links are clicked, initial URL, and other parameters.

The app was published on Google Play on March 21, 2024 under the name “Mestox Calculator”. The application’s name was later changed several times.

**Figure 6** – Cached app page in Google.

### **Obfuscation and anti-analysis techniques**

In this section, we explore how the application operates and uncover why it has zero detection on VirusTotal (VT). We also explain how it passed verification on Google Play while remaining undetected for so long despite its obvious malicious nature.

**Figure 7** – APK detection on the VirusTotal.

The initial URL of the analyzed malicious Median application points to “`https://mestoxcalculator[.]com/`”.

If users visit this site through a browser, they will see a seemingly harmless web application, a multifunctional calculator with many features called “Mestox Calculator”. The website is based on the open-source project called [CalcDiverse]().

**Figure 8** – Mestox Calculator decoy application.

However, this is all a charade to evade detection of the app’s malicious functionality. Before we start, the complete workflow of how their resources operate is illustrated in the graph below:

**Figure 9** – Malicious application workflow.

Depending on certain parameters, such as the user’s IP address and User-Agent, the user is redirected to the following resource:

`https://connectprotocol[.]app/gate/index.php`

**Figure 10** – Redirecting to the malicious website.

This technique allows attackers to pass the app review process in Google Play, as automated and manual checks will load the “harmless” calculator application.

The new link hosts the actual malicious web application. However, another technique to evade analysis and detection is used during its loading phase. The main HTML page contains an embedded script encoded in BASE64:

**Figure 11** – Base64-encoded inline script on the main page of the malicious application.

This script loads another script, which is located at an address also stored in BASE64 encoding:

**Figure 12** – Decoded inline script.

After decoding the BASE64 string, we obtain the address from which the main malicious script is loaded: `https://mestoxcalculator[.]com/assets/js/jquery.min.js`. This script is also obfuscated and contains the core logic of the drainer.

### The Drainer’s Core Logic

The deobfuscated script reveals the functionality of a typical crypto drainer. It uses the WalletConnect library to interact with the victim’s wallet. The script is designed to steal various types of crypto assets, including native coins (like ETH, BNB) and ERC-20 tokens.

**Key functionalities observed:**

1.  **Wallet Connection**: Initiates a connection to the victim’s mobile wallet using WalletConnect.
2.  **Asset Discovery**: Once connected, the script queries the wallet for balances of native coins and a predefined list of valuable ERC-20 tokens.
3.  **Approval Requests**: For ERC-20 tokens, the drainer crafts `approve` transactions, requesting the victim to grant spending permission to an attacker-controlled address. Often, this is for the maximum possible amount (`MAX_UINT256`).
4.  **Transaction Signing**: The script presents these malicious transactions (approvals or direct transfers of native coins) to the victim for signing through the WalletConnect interface.
5.  **Asset Transfer**: Upon receiving the signed approval or transaction, the attacker can then transfer the assets from the victim’s wallet to their own.

### Backend Communication

While the Check Point article focuses primarily on the mobile app and frontend drainer script, typical drainer kits involve backend infrastructure for several purposes:

*   **Logging Victim Data**: The frontend script would send information about the connected wallet (address, IP, User-Agent, discovered assets) to a backend server. This is often done via POST requests to a PHP or Node.js endpoint.
*   **Managing Attacker Wallets**: The backend might provide fresh attacker-controlled wallet addresses to the frontend script to receive stolen funds, helping to avoid blacklisting.
*   **Storing Configuration**: The backend could host configurations for the drainer, such as lists of target tokens or specific smart contracts to interact with.
*   **Triggering Draining (Potentially)**: In some setups, after approvals are obtained, the backend might be responsible for initiating the `transferFrom` calls using its own Web3 provider and the victim’s approval, especially if the draining is delayed or batched.

The article mentions the redirect to `https://connectprotocol[.]app/gate/index.php`. This `index.php` script is a clear indicator of a PHP backend. This script likely handles:

*   **User-Agent and IP Filtering**: To serve the decoy content (calculator) to bots/reviewers and the malicious drainer page to potential victims.
*   **Logging initial contact**: Recording IP addresses and User-Agents that reach the gate.
*   **Serving the malicious HTML page**: Which then loads the JavaScript drainer.

Further backend components would likely exist to receive data from the JavaScript drainer once it successfully connects to a wallet and gets approvals. These would be separate endpoints, possibly on the same `connectprotocol[.]app` domain or another C2 server.

## Conclusion (from Check Point article, summarized)

The attackers used a sophisticated multi-stage approach, combining a deceptive app on Google Play, social engineering, and a crypto drainer toolkit. The use of `median.co` to wrap a website into an app, coupled with IP/User-Agent filtering at the `index.php` gate, allowed them to bypass Google Play’s security checks for an extended period. The core draining logic relies on tricking users into approving malicious transactions via WalletConnect.

This case highlights the evolving tactics of crypto thieves, extending their reach to mobile users and employing robust evasion techniques. Users need to be extremely cautious when downloading apps, even from official stores, and meticulously verify any permissions or transactions requested by crypto-related applications.
