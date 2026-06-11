---
layout: single
title: "Apex: Salesforce Apex  Crypto Class"
date: 2026-06-07
categories:
  - Development
tags:
  - Apex
  - Salesforce
  - Crypto Class
---

In modern enterprise architecture, Salesforce rarely operates as an isolated island. It is constantly communicating with external ecosystems—whether it's syncing financial records with an on-premise ERP, sending customer payloads to a legacy billing system, or orchestrating webhooks with third-party APIs.

When designing these **external interfaces**, security cannot be an afterthought. Passing raw, sensitive data across the wire exposes your architecture to severe compliance and security vulnerabilities. Many third-party systems mandate that inbound data payloads be strictly encrypted, signed, or hashed before transmission to guarantee confidentiality and data integrity.

This is exactly where the native Apex **`Crypto` class** becomes an indispensable asset in your integration toolkit.

```
[Salesforce Apex] --(Encrypted Payload / Digital Signature)--> [External ERP / Third-Party API]

```

Instead of spinning up costly external middleware just to handle payload encryption, the `Crypto` class allows developers to implement industry-standard cryptographic algorithms directly within the platform. It serves as the primary engine for:

* **Securing Outbound Payloads:** Utilizing symmetric encryption (like AES128 or AES256) to completely obfuscate data before it leaves the Salesforce boundary.
* **Verifying Data Integrity & Authenticity:** Implementing Message Authentication Codes (MAC/HMAC) to ensure that the payload wasn't tampered with during transit.
* **Digital Signatures & Non-Repudiation:** Generating and verifying digital signatures using asymmetric keys to establish ironclad trust between Salesforce and external endpoints.

In this post, we’ll explore how to leverage the Apex `Crypto` class to build secure outbound interfaces, protect sensitive data, and implement industry-standard cryptographic patterns natively in Salesforce.

---

## 2. Available Algorithm 

In the past, Salesforce supported DES and Triple DES for its cryptographic algorithms. However, as these algorithms became internationally recognized as vulnerable and deprecation was highly recommended, Salesforce discontinued their support. Currently, it exclusively supports AES. 

Salesforce Crypto Class Technical Specifications:

Encryption Algorithm: AES (Advanced Encryption Standard) with 128, 192, and 256-bit keys

AES128, AES128-CBC
AES192, AES192-CBC
AES256, AES256-CBC
AES256-GCM

Cipher Mode & Padding: Supports CBC mode with PKCS7/PKCS5 padding, and GCM (Galois/Counter Mode) for authenticated encryption to mitigate padding oracle vulnerabilities

Data Integrity & Hashing: Supports HMAC (SHA-256, SHA-512) and Digital Signatures (RSA/ECDSA) for message authentication and non-repudiation.

### 2.1 Alignment with Global Compliance Standards (NIST & FIPS)

The transition away from legacy algorithms like DES and 3DES isn't just a Salesforce platform update; it is a strict enforcement of international cryptographic compliance. 

According to the **NIST (National Institute of Standards and Technology)** guidelines, block ciphers with a 64-bit block size (such as Triple DES) are susceptible to practical collision attacks (e.g., the Sweet32 vulnerability). Consequently, modern enterprise architectures mandate the use of **AES (Advanced Encryption Standard)** with minimum key lengths of 128 bits, though 256-bit keys are preferred for future-proofing sensitive data.

Furthermore, the choice between cipher modes dictates your system's vulnerability posture:
 **AES-CBC (Cipher Block Chaining):** Reliable but requires a unique Initialization Vector (IV) for every operation. It is vulnerable to padding oracle attacks if the decryption errors are improperly handled by the external API.
 **AES-GCM (Galois/Counter Mode):** Widely recognized as the industry gold standard for modern HTTP integrations (such as TLS 1.3). It provides **AEAD (Authenticated Encryption with Associated Data)**, meaning it encrypts the payload and verifies its integrity simultaneously, neutralizing padding oracle threats entirely.

## 3. Real-World Implementation Patterns

When integrating with third-party APIs, raw cryptographic data cannot be transmitted as raw strings or binary Blobs. They must be handled carefully using Apex `Blob` methods and formatted via `EncodingUtil` (Base64 or Hex) to ensure safe HTTP transport.

### 3.1 Outbound Payload Encryption using AES256 (With Managed IV)

When sending highly sensitive data (such as financial payloads or personally identifiable information) to an external system, symmetric encryption is the standard defense. 

Using `Crypto.encryptWithManagedIV()` is the platform best practice. Salesforce automatically generates a secure, random Initialization Vector (IV), executes the encryption, and prepends the IV to the cipher text so you don't have to manage it manually.

```java
public class CryptoClass {
    public static String encryptOutboundPayload(String plainText, Blob privateKey) {
        if (String.isBlank(plainText) || privateKey == null) {
            return null;
        }
        
        // 1. Convert the plain text string into a binary Blob
        Blob dataToEncrypt = Blob.valueOf(plainText);
        
        // 2. Encrypt using AES256 with an automatically managed Initialization Vector (IV)
        Blob encryptedBlob = Crypto.encryptWithManagedIV('AES256', privateKey, dataToEncrypt);
        
        return EncodingUtil.base64Encode(encryptedBlob);
    }
}

```

### 3.2 Securing Webhooks via HMAC-SHA256 Signatures

While symmetric encryption obfuscates the payload, many standard webhooks require an assertion of message authenticity without the overhead of full decryption. This is achieved via a Hash-based Message Authentication Code (HMAC). 

By sharing a secret key with the external system, Salesforce can sign the outbound request body. The receiver calculates the identical hash to ensure the payload was not intercepted or altered by a Man-in-the-Middle (MitM) attack.

```java
    /**
     * @description Generates a hex-encoded HMAC-SHA256 signature for API header verification
     * @param requestBody The raw HTTP request body string
     * @param secretKey The pre-shared secret string
     * @return Hex-encoded signature string
     */
    public static String generateHMAC(String requestBody, String secretKey) {
        if (requestBody == null || secretKey == null) {
            return null;
        }
        
        Blob targetBlob = Blob.valueOf(requestBody);
        Blob keyBlob = Blob.valueOf(secretKey);
        
        // Generate Message Authentication Code (MAC) natively
        Blob hmacBlob = Crypto.generateMac('HmacSHA256', targetBlob, keyBlob);
        
        return EncodingUtil.convertToHex(hmacBlob);
    }

```

## 4. Architect's Note: Enterprise Key Lifecycle Management

An encryption architecture is only as secure as its key storage mechanism. Implementing a flawless Crypto class method yields zero defensive value if your private keys are compromised.

Never Hardcode Secrets: Storing private keys or webhook tokens as plain strings inside Apex classes exposes them to anyone with metadata visibility or source repository access.

Leverage Protected Custom Metadata: Store encryption secrets within Protected Custom Metadata Types inside a managed package environment. This keeps them entirely invisible to subscriber org admins.

Utilize Named Credentials: When orchestrating outbound calls requiring client certificates or asymmetric signatures, generate the keystore entries via Salesforce's native Certificate and Key Management setup and reference them cleanly via Named Credentials.

## 5. Summary & Performance Considerations

When extending your Salesforce org to interact with compliance-heavy external networks, the native Crypto class provides a performant, platform-managed perimeter.

However, keep the platform limits in mind: cryptographic functions process data as Blob data types. Converting large, multi-megabyte payloads into binary arrays can aggressively spike your transaction's Apex Heap Limit (6MB synchronous / 12MB asynchronous). Always validate your payload data footprint before executing heavy cryptographic transformations.


👉 [Previous Crypto Apex Class Document](https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_classes_restful_crypto.htm)
