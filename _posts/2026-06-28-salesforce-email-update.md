---
layout: single
title: "Salesforce : Single Email Verification "
date: 2026-06-28
categories:
  - Concepts
tags:
  - Apex
  - Salesforce
  - Setting
  - DKIM Key
---

Historically within the Salesforce ecosystem, executing outbound email communications only required **Single Email Verification (User-Level Verification)**. An individual user simply clicked a verification link sent to their inbox, and the platform granted permission to route outbound emails using their email address.

However, as email spoofing, phishing, and domain-impersonation vectors have evolved, major email service providers (such as Google and Yahoo) have aggressively tightened their security frameworks for bulk senders. In response, Salesforce email infrastructure has underwent a major structural evolution: moving away from isolating verification at the "individual user level" toward enforcing ironclad trustworthiness at the **"corporate domain level."**

---

## 1. Spring '26 Update: Mandatory Domain Verification (Hard Enforcement)
Starting with the **Spring '26 release**, Salesforce has systematically restricted outbound email rules. Even if an individual user's email address is successfully verified at the user profile level, **if the top-level domain following the "@" symbol has not been authenticated at the Org level, the email delivery will completely fail.**
This change is not a mere recommendation; it is a **hard enforcement**. This security boundary directly impacts every outbound communication pipe in your org, including:
* Automated workflow email alerts
* Flow Builder `Send Email` actions
* Imperative Apex integrations executing `Messaging.SingleEmailMessage`
If your domain is unverified, emails will be silently dropped or hard-bounced by receiving mail servers, breaking critical business communication flows.

## 2. Comparing Compliance Strategies: DKIM Keys vs. Authorized Domains
To prove domain ownership and satisfy the modern compliance matrix, Salesforce provides two distinct architectural paths. For optimal deliverability and domain governance, **implementing DKIM (DomainKeys Identified Mail) is the industry best practice.**

| Strategy | Verification Mechanism | DNS Record Required | Architect's Verdict |
| :--- | :--- | :--- | :--- |
| **DKIM Key**<br>(Recommended) | Attaches a cryptographic digital signature to the email header to prove authenticity and guarantee the payload wasn't tampered with mid-transit. | CNAME<br>(2 records: Main & Alternate Selector) | **Highly Recommended.** It fully satisfies the platform domain validation rule while drastically improving email deliverability. It minimizes the risk of your business emails landing in the recipient's spam folder. Salesforce completely automates the key rotation cycle. |
| **Authorized Email Domains** | A lighter list-based registry that validates ownership via a single handshake code. | TXT<br>(Salesforce Verification Code) | **Alternative Only.** This method validates domain ownership but does not inject advanced cryptographic signing into the email headers. It should only be used as a temporary fallback if your corporate IT infrastructure cannot immediately deploy a DKIM configuration. |

## 3. Implementation Guide: Configuring and Activating DKIM Keys

To ensure uninterrupted automated business alerts from your org, follow this production-ready setup pipeline to establish your DKIM foundation:

### 3.1 Generating the DKIM Key in Salesforce
1. Navigate to **Setup** ➔ Search for **DKIM Keys** in the Quick Find box.
2. Click **Create New Key**.
3. Select a key size of **2048-bit** (the modern standard for robust asymmetric encryption; avoid the legacy 1024-bit option unless strictly restricted by old network hardware).
4. Enter a unique string for the **Selector** and **Alternate Selector** (e.g., `sf1` and `sf2`). Salesforce requires two selectors to perform seamless, zero-downtime automated key rotations behind the scenes.
5. Provide your exact domain name (e.g., `yourcompany.com`) and choose your desired domain match pattern, then save.

### 3.2 Updating the Corporate DNS Records
Once saved, Salesforce generates the exact public key details mapped to two CNAME records.
* Export these CNAME configurations and route them to your corporate IT Infrastructure/Network routing team.
* The network team must publish these CNAME records into your public corporate DNS registrar (e.g., AWS Route 53, Cloudflare, GoDaddy).
* Allow a buffer window for global DNS propagation (typically taking anywhere from a few minutes up to a couple of hours).

### 3.3 Activating the Key
* Once DNS propagation is complete, return to the **DKIM Keys** list view in Salesforce.
* Click into your generated key and select **Activate**.
* Upon successful activation, Salesforce instantly starts signing all outbound mail payloads originating from that domain with an enterprise-grade digital signature, completely clearing the modern verification guardrails.

## 4. Conclusion & Architectural Takeaway
Relying entirely on legacy Single Email Verification links is no longer a viable defense mechanism for enterprise communication channels. As a System Architect, it is critical to proactively audit your active outbound email domains, coordinate with your networking team, and bind an active 2048-bit DKIM Key to every sender domain to maintain complete business continuity.
