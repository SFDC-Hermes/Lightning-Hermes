---
layout: single
title: "Salesforce : Integrate to Salesforce Org (Inbound REST API Guide)"
date: 2026-08-16
categories:
  - Development
tags:
  - Apex
  - Salesforce
  - Data
  - REST API
  - Integration
---

When external systems (such as an ERP, legacy database, mobile backend, or AWS microservice) need to push data into or retrieve data from Salesforce via REST API (GET, POST, PATCH, DELETE), the Salesforce Developer is responsible for laying down the security, authentication, and API architecture.

External development teams often view Salesforce as a black box. As the platform developer, your role is not just writing Apex—it is defining **how they authenticate**, **where they send requests**, **what permissions they hold**, **how HTTP status codes are returned**, and **how error contracts should be structured**.

This guide outlines the end-to-end technical responsibilities required to open an Inbound REST API endpoint securely and professionally.

---

## 1. Authentication & Connected App Setup

Before an external client can issue a single HTTP request, they must establish an authenticated OAuth 2.0 session. In Salesforce, this is configured via a **Connected App**.

```text
┌──────────────────────────┐                                 ┌──────────────────────────┐
│     External System      │                                 │      Salesforce Org      │
│                          │  1. Request OAuth Token         │                          │
│   * Client ID & Secret   ├──────────────────────────────►  │   * Connected App        │
│     OR Signed JWT        │  (POST to Token Endpoint)       │   * Validates Identity   │
│                          │                                 │                          │
│                          │  2. Returns Bearer Access Token │                          │
│   * Retains Session      │  ◄──────────────────────────────┤                          │
│                          │                                 │                          │
│   * Issues HTTP REST     │  3. Inbound API Request         │                          │
│     (GET/POST/PATCH)     ├──────────────────────────────►  │  * Executes Apex / Data  │
│                          │  (Authorization: Bearer Token)  │    within User Context   │
└──────────────────────────┘                                 └──────────────────────────┘
```

### 1.1 OAuth 2.0 Flow Selection

Depending on the client's system architecture, you must choose and configure the appropriate OAuth flow:

* **OAuth 2.0 Client Credentials Flow (Recommended for simplicity):** Best for server-to-server integrations where the external client can securely store a `client_id` and `client_secret`.
* **OAuth 2.0 JWT Bearer Token Flow (Recommended for maximum security):** Essential for enterprise financial or high-security integrations. Requires asymmetric cryptography using an **X.509 Digital Certificate** (JKS/CRT format). You receive the public certificate from the external team and upload it directly into the Connected App setup.

### 1.2 Token Endpoint Environment Matrix & Delivery Guardrails

External teams frequently confuse environment URLs during integration testing. You must explicitly differentiate and deliver the **Test (Sandbox) environment URL** and your **My Domain URL** as separate, distinct endpoints:

| Environment Target | Auth Token Endpoint URL |
| --- | --- |
| **Test / Sandbox Org (Generic)** | `https://test.salesforce.com/services/oauth2/token` |
| **My Domain (Org-Specific)** | `https://<my-domain>.my.salesforce.com/services/oauth2/token` |

> ⚠️ **Architect's Warning: Strict Differentiated Delivery Required**
> You **MUST** deliver the Test/Sandbox URL and the My Domain URL as separate configuration items to the external development team, explicitly detailing when to use each:
> 1. **Generic Test Endpoint (`test.salesforce.com`):** Standard entry point for initial sandbox OAuth requests during integration testing.
> 2. **My Domain Endpoint (`<my-domain>.my.salesforce.com`):** Required when org policy enforces My Domain login restrictions, IP range boundaries, or Enhanced Domains.
> 
> 
> Conflating or incorrectly swapping these two URLs will trigger immediate `400 Bad Request` or `INVALID_SESSION_ID` errors. Always ensure the external team configures these endpoints in distinct environment variables within their API client.

---
