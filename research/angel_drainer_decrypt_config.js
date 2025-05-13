function base64ToByteString(base64) {
    return Buffer.from(base64, 'base64').toString('binary');
}

const CryptoJS = require('crypto-js');

function decryptBody(base64EncryptedString) {
    // Decode from Base64 to a raw byte string
    const encryptedByteString = base64ToByteString(base64EncryptedString);

    console.log(encryptedByteString);

    // const key = "F-JaNdRgUkXp2r5u8x/A?D(G+KbPeShVmYq3t6v9y$B&E)H@McQfTjWnZr4u7x!z%C\\*F-JaNdRgUkXp2s5v8y/B?D(G+KbPeShVmYq3t6w9z$C&F)H@McQfTjWnZr4u7";
    const key = "y$B&E)H@McQfTjWmZq4t7w!z%C\\*F-JaNdRgUkXp2r5u8x/A?D(G+KbPeShVmYq3t6v9y$B&E)H@McQfTjWnZr4u7x!z%C\\*F-JaNdRgUkXp2s5v8y/B?D(G+KbPeShVmY";

    const decrypted = CryptoJS.AES.decrypt(base64EncryptedString, key);
    const decryptedText = decrypted.toString(CryptoJS.enc.Utf8);

    return decryptedText;
}

if (process.argv.length !== 3) {
    console.log("Usage: node decrypt.js <base64_encoded_encrypted_string>");
    process.exit(1);
}

const base64EncryptedString = process.argv[2];
const decryptedString = decryptBody(base64EncryptedString);
console.log("Decrypted String:", decryptedString);
