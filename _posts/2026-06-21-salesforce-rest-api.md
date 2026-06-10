---
layout: single
title: "Salesforce : Designing Resilient REST API Interfaces"
date: 2026-06-21
categories:
  - Development
tags:
  - LWC
  - Salesforce
  - Apex
  - REST API
---

## 1. Overview: The Integration Landscape (REST vs. SOAP)

In an enterprise Salesforce ecosystem, data architecture extends far beyond the boundaries of a single cloud. As a Data Architect or integration engineer, designing a seamless data exchange strategy between Salesforce and external applications is one of the most critical structural decisions you will make. 

When it comes to web service integrations, Salesforce provides two foundational API protocols out of the box: **REST (Representational State Transfer) API** and **SOAP (Simple Object Access Protocol) API**. 

Choosing between them is not merely a matter of developer preference; it is an architectural trade-off involving performance, data volume, system constraints, and contract governance.

---

### 1.1 REST API: The Lightweight, Modern Standard

REST has become the industry standard for modern web integrations due to its simplicity, scalability, and loose coupling.

* **Architectural Style:** REST is an architectural style that relies on stateless operations and utilizes standard HTTP methods (`GET`, `POST`, `PUT`, `PATCH`, `DELETE`) to perform CRUD operations on resources.
* **Payload Flexibility:** It supports multiple data formats, predominantly **JSON** and **XML**. JSON’s lightweight footprint significantly reduces serialization overhead and network bandwidth, making it the ideal choice for high-throughput mobile apps, modern web frameworks, and real-time events.
* **Scalability:** Because it is stateless, REST APIs scale exceptionally well in high-volume, transactional environments.

---


### 1.2 SOAP API: The Rigid, Enterprise-Grade Protocol
SOAP is a highly structured, strict protocol that has long been the backbone of legacy enterprise systems, financial networks, and corporate ERPs.
* **Contract-Driven (WSDL):** SOAP relies strictly on the **WSDL (Web Services Description Language)**, an XML-based contract that rigidly defines the exact structure of requests and responses. This ensures absolute compile-time data integrity between endpoints.
* **Payload Restriction:** It exclusively supports **XML**. While XML guarantees strict typing and schema validation, its verbose nature introduces noticeable parsing overhead and increased payload sizes compared to JSON.
* **Enterprise Security & ACID Compliance:** SOAP natively supports advanced WS-Security standards and transactional reliability, making it a frequent requirement for banking, legacy on-premise systems, and scenarios where multi-step transactional rollbacks are mandatory.
---

### 1.3 Deep Dive: Serialization Payloads (JSON vs. XML)
While the protocol sets the rules of engagement, the data format handles the actual payload weight. When designing RESTful interfaces that are capable of consuming or producing **both JSON and XML**, evaluating the serialization payload becomes critical.
| Serialization Feature | JSON (JavaScript Object Notation) | XML (Extensible Markup Language) |
| :--- | :--- | :--- |
| **Readability & Weight** | Lightweight, minimalist, key-value syntax. | Verbose, uses opening/closing tags. |
| **Parsing Overhead** | Extremely low. Native JSON serialization in Apex. | Higher. Requires DOM or SAX parsing trees. |
| **Data Types** | Supports Arrays, Numbers, Strings, Booleans natively. | Treats everything as textual strings by default. |
| **Schema Validation** | Optional (JSON Schema). | Strict, built-in validation via XSD. |

#### ⚠️ Real-World Gotcha: Native XmlStreamReader vs. Community XMLParser
When dealing with legacy XML integrations, Salesforce’s native **`XmlStreamReader`** introduces a critical roadblock: it cannot gracefully parse **CDATA** blocks (`<![CDATA[ ... ]]>`)—which external ERPs frequently use to embed raw HTML, SQL, or nested JSON payloads.
* **The Native Problem (Token Skipping):** The native `XmlStreamReader` often skips or truncates text tokens nested inside CDATA boundaries, causing silent data loss and requiring convoluted, unmaintainable loops to bypass.
* **The Solution (Bypassing with `XMLParser`):** To resolve this platform limitation, I abandoned raw native stream handling and utilized a widely adopted community open-source **`XMLParser`** utility class. This wrapper treats the payload as a raw string matrix to safely isolate and extract CDATA buffers without risking token degradation.
This exact engineering hurdle is why **JSON remains the superior, defensive choice** for modern enterprise contracts whenever you have the authority to negotiate the interface schema.

## 2. Secure Authentication: Named Credentials

When establishing an outbound REST connection, hardcoding endpoints, client secrets, or bearer tokens inside Apex classes is a critical security vulnerability. Salesforce provides **Named Credentials** to securely abstract authentication management.

By using Named Credentials, Apex code remains clean and environment-agnostic, calling a symbolic name rather than a raw URL string:

```apex

// Abstracted callout utilizing platform-secured Named Credentials
HttpRequest req = new HttpRequest();
req.setEndpoint('callout:My_External_ERP_Endpoint/v1/sync');
req.setMethod('POST');

```

## 3. Managing Governor Limits: The Integration Guardrails

Every outbound HTTP request must play by the strict rules of the Salesforce multitenant framework. For an integration engineer, ignoring these boundaries will inevitably cause transaction crashes in production. Here are the five critical guardrails you must architect around:

### 3.1 The "Callout Before DML" Rule 

You cannot execute an HTTP request if there is an uncommitted DML transaction pending in the current context. If you insert a record and then immediately call a REST API, the system throws a `System.CalloutException: You have uncommitted work pending`.
  * *The Fix:* Always architect your transactional sequence to trigger all external REST integration calls **before** saving or updating records to the database via DML.

### 3.2 Timeout Constraints (The 120-Second Limit) 
Synchronous callouts are capped at a maximum cumulative timeout of **120 seconds** per transaction. By default, the platform sets a 10-second timeout if not specified.
  * *The Fix:* Always set defensive timeouts using `req.setTimeout()`. For high-volume bulk synchronizations that exceed two minutes, decouple the transaction loop using asynchronous patterns like `Queueable Apex` or `Batch Apex`.
    
### 3.3 The 100-Callout Cap & The Danger of Loops:** Salesforce restricts a single transaction to a maximum of **100 HTTP callouts**.
 * *The Trap:* A common anti-pattern is executing a callout inside a `for` loop (e.g., iterating over a trigger batch). If the batch size exceeds 100, the transaction immediately crashes with a `System.LimitException`.
 * *The Fix:* Always bulkify your integration architecture. Instead of making 100 individual REST calls for 100 records, negotiate with the external system to accept a **composite batch payload** (a single JSON array) in one single HTTP request.

* **3.4 Heap Size Thresholds (6MB Synchronous / 12MB Asynchronous):** Cryptographic conversions, heavy XML/JSON string mapping, and handling raw binary Blobs consume a massive memory footprint.
 * *The Trap:* When fetching or sending large transactional datasets, parsing the response into custom Apex classes can instantly trigger an `Apex heap size exceeded` exception.
 * *The Fix:* For high-volume payloads, keep your data structures lean, minimize the use of temporary state variables, and leverage asynchronous processing (Queueable/Batch Apex) to double your heap runway from 6MB to 12MB.
