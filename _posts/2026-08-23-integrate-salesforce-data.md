---
layout: single
title: "Salesforce : Integrate to Salesforce Org (Inbound REST API Guide)"
date: 2026-08-23
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

## 2. Security & Permission Scoping (Least Privilege Model)

Never assign `System Administrator` profiles to API integration accounts. Instead, enforce a **Minimum Access Policy**:

1. **Dedicated Integration User:** Assign the native **Salesforce Integration User License** (which offers cost-effective API-only access).
2. **Profile Scoping:** Assign a baseline profile with zero CRUD/FLS permissions.
3. **Custom Permission Sets:** Create a dedicated Permission Set (e.g., `PS_ERP_Inbound_Integration`) that explicitly grants:
* **Apex Class Access:** Required if calling Custom Apex REST endpoints (`@RestResource`).
* **Object CRUD & Field-Level Security (FLS):** Read/Create/Edit access strictly on target fields.
* **System Permission:** `Api Enabled` active.

---

## 3. API Design Options & Custom Apex REST Error Handling

Depending on payload complexity, data volume, and business logic requirements, select the correct integration mechanism:

### Option A: Standard Salesforce REST API

Best when the external system simply wants to perform standard CRUD operations directly on SObjects without complex transformation logic.

* **Endpoint Pattern:** `/services/data/v61.0/sobjects/Account/`
* **HTTP Methods:** `GET` (Read), `POST` (Create), `PATCH` (Upsert/Update via External ID), `DELETE`.
* **Pros:** Zero Apex code required; built-in platform indexing and error handling.

---

### Option B: Custom Apex REST API (`@RestResource`) with Standardized Error Contracts

When inbound data requires multi-object orchestration, complex validation, or custom response formatting, you build a Custom Apex REST API.

However, unlike standard APIs, **Custom Apex REST leaves error handling 100% up to the Apex developer**. You must explicitly set `RestContext.response.statusCode` and return a standardized error JSON schema. Returning an HTTP `200 OK` status with an embedded "error" message in the body is a critical anti-pattern that breaks external API gateway monitoring.

#### Apex Implementation Pattern: Exception Handling & HTTP Status Binding

```apex
@RestResource(urlMapping='/api/v1/orders/sync/*')
global with sharing class CustomOrderInboundAPI {

    @HttpPost
    global static CustomAPIResponse syncIncomingOrder() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        CustomAPIResponse responseWrapper = new CustomAPIResponse();

        try {
            // 1. Validate Payload & Parse JSON
            String requestBody = req.requestBody.toString();
            if (String.isBlank(requestBody)) {
                return buildErrorResponse(res, 400, 'INVALID_PAYLOAD', 'Request body cannot be empty.');
            }

            OrderPayload payload = (OrderPayload) JSON.deserialize(requestBody, OrderPayload.class);
            
            // 2. Business Validation
            if (String.isBlank(payload.externalOrderKey)) {
                return buildErrorResponse(res, 400, 'MISSING_REQUIRED_FIELD', 'externalOrderKey is mandatory.');
            }

            // 3. Execute Business Logic & Data Upserts
            Id orderId = CustomOrderService.processIncomingOrder(payload);

            // 4. Success Response (HTTP 200)
            res.statusCode = 200;
            responseWrapper.isSuccess = true;
            responseWrapper.recordId = orderId;
            responseWrapper.message = 'Order successfully synchronized.';

        } catch (QueryException qe) {
            // Target Record Not Found (HTTP 404)
            return buildErrorResponse(res, 404, 'RECORD_NOT_FOUND', qe.getMessage());
        } catch (System.JSONException je) {
            // Bad JSON Format (HTTP 400)
            return buildErrorResponse(res, 400, 'MALFORMED_JSON', 'Invalid JSON syntax: ' + je.getMessage());
        } catch (Exception e) {
            // Unexpected System Failure (HTTP 500)
            return buildErrorResponse(res, 500, 'INTERNAL_SERVER_ERROR', 'An unexpected error occurred: ' + e.getMessage());
        }

        return responseWrapper;
    }

    // Standardized Error Helper
    private static CustomAPIResponse buildErrorResponse(RestResponse res, Integer statusCode, String errorCode, String errorMessage) {
        res.statusCode = statusCode;
        CustomAPIResponse errResponse = new CustomAPIResponse();
        errResponse.isSuccess = false;
        errResponse.errorCode = errorCode;
        errResponse.message = errorMessage;
        return errResponse;
    }

    // Request & Response DTO Wrappers
    global class OrderPayload {
        public String externalOrderKey;
        public String accountName;
        public Decimal totalAmount;
    }

    global class CustomAPIResponse {
        public Boolean isSuccess;
        public String recordId;
        public String errorCode; // E.g., MISSING_REQUIRED_FIELD, MALFORMED_JSON
        public String message;   // Human-readable error detail
    }
}

```
