---
layout: single
title: "Apex: Salesforce Apex Class"
date: 2026-06-07
categories:
  - Development
tags:
  - Apex
  - Salesforce
  - Crypto Class
---

## 1. Overview

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

👉 [Previous Crypto Apex Class Document](https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_classes_restful_crypto.htm)
