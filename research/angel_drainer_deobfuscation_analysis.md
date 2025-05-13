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
